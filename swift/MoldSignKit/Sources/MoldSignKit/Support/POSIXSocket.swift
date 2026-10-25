import Foundation
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif
import CPCSC

// POSIX socket helpers for Linux (and MOLDSIGN_PORTABLE test builds on macOS), where Network.framework
// is unavailable: the plain-HTTP PKI client (LNX-04) and the bridge listener (LNX-05).

enum POSIXSocket {
    #if canImport(Glibc)
    static let stream = Int32(SOCK_STREAM.rawValue)
    #else
    static let stream = SOCK_STREAM
    #endif

    static var lastError: POSIXError {
        POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
    }

    static func setTimeouts(_ fd: Int32, seconds: TimeInterval) {
        var tv = timeval(tv_sec: Int(seconds), tv_usec: 0)
        setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
        setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))
    }

    static func sendAll(_ fd: Int32, _ data: Data) -> Bool {
        data.withUnsafeBytes { raw -> Bool in
            guard var p = raw.baseAddress else { return true }
            var left = raw.count
            while left > 0 {
                let n = send(fd, p, left, 0)
                if n <= 0 { return false }
                p += n
                left -= n
            }
            return true
        }
    }

    /// Ignore SIGPIPE process-wide: a peer closing mid-write must not kill the app.
    static let ignoreSIGPIPE: Void = { _ = signal(SIGPIPE, SIG_IGN) }()
}

/// One client socket: plain, or TLS over the C shim's OpenSSL session.
struct BridgeConnection {
    let fd: Int32
    let tls: UnsafeMutableRawPointer?

    func read(into buf: inout [UInt8]) -> Int {
        if let tls { return Int(c_tls_read(tls, &buf, Int32(buf.count))) }
        return recv(fd, &buf, buf.count, 0)
    }

    func write(_ data: Data) {
        if let tls {
            data.withUnsafeBytes { raw in
                var off = 0
                while off < raw.count {
                    let n = c_tls_write(tls, raw.baseAddress!.assumingMemoryBound(to: UInt8.self) + off, Int32(raw.count - off))
                    if n <= 0 { break }
                    off += Int(n)
                }
            }
        } else {
            _ = POSIXSocket.sendAll(fd, data)
        }
    }

    func close() {
        if let tls { c_tls_close(tls) }
        #if canImport(Glibc)
        Glibc.close(fd)
        #else
        Darwin.close(fd)
        #endif
    }
}

/// HTTP/1.1 listener on 127.0.0.1 (one request per connection, `Connection: close`), mirroring the
/// Network.framework listener used on Apple platforms.
final class POSIXHTTPListener {
    private let fd: Int32
    private let tls: UnsafeMutableRawPointer?
    private let maxRequestBytes: Int
    private let handler: (Data, @escaping (Data) -> Void) -> Void
    private let connections = DispatchQueue(label: "msign-posix-conn", attributes: .concurrent)

    init(port: UInt16, tls: UnsafeMutableRawPointer?, maxRequestBytes: Int,
         handler: @escaping (Data, @escaping (Data) -> Void) -> Void) throws {
        _ = POSIXSocket.ignoreSIGPIPE
        self.tls = tls
        self.maxRequestBytes = maxRequestBytes
        self.handler = handler
        fd = socket(AF_INET, POSIXSocket.stream, 0)
        guard fd >= 0 else { throw POSIXSocket.lastError }
        var yes: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout<Int32>.size))
        var addr = sockaddr_in()
        #if canImport(Darwin)
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        #endif
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")   // SEC-03: loopback only
        let bound = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
        }
        guard bound == 0, listen(fd, 64) == 0 else {
            let error = POSIXSocket.lastError
            BridgeConnection(fd: fd, tls: nil).close()
            throw error
        }
        let thread = Thread { [weak self] in self?.acceptLoop() }
        thread.name = "msign-accept-\(port)"
        thread.start()
    }

    func stop() {
        shutdown(fd, Int32(SHUT_RDWR))
        BridgeConnection(fd: fd, tls: nil).close()
    }

    private func acceptLoop() {
        while true {
            let client = accept(fd, nil, nil)
            if client < 0 {
                if errno == EINTR { continue }
                return   // listener closed
            }
            connections.async { [weak self] in self?.serve(client) }
        }
    }

    private func serve(_ client: Int32) {
        POSIXSocket.setTimeouts(client, seconds: 30)
        var session: UnsafeMutableRawPointer?
        if let tls {
            session = c_tls_accept(tls, client)
            if session == nil { BridgeConnection(fd: client, tls: nil).close(); return }
        }
        let conn = BridgeConnection(fd: client, tls: session)
        var request = Data()
        var buf = [UInt8](repeating: 0, count: 64 * 1024)
        while !MoldSignServer.httpComplete(request) {
            let n = conn.read(into: &buf)
            if n <= 0 || request.count + n > maxRequestBytes { conn.close(); return }
            request.append(contentsOf: buf[0..<n])
        }
        handler(request) { response in
            conn.write(response)
            conn.close()
        }
    }
}
