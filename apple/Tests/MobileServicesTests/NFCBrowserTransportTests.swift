import XCTest
import MoldSignKit
@testable import MobileServices

final class NFCBrowserTransportTests: XCTestCase {
    private final class RecordingTransport: CardTransport, @unchecked Sendable {
        let readerName = "test"
        var sent: [Data] = []
        var disconnects = 0
        func transmit(_ apdu: Data) throws -> Data {
            sent.append(apdu)
            guard apdu != Data([0xFF]) else { throw CardError.cardNotResponding }
            return Data([0x90, 0x00])
        }
        func disconnect() { disconnects += 1 }
    }

    private final class Closures: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: [String] = []
        var values: [String] { lock.lock(); defer { lock.unlock() }; return stored }
        func add(_ value: String) { lock.lock(); stored.append(value); lock.unlock() }
    }

    func testTransmitsThroughAndClosesTheSessionOnce() throws {
        let card = RecordingTransport()
        let closes = Closures()
        let transport = NFCBrowserTransport(transport: card) { error in closes.add(error.map { "\($0)" } ?? "ok") }
        XCTAssertEqual(transport.readerName, "Core NFC browser")
        XCTAssertEqual(try transport.transmit(Data([0x00, 0xA4])), Data([0x90, 0x00]))
        XCTAssertThrowsError(try transport.transmit(Data([0xFF])))
        XCTAssertEqual(card.sent, [Data([0x00, 0xA4]), Data([0xFF])])
        transport.disconnect()
        transport.finish(error: CardError.cardNotResponding)
        transport.disconnect()
        XCTAssertEqual(card.disconnects, 1)
        XCTAssertEqual(closes.values, ["ok"])
    }

    func testFailureIsReportedToTheSession() {
        let card = RecordingTransport()
        let closes = Closures()
        let transport = NFCBrowserTransport(transport: card) { error in closes.add(error.map { "\($0)" } ?? "ok") }
        transport.finish(error: CardError.cardNotResponding)
        transport.disconnect()
        XCTAssertEqual(card.disconnects, 1)
        XCTAssertEqual(closes.values, ["\(CardError.cardNotResponding)"])
    }

    func testWorkerThreadsWaitForMainActorResults() throws {
        let finished = expectation(description: "worker")
        let outcomes = Closures()
        DispatchQueue.global().async {
            let value = Result { try NFCBrowserResult<Int>.wait { MainActor.assertIsolated(); return 42 } }
            outcomes.add((try? value.get()).map(String.init) ?? "failed")
            let failure = Result { try NFCBrowserResult<Int>.wait { throw CardError.pinBlocked } }
            if case .failure(CardError.pinBlocked) = failure { outcomes.add("pinBlocked") }
            finished.fulfill()
        }
        wait(for: [finished], timeout: 10)
        XCTAssertEqual(outcomes.values, ["42", "pinBlocked"])
    }
}
