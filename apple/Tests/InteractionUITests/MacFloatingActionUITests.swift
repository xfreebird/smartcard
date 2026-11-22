import XCTest

#if os(macOS)
/// Exercises the production macOS workspace with fictional inputs and an injected signer.
@MainActor
final class MacFloatingActionUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testActionRemainsAtBottomWhileScrollingAndResizing() {
        for (language, theme) in [("en", "light"), ("ro", "light"), ("ru", "dark")] {
            let app = launch(language: language, theme: theme)
            defer { app.terminate() }
            let window = app.windows.firstMatch
            let sign = app.buttons["sign.submit"].firstMatch
            assertFloating(sign, in: window)
            // Leave enough width above the content minimum to observe a real shrink
            // across native drag rounding and localized window chrome.
            resize(window, width: 940, height: 650)
            wait("Window reaches compact size", in: app) { abs(window.frame.width - 940) < 10 }
            assertFloating(sign, in: window)
            XCTAssertTrue(sign.isEnabled)
            let position = sign.frame
            let workspace = app.scrollViews["signing.workspace"].firstMatch
            XCTAssertTrue(workspace.exists)
            let lastFile = app.descendants(matching: .any)["sign.options.Sample-request.txt"].firstMatch
            XCTAssertTrue(lastFile.exists)
            let filePosition = lastFile.frame.minY
            workspace.scroll(byDeltaX: 0, deltaY: -600)
            wait("Document content scrolls", in: app) { lastFile.frame.minY < filePosition - 20 }
            assertFloating(sign, in: window)
            XCTAssertEqual(sign.frame.minY, position.minY, accuracy: 3)
            XCTAssertEqual(sign.frame.minX, position.minX, accuracy: 3)
            attach(window, name: "floating-sign-\(language)-\(theme)")

            let before = window.frame
            // Shrink toward the supported minimum. Growing can hit a hosted display's edge.
            resize(window, width: 860, height: 620)
            wait("Window shrinks to the compact minimum", in: app) {
                let width = window.frame.width
                return width < before.width - 50 && abs(width - 860) < 20
            }
            assertFloating(sign, in: window)
            XCTAssertEqual(window.frame.maxX - sign.frame.maxX, before.maxX - position.maxX, accuracy: 3)
            XCTAssertEqual(window.frame.maxY - sign.frame.maxY, before.maxY - position.maxY, accuracy: 3)
            attach(window, name: "floating-sign-resized-\(language)")
        }
    }

    func testUnavailableAndBusyCardsKeepActionDisabled() {
        for scenario in ["no-reader", "reading", "signing"] {
            let app = launch(scenario: scenario)
            defer { app.terminate() }
            let sign = app.buttons["sign.submit"].firstMatch
            assertFloating(sign, in: app.windows.firstMatch, enabled: false)
            XCTAssertFalse(sign.isEnabled, scenario)
            XCTAssertFalse(app.secureTextFields.firstMatch.exists)
            attach(app.windows.firstMatch, name: "floating-sign-disabled-\(scenario)")
        }
    }

    func testClickAndKeyboardShortcutCompleteMockBatch() {
        for useShortcut in [false, true] {
            let app = launch()
            defer { app.terminate() }
            let sign = app.buttons["sign.submit"].firstMatch
            assertFloating(sign, in: app.windows.firstMatch)
            if useShortcut { app.typeKey(.return, modifierFlags: .command) }
            else { sign.click() }
            wait("Mock batch completes", in: app) {
                app.descendants(matching: .any).matching(identifier: "sign.result").count == 2 && !sign.exists
            }
            XCTAssertFalse(app.secureTextFields.firstMatch.exists)
        }
    }

    func testEmptyQueueHasNoFloatingAction() {
        let app = launch(files: ":")
        defer { app.terminate() }
        XCTAssertTrue(app.scrollViews["signing.workspace"].firstMatch.waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["sign.submit"].exists)
    }

    private func assertFloating(_ button: XCUIElement, in window: XCUIElement, enabled: Bool = true) {
        XCTAssertTrue(button.waitForExistence(timeout: 15))
        XCTAssertEqual(window.buttons.matching(identifier: "sign.submit").count, 1)
        XCTAssertEqual(window.toolbars.buttons.matching(identifier: "sign.submit").count, 0)
        if enabled { XCTAssertTrue(button.isHittable) }
        XCTAssertGreaterThanOrEqual(button.frame.height, 44)
        XCTAssertGreaterThanOrEqual(button.frame.width, 120)
        XCTAssertGreaterThan(button.frame.midX, window.frame.midX)
        XCTAssertGreaterThan(button.frame.midY, window.frame.midY)
        XCTAssertGreaterThanOrEqual(button.frame.minX, window.frame.minX)
        XCTAssertLessThan(button.frame.maxX, window.frame.maxX)
        XCTAssertLessThan(button.frame.maxY, window.frame.maxY)
        XCTAssertLessThan(window.frame.maxY - button.frame.maxY, 40)
    }

    private func wait(_ message: String, in app: XCUIApplication, condition: @escaping () -> Bool) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 15), .completed, message)
    }

    private func resize(_ window: XCUIElement, width: CGFloat, height: CGFloat) {
        // Rounded window corners are outside the resize hit region on newer macOS.
        // Exercise the native straight edges instead of the transparent corner.
        let right = window.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5))
            .withOffset(CGVector(dx: -1, dy: 0))
        right.click(forDuration: 0.2, thenDragTo: right.withOffset(
            CGVector(dx: width - window.frame.width, dy: 0)))
        let bottom = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1))
            .withOffset(CGVector(dx: 0, dy: -1))
        bottom.click(forDuration: 0.2, thenDragTo: bottom.withOffset(
            CGVector(dx: 0, dy: height - window.frame.height)))
    }

    private func attach(_ window: XCUIElement, name: String) {
        let attachment = XCTAttachment(screenshot: window.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func launch(scenario: String = "ready", files: String = "fixture", language: String = "en",
                        theme: String = "light") -> XCUIApplication {
        let app = makeMacTestApplication()
        app.launchEnvironment = ["MSIGN_QA_NO_HARDWARE": "1", "MSIGN_SCREENSHOT_CAPTURE": "1",
            "MSIGN_DEMO_PREVIEW": "0", "MSIGN_DEMO_CARDS": "2", "MSIGN_DEMO_FILES": files,
            "MSIGN_DEMO_SCENARIO": scenario, "MSIGN_UI_TEST_SCENARIO": "sign-success",
            "MSIGN_DEMO_PREFERENCES_SUITE": "md.esemnbun.qa.mac-floating.\(UUID().uuidString)"]
        app.launchArguments = ["-appLanguage", language, "-AppleLanguages", "(\(language))", "-appTheme", theme,
            "-bridgeEnabled", "NO", "-mainSection", "sign", "--show-main-window"]
        app.launch()
        return app
    }
}
#endif
