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
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return L10n.text(.ui_content_size_unknown)
        }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}
