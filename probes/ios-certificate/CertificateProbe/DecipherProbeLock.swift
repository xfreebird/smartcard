import Foundation
import Darwin

enum DecipherProbeLock {
    static var url: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("decipher-attempt.lock")
    }
    static var exists: Bool { FileManager.default.fileExists(atPath: url.path) }
    static var fileRoundTripURL: URL { url.deletingLastPathComponent().appendingPathComponent("file-round-trip-attempt.lock") }
    static var fileRoundTripExists: Bool { FileManager.default.fileExists(atPath: fileRoundTripURL.path) }
    static func create() throws { try create(at: url) }
    static func createFileRoundTrip() throws { try create(at: fileRoundTripURL) }
    private static func create(at target: URL) throws {
        try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        let fd = target.path.withCString { Darwin.open($0,O_WRONLY | O_CREAT | O_EXCL,0o600) }
        guard fd >= 0 else { throw ProbeFailure.message("A decipher attempt is already locked, or the lock cannot be created. Do not retry.") }
        defer { Darwin.close(fd) }
        #if os(iOS)
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: target.path)
        #endif
    }
}
