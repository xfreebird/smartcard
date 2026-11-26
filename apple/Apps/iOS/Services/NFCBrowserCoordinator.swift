import Foundation
import Security
import MoldSignKit

/// The browser advertises public metadata; each signature still requires a fresh live card.
@MainActor @Observable
final class NFCBrowserCoordinator {
    var certificate: SigningService.CertificateSummary?
    var enabled: Bool = NFCSigningSession.available && (AppPreferencesStore.defaults.object(forKey: "browserAuthenticationNFC") as? Bool ?? true) {
        didSet { AppPreferencesStore.defaults.set(enabled, forKey: "browserAuthenticationNFC") }
    }
    var visible = false
    private(set) var busy = false
    private var session: NFCSigningSession?
    var error: String?

    func cancel() { session?.finish(error: CancellationError()) }

    func identify() async {
        guard !busy else { return }
        busy = true
        error = nil
        let session = NFCSigningSession(purpose: "browserIdentify")
        self.session = session
        defer { self.session = nil; busy = false }
        do {
            let transport = try await session.open(message: L10n.text(.browser_nfc_read_hint))
            let der = try await Task.detached { try ContactlessCertificateReader.read(using: transport) }.value
            guard SecCertificateCreateWithData(nil, der as CFData) != nil else { throw CardError.cardNotResponding }
            certificate = SigningService.CertificateSummary(der: der)
            enabled = true
            await session.close()
        } catch {
            let presented = AppModel.describe(error)
            self.error = error is CancellationError ? nil : [presented.message, presented.recovery].filter { !$0.isEmpty }.joined(separator: " ")
            await session.close(error: error)
        }
    }

    func open(expected: Data) async throws -> CardTransport {
        guard !busy, enabled, certificate?.der == expected else { throw NFCSigningError.busy }
        busy = true
        let session = NFCSigningSession(purpose: "browserSign")
        self.session = session
        do {
            let transport = try await session.open(message: L10n.text(.browser_nfc_sign_hint))
            return NFCBrowserTransport(transport: transport) { [weak self] error in
                Task { @MainActor in
                    await session.close(error: error)
                    if self?.session === session { self?.session = nil; self?.busy = false }
                }
            }
        } catch {
            await session.close(error: error)
            self.session = nil
            busy = false
            throw error
        }
    }
}
