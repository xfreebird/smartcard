#if os(iOS)
import XCTest

@MainActor
final class SharedCardPINUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testDeletingReaderPINAlsoUpdatesSameNFCCard() {
        let app = launch(cards: "2")
        defer { app.terminate() }
        app.buttons["Settings"].firstMatch.tapWhenReady()
        app.buttons["settings.card"].tapWhenReady()
        let choice = app.buttons["signing.method"]
        XCTAssertTrue(choice.waitForExistence(timeout: 10))
        app.selectSigningMethod("reader")
        app.selectSigningMethod("nfc")
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "signing.nfc.card").firstMatch.label.contains("Popescu Ion"))
        app.buttons["card.details"].tapWhenReady()
        let status = app.descendants(matching: .any).matching(identifier: "card.pin.status").firstMatch
        reveal(status, in: app)
        XCTAssertTrue(status.label.contains("PIN is saved"))
        app.buttons["card.pin.delete"].tapWhenReady()
        XCTAssertTrue(status.label.contains("PIN is not saved"))
        app.buttons["settings.sheet.done"].firstMatch.tapWhenReady()
        app.selectSigningMethod("reader")
        app.buttons["card.details"].tapWhenReady()
        reveal(status, in: app)
        XCTAssertTrue(status.label.contains("PIN is not saved"))
        XCTAssertFalse(app.buttons["card.pin.delete"].exists)
    }

    func testAnotherNFCCardDoesNotBorrowConnectedCardsPIN() {
        let app = launch(cards: "2")
        defer { app.terminate() }
        let choice = app.buttons["signing.method"]
        XCTAssertTrue(choice.waitForExistence(timeout: 15))
        app.selectSigningMethod("reader")
        app.selectSigningMethod("nfc")
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "signing.nfc.card").firstMatch.label.contains("Popescu Ion"))
        app.buttons["signing.nfc.card"].tapWhenReady()
        app.buttons["signing.nfc.anotherCard"].tapWhenReady()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "signing.nfc.card").firstMatch.label.contains("The card you tap"))
        XCTAssertFalse(app.descendants(matching: .any)["signing.nfc.pinStatus"].exists)
        app.selectSigningMethod("reader")
        app.selectSigningMethod("nfc")
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "signing.nfc.card").firstMatch.label.contains("The card you tap"))
    }

    func testSavedPINsCanBeManagedWithoutReaderAndRemainSeparateForDifferentCards() {
        let app = launch(cards: "none")
        defer { app.terminate() }
        app.buttons["Settings"].firstMatch.tapWhenReady()
        let saved = app.buttons["card.savedPINs"]
        reveal(saved, in: app)
        saved.tapWhenReady()
        let first = "14" + String(repeating: "0", count: 38)
        let second = "75" + String(repeating: "0", count: 38)
        XCTAssertTrue(app.buttons["savedPIN.delete.\(first)"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["savedPIN.delete.\(second)"].exists)
        app.buttons["savedPIN.delete.\(first)"].tapWhenReady()
        XCTAssertFalse(app.buttons["savedPIN.delete.\(first)"].exists)
        XCTAssertTrue(app.buttons["savedPIN.delete.\(second)"].exists)
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<5 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.exists)
    }

    private func launch(cards: String) -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication(bundleIdentifier: "md.esemnbun.ios")
        app.launchEnvironment = ["MSIGN_QA_NO_HARDWARE": "1", "MSIGN_SCREENSHOT_CAPTURE": "1",
            "MSIGN_DEMO_CARDS": cards, "MSIGN_DEMO_FILES": "fixture", "MSIGN_DEMO_SHARED_PINS": "1",
            "MSIGN_DEMO_SCENARIO": "ready", "MSIGN_DEMO_PREFERENCES_SUITE": "md.esemnbun.qa.shared-pins.\(UUID())"]
        app.launchArguments = ["-appLanguage", "en", "-AppleLanguages", "(en)", "-bridgeEnabled", "NO", "-mainSection", "sign"]
        app.launch()
        XCTAssertTrue(app.buttons["signing.method"].waitForExistence(timeout: 15))
        return app
    }
}
#endif
