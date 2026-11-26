import XCTest

@MainActor
final class DemoModeUITests: XCTestCase {
    func testDemoRequiresDisclaimerPersistsAndSharesSampleWithoutHardware() throws {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "md.esemnbun.ios")
        app.launchEnvironment["MSIGN_QA_NO_HARDWARE"] = "1"
        app.launchEnvironment["MSIGN_DEMO_PREFERENCES_SUITE"] = "md.esemnbun.qa.user-demo.\(UUID().uuidString)"
        app.launchArguments = ["-AppleLanguages", "(en)", "-appLanguage", "en"]
        app.launch()
        navigate("Settings", in: app)
        let toggle = demoToggle(in: app)
        XCTAssertEqual(toggle.value as? String, "0")
        XCTAssertTrue(toggle.isEnabled)
        print("DEMO_SWITCH_FRAME \(toggle.frame)")
        tapSwitch(toggle)
        let accept = app.buttons["Use demo mode"]
        if !accept.waitForPresence(timeout: 3), toggle.value as? String == "0" {
            tapSwitch(toggle)
        }
        XCTAssertTrue(accept.waitForPresence(timeout: 5), "A disclaimer must precede activation")
        attach(app, "01-enable-disclaimer")
        accept.tapWhenReady()
        waitForValue("1", on: toggle)
        navigate("Sign", in: app)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "demo.banner").firstMatch.waitForPresence(timeout: 5))
        let expand = app.buttons["sign.expandBatch"]
        if expand.exists { expand.tap() }
        XCTAssertTrue(app.buttons["sign.options.Sample-contract.pdf"].waitForPresence(timeout: 5))
        attach(app, "02-demo-ready")
        app.buttons["sign.submit"].tap()
        XCTAssertTrue(app.staticTexts["Demo signing completed"].firstMatch.waitForPresence(timeout: 10))
        XCTAssertFalse(app.secureTextFields.firstMatch.exists, "Simulation must not request a real PIN")
        attach(app, "03-demo-completed")
        let share = app.buttons["Share"].firstMatch
        XCTAssertTrue(share.exists)
        share.tap()
        let nativeShare = app.otherElements["ActivityListView"]
        let shareVisible = nativeShare.waitForPresence(timeout: 8) || app.buttons["Copy"].exists || app.buttons["Save to Files"].exists
        XCTAssertTrue(shareVisible, "The native share sheet must actually appear before capturing it")
        attach(app, "04-share-sample")
        // XCTest restarts the app on launch, preserving the fixture's preferences.
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "demo.banner").firstMatch.waitForPresence(timeout: 10))
        attach(app, "05-persisted-demo")
        navigate("Settings", in: app)
        let persisted = demoToggle(in: app)
        XCTAssertEqual(persisted.value as? String, "1")
        attach(app, "05a-before-demo-disable")
        tapSwitch(persisted)
        let disabled = NSPredicate(format: "value == %@", "0")
        if XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: disabled, object: persisted)], timeout: 3) != .completed,
           persisted.value as? String == "1" {
            tapSwitch(persisted)
        }
        waitForValue("0", on: persisted)
        navigate("Sign", in: app)
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "demo.banner").firstMatch.exists)
        assertNoDemoWording(in: app)
        attach(app, "06-return-to-live-mock")
        // The simulated output stayed in the demo library; the live documents never list it.
        navigate("Documents", in: app)
        XCTAssertFalse(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'DEMO-result'")).firstMatch
            .waitForPresence(timeout: 2))
        assertNoDemoWording(in: app)
        attach(app, "07-live-documents")
    }

    /// Demo banner text, sample-output notice, simulated completion and fictional-data wording are demo-only.
    private func assertNoDemoWording(in app: XCUIApplication) {
        let demoOnly = NSPredicate(format: "label CONTAINS[c] 'fictional' OR label CONTAINS[c] 'Sample document' OR label CONTAINS[c] 'Demo signing' OR label CONTAINS[c] 'Demo mode'")
        XCTAssertFalse(app.staticTexts.containing(demoOnly).firstMatch.exists, app.debugDescription)
    }

    private func waitForValue(_ value: String, on element: XCUIElement) {
        let expected = NSPredicate(format: "value == %@", value)
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: expected, object: element)], timeout: 10), .completed)
    }

    private func tapSwitch(_ element: XCUIElement) {
        guard element.waitUntilReady() else { return }
        // SwiftUI exposes the entire row. Target the thumb in its current position,
        // after navigation has settled, rather than the track between its two states.
        let inset: CGFloat = element.value as? String == "1" ? 35 : 65
        element.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5))
            .withOffset(CGVector(dx: -inset, dy: 0)).tap()
    }

    private func navigate(_ title: String, in app: XCUIApplication) {
        app.selectMainTab(title)
    }

    private func demoToggle(in app: XCUIApplication) -> XCUIElement {
        let toggle = app.switches["settings.demoMode"]
        let form = app.collectionViews.firstMatch
        XCTAssertTrue(form.waitForPresence(timeout: 10))
        for _ in 0..<6 where !toggle.exists || !toggle.isHittable {
            form.swipeUp()
        }
        XCTAssertTrue(toggle.waitForPresence(timeout: 5), app.debugDescription)
        XCTAssertTrue(toggle.isHittable)
        return toggle
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
