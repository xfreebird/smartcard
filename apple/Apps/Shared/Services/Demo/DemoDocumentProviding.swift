import Foundation

/// Supplies isolated input/output fixtures without exposing file-generation implementation details.
protocol DemoDocumentProviding: Sendable {
    var directory: URL { get }
    func inputs() throws -> [URL]
    func output() throws -> URL
}
