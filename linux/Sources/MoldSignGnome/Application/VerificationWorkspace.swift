import Foundation

/// Main-loop state reducer; no GTK, file access or worker queues.
final class VerificationWorkspace {
    var file: URL?
    var reports: [SignatureReport]?
    var documents: [(url: URL, reports: [SignatureReport])] = []
    private(set) var generation = UUID()

    @discardableResult
    func begin(clearDocuments: Bool) -> UUID {
        generation = UUID()
        file = nil
        reports = nil
        if clearDocuments { documents = [] }
        return generation
    }

    func select(_ url: URL) { file = url; reports = nil }

    @discardableResult
    func complete(_ result: [SignatureReport], for url: URL, generation request: UUID) -> Bool {
        guard generation == request else { return false }
        // A batch can have several outstanding reads. Only the selected file owns the detail pane.
        if file == url { reports = result }
        documents.removeAll { $0.url == url }
        documents.append((url, result))
        return true
    }
}
