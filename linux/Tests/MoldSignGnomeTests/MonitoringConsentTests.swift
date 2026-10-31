import Foundation
import XCTest
@testable import MoldSignGnome

final class MonitoringConsentTests: XCTestCase {
    private final class Memory: MonitoringConsentStoring {
        var value: MonitoringConsent?
        var failSave = false
        func load() -> MonitoringConsent? { value }
        func save(_ consent: MonitoringConsent) throws {
            if failSave { throw CocoaError(.fileWriteNoPermission) }
            value = consent
        }
    }
    func testUnknownAndRefusalNeverStartSDK() throws {
        let memory = Memory()
        var starts = 0
        let coordinator = MonitoringCoordinator(store: memory, start: { _ in starts += 1 }, revoke: {})
        coordinator.restore()
        XCTAssertNil(coordinator.consent)
        try coordinator.choose(MonitoringConsent(crashes: false, metrics: false))
        coordinator.restore()
        XCTAssertNotNil(memory.value)
        XCTAssertEqual(starts, 0)
    }
    func testIndependentSignalChoicesAndRevocationOrder() throws {
        let memory = Memory()
        var events: [String] = []
        let coordinator = MonitoringCoordinator(store: memory,
            start: { events.append("start:\($0.crashes):\($0.metrics)") }, revoke: { events.append("revoke") })
        try coordinator.choose(MonitoringConsent(crashes: false, metrics: true))
        try coordinator.choose(MonitoringConsent(crashes: true, metrics: false))
        try coordinator.choose(MonitoringConsent(crashes: true, metrics: true))
        try coordinator.choose(MonitoringConsent(crashes: false, metrics: false))
        XCTAssertEqual(events, ["revoke", "start:false:true", "revoke", "start:true:false", "revoke", "start:true:true", "revoke"])
    }
    func testPersistenceFailureCannotLeaveSDKEnabled() throws {
        let memory = Memory(); memory.value = MonitoringConsent(crashes: true, metrics: true)
        var events: [String] = []
        let coordinator = MonitoringCoordinator(store: memory, start: { _ in events.append("start") }, revoke: { events.append("revoke") })
        coordinator.restore()
        memory.failSave = true
        XCTAssertThrowsError(try coordinator.choose(MonitoringConsent(crashes: false, metrics: false)))
        XCTAssertNil(coordinator.consent)
        XCTAssertEqual(events, ["start", "revoke"])
    }
    func testMissingCorruptAndStoredConsent() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = JSONMonitoringConsentStore(url: directory.appendingPathComponent("consent.json"))
        XCTAssertNil(store.load())
        try store.save(MonitoringConsent(crashes: false, metrics: false))
        XCTAssertEqual(store.load(), MonitoringConsent(crashes: false, metrics: false))
        try Data("broken".utf8).write(to: store.url)
        XCTAssertNil(store.load())
    }
}
