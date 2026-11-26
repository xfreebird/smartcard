import XCTest
@testable import MoldSignGnome

final class DemoIsolationTests: GnomeTestCase {
    func testPreviewPreferencesDisableExternalServicesWithoutChangingOriginal() {
        var real = AppSettings()
        real.bridgeEnabled = true; real.agentApprovalEnabled = true
        real.launchAtLogin = true; real.showOnCardInsertion = true
        let preview = MemorySettingsStore(real)
        let settings = preview.load()
        XCTAssertFalse(settings.bridgeEnabled)
        XCTAssertFalse(settings.agentApprovalEnabled)
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertFalse(settings.runInBackground)
        XCTAssertFalse(settings.showOnCardInsertion)
        XCTAssertTrue(settings.onboardingCompleted)
        XCTAssertTrue(real.bridgeEnabled)
        XCTAssertTrue(real.launchAtLogin)
    }

    func testPreviewPINStoreNeverRetainsCredentials() throws {
        let vault = DemoPINStore()
        try vault.save("test-only", certID: "fictional", holder: "Demo")
        XCTAssertFalse(vault.hasPIN(certID: "fictional"))
        if case .missing = vault.load(certID: "fictional") {} else { XCTFail("Demo must never return a credential") }
    }
}
