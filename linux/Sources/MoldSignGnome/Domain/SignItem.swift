import Foundation
import MoldSignKit

struct SignItem: Equatable {
    let id = UUID()
    let url: URL
    var format: SignFormat
    var stamp: PDFStampPlacement?
    var error: String?

    init(url: URL) {
        self.url = url
        format = .automatic(for: url)
    }

    var sizeText: String {
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value ?? 0
        return Format.bytes(size)
    }
}
