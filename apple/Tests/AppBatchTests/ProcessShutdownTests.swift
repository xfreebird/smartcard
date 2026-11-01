import XCTest
@testable import AppBatch

final class ProcessShutdownTests: XCTestCase {
    struct Identity: Equatable { let pid: Int; let started: Int }
    let original = Identity(pid: 10, started: 1)

    func testSignalsApprovedProcessAndWaitsUntilReleased() {
        var current = [original]
        var signalled: [Identity] = []
        var waits = 0
        let result = ProcessShutdown.request(approved: [original], current: { current }, signal: {
            signalled.append($0); return true
        }, wait: { waits += 1; current = [] })
        XCTAssertTrue(result)
        XCTAssertEqual(signalled, [original])
        XCTAssertEqual(waits, 1)
    }

    func testReusedPIDIsNeverSignalled() {
        let replacement = Identity(pid: 10, started: 2)
        var signalled: [Identity] = []
        let result = ProcessShutdown.request(approved: [original], current: { [replacement] }, signal: {
            signalled.append($0); return true
        }, wait: {}, maximumPolls: 2)
        XCTAssertFalse(result)
        XCTAssertTrue(signalled.isEmpty)
    }

    func testFailureAndTimeoutNeverEscalateOrRepeatSignals() {
        var signals = 0
        XCTAssertFalse(ProcessShutdown.request(approved: [original], current: { [original] }, signal: { _ in
            signals += 1; return false
        }, wait: { XCTFail("No waiting after denied signal") }))
        XCTAssertEqual(signals, 1)
        signals = 0
        var waits = 0
        XCTAssertFalse(ProcessShutdown.request(approved: [original], current: { [original] }, signal: { _ in
            signals += 1; return true
        }, wait: { waits += 1 }, maximumPolls: 3))
        XCTAssertEqual(signals, 1)
        XCTAssertEqual(waits, 2)
    }
}
