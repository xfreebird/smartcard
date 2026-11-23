import XCTest

/// Native layout and disabled-state checks using fictional cards and an injected signer.
@MainActor
final class FloatingActionUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testSignActionStaysVisibleWhileScrollingAndRotating() {
        defer { XCUIDevice.shared.orientation = .portrait }
        for theme in ["light", "dark"] {
            let app = launch("ready", theme: theme)
            let sign = app.buttons["sign.submit"].firstMatch
            assertFloating(sign, in: app)
            XCTAssertTrue(sign.isEnabled)
            let initial = sign.frame
            app.scrollViews.firstMatch.swipeUp()
            assertFloating(sign, in: app)
            XCTAssertEqual(sign.frame.minY, initial.minY, accuracy: 3, "Scrolling must not move the Sign action")
            attach(name: "floating-sign-\(theme)-portrait")

            XCUIDevice.shared.orientation = .landscapeLeft
            // Foldable and windowed scenes need not match the physical device's aspect ratio.
            // Validate the controls in the resulting scene rather than assuming it is wider than tall.
            XCTAssertEqual(XCUIDevice.shared.orientation, .landscapeLeft)
            assertFloating(sign, in: app)
            XCTAssertTrue(sign.isEnabled)
            attach(name: "floating-sign-\(theme)-landscape")
        }
    }

    func testUnavailableAndBusyCardsKeepSignDisabled() {
        for (scenario, theme) in [("no-reader", "light"), ("reading", "dark"), ("signing", "light")] {
            let app = launch(scenario, theme: theme)
            if scenario != "signing" { app.selectSigningMethod("reader") }
            let sign = app.buttons["sign.submit"].firstMatch
            assertFloating(sign, in: app, hittable: false)
            XCTAssertFalse(sign.isEnabled, scenario)
            XCTAssertFalse(app.secureTextFields.firstMatch.exists)
            attach(name: "disabled-sign-\(scenario)-\(theme)")
        }
    }

    func testFloatingActionFitsAccessibilityText() {
        let app = launch("ready", accessibilityText: true)
        let sign = app.buttons["sign.submit"].firstMatch
        assertFloating(sign, in: app)
        XCTAssertTrue(sign.isEnabled)
        XCTAssertLessThan(sign.frame.height, app.frame.height / 4, "The action must leave room for document content")
        XCTAssertEqual(sign.label, "Continue", "The guided mobile action advances to PIN confirmation")
        XCTAssertEqual(sign.value as? String, "Sign 2 documents", "Keep the complete document count accessible")
        attach(name: "floating-sign-accessibility-text")
    }

    func testBrowserActionsRetainMinimumTouchTargets() {
        let app = launch("ready", tab: "browser")
        for title in ["Back", "Forward", "Reload"] {
            let button = app.buttons[title].firstMatch
            XCTAssertTrue(button.waitForPresence(timeout: 15), title)
            XCTAssertGreaterThanOrEqual(button.frame.width, 44, title)
            XCTAssertGreaterThanOrEqual(button.frame.height, 44, title)
        }
        attach(name: "browser-native-actions")
    }

    private func assertFloating(_ button: XCUIElement, in app: XCUIApplication, hittable: Bool = true) {
        XCTAssertTrue(button.waitForPresence(timeout: 15))
        XCTAssertEqual(app.buttons.matching(identifier: "sign.submit").count, 1)
        let tabs = app.tabBars.firstMatch
        var previous: [CGRect] = []
        var matchingSamples = 0
        // Orientation changes return before accessibility finishes transforming the scene.
        // Wait for stable geometry without making the expected layout part of the wait.
        let settled = NSPredicate { _, _ in
            let frames = [app.frame, button.frame, tabs.exists ? tabs.frame : .null]
            guard !frames[0].isEmpty, !frames[1].isEmpty else {
                matchingSamples = 0
                return false
            }
            matchingSamples = frames == previous ? matchingSamples + 1 : 0
            previous = frames
            return matchingSamples >= 2
        }
        let ready = XCTNSPredicateExpectation(predicate: settled, object: nil)
        guard XCTWaiter.wait(for: [ready], timeout: 15) == .completed else {
            XCTFail("Workspace and action geometry did not settle")
            return
        }
        if hittable {
            let accessible = NSPredicate(format: "hittable == true")
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: accessible, object: button)], timeout: 10), .completed)
        }
        let workspace = previous[0], action = previous[1], navigation = previous[2]
        XCTAssertGreaterThan(action.midY, workspace.midY, "The action belongs at the bottom of the workspace")
        XCTAssertGreaterThanOrEqual(action.minX, workspace.minX)
        XCTAssertLessThanOrEqual(action.maxX, workspace.maxX)
        XCTAssertLessThan(action.maxY, workspace.maxY)
        XCTAssertGreaterThanOrEqual(action.height, 44)
        if !navigation.isNull && navigation.minY > workspace.midY {
            XCTAssertLessThanOrEqual(action.maxY, navigation.minY, "Sign must not overlap bottom navigation")
        }
    }

    private func attach(name: String) {
        // Capture the display so rotated windows are not cropped using portrait bounds.
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func launch(_ scenario: String, theme: String = "light", accessibilityText: Bool = false,
                        tab: String = "sign") -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication(bundleIdentifier: "md.esemnbun.ios")
        app.launchEnvironment = ["MSIGN_QA_NO_HARDWARE": "1", "MSIGN_SCREENSHOT_CAPTURE": "1",
            "MSIGN_DEMO_PREVIEW": "0", "MSIGN_DEMO_CARDS": "2", "MSIGN_DEMO_FILES": "fixture",
            "MSIGN_DEMO_TAB": tab, "MSIGN_DEMO_SCENARIO": scenario, "MSIGN_UI_TEST_SCENARIO": "sign-success",
            "MSIGN_DEMO_PREFERENCES_SUITE": "md.esemnbun.qa.floating.\(UUID().uuidString)"]
        app.launchArguments = ["-appLanguage", "en", "-AppleLanguages", "(en)", "-appTheme", theme, "-bridgeEnabled", "NO"]
        if accessibilityText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        return app
    }
}
