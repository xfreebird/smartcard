import Dispatch
import Foundation
import MoldSignKit

final class LiveCardDataProvider: CardDataProviding {
    private let service: SigningService
    private let vault: any PINStoring
    private let queue = DispatchQueue(label: "md.moldsign.reader")

    init(service: SigningService, vault: any PINStoring) {
        self.service = service
        self.vault = vault
    }

    func read(reader: String, completion: @escaping (CardReadResult) -> Void) {
        queue.async { [service, vault] in
            let result: CardReadResult
            do {
                let certificate = try service.readCertificate(reader: reader)
                result = CardReadResult(certificate: certificate,
                                        hasStoredPIN: vault.hasPIN(certID: certificate.sha1Hex))
            } catch {
                result = CardReadResult(problem: UserFacingError.describe(error).message)
            }
            onMain { completion(result) }
        }
    }
}
