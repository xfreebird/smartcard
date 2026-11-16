#if os(iOS)
import XCTest

@MainActor
final class SettingsNavigationUITests: XCTestCase {
    func testSettingsCombinesCardsPINsAndPreferencesInBothOrientations() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication(bundleIdentifier: "md.esemnbun.ios")
        app.launchEnvironment = ["MSIGN_QA_NO_HARDWARE": "1", "MSIGN_SCREENSHOT_CAPTURE": "1",
            "MSIGN_DEMO_CARDS": "2", "MSIGN_DEMO_SHARED_PINS": "1",
            "MSIGN_DEMO_PREFERENCES_SUITE": "md.esemnbun.qa.settings.\(UUID())"]
        app.launchArguments = ["-appLanguage", "en", "-AppleLanguages", "(en)", "-appTheme", "light"]
        app.launch()
        defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
        XCTAssertTrue(app.buttons["sign.pickFiles"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["sign.pickFiles"].isHittable)
        XCTAssertTrue(app.buttons["signing.nfc.help"].isHittable)
        capture(app, "sign-portrait-illustration")
        let methodY = app.buttons["signing.method"].frame.minY
        let documentActionY = app.buttons["sign.pickFiles"].frame.minY
        app.selectSigningMethod("reader")
        XCTAssertEqual(app.buttons["signing.method"].frame.minY, methodY, accuracy: 1)
        XCTAssertEqual(app.buttons["sign.pickFiles"].frame.minY, documentActionY, accuracy: 1)
        XCTAssertTrue(app.descendants(matching: .any)["signing.reader.cards"].exists)
        // Duo's system tab rail occupies part of the app frame. Measure the usable
        // content column shared by the card and fixed document action instead.
        XCTAssertGreaterThanOrEqual(app.collectionViews["signing.reader.cards"].frame.width,
                                    min(400, app.buttons["sign.pickFiles"].frame.width) - 12)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "Popescu Ion")).firstMatch.exists)
        capture(app, "sign-portrait-actual-reader-card")
        selectTab("Settings", in: app)
        let cards = app.buttons["settings.card"]
        capture(app, "settings-top")
        XCTAssertTrue(app.switches["settings.demoMode"].isHittable || app.descendants(matching: .any)["settings.demoMode"].isHittable)
        reveal(app.buttons["card.savedPINs"], in: app)
        capture(app, "settings-portrait")
        XCTAssertFalse(app.buttons["signing.method"].exists)
        app.buttons["settings.help"].tapWhenReady()
        XCTAssertTrue(app.descendants(matching: .any)["settings.help.page"].waitForExistence(timeout: 5))
        closeSheet(app)
        app.buttons["card.savedPINs"].tapWhenReady()
        XCTAssertTrue(app.buttons["savedPIN.delete.14" + String(repeating: "0", count: 38)].waitForExistence(timeout: 5))
        closeSheet(app)
        reveal(cards, in: app)
        capture(app, "settings-returned")
        cards.tapWhenReady()
        app.selectSigningMethod("reader")
        XCTAssertTrue(app.descendants(matching: .any)["signing.reader.cards"].waitForExistence(timeout: 5))
        capture(app, "settings-reader-cards")
        app.buttons["card.details"].tapWhenReady()
        XCTAssertTrue(app.descendants(matching: .any)["card.pin.status"].waitForExistence(timeout: 5))
        capture(app, "card-details-modal")
        closeSheet(app)
        XCTAssertTrue(app.buttons["signing.method"].waitForExistence(timeout: 5))
        closeSheet(app)
        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 3)
        reveal(cards, in: app)
        capture(app, "settings-landscape")
        selectTab("Sign", in: app)
        XCTAssertTrue(app.buttons["sign.pickFiles"].isHittable)
        XCTAssertTrue(app.descendants(matching: .any)["signing.reader.cards"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["signing.steps"].exists)
        capture(app, "sign-landscape-compact-card")
        selectTab("Verify", in: app)
        XCTAssertTrue(app.descendants(matching: .any)["verify.dropZone"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["verify.pickFiles"].isHittable)
        capture(app, "verify-landscape-drop-target")
        selectTab("Documents", in: app)
        XCTAssertTrue(app.buttons["documents.protectFiles"].isHittable)
        app.buttons["documents.protectFiles"].tapWhenReady()
        XCTAssertTrue(app.buttons["protect.chooseFile"].waitForExistence(timeout: 5))
        capture(app, "documents-direct-protection")
    }

    private func selectTab(_ title: String, in app: XCUIApplication) {
        let choices = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", title))
        for _ in 0..<3 {
            if let visible = choices.allElementsBoundByIndex.first(where: { $0.isHittable }) {
                visible.tapWhenReady()
                return
            }
            // iPad's native tab strip pages when its labels exceed the available width.
            let next = app.buttons["Next Page"]
            let previous = app.buttons["Previous Page"]
            if next.isHittable { next.tapWhenReady() }
            else if previous.isHittable { previous.tapWhenReady() }
            else { break }
        }
        XCTFail("No visible tab for " + title)
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<4 {
            if element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

    private func closeSheet(_ app: XCUIApplication) {
        let done = app.buttons.matching(identifier: "settings.sheet.done").allElementsBoundByIndex.first { $0.isHittable }
        XCTAssertNotNil(done)
        done?.tapWhenReady()
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = name; image.lifetime = .keepAlways; add(image)
        print("MSIGN_UI_CAPTURE " + name)
        Thread.sleep(forTimeInterval: 1)
    }
}
#endif
