import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

/// Runs an operator-selected credential helper with bounded time and output. This is
/// not exposed as an MCP tool; callers must validate the returned credential format.
public enum MCPBoundedCredentialCommand {
    public static func read(executable: String, arguments: [String], timeout: TimeInterval = 20) throws -> Data {
        guard timeout > 0, timeout.isFinite else { throw MCPFailure.credentialUnavailable }
        let process = Process(), output = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        // op gets its configured service-account/session environment; no shell and no
        // PIN is passed in argv. Its output and diagnostics never reach MCP stdout.
        do { try process.run() } catch { throw MCPFailure.credentialUnavailable }
        try? output.fileHandleForWriting.close()
        // Drain a bounded nonblocking pipe while waiting. A descendant that inherits
        // stdout cannot extend the deadline after the provider itself exits.
        let descriptor = output.fileHandleForReading.fileDescriptor
        defer { try? output.fileHandleForReading.close() }
        let descriptorFlags = fcntl(descriptor, F_GETFL)
        guard descriptorFlags >= 0, fcntl(descriptor, F_SETFL, descriptorFlags | O_NONBLOCK) == 0 else {
            if process.isRunning { kill(process.processIdentifier, SIGKILL) }
            throw MCPFailure.credentialUnavailable
        }
        // Foundation reaps the child asynchronously. waitUntilExit can wait for inherited
        // pipes on Linux, defeating the credential deadline after the direct child exits.
        defer {
            if process.isRunning { kill(process.processIdentifier, SIGKILL) }
        }
        let expiry = ProcessInfo.processInfo.systemUptime + timeout
        var data = Data()
        var reachedEOF = false
        while ProcessInfo.processInfo.systemUptime < expiry {
            var bytes = [UInt8](repeating: 0, count: 33 - data.count)
            let count = bytes.withUnsafeMutableBytes { buffer in
                #if canImport(Darwin)
                Darwin.read(descriptor, buffer.baseAddress!, buffer.count)
                #else
                Glibc.read(descriptor, buffer.baseAddress!, buffer.count)
                #endif
            }
            if count > 0 {
                data.append(contentsOf: bytes.prefix(count))
                guard data.count <= 32 else { throw MCPFailure.credentialUnavailable }
            } else if count == 0 {
                reachedEOF = true
            } else if errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR {
                throw MCPFailure.credentialUnavailable
            }
            if reachedEOF && !process.isRunning { break }
            Thread.sleep(forTimeInterval: 0.01)
        }
        guard reachedEOF, !process.isRunning, process.terminationStatus == 0 else {
            throw MCPFailure.credentialUnavailable
        }
        return data
    }
}
