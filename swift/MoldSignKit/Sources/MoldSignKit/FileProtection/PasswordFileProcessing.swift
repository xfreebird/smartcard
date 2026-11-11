import Foundation

/// Synchronous transformation port for desktop workflows with a separate native Save step.
public protocol PasswordFileProcessing {
    func process(_ input: URL, operation: FileProtectionOperation, password: String) throws -> Data?
}
