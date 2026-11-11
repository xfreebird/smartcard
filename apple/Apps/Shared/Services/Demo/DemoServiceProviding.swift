import Foundation
import MoldSignKit

/// A demo session owns its fixtures and substitutes the same document ports as a live session.
@MainActor
protocol DemoServiceProviding {
    var files: any DemoDocumentProviding { get }
    var signer: any DocumentSigning { get }
    var verifier: any DocumentVerifying { get }
    func cards(count: Int, certificates: [SigningService.CertificateSummary]?) -> [CardSlot]
}
