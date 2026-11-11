import Foundation

public struct PasswordFileProcessor: PasswordFileProcessing {
    public init() { }

    public func process(_ input: URL, operation: FileProtectionOperation, password: String) throws -> Data? {
        try Task.checkCancellation()
        #if !os(Linux)
        let access = input.startAccessingSecurityScopedResource()
        defer { if access { input.stopAccessingSecurityScopedResource() } }
        #endif
        if operation == .remove {
            try ProtectedFileIO.overwriteAndRemove(input)
            return nil
        }
        let bytes = try ProtectedFileIO.read(input)
        return try operation == .encrypt
            ? PasswordFileProtection.encrypt(bytes, password: password)
            : PasswordFileProtection.decrypt(bytes, password: password)
    }
}
