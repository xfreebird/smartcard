import XCTest

@MainActor
final class DemoModeUITests: XCTestCase {
    func testDemoRequiresDisclaimerPersistsAndSharesSampleWithoutHardware() throws {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "md.esemnbun.ios")
        defer { app.terminate() }
        app.launchEnvironment["MSIGN_QA_NO_HARDWARE"] = "1"
        app.launchEnvironment["MSIGN_DEMO_PREFERENCES_SUITE"] = "md.esemnbun.qa.user-demo.\(UUID().uuidString)"
        app.launchArguments = ["-AppleLanguages", "(en)", "-appLanguage", "en"]
        app.launch()
        navigate("Card", in: app)
        app.buttons["card.settings"].tap()
        let toggle = demoToggle(in: app)
        XCTAssertEqual(toggle.value as? String, "0")
        XCTAssertTrue(toggle.isEnabled)
        print("DEMO_SWITCH_FRAME \(toggle.frame)")
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.5)).tap()
        let accept = app.buttons["Use demo mode"]
        XCTAssertTrue(accept.waitForExistence(timeout: 5), "A disclaimer must precede activation")
        attach(app, "01-enable-disclaimer")
        accept.tapWhenReady()
        waitForValue("1", on: toggle)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "demo.banner").firstMatch.waitForExistence(timeout: 5))
        navigate("Sign", in: app)
        let expand = app.buttons["sign.expandBatch"]
        if expand.exists { expand.tap() }
        XCTAssertTrue(app.buttons["sign.options.Sample-contract.pdf"].waitForExistence(timeout: 5))
        attach(app, "02-demo-ready")
        app.buttons["sign.submit"].tap()
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
        navigate("Card", in: app)
        app.buttons["card.settings"].tap()
        let persisted = demoToggle(in: app)
        XCTAssertEqual(persisted.value as? String, "1")
        persisted.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.5)).tap()
        waitForValue("0", on: persisted)
        app.buttons["Done"].tap()
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "demo.banner").firstMatch.exists)
        attach(app, "06-return-to-live-mock")
        app.terminate()
    }

    private func waitForValue(_ value: String, on element: XCUIElement) {
        let expected = NSPredicate(format: "value == %@", value)
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: expected, object: element)], timeout: 10), .completed)
    }

    private func navigate(_ title: String, in app: XCUIApplication) {
        let destination = app.buttons[title].firstMatch
        XCTAssertTrue(destination.waitForExistence(timeout: 20), app.debugDescription)
        destination.tap()
    }

    private func demoToggle(in app: XCUIApplication) -> XCUIElement {
        let toggle = app.switches["settings.demoMode"]
        let form = app.collectionViews.firstMatch
        XCTAssertTrue(form.waitForExistence(timeout: 10))
        for _ in 0..<6 where !toggle.exists || !toggle.isHittable {
            form.swipeUp()
        }
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), app.debugDescription)
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
