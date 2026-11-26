import XCTest
@testable import MoldSignKit

/// The PKI client and the POSIX bridge listener against each other on 127.0.0.1. No external network.
final class PlainHTTPLoopbackTests: XCTestCase {
    private var servers: [LoopbackHTTPServer] = []

    override func tearDown() {
        servers.forEach { $0.stop() }
        servers = []
        super.tearDown()
    }

    private func serve(maxRequestBytes: Int = 1 << 20, _ respond: @escaping @Sendable (Data) -> Data?) throws -> LoopbackHTTPServer {
        let server = try LoopbackHTTPServer(maxRequestBytes: maxRequestBytes, respond: respond)
        servers.append(server)
        return server
    }

    func testClientAndListenerExchangeRequestsAndBodies() throws {
        let server = try serve { request in
            let head = String(decoding: request.prefix(while: { $0 != 0x0D }), as: UTF8.self)
            return LoopbackHTTPServer.response(200, Data(head.utf8) + Data("|".utf8) + LoopbackHTTPServer.body(of: request))
        }
        let get = try TrustServices.get("http://127.0.0.1:\(server.port)/crl/root.crl?fresh=1")
        XCTAssertEqual(String(decoding: get, as: UTF8.self), "GET /crl/root.crl?fresh=1 HTTP/1.1|")
        let post = try TrustServices.post("http://127.0.0.1:\(server.port)/moldsign2/", body: Data("query".utf8),
                                          contentType: "application/timestamp-query")
        XCTAssertEqual(String(decoding: post, as: UTF8.self), "POST /moldsign2/ HTTP/1.1|query")
        let posted = String(decoding: try XCTUnwrap(server.requests.last), as: UTF8.self)
        XCTAssertTrue(posted.contains("Content-Type: application/timestamp-query\r\n"))
        XCTAssertTrue(posted.contains("Content-Length: 5\r\n"))
        XCTAssertTrue(posted.contains("Connection: close\r\n"))
    }

    func testOCSPFetchPostsTheRequestAndIgnoresTinyAnswers() throws {
        let answer = Box(Data(repeating: 0x30, count: 160))
        let server = try serve { _ in LoopbackHTTPServer.response(200, answer.value) }
        let expected = try TrustServices.ocspRequest(issuerDER: ChainCerts.mdTrustCA, certDER: ChainCerts.mdQSign)
        XCTAssertEqual(try TrustServices.fetchOCSP(issuerDER: ChainCerts.mdTrustCA, certDER: ChainCerts.mdQSign, url: server.url),
                       answer.value)
        let request = try XCTUnwrap(server.requests.first)
        XCTAssertEqual(LoopbackHTTPServer.body(of: request), expected)
        XCTAssertTrue(String(decoding: request, as: UTF8.self).contains("application/ocsp-request"))
        answer.value = Data([0x30, 0x03, 0x0A, 0x01, 0x06])   // unauthorized: too small to be a real response
        XCTAssertNil(try TrustServices.fetchOCSP(issuerDER: ChainCerts.mdTrustCA, certDER: ChainCerts.mdQSign, url: server.url))
    }

    func testHTTPErrorsCarryStatusAndURL() throws {
        let server = try serve { _ in LoopbackHTTPServer.response(503, Data("busy".utf8)) }
        XCTAssertThrowsError(try TrustServices.get(server.url)) { error in
            guard case TrustServices.NetworkError.http(let failedURL, 503) = error else { return XCTFail("\(error)") }
            XCTAssertEqual(failedURL, server.url)
            XCTAssertEqual(error.localizedDescription, "HTTP 503 from \(server.url)")
        }
    }

    func testOversizedRequestIsDroppedWithoutAnAnswer() throws {
        let server = try serve(maxRequestBytes: 64) { _ in LoopbackHTTPServer.response(200, Data()) }
        XCTAssertThrowsError(try TrustServices.post(server.url, body: Data(repeating: 0x41, count: 4096), contentType: "text/plain")) { error in
            // An empty close or a reset, depending on how much the listener read first.
            guard case TrustServices.NetworkError.transport(server.url, _) = error else { return XCTFail("\(error)") }
        }
        XCTAssertTrue(server.requests.isEmpty)
    }

    func testSilentServerTimesOut() throws {
        let server = try serve { _ in nil }
        XCTAssertThrowsError(try PlainHTTP.send(method: "GET", url: server.url, body: nil, contentType: nil, timeout: 1)) { error in
            #if !canImport(Network) || MOLDSIGN_PORTABLE
            // POSIX sockets (Linux, or the portable macOS build) surface the receive timeout as a failed read.
            // MOLDSIGN_PORTABLE alone is only defined for the library target on Linux, not for this test target.
            guard case TrustServices.NetworkError.transport(server.url, _) = error else { return XCTFail("\(error)") }
            #else
            XCTAssertEqual(error.localizedDescription, "Network error for \(server.url): timed out")
            #endif
        }
    }

    func testStoppedListenerRefusesConnections() throws {
        let server = try serve { _ in LoopbackHTTPServer.response(200, Data("ok".utf8)) }
        XCTAssertEqual(try TrustServices.get(server.url), Data("ok".utf8))
        server.stop()
        XCTAssertThrowsError(try PlainHTTP.send(method: "GET", url: server.url, body: nil, contentType: nil, timeout: 5)) { error in
            guard case TrustServices.NetworkError.transport = error else { return XCTFail("\(error)") }
        }
    }

    func testPortInUseIsReportedWhenListening() throws {
        let server = try serve { _ in LoopbackHTTPServer.response(200, Data()) }
        XCTAssertThrowsError(try POSIXHTTPListener(port: server.port, tls: nil, maxRequestBytes: 1024) { _, _ in }) { error in
            XCTAssertEqual((error as? POSIXError)?.code, .EADDRINUSE)
            XCTAssertTrue(MoldSignServer.isAddressInUse(error))
        }
        XCTAssertFalse(MoldSignServer.isAddressInUse(POSIXError(.ECONNREFUSED)))
        XCTAssertFalse(MoldSignServer.isAddressInUse(CocoaError(.fileNoSuchFile)))
    }

    func testOnlyPlainHTTPURLsAreAccepted() {
        for url in ["https://tsp.pki.gov.md/moldsign2/", "not a url", "ftp://pki.md/crl"] {
            XCTAssertThrowsError(try TrustServices.get(url)) { error in
                XCTAssertEqual(error.localizedDescription, "Network error for \(url): only http:// URLs are supported")
            }
        }
    }

    func testResponseParsingHandlesLengthChunkingAndDamage() throws {
        let url = "http://pki.md/test"
        let sized = Data("HTTP/1.1 200 OK\r\nContent-Length: 3\r\n\r\nabcdef".utf8)
        XCTAssertEqual(try PlainHTTP.parse(sized, url: url), Data("abc".utf8))
        let chunked = Data("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n4;ext=1\r\nWiki\r\n5\r\npedia\r\n0\r\n\r\n".utf8)
        XCTAssertEqual(try PlainHTTP.parse(chunked, url: url), Data("Wikipedia".utf8))
        XCTAssertEqual(try PlainHTTP.dechunk(Data("0\r\n\r\n".utf8), url: url), Data())
        let failures: [(String, String)] = [
            ("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\nzz\r\nbody\r\n0\r\n\r\n", "bad chunk size"),
            ("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n10\r\nshort\r\n", "truncated chunked body"),
            // A complete chunk cut off before its CRLF used to trap while computing the next offset.
            ("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n3\r\nabc", "truncated chunked body"),
            ("HTTP/1.1 200 OK\r\nno blank line", "malformed HTTP response"),
        ]
        for (raw, message) in failures {
            XCTAssertThrowsError(try PlainHTTP.parse(Data(raw.utf8), url: url)) { error in
                XCTAssertEqual(error.localizedDescription, "Network error for \(url): \(message)")
            }
        }
        XCTAssertThrowsError(try PlainHTTP.parse(Data("garbage\r\n\r\n".utf8), url: url)) { error in
            guard case TrustServices.NetworkError.http(_, 0) = error else { return XCTFail("\(error)") }
        }
    }
}

/// A value shared with a listener thread.
final class Box<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: T
    init(_ value: T) { stored = value }
    var value: T {
        get { lock.lock(); defer { lock.unlock() }; return stored }
        set { lock.lock(); stored = newValue; lock.unlock() }
    }
}
