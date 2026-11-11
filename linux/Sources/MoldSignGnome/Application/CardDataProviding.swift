import Foundation
import MoldSignKit

struct CardReadResult {
    var certificate: SigningService.CertificateSummary?
    var problem: String?
    var hasStoredPIN = false
}

/// Completion is delivered on the GTK main loop. Providers own I/O and credential lookup.
protocol CardDataProviding {
    func read(reader: String, completion: @escaping (CardReadResult) -> Void)
}
