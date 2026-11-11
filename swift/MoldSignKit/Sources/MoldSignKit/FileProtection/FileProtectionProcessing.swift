import Foundation

/// Application boundary: native views supply inputs and present outcomes, without owning file I/O.
public protocol FileProtectionProcessing: Sendable {
    func process(_ input: URL, operation: FileProtectionOperation, password: String) async throws -> URL?
}
