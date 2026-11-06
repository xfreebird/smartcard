import Dispatch
import Foundation
import MoldSignKit


/// Owns listener lifetime and the worker/main-loop boundary. Authorization policy stays in the application.
final class BridgeHost: BridgeHosting {
    private(set) var state: BridgeState = .stopped { didSet { onStateChange?() } }
    var previewPDFEnabled: (() -> Bool)?
    var previewPDF: ((BridgeRequest, Data, @escaping (PDFStampDecision) -> Void) -> Void)?
    var authorize: ((BridgeRequest, @escaping (BridgeDecision) -> Void) -> Void)?
    var onSignResult: ((BridgeRequest, Error?) -> Void)?
    var onStateChange: (() -> Void)?
    private var server: MoldSignServer?
    var allowsLegacyDesktopClient = false
    private let makeServer: (() -> MoldSignServer)?
    private var recovery: DispatchWorkItem?
    private var enabled = false

    init(makeServer: (() -> MoldSignServer)? = nil) { self.makeServer = makeServer }

    func start() {
        enabled = true
        recovery?.cancel(); recovery = nil
        guard server == nil else { return }
        let server = makeServer?() ?? MoldSignServer(allowsLegacyDesktopClient: allowsLegacyDesktopClient)
        server.previewPDFEnabled = { [weak self] in
            let done = DispatchSemaphore(value: 0)
            // Read application settings on GTK's main loop, like the preview callback.
            let answer = StampEnabledBox()
            onMain { answer.value = self?.previewPDFEnabled?() ?? false; done.signal() }
            done.wait(); return answer.value
        }
        server.previewPDF = { [weak self] request, bytes in
            let answer = StampDecisionBox(); let done = DispatchSemaphore(value: 0)
            onMain {
                guard let preview = self?.previewPDF else { done.signal(); return }
                preview(request, bytes) { answer.value = $0; done.signal() }
            }
            done.wait(); return answer.value
        }
        server.authorize = { [weak self] request in
            // Only the server worker waits; the GTK main loop continues handling the consent/PIN dialog.
            let answer = DecisionBox()
            let done = DispatchSemaphore(value: 0)
            onMain {
                guard let authorize = self?.authorize else { done.signal(); return }
                authorize(request) { answer.value = $0; done.signal() }
            }
            done.wait()
            return answer.value
        }
        server.onSignResult = { [weak self] request, error in
            onMain { self?.onSignResult?(request, error) }
        }
        server.onListenerError = { [weak self, weak server] _, error in
            onMain {
                guard let self, let server, self.server === server else { return }
                self.server = nil
                server.stop()
                self.state = MoldSignServer.isAddressInUse(error) ? .portBusy : .failed("\(error)")
                self.scheduleRecovery()
            }
        }
        do {
            try server.start(requireHTTPS: true)
            self.server = server
            state = .running
        } catch is MoldSignServer.TLSIdentityError {
            server.stop()
            state = .identityRequired
        } catch {
            server.stop()
            state = MoldSignServer.isAddressInUse(error) ? .portBusy : .failed("\(error)")
            scheduleRecovery()
        }
    }

    private func scheduleRecovery() {
        guard enabled, state == .portBusy else { return }
        let work = DispatchWorkItem { [weak self] in
            onMain {
                guard let self, self.enabled, self.state == .portBusy else { return }
                self.start()
            }
        }
        recovery?.cancel(); recovery = work
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 5, execute: work)
    }

    func stop() {
        enabled = false
        recovery?.cancel(); recovery = nil
        server?.stop()
        server = nil
        state = .stopped
    }
}

private final class DecisionBox: @unchecked Sendable {
    var value: BridgeDecision = .deny
}

private final class StampDecisionBox: @unchecked Sendable { var value: PDFStampDecision = .cancel }

private final class StampEnabledBox: @unchecked Sendable { var value = false }
