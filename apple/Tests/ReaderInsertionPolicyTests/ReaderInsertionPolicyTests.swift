import XCTest
@testable import ReaderInsertionPolicy

final class ReaderInsertionPolicyTests: XCTestCase {
    func testInitialSnapshotDoesNotOpenAnApp() {
        var policy = ReaderInsertionPolicy()
        XCTAssertFalse(policy.shouldOpen(for: ["reader": true]))
        XCTAssertFalse(policy.shouldOpen(for: ["reader": true]))
    }
    func testReaderThenCardInsertionEachOpenOnce() {
        var policy = ReaderInsertionPolicy()
        XCTAssertFalse(policy.shouldOpen(for: [:]))
        XCTAssertTrue(policy.shouldOpen(for: ["reader": false]))
        XCTAssertFalse(policy.shouldOpen(for: ["reader": false]))
        XCTAssertTrue(policy.shouldOpen(for: ["reader": true]))
        XCTAssertFalse(policy.shouldOpen(for: ["reader": true]))
    }
    func testRemovalSilentAndReinsertionOpens() {
        var policy = ReaderInsertionPolicy()
        XCTAssertFalse(policy.shouldOpen(for: ["reader": true]))
        XCTAssertFalse(policy.shouldOpen(for: ["reader": false]))
        XCTAssertTrue(policy.shouldOpen(for: ["reader": true]))
        XCTAssertFalse(policy.shouldOpen(for: [:]))
        XCTAssertTrue(policy.shouldOpen(for: ["reader": true]))
    }
    func testSecondReaderDoesNotDependOnFirstReaderState() {
        var policy = ReaderInsertionPolicy()
        XCTAssertFalse(policy.shouldOpen(for: ["one": true]))
        XCTAssertTrue(policy.shouldOpen(for: ["one": true, "two": false]))
        XCTAssertTrue(policy.shouldOpen(for: ["one": true, "two": true]))
    }
    func testDemoSuppressesLaunchesAndResumingRequiresANewInsertion() {
        var policy = ReaderInsertionPolicy()
        XCTAssertFalse(policy.shouldOpen(for: [:], demoMode: true))
        XCTAssertFalse(policy.shouldOpen(for: ["reader": false], demoMode: true))
        XCTAssertFalse(policy.shouldOpen(for: ["reader": true], demoMode: true))
        XCTAssertFalse(policy.shouldOpen(for: ["reader": true], demoMode: false))
        XCTAssertFalse(policy.shouldOpen(for: ["reader": false], demoMode: false))
        XCTAssertTrue(policy.shouldOpen(for: ["reader": true], demoMode: false))
    }
}

final class ReaderInsertionDeliveryTests: XCTestCase {
    func testRunningAppReceivesTheURLWithoutActivationInBothEditions() {
        for storeEdition in [false, true] {
            let delivery = ReaderInsertionDelivery.choose(appRunning: true, storeEdition: storeEdition)
            XCTAssertEqual(delivery, ReaderInsertionDelivery(route: .readerURL, activates: false))
        }
    }
    func testColdLaunchActivatesTheAppAsBefore() {
        XCTAssertEqual(ReaderInsertionDelivery.choose(appRunning: false, storeEdition: false),
                       ReaderInsertionDelivery(route: .launchApplication, activates: true))
        XCTAssertEqual(ReaderInsertionDelivery.choose(appRunning: false, storeEdition: true),
                       ReaderInsertionDelivery(route: .readerURL, activates: true))
    }
}
