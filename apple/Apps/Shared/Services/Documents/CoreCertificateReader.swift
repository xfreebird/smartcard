import Foundation
import MoldSignKit

struct CoreCertificateReader: CertificateReading {
    let service: SigningService
    func readCertificate(reader: String) async throws -> SigningService.CertificateSummary {
        try await Task.detached { try service.readCertificate(reader: reader) }.value
    }
}
