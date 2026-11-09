import Foundation
import MoldSignKit


final class DocumentVerifier: DocumentVerifying {
    private let service: SigningService
    init(service: SigningService) { self.service = service }

    func verify(_ url: URL) -> [SignatureReport] { verify(url, companions: []) }

    func verify(_ url: URL, companions: [URL]) -> [SignatureReport] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let isPDF = url.pathExtension.lowercased() == "pdf"
        let initial = service.verify(data, isPDF: isPDF, detached: [:])
        guard !isPDF else { return initial.map(SignatureReport.init) }
        let names = Set(initial.flatMap(\.missingDetachedReferences))
        let files = DetachedDocumentAccess.companions(named: names, near: url, selected: companions)
        return service.verify(data, isPDF: false, detached: files).map(SignatureReport.init)
    }
}
