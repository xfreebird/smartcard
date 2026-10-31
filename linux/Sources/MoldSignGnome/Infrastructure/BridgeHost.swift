import Dispatch
import Foundation
import MoldSignKit


/// Owns listener lifetime and the worker/main-loop boundary. Authorization policy stays in the application.
final class BridgeHost: BridgeHosting {
    private(set) var state: BridgeState = .stopped { didSet { onStateChange?() } }
    var authorize: ((BridgeRequest, @escaping (BridgeDecision) -> Void) -> Void)?
    var onSignResult: ((BridgeRequest, Error?) -> Void)?
    var onStateChange: (() -> Void)?
    private var server: MoldSignServer?
    private let makeServer: () -> MoldSignServer

    init(makeServer: @escaping () -> MoldSignServer = { MoldSignServer() }) { self.makeServer = makeServer }

    func start() {
        guard server == nil else { return }
        let server = makeServer()
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
                self.state = MoldSignServer.isAddressInUse(error) ? .portBusy : .failed("\(error)")
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
        }
    }

    func stop() {
        server?.stop()
        server = nil
        state = .stopped
    }
}

private final class DecisionBox: @unchecked Sendable {
    var value: BridgeDecision = .deny
}
