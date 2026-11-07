import Foundation
import MoldSignKit


final class DocumentVerifier: DocumentVerifying {
    private let service: SigningService
    init(service: SigningService) { self.service = service }

    func verify(_ url: URL) -> [SignatureReport] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let isPDF = url.pathExtension.lowercased() == "pdf"
        let detached = isPDF ? [:] : detachedDocuments(for: data, near: url)
        return service.verify(data, isPDF: isPDF, detached: detached).map(SignatureReport.init)
    }

    /// XAdES detached references are `file:/<basename>`: look next to the signature (same rule as the CLI).
    private func detachedDocuments(for xml: Data, near url: URL) -> [String: Data] {
        var files: [String: Data] = [:]
        let text = String(decoding: xml, as: UTF8.self)
        var start = text.startIndex
        while let r = text.range(of: "URI=\"file:/", range: start..<text.endIndex),
              let e = text[r.upperBound...].firstIndex(of: "\"") {
            let name = String(text[r.upperBound..<e])
            files[name] = try? DetachedDocumentAccess.read(name, beneath: url.deletingLastPathComponent())
            start = e
        }
        return files
    }

}
