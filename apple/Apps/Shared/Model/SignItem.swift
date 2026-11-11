import SwiftUI
import MoldSignKit

struct SignItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var format: SignFormat
    var stamp: PDFStampPlacement?
    var signingError: String?

    init(url: URL) {
        self.url = url
        format = .automatic(for: url)
    }

    var sizeText: String {
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}
