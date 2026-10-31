import XCTest
@testable import MonitoringConsentPolicy

final class MonitoringConsentTests: XCTestCase {
    private func preferences() -> UserDefaults {
        let name = "md.esemnbun.qa.consent.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }

    func testUnknownDoesNotPermitSDKAndDefaultsOff() {
        let unknown = MonitoringConsent.load(from: preferences())
        XCTAssertFalse(unknown.decided)
        XCTAssertFalse(unknown.crashes)
        XCTAssertFalse(unknown.metrics)
        XCTAssertFalse(unknown.canStart)
        XCTAssertFalse(unknown.permits(.crashes))
        XCTAssertFalse(unknown.permits(.metrics))
    }

    func testDeclinePersistsAsDecidedWithoutAnyCategory() {
        let defaults = preferences()
        MonitoringConsent(decided: true, crashes: false, metrics: false).save(to: defaults)
        let stored = MonitoringConsent.load(from: defaults)
        XCTAssertTrue(stored.decided)
        XCTAssertFalse(stored.canStart)
    }

    func testBothChoicesPersistAndPermitSDK() {
        let defaults = preferences()
        let consent = MonitoringConsent(decided: true, crashes: true, metrics: true)
        consent.save(to: defaults)
        XCTAssertEqual(MonitoringConsent.load(from: defaults), consent)
        XCTAssertTrue(consent.canStart)
    }

    func testCategoriesRemainIndependent() {
        let defaults = preferences()
        for consent in [MonitoringConsent(decided: true, crashes: true, metrics: false),
                        MonitoringConsent(decided: true, crashes: false, metrics: true)] {
            consent.save(to: defaults)
            XCTAssertEqual(MonitoringConsent.load(from: defaults), consent)
            XCTAssertTrue(consent.canStart)
            XCTAssertEqual(consent.permits(.crashes), consent.crashes)
            XCTAssertEqual(consent.permits(.metrics), consent.metrics)
        }
        MonitoringConsent(decided: true, crashes: false, metrics: false).save(to: defaults)
        XCTAssertFalse(MonitoringConsent.load(from: defaults).permits(.crashes))
        XCTAssertFalse(MonitoringConsent.load(from: defaults).permits(.metrics))
    }

    func testUnknownCannotPreauthorizeStoredChoices() {
        let defaults = preferences()
        MonitoringConsent(decided: false, crashes: true, metrics: true).save(to: defaults)
        XCTAssertEqual(MonitoringConsent.load(from: defaults), MonitoringConsent())
    }
}
