import XCTest

/// Native layout and disabled-state checks using fictional cards and an injected signer.
@MainActor
final class FloatingActionUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testSignActionStaysVisibleWhileScrollingAndRotating() {
        for theme in ["light", "dark"] {
            let app = launch("ready", theme: theme)
            defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
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
            defer { app.terminate() }
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
        defer { app.terminate() }
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
        defer { app.terminate() }
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
        if hittable { XCTAssertTrue(button.isHittable) }
        XCTAssertGreaterThan(button.frame.midY, app.frame.midY, "The action belongs at the bottom of the workspace")
        XCTAssertGreaterThanOrEqual(button.frame.minX, app.frame.minX)
        XCTAssertLessThanOrEqual(button.frame.maxX, app.frame.maxX)
        XCTAssertLessThan(button.frame.maxY, app.frame.maxY)
        XCTAssertGreaterThanOrEqual(button.frame.height, 44)
        let tabs = app.tabBars.firstMatch
        if tabs.exists && tabs.frame.minY > app.frame.midY {
            XCTAssertLessThanOrEqual(button.frame.maxY, tabs.frame.minY, "Sign must not overlap bottom navigation")
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
