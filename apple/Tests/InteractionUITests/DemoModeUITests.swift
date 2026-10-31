import XCTest

@MainActor
final class DemoModeUITests: XCTestCase {
    func testDemoRequiresDisclaimerPersistsAndSharesSampleWithoutHardware() throws {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "md.esemnbun.ios")
        app.launchEnvironment["MSIGN_QA_NO_HARDWARE"] = "1"
        app.launchEnvironment["MSIGN_DEMO_PREFERENCES_SUITE"] = "md.esemnbun.qa.user-demo.\(UUID().uuidString)"
        app.launchArguments = ["-AppleLanguages", "(en)"]
        app.launch()
        app.tabBars.buttons["Card"].tap()
        app.buttons["card.settings"].tap()
        let toggle = app.switches["settings.demoMode"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        XCTAssertEqual(toggle.value as? String, "0")
        XCTAssertTrue(toggle.isEnabled)
        print("DEMO_SWITCH_FRAME \(toggle.frame)")
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.5)).tap()
        let accept = app.buttons["Use demo mode"]
        XCTAssertTrue(accept.waitForExistence(timeout: 5), "A disclaimer must precede activation")
        attach(app, "01-enable-disclaimer")
        accept.tap()
        XCTAssertEqual(toggle.value as? String, "1")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "demo.banner").firstMatch.waitForExistence(timeout: 5))
        app.tabBars.buttons["Sign"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Sample-contract.pdf")).firstMatch.waitForExistence(timeout: 5))
        attach(app, "02-demo-ready")
        app.buttons.matching(NSPredicate(format: "label == %@", "Sign 2 documents")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Demo signing completed"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.secureTextFields.firstMatch.exists, "Simulation must not request a real PIN")
        attach(app, "03-demo-completed")
        let share = app.buttons["Share"].firstMatch
        XCTAssertTrue(share.exists)
        share.tap()
        let nativeShare = app.otherElements["ActivityListView"]
        let shareVisible = nativeShare.waitForExistence(timeout: 8) || app.buttons["Copy"].exists || app.buttons["Save to Files"].exists
        XCTAssertTrue(shareVisible, "The native share sheet must actually appear before capturing it")
        attach(app, "04-share-sample")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "demo.banner").firstMatch.waitForExistence(timeout: 10))
        attach(app, "05-persisted-demo")
        app.tabBars.buttons["Card"].tap()
        app.buttons["card.settings"].tap()
        let persisted = app.switches["settings.demoMode"]
        XCTAssertEqual(persisted.value as? String, "1")
        persisted.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.5)).tap()
        XCTAssertEqual(persisted.value as? String, "0")
        app.buttons["Done"].tap()
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "demo.banner").firstMatch.exists)
        attach(app, "06-return-to-live-mock")
        app.terminate()
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
