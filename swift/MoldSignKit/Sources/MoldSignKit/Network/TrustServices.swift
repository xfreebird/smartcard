import Foundation
#if canImport(Network) && !MOLDSIGN_PORTABLE
import Network
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

/// HTTP access to the Moldovan PKI services (TSA, OCSP, CRL) without spawning `curl`/`openssl` (F-05),
/// so the same code runs on iOS and inside the sandboxed macOS app.
///
/// All three endpoints are plain HTTP (see `PlainHTTP`). Apps still declare ATS exceptions for `tsp.pki.gov.md` and `pki.md`
/// (incl. subdomains) in their Info.plist. Calls block: never use them on the main thread.
public enum TrustServices {
    public static let tsaURL = "http://tsp.pki.gov.md/moldsign2/"
    public static let ocspURL = "http://mdqsign.ocsp.pki.md"
    public static var timeout: TimeInterval = 30

    public enum NetworkError: Error, LocalizedError {
        case transport(String, String)
        case http(String, Int)

        public var errorDescription: String? {
            switch self {
            case .transport(let url, let message): return "Network error for \(url): \(message)"
            case .http(let url, let status): return "HTTP \(status) from \(url)"
            }
        }
    }

    // MARK: - HTTP

    static func post(_ url: String, body: Data, contentType: String) throws -> Data {
        try PlainHTTP.send(method: "POST", url: url, body: body, contentType: contentType, timeout: timeout)
    }

    static func get(_ url: String) throws -> Data {
        try PlainHTTP.send(method: "GET", url: url, body: nil, contentType: nil, timeout: timeout)
    }
}

/// Minimal HTTP/1.1 client for the plain-http PKI endpoints.
///
/// Not URLSession: it applies HSTS and silently rewrites `http://tsp.pki.gov.md` to https, where the TSA
/// drops the connection (NSURLError -1005). ATS exceptions don't help. The original code used `curl` for
/// this reason. Apple platforms use `NWConnection` (works on iOS, activates cellular); Linux uses POSIX sockets.
enum PlainHTTP {
    static func send(method: String, url: String, body: Data?, contentType: String?, timeout: TimeInterval) throws -> Data {
        try parse(try sendReturningRaw(method: method, url: url, body: body, contentType: contentType, timeout: timeout), url: url)
    }

    /// The raw HTTP response (status line + headers + body); tests use it against the local bridge.
    static func sendReturningRaw(method: String, url: String, body: Data?, contentType: String?,
                                 extraHeaders: [String] = [], timeout: TimeInterval) throws -> Data {
        // URLComponents keeps the path verbatim; URL.path drops the trailing slash and the TSA 301s on /moldsign2
        guard let u = URLComponents(string: url), u.scheme == "http", let host = u.host else {
            throw TrustServices.NetworkError.transport(url, "only http:// URLs are supported")
        }
        let path = (u.percentEncodedPath.isEmpty ? "/" : u.percentEncodedPath) + (u.percentEncodedQuery.map { "?" + $0 } ?? "")
        var head = "\(method) \(path) HTTP/1.1\r\nHost: \(host)\r\nUser-Agent: MoldSign\r\nAccept: */*\r\nConnection: close\r\n"
        if let contentType { head += "Content-Type: \(contentType)\r\n" }
        if let body { head += "Content-Length: \(body.count)\r\n" }
        for header in extraHeaders { head += header + "\r\n" }
        let request = Data((head + "\r\n").utf8) + (body ?? Data())
        return try exchange(host: host, port: UInt16(u.port ?? 80), request: request, timeout: timeout, url: url)
    }

    /// Splits status line + headers, checks 2xx, returns the (de-chunked) body.
    static func parse(_ raw: Data, url: String) throws -> Data {
        guard let sep = raw.range(of: Data("\r\n\r\n".utf8)) else {
            throw TrustServices.NetworkError.transport(url, "malformed HTTP response")
        }
        let head = String(decoding: raw[raw.startIndex..<sep.lowerBound], as: UTF8.self)
        let lines = head.components(separatedBy: "\r\n")
        let status = lines.first.flatMap { Int($0.split(separator: " ").dropFirst().first ?? "") } ?? 0
        guard (200..<300).contains(status) else { throw TrustServices.NetworkError.http(url, status) }
        var body = Data(raw[sep.upperBound...])
        let headers = lines.dropFirst().map { $0.lowercased() }
        if headers.contains(where: { $0.hasPrefix("transfer-encoding:") && $0.contains("chunked") }) {
            body = try dechunk(body, url: url)
        } else if let cl = headers.first(where: { $0.hasPrefix("content-length:") }),
                  let n = Int(cl.dropFirst(15).trimmingCharacters(in: .whitespaces)), body.count > n {
            body = body.prefix(n)
        }
        return body
    }

    static func dechunk(_ data: Data, url: String) throws -> Data {
        var out = Data()
        var pos = data.startIndex
        while let lineEnd = data[pos...].range(of: Data("\r\n".utf8)) {
            let sizeText = String(decoding: data[pos..<lineEnd.lowerBound], as: UTF8.self).split(separator: ";").first ?? ""
            guard let size = Int(sizeText.trimmingCharacters(in: .whitespaces), radix: 16) else {
                throw TrustServices.NetworkError.transport(url, "bad chunk size")
            }
            if size == 0 { return out }
            let start = lineEnd.upperBound
            guard data.distance(from: start, to: data.endIndex) >= size else { break }
            out += data[start..<data.index(start, offsetBy: size)]
            pos = data.index(start, offsetBy: size + 2)
            guard pos <= data.endIndex else { break }
        }
        throw TrustServices.NetworkError.transport(url, "truncated chunked body")
    }

    #if canImport(Network) && !MOLDSIGN_PORTABLE
    private static func exchange(host: String, port: UInt16, request: Data, timeout: TimeInterval, url: String) throws -> Data {
        // Direct, like the curl calls this replaced: Network.framework otherwise honours the system HTTP proxy
        // (e.g. a debugging proxy left configured), which broke TSA/CRL/OCSP. TODO(X-08): explicit proxy setting.
        let params = NWParameters.tcp
        params.preferNoProxies = true
        let conn = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: params)
        let queue = DispatchQueue(label: "msign-plain-http")
        let done = DispatchSemaphore(value: 0)
        var received = Data()
        var failure: Error?
        var finished = false
        func finish(_ error: Error? = nil) {
            guard !finished else { return }
            finished = true
            failure = error
            done.signal()
        }
        func receive() {
            conn.receive(minimumIncompleteLength: 1, maximumLength: 1 << 20) { data, _, isComplete, error in
                if let data { received.append(data) }
                if let error { finish(error) } else if isComplete { finish() } else { receive() }
            }
        }
        conn.stateUpdateHandler = { state in
            switch state {
            case .ready:
                conn.send(content: request, completion: .contentProcessed { error in
                    if let error { finish(error) } else { receive() }
                })
            case .waiting(let error), .failed(let error):
                finish(error)
            default:
                break
            }
        }
        conn.start(queue: queue)
        defer { conn.cancel() }
        guard done.wait(timeout: .now() + timeout) == .success else {
            throw TrustServices.NetworkError.transport(url, "timed out")
        }
        if let failure { throw TrustServices.NetworkError.transport(url, "\(failure)") }
        return received
    }
    #else
    /// POSIX sockets (Linux, MOLDSIGN_PORTABLE). No proxy support, like the NWConnection path (X-08).
    private static func exchange(host: String, port: UInt16, request: Data, timeout: TimeInterval, url: String) throws -> Data {
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = POSIXSocket.stream
        var results: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, String(port), &hints, &results) == 0, let first = results else {
            throw TrustServices.NetworkError.transport(url, "cannot resolve \(host)")
        }
        defer { freeaddrinfo(results) }
        var fd: Int32 = -1
        var candidate: UnsafeMutablePointer<addrinfo>? = first
        while let ai = candidate {
            fd = socket(ai.pointee.ai_family, ai.pointee.ai_socktype, ai.pointee.ai_protocol)
            if fd >= 0 {
                POSIXSocket.setTimeouts(fd, seconds: timeout)
                if connect(fd, ai.pointee.ai_addr, ai.pointee.ai_addrlen) == 0 { break }
                BridgeConnection(fd: fd, tls: nil).close()
                fd = -1
            }
            candidate = ai.pointee.ai_next
        }
        guard fd >= 0 else { throw TrustServices.NetworkError.transport(url, "cannot connect to \(host):\(port)") }
        let conn = BridgeConnection(fd: fd, tls: nil)
        defer { conn.close() }
        _ = POSIXSocket.ignoreSIGPIPE
        guard POSIXSocket.sendAll(fd, request) else { throw TrustServices.NetworkError.transport(url, "send failed") }
        var received = Data()
        var buf = [UInt8](repeating: 0, count: 64 * 1024)
        while true {
            let n = conn.read(into: &buf)
            if n == 0 { break }
            if n < 0 { throw TrustServices.NetworkError.transport(url, "receive failed (\(POSIXSocket.lastError.code))") }
            received.append(contentsOf: buf[0..<n])
        }
        return received
    }
    #endif
}

extension TrustServices {

    // MARK: - OCSP (RFC 6960)

    /// OCSPRequest for one certificate: SHA-1 CertID (what `openssl ocsp` sends), no nonce.
    static func ocspRequest(issuerDER: Data, certDER: Data) throws -> Data {
        let issuer = try CertFields(Data(issuerDER))
        let leaf = try CertFields(Data(certDER))
        let sha1AlgId = DER.seq(DER.tlv(0x06, Data([0x2B, 0x0E, 0x03, 0x02, 0x1A])) + Data([0x05, 0x00]))
        let certID = DER.seq(sha1AlgId
                             + DER.tlv(0x04, issuer.subjectDER.sha1())
                             + DER.tlv(0x04, issuer.publicKeyBits.sha1())
                             + leaf.serialTLV)
        let request = DER.seq(certID)
        let requestList = DER.seq(request)
        let tbsRequest = DER.seq(requestList)
        return DER.seq(tbsRequest)
    }

    /// Raw OCSPResponse DER for `certDER`, or nil when the responder gave nothing usable.
    static func fetchOCSP(issuerDER: Data, certDER: Data, url: String = ocspURL) throws -> Data? {
        let body = try ocspRequest(issuerDER: issuerDER, certDER: certDER)
        let resp = try post(url, body: body, contentType: "application/ocsp-request")
        return resp.count > 100 ? resp : nil
    }
}
