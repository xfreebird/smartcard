import Foundation
import MoldSignKit

protocol DocumentSigning {
    func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String,
              progress: @escaping (SigningService.Step) -> Void) throws -> URL
}

protocol BatchSigning {
    /// Synchronous work. The caller supplies the execution queue and dispatches UI callbacks.
    func sign(_ items: [SignItem], pin: String, remember: Bool, cert: SigningService.CertificateSummary,
              reader: String, progress: @escaping (SigningService.Step) -> Void,
              completed: (SignItem, Result<URL, Error>, Bool) -> Void) -> Error?
}

/// One frozen card identity and PIN for the entire batch. Stops at the first error, without retry.
final class BatchSigningService: BatchSigning {
    private let signer: any DocumentSigning
    private let vault: any PINStoring

    init(signer: any DocumentSigning, vault: any PINStoring) {
        self.signer = signer
        self.vault = vault
    }

    func sign(_ items: [SignItem], pin: String, remember: Bool, cert: SigningService.CertificateSummary,
              reader: String, progress: @escaping (SigningService.Step) -> Void,
              completed: (SignItem, Result<URL, Error>, Bool) -> Void) -> Error? {
        var savedPIN = false
        var triedSavingPIN = false
        for item in items {
            do {
                let output = try signer.sign(item, pin: pin, reader: reader, certificateSHA1: cert.sha1Hex, progress: progress)
                // Persist only after acceptance by the card, and attempt it at most once per batch.
                if remember && !triedSavingPIN {
                    triedSavingPIN = true
                    savedPIN = (try? vault.save(pin, certID: cert.sha1Hex, holder: cert.holder)) != nil
                }
                completed(item, .success(output), savedPIN)
            } catch {
                switch error {
                case CardError.wrongPIN, CardError.pinBlocked: vault.delete(certID: cert.sha1Hex)
                default: break
                }
                completed(item, .failure(error), false)
                return error
            }
        }
        return nil
    }
}
