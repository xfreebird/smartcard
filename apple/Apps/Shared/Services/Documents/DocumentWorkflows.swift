import Foundation
import MoldSignKit

/// Narrow app ports let a scenario replace card reads, signing or verification independently.
protocol CertificateReading: Sendable {
    func readCertificate(reader: String) async throws -> SigningService.CertificateSummary
}
protocol DocumentSigning: Sendable {
    func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String,
              progress: @escaping @Sendable (SigningService.Step) -> Void) async throws -> URL
}
