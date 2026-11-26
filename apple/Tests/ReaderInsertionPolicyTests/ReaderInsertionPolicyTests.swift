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

final class ReaderInsertionMonitorTests: XCTestCase {
    func testPresentCardStatesIncludeProbingAndMuteCards() {
        XCTAssertFalse(ReaderInsertionMonitor.cardPresent(nil))
        XCTAssertFalse(ReaderInsertionMonitor.cardPresent(.missing))
        XCTAssertFalse(ReaderInsertionMonitor.cardPresent(.empty))
        XCTAssertTrue(ReaderInsertionMonitor.cardPresent(.probing))
        XCTAssertTrue(ReaderInsertionMonitor.cardPresent(.muteCard))
        XCTAssertTrue(ReaderInsertionMonitor.cardPresent(.validCard))
    }

    func testMockSnapshotsDecodeOnlySlotPresenceMaps() {
        XCTAssertEqual(ReaderInsertionMonitor.mockSnapshot(Data(#"{"reader": true, "other": false}"#.utf8)),
                       ["reader": true, "other": false])
        XCTAssertNil(ReaderInsertionMonitor.mockSnapshot(Data(#"{"reader": "yes"}"#.utf8)))
        XCTAssertNil(ReaderInsertionMonitor.mockSnapshot(Data("[]".utf8)))
    }

    func testStoreWaitsForThePublishedModeAndDirectEditionDefaultsToLive() {
        let store = ReaderInsertionMonitor(storeEdition: true)
        XCTAssertTrue(store.demoMode(stored: nil, flag: false))
        XCTAssertFalse(store.demoMode(stored: false, flag: true))
        XCTAssertTrue(store.demoMode(stored: true, flag: false))
        let direct = ReaderInsertionMonitor(storeEdition: false)
        XCTAssertFalse(direct.demoMode(stored: nil, flag: false))
        XCTAssertTrue(direct.demoMode(stored: "YES", flag: true))
    }

    func testDeliveriesFollowInsertionsAtMostOncePerSecond() {
        var monitor = ReaderInsertionMonitor(storeEdition: false)
        let start = Date(timeIntervalSinceReferenceDate: 1000)
        XCTAssertFalse(monitor.shouldDeliver(for: [:], demoMode: false, at: start))
        XCTAssertTrue(monitor.shouldDeliver(for: ["reader": false], demoMode: false, at: start))
        // A card arriving half a second after the reader is the same user action.
        XCTAssertFalse(monitor.shouldDeliver(for: ["reader": true], demoMode: false, at: start + 0.5))
        XCTAssertFalse(monitor.shouldDeliver(for: ["reader": false], demoMode: false, at: start + 2))
        XCTAssertTrue(monitor.shouldDeliver(for: ["reader": true], demoMode: false, at: start + 2.5))
        XCTAssertFalse(monitor.shouldDeliver(for: ["reader": false], demoMode: true, at: start + 5))
        XCTAssertFalse(monitor.shouldDeliver(for: ["reader": true], demoMode: true, at: start + 6))
    }

    func testDeliveryUsesTheEditionsRoute() {
        XCTAssertEqual(ReaderInsertionMonitor(storeEdition: true).delivery(appRunning: false),
                       ReaderInsertionDelivery(route: .readerURL, activates: true))
        XCTAssertEqual(ReaderInsertionMonitor(storeEdition: false).delivery(appRunning: false),
                       ReaderInsertionDelivery(route: .launchApplication, activates: true))
        XCTAssertEqual(ReaderInsertionMonitor(storeEdition: false).delivery(appRunning: true),
                       ReaderInsertionDelivery(route: .readerURL, activates: false))
    }
}
