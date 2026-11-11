import Foundation
import MoldSignKit

struct CoreDocumentVerifier: DocumentVerifying {
    let service: SigningService
    func verify(_ url: URL) async -> [Validator.Report] {
        (try? await inspect(url)) ?? []
    }

    func inspect(_ url: URL) async throws -> [Validator.Report] {
        try await inspect(url, companions: [])
    }

    func inspect(_ url: URL, companions: [URL]) async throws -> [Validator.Report] {
        let inputs = [url] + companions
        let scopes = inputs.filter { $0.startAccessingSecurityScopedResource() }
        defer { scopes.forEach { $0.stopAccessingSecurityScopedResource() } }
        try Task.checkCancellation()
        let reports = try await Task.detached {
            let data = try Data(contentsOf: url)
            let isPDF = url.pathExtension.lowercased() == "pdf"
            let initial = service.verify(data, isPDF: isPDF, detached: [:])
            guard !isPDF else { return initial }
            let names = Set(initial.flatMap(\.missingDetachedReferences))
            let files = DetachedDocumentAccess.companions(named: names, near: url, selected: companions)
            return service.verify(data, isPDF: false, detached: files)
        }.value
        try Task.checkCancellation()
        return reports
    }
}
