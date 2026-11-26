import Foundation
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif
@testable import MoldSignKit

/// A 127.0.0.1 HTTP responder on the product's POSIX listener, for PKI and bridge tests without external network.
final class LoopbackHTTPServer: @unchecked Sendable {
    let port: UInt16
    private let listener: POSIXHTTPListener
    private let sink: RequestSink

    /// `respond` returns the full raw response, or nil to never answer the connection.
    init(maxRequestBytes: Int = 1 << 20, respond: @escaping @Sendable (Data) -> Data?) throws {
        var lastError: Error = POSIXError(.EADDRINUSE)
        let log = RequestSink()
        for _ in 0..<5 {
            let port = try Self.freePort()
            do {
                listener = try POSIXHTTPListener(port: port, tls: nil, maxRequestBytes: maxRequestBytes) { request, reply in
                    log.append(request)
                    if let response = respond(request) { reply(response) }
                }
                self.port = port
                self.sink = log
                return
            } catch { lastError = error }
        }
        throw lastError
    }

    var url: String { "http://127.0.0.1:\(port)/" }
    var requests: [Data] { sink.requests }
    func stop() { listener.stop() }

    static func response(_ status: Int, _ body: Data, contentType: String = "application/octet-stream") -> Data {
        Data("HTTP/1.1 \(status) Test\r\nContent-Type: \(contentType)\r\nContent-Length: \(body.count)\r\nConnection: close\r\n\r\n".utf8) + body
    }

    /// The body of a raw request (after the blank line).
    static func body(of request: Data) -> Data {
        request.range(of: Data("\r\n\r\n".utf8)).map { Data(request[$0.upperBound...]) } ?? Data()
    }

    /// An ephemeral loopback port the kernel just handed out and released.
    static func freePort() throws -> UInt16 {
        let fd = socket(AF_INET, POSIXSocket.stream, 0)
        guard fd >= 0 else { throw POSIXSocket.lastError }
        defer { BridgeConnection(fd: fd, tls: nil).close() }
        var addr = sockaddr_in()
        #if canImport(Darwin)
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        #endif
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let bound = withUnsafeMutablePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { pointer -> Int32 in
                guard bind(fd, pointer, length) == 0 else { return -1 }
                return getsockname(fd, pointer, &length)
            }
        }
        guard bound == 0 else { throw POSIXSocket.lastError }
        return UInt16(bigEndian: addr.sin_port)
    }
}

private final class RequestSink: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [Data] = []
    var requests: [Data] { lock.lock(); defer { lock.unlock() }; return storage }
    func append(_ request: Data) { lock.lock(); storage.append(request); lock.unlock() }
}
