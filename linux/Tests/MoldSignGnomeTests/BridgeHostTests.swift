import Dispatch
import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome
#if canImport(Glibc)
import Glibc
#endif

/// The HTTPS listener lifetime and the worker ↔ main-loop hand-off, on private loopback ports.
final class BridgeHostTests: GnomeTestCase {
    private var servers: [MoldSignServer] = []

    private static func freePort() -> UInt16 {
        #if os(Linux)
        let fd = socket(AF_INET, Int32(SOCK_STREAM.rawValue), 0)
        #else
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        #endif
        defer { close(fd) }
        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        address.sin_port = 0
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        _ = withUnsafeMutablePointer(to: &address) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(fd, $0, length) } }
        _ = withUnsafeMutablePointer(to: &address) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(fd, $0, &length) } }
        return UInt16(bigEndian: address.sin_port)
    }

    private func host(identity: Data? = TestEnvironment.bridgeIdentity, http: UInt16 = freePort(), https: UInt16 = freePort()) -> BridgeHost {
        BridgeHost(makeServer: { [unowned self] in
            let server = MoldSignServer(tlsP12: identity, httpPort: http, httpsPort: https)
            servers.append(server)
            return server
        })
    }

    /// Runs `body` on a worker (like the server's request queue) while the GTK main loop keeps turning.
    private func onWorker<T>(_ body: @escaping () -> T) -> T? {
        let result = Locked<T?>(nil)
        let done = DispatchSemaphore(value: 0)
        DispatchQueue.global().async { result.value = body(); done.signal() }
        XCTAssertTrue(GTKTest.pump(until: { done.wait(timeout: .now()) == .success }, timeout: 5))
        return result.value
    }

    func testStartsWithTheIdentityAndRelaysEveryWorkerCallbackToTheMainLoop() throws {
        try XCTSkipIf(TestEnvironment.bridgeIdentity == nil, "No localhost.p12 in this checkout")
        let bridge = host()
        var changes = 0
        bridge.onStateChange = { changes += 1 }
        bridge.start()
        defer { bridge.stop() }
        XCTAssertEqual(bridge.state, .running)
        XCTAssertGreaterThan(changes, 0)
        bridge.start()
        XCTAssertEqual(servers.count, 1, "A running bridge is not started twice")
        let server = try XCTUnwrap(servers.first)
        let request = BridgeRequest(origin: "https://msign.gov.md", operation: .signPDF, documentName: "a.pdf", format: "PAdES", pinIncluded: false)

        // Without an application handler a request is denied and no preview is shown.
        guard case .deny? = onWorker({ server.authorize?(request) }) else { return XCTFail("Expected deny") }
        guard case .cancel? = onWorker({ server.previewPDF?(request, Data()) }) else { return XCTFail("Expected cancel") }
        XCTAssertEqual(onWorker({ server.previewPDFEnabled?() }), false)

        var onMainThread = false
        bridge.authorize = { _, answer in onMainThread = Thread.isMainThread; answer(.allow(pin: "1234", certificateSHA1: "aa")) }
        bridge.previewPDFEnabled = { true }
        bridge.previewPDF = { _, bytes, answer in answer(bytes.isEmpty ? .cancel : .proceed(nil)) }
        guard case .allow(let pin, _)? = onWorker({ server.authorize?(request) }) else { return XCTFail("Expected allow") }
        XCTAssertEqual(pin, "1234")
        XCTAssertTrue(onMainThread)
        XCTAssertEqual(onWorker({ server.previewPDFEnabled?() }), true)
        guard case .proceed? = onWorker({ server.previewPDF?(request, Data("%PDF".utf8)) }) else { return XCTFail("Expected proceed") }
        var results: [Error?] = []
        bridge.onSignResult = { results.append($1) }
        server.onSignResult?(request, CardError.pinBlocked)
        XCTAssertTrue(GTKTest.pump(until: { results.count == 1 }))
        // A listener failure stops this server and is reported.
        server.onListenerError?(1, POSIXError(.ECONNRESET))
        XCTAssertTrue(GTKTest.pump(until: { if case .failed = bridge.state { return true }; return false }))
        bridge.stop()
        XCTAssertEqual(bridge.state, .stopped)
    }

    func testMissingIdentityAndBusyPortsHaveTheirOwnStates() throws {
        let missing = host(identity: nil)
        missing.start()
        XCTAssertEqual(missing.state, .identityRequired)
        missing.stop()
        try XCTSkipIf(TestEnvironment.bridgeIdentity == nil, "No localhost.p12 in this checkout")
        let port = Self.freePort()
        let holder = host(http: port)
        holder.start()
        defer { holder.stop() }
        XCTAssertEqual(holder.state, .running)
        let second = host(http: port)
        second.start()
        XCTAssertEqual(second.state, .portBusy, "The vendor suite (or another instance) holds the port")
        holder.stop()
        // Recovery retries every 5 s while enabled.
        XCTAssertTrue(GTKTest.pump(until: { second.state == .running }, timeout: 9))
        second.stop()
        XCTAssertEqual(second.state, .stopped)
    }
}
