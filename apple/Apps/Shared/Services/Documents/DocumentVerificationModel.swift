import Foundation
import Observation
import MoldSignKit

/// Owns the Verify workspace. Late or cancelled requests cannot publish into a newer selection.
@MainActor @Observable
final class DocumentVerificationModel {
    var file: URL?
    var reports: [Validator.Report]?
    var documents: [(url: URL, reports: [Validator.Report])] = []
    var isVerifying = false
    private(set) var generation = UUID()

    func clear() {
        generation = UUID()
        isVerifying = false
        documents = []
        file = nil
        reports = nil
    }

    func verify(_ urls: [URL], using verifier: any DocumentVerifying,
                completed: (URL, [Validator.Report]) -> Void) async {
        clear()
        let request = generation
        isVerifying = true
        defer { if generation == request { isVerifying = false } }
        for url in urls {
            guard generation == request, !Task.isCancelled else { return }
            file = url
            reports = nil
            let result = await verifier.verify(url)
            guard generation == request, !Task.isCancelled else { return }
            reports = result
            documents.append((url, result))
            completed(url, result)
        }
    }
}
