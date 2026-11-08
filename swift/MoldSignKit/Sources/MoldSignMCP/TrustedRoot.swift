import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

public enum MCPFailure: String, Error {
    case invalidArgument = "INVALID_ARGUMENT", pathDenied = "PATH_DENIED"
    case limitExceeded = "LIMIT_EXCEEDED", unsupported = "UNSUPPORTED"
    case brokerUnavailable = "BROKER_UNAVAILABLE", unknownJob = "UNKNOWN_JOB"
    case credentialUnavailable = "CREDENTIAL_UNAVAILABLE", signingDisabled = "SIGNING_DISABLED"
    case pinIncorrect = "PIN_INCORRECT", pinBlocked = "PIN_BLOCKED", cardChanged = "CARD_CHANGED"
    case noCard = "NO_CARD", outcomeUnknown = "OUTCOME_UNKNOWN", networkFailed = "NETWORK_FAILED"
}

/// Holds the configured directory inode open for its lifetime. All descendant opens reject links.
public final class TrustedRoot {
    private let descriptor: Int32
    public init(path: String, privateDirectory: Bool = false) throws {
        guard path.hasPrefix("/"), !path.contains("\0") else { throw MCPFailure.pathDenied }
        // Walk from / so even intermediate symlinks in trusted configuration are rejected.
        var fd = open("/", O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard fd >= 0 else { throw MCPFailure.pathDenied }
        for part in path.split(separator: "/") {
            guard part != ".", part != ".." else { close(fd); throw MCPFailure.pathDenied }
            let next = openat(fd, String(part), O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            close(fd); fd = next
            guard fd >= 0 else { throw MCPFailure.pathDenied }
        }
        var info = stat()
        guard fstat(fd, &info) == 0,
              !privateDirectory || (info.st_uid == getuid() && info.st_mode & 0o777 == 0o700) else {
            close(fd); throw MCPFailure.pathDenied
        }
        descriptor = fd
    }
    deinit { close(descriptor) }
    private func parent(_ path: String) throws -> (Int32, String) {
        let parts = path.split(separator: "/", omittingEmptySubsequences: false)
        guard path.utf8.count <= 1024, !path.contains("\0"), !path.contains(":"), !path.contains("\\"),
              !parts.isEmpty, parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else { throw MCPFailure.pathDenied }
        var fd = dup(descriptor)
        guard fd >= 0 else { throw MCPFailure.pathDenied }
        for part in parts.dropLast() {
            let next = openat(fd, String(part), O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            close(fd); fd = next
            guard fd >= 0 else { throw MCPFailure.pathDenied }
        }
        return (fd, String(parts.last!))
    }
    public func read(_ path: String, limit: Int, privateFile: Bool = false) throws -> Data {
        let (parentFD, name) = try parent(path); defer { close(parentFD) }
        let fd = openat(parentFD, name, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard fd >= 0 else { throw MCPFailure.pathDenied }; defer { close(fd) }
        var info = stat()
        guard fstat(fd, &info) == 0, info.st_mode & mode_t(S_IFMT) == mode_t(S_IFREG),
              !privateFile || (info.st_uid == getuid() && info.st_mode & 0o777 == 0o600) else { throw MCPFailure.pathDenied }
        guard info.st_size <= limit else { throw MCPFailure.limitExceeded }
        var data = Data(), buffer = [UInt8](repeating: 0, count: 65536)
        while true {
            let n = buffer.withUnsafeMutableBytes {
                #if canImport(Darwin)
                Darwin.read(fd, $0.baseAddress!, $0.count)
                #else
                Glibc.read(fd, $0.baseAddress!, $0.count)
                #endif
            }
            if n == 0 { return data }
            if n < 0 { if errno == EINTR { continue }; throw MCPFailure.pathDenied }
            guard data.count + n <= limit else { throw MCPFailure.limitExceeded }
            data.append(contentsOf: buffer.prefix(n))
        }
    }
    public func writeExclusive(_ path: String, data: Data) throws {
        let (fd, name) = try parent(path); defer { close(fd) }
        let temporary = "." + UUID().uuidString
        let output = openat(fd, temporary, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard output >= 0 else { throw MCPFailure.brokerUnavailable }
        defer { close(output); unlinkat(fd, temporary, 0) }
        try data.withUnsafeBytes { bytes in
            var offset = 0
            while offset < bytes.count {
                #if canImport(Darwin)
                let n = Darwin.write(output, bytes.baseAddress!.advanced(by: offset), bytes.count - offset)
                #else
                let n = Glibc.write(output, bytes.baseAddress!.advanced(by: offset), bytes.count - offset)
                #endif
                if n < 0 && errno == EINTR { continue }
                guard n > 0 else { throw MCPFailure.brokerUnavailable }; offset += n
            }
        }
        guard fsync(output) == 0, linkat(fd, temporary, fd, name, 0) == 0,
              fsync(fd) == 0 else { throw MCPFailure.brokerUnavailable }
    }

    /// Removes a directory entry without following a final or intermediate symlink.
    public func remove(_ path: String) throws {
        let (fd, name) = try parent(path); defer { close(fd) }
        guard unlinkat(fd, name, 0) == 0, fsync(fd) == 0 else { throw MCPFailure.pathDenied }
    }
}
