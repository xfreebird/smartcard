#if os(iOS)
import XCTest

@MainActor
final class PINActionsUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }
    override func tearDown() { XCUIDevice.shared.orientation = .portrait; super.tearDown() }

    func testPINActionsRemainVisibleWithKeyboardInPortrait() { checkActions(landscape: false) }
    func testPINActionsRemainVisibleWithKeyboardInLandscape() { checkActions(landscape: true) }

    private func checkActions(landscape: Bool) {
        XCUIDevice.shared.orientation = landscape ? .landscapeLeft : .portrait
        let app = XCUIApplication(bundleIdentifier: "md.esemnbun.ios")
        app.launchEnvironment = ["MSIGN_QA_NO_HARDWARE": "1", "MSIGN_SCREENSHOT_CAPTURE": "1",
            "MSIGN_DEMO_CARDS": "2", "MSIGN_DEMO_FILES": "fixture", "MSIGN_DEMO_SCENARIO": "pin",
            "MSIGN_DEMO_PREFERENCES_SUITE": "md.esemnbun.qa.pin-actions.\(UUID())"]
        app.launchArguments = ["-appLanguage", "ro", "-AppleLanguages", "(ro)", "-bridgeEnabled", "NO"]
        app.launch()
        // Duo/windowed scenes can keep a tall aspect ratio after physical rotation.
        // The keyboard and action bounds below verify the resulting layout directly.
        XCTAssertEqual(XCUIDevice.shared.orientation, landscape ? .landscapeLeft : .portrait)
        let submit = app.buttons["pin.submit"]
        let cancel = app.buttons["pin.cancel"]
        XCTAssertTrue(submit.waitForPresence(timeout: 15))
        XCTAssertTrue(cancel.isHittable)
        XCTAssertFalse(submit.isEnabled)
        XCTAssertGreaterThanOrEqual(submit.frame.minY, app.frame.minY)
        XCTAssertLessThanOrEqual(submit.frame.maxY, app.frame.maxY)
        let input = app.secureTextFields["pin.input"]
        XCTAssertTrue(input.waitForPresence(timeout: 5))
        input.tap()
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForPresence(timeout: 5), "This regression requires the software keyboard.")
        input.typeText("1234") // Synthetic fixture only; the hardware gate forbids real card access.
        XCTAssertTrue(submit.isEnabled)
        XCTAssertTrue(submit.isHittable)
        XCTAssertLessThanOrEqual(submit.frame.maxY, app.frame.maxY)
        // Secure-text injection can temporarily dismiss the simulator's software keyboard.
        // Refocus before measuring; the test still requires a visible keyboard during submission.
        if !keyboard.exists { input.tap() }
        XCTAssertTrue(keyboard.waitForPresence(timeout: 5))
        XCTAssertLessThanOrEqual(submit.frame.maxY, keyboard.frame.minY + 1)
        // Capture after submission: XCTest's secure-input screenshot can temporarily hide the
        // keyboard and invalidate the button's cached position just before the synthesized tap.
        app.buttons["pin.submit"].tapWhenReady()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: submit)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = landscape ? "pin-submitted-landscape" : "pin-submitted-portrait"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
#endif
