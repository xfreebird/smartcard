import Foundation
@preconcurrency import CoreNFC
import MoldSignKit
import Security

enum NFCSigningError: LocalizedError {
    case unavailable, connectionLost, multipleCards, busy
    var errorDescription: String? {
        switch self {
        case .unavailable: return L10n.text(.nfc_unavailable)
        case .connectionLost: return L10n.text(.nfc_connection_lost)
        case .multipleCards: return L10n.text(.nfc_one_card)
        case .busy: return L10n.text(.nfc_busy)
        }
    }
}

/// Owns one foreground NFC sheet and one card. It never chooses a connected USB reader.
@MainActor
final class NFCSigningSession: NSObject, NFCTagReaderSessionDelegate {
    static var available: Bool { NFCReaderSession.readingAvailable }
    let diagnostics: NFCSessionDiagnostics
    private var session: NFCTagReaderSession?
    private var transport: NFCISO7816Transport?
    private var connecting = false
    private var connectingTag: NFCISO7816Tag?
    private var ending = false
    private var opened: CheckedContinuation<NFCISO7816Transport, Error>?
    private var closed: [CheckedContinuation<Void, Never>] = []

    init(purpose: String) {
        diagnostics = NFCSessionDiagnostics(purpose: purpose)
        super.init()
    }

    func open(message: String) async throws -> NFCISO7816Transport {
        guard Self.available else { throw NFCSigningError.unavailable }
        guard session == nil else { throw NFCSigningError.busy }
        diagnostics.record("sessionRequested")
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                opened = continuation
                guard let reader = NFCTagReaderSession(pollingOption: .iso14443, delegate: self, queue: .main) else {
                    opened = nil
                    continuation.resume(throwing: NFCSigningError.unavailable)
                    return
                }
                session = reader
                reader.alertMessage = message
                reader.begin()
            }
        } onCancel: {
            Task { @MainActor in self.finish(error: CancellationError()) }
        }
    }

    func finish(error: Error? = nil) {
        guard let session, !ending else { return }
        ending = true
        diagnostics.record(error == nil ? "cardStepComplete" : "operationFailed", error: error)
        transport?.invalidate(error ?? CancellationError())
        if let opened { self.opened = nil; opened.resume(throwing: error ?? CancellationError()) }
        if let error {
            session.invalidate(errorMessage: error is CancellationError ? L10n.text(.nfc_cancelled) : [AppModel.describe(error).message, AppModel.describe(error).recovery].filter { !$0.isEmpty }.joined(separator: " "))
        }
        else {
            session.alertMessage = L10n.text(.nfc_card_step_complete)
            session.invalidate()
        }
    }

    func close(error: Error? = nil) async {
        guard session != nil else { return }
        await withCheckedContinuation { continuation in
            closed.append(continuation)
            finish(error: error)
        }
    }

    nonisolated func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        Task { @MainActor in
            guard self.session === session else { return }
            self.diagnostics.record("sessionActive")
        }
    }
    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        Task { @MainActor in self.detect(tags, session: session) }
    }
    private func detect(_ tags: [NFCTag], session: NFCTagReaderSession) {
        guard self.session === session, !ending, !connecting, transport == nil else { return }
        guard tags.count == 1, case let .iso7816(tag) = tags[0] else {
            finish(error: NFCSigningError.multipleCards); return
        }
        connecting = true
        diagnostics.record("tagDetected")
        connectingTag = tag
        session.connect(to: tags[0]) { [weak self] error in
            Task { @MainActor in
                guard let self, self.session != nil, !self.ending, let tag = self.connectingTag else { return }
                self.connectingTag = nil
                if let error {
                    self.diagnostics.record("connectFailed", error: error)
                    self.finish(error: NFCSigningError.connectionLost)
                    return
                }
                self.diagnostics.record("tagConnected")
                let transport = NFCISO7816Transport(tag: tag, diagnostics: self.diagnostics) { [weak self] error in
                    Task { @MainActor in self?.finish(error: error) }
                }
                self.transport = transport
                let continuation = self.opened
                self.opened = nil
                continuation?.resume(returning: transport)
            }
        }
    }
    nonisolated func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            guard self.session === session else { return }
            self.diagnostics.record("sessionInvalidated", error: error)
            let failure: Error = (error as NSError).code == 200 ? CancellationError() : NFCSigningError.connectionLost
            self.transport?.invalidate(failure)
            if let opened = self.opened { self.opened = nil; opened.resume(throwing: failure) }
            self.session = nil
            self.connectingTag = nil
            self.transport = nil
            let waiting = self.closed
            self.closed = []
            waiting.forEach { $0.resume() }
        }
    }
}

/// Synchronous adapter for the existing signing core; Core NFC callbacks stay on the main queue.
final class NFCISO7816Transport: CardTransport, @unchecked Sendable {
    let readerName = "Core NFC"
    private let tag: NFCISO7816Tag
    private let diagnostics: NFCSessionDiagnostics
    private let failed: @Sendable (Error) -> Void
    private let lock = NSLock()
    private var failure: Error?
    private var pending: BlockingCardCommand?
    init(tag: NFCISO7816Tag, diagnostics: NFCSessionDiagnostics, failed: @escaping @Sendable (Error) -> Void) {
        self.tag = tag
        self.diagnostics = diagnostics
        self.failed = failed
    }
    func invalidate(_ error: Error) {
        lock.lock()
        if failure == nil { failure = error }
        let command = pending
        lock.unlock()
        command?.complete(.failure(error))
    }
    func disconnect() { invalidate(CancellationError()) }
    private func isCurrent(_ command: BlockingCardCommand) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return failure == nil && pending === command
    }
    func transmit(_ apdu: Data) throws -> Data {
        guard !Thread.isMainThread else { throw NFCSigningError.busy }
        guard let request = NFCISO7816APDU(data: apdu) else { throw CardError.cardNotResponding }
        let command = BlockingCardCommand()
        lock.lock()
        if let failure { lock.unlock(); throw failure }
        guard pending == nil else { lock.unlock(); throw NFCSigningError.busy }
        pending = command
        lock.unlock()
        defer { lock.lock(); if pending === command { pending = nil }; lock.unlock() }
        DispatchQueue.main.async { [self] in
            guard isCurrent(command) else { return }
            diagnostics.record("commandSent", instruction: apdu[1], secure: apdu[0] & 0x0C == 0x0C)
            tag.sendCommand(apdu: request) { data, sw1, sw2, error in
                self.diagnostics.record("commandResponse", instruction: apdu[1], responseBytes: data.count,
                                        status: error == nil ? UInt16(sw1) << 8 | UInt16(sw2) : nil, error: error)
                if error != nil { command.complete(.failure(NFCSigningError.connectionLost)) }
                else { command.complete(.success(data + Data([sw1, sw2]))) }
            }
        }
        do {
            return try command.wait(until: .now() + 20, timeoutError: NFCSigningError.connectionLost)
        } catch {
            invalidate(error)
            failed(error)
            throw error
        }
    }
}

struct NFCDocumentSigner: DocumentSigning {
    let hardwareGate: DemoHardwareGate
    let identity: NFCSigningIdentity
    func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String,
              progress: @escaping @Sendable (SigningService.Step) -> Void) async throws -> URL {
        guard hardwareGate.begin() else { throw NFCSigningError.unavailable }
        defer { hardwareGate.end() }
        let session = await NFCSigningSession(purpose: "sign")
        return try await withTaskCancellationHandler {
            try await sign(item, pin: pin, reader: reader, certificateSHA1: certificateSHA1,
                           progress: progress, session: session)
        } onCancel: {
            Task { @MainActor in session.finish(error: CancellationError()) }
        }
    }

    private func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String,
                      progress: @escaping @Sendable (SigningService.Step) -> Void,
                      session: NFCSigningSession) async throws -> URL {
        let diagnostics = await session.diagnostics
        do {
            progress(.connecting)
            let transport = try await session.open(message: L10n.text(.nfc_hold_to_sign, item.url.lastPathComponent))
            progress(.readingCertificate)
            diagnostics.record("step.identifyingCard")
            let certificate = try await Task.detached {
                let der = try ContactlessCertificateReader.read(using: transport)
                guard let cert = SecCertificateCreateWithData(nil, der as CFData), SecCertificateCopyKey(cert) != nil else {
                    throw CardError.cardNotResponding
                }
                guard identity.bind(der) else { throw CardError.cardChanged }
                return SigningService.CertificateSummary(der: der)
            }.value
            try Task.checkCancellation()
            diagnostics.record("identityRead")
            let service = SigningService()
            service.transportFactory = { _ in transport }
            let output = try await CoreDocumentSigner(service: service).sign(item, pin: pin, reader: reader,
                                                                             certificateSHA1: certificate.sha1Hex) { step in
                diagnostics.record("step." + step.rawValue)
                progress(step)
                // The card is no longer needed once its signature has been obtained. Do not keep
                // the owner holding it while timestamps or revocation data are fetched online.
                if step == .timestamping || step == .done {
                    Task { @MainActor in session.finish() }
                }
            }
            diagnostics.record("documentWritten")
            await session.close()
            return output
        } catch {
            diagnostics.record("documentFailed", error: error)
            await session.close(error: error)
            throw error
        }
    }
}
