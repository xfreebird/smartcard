import Foundation

/// Stores each output in a private directory; failed writes leave no partial library entry.
public struct FileProtectionService: FileProtectionProcessing {
    private let outputDirectory: URL

    public init(outputDirectory: URL) {
        self.outputDirectory = outputDirectory
    }

    public func process(_ input: URL, operation: FileProtectionOperation, password: String) async throws -> URL? {
        try Task.checkCancellation()
        let worker = Task.detached { try processFile(input, operation: operation, password: password) }
        return try await withTaskCancellationHandler {
            try await worker.value
        } onCancel: {
            worker.cancel()
        }
    }

    private func processFile(_ input: URL, operation: FileProtectionOperation, password: String) throws -> URL? {
        try Task.checkCancellation()
        guard let result = try PasswordFileProcessor().process(input, operation: operation, password: password) else {
            return nil
        }
        try Task.checkCancellation()
        let folder = outputDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true,
                                               attributes: [.posixPermissions: 0o700])
        let name = input.lastPathComponent
        let suffix = PasswordFileProtection.suffix
        let outputName = operation == .encrypt ? name + suffix
            : "decrypted-" + (name.hasSuffix(suffix) ? String(name.dropLast(suffix.count)) : name)
        let output = folder.appendingPathComponent(outputName)
        do {
            try Task.checkCancellation()
            try ProtectedFileIO.saveNew(result, to: output)
            return output
        } catch {
            try? FileManager.default.removeItem(at: folder)
            throw error
        }
    }
}
