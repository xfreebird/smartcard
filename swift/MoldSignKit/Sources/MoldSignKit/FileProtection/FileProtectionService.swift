import Foundation

/// Stores each output in a private directory; failed writes leave no partial library entry.
public struct FileProtectionService: FileProtectionProcessing {
    private let outputDirectory: URL

    private let processor: PasswordFileProcessor

    public init(outputDirectory: URL, signingService: SigningService = .shared) {
        processor = PasswordFileProcessor(signingService: signingService)
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
        guard let result = try processor.process(input, operation: operation, password: password),
              let outputName = operation.outputName(for: input.lastPathComponent) else {
            return nil
        }
        try Task.checkCancellation()
        let folder = outputDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true,
                                               attributes: [.posixPermissions: 0o700])
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
