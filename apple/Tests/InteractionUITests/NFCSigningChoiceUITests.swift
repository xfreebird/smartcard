#if os(iOS)
import XCTest

@MainActor
final class NFCSigningChoiceUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    func testNFCRemainsSelectableWithConnectedReaderCards() {
        let app = launch(cards: "2")
        defer { app.terminate() }
        let choice = app.buttons["signing.method"]
        XCTAssertTrue(choice.waitForPresence(timeout: 15))
        let reader = choice
        XCTAssertTrue(choice.label.contains("NFC"))
        XCTAssertFalse(app.descendants(matching: .any)["signing.steps"].exists)
        app.selectSigningMethod("nfc")
        XCTAssertTrue(choice.label.contains("NFC"))
        XCTAssertTrue(app.buttons["signing.nfc.help"].exists)
        XCTAssertTrue(app.buttons["sign.submit"].isEnabled)
        app.selectSigningMethod("reader")
        XCTAssertTrue(reader.label.contains("reader"))
        XCTAssertTrue(app.descendants(matching: .any)["signing.reader.cards"].exists)
        app.buttons["signing.reader.cards"].tapWhenReady()
        XCTAssertTrue(app.staticTexts["Swipe to choose the card you want to use."].exists)
        app.buttons["Done"].tapWhenReady()
        XCTAssertTrue(app.buttons["sign.submit"].isEnabled)
        app.selectSigningMethod("nfc")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "nfc-choice-with-two-synthetic-reader-cards"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testNFCChoiceDoesNotRequireReaderAndDemoNeverAsksForRealPIN() {
        let app = launch(cards: "none")
        defer { app.terminate() }
        let choice = app.buttons["signing.method"]
        XCTAssertTrue(choice.waitForPresence(timeout: 15))
        let sign = app.buttons["sign.submit"]
        XCTAssertTrue(choice.label.contains("NFC"))
        XCTAssertTrue(sign.isEnabled)
        app.selectSigningMethod("reader")
        XCTAssertTrue(app.staticTexts["Connect the reader"].firstMatch.exists)
        XCTAssertFalse(sign.isEnabled)
        app.selectSigningMethod("nfc")
        XCTAssertTrue(sign.isEnabled)
        sign.tap()
        let result = app.descendants(matching: .any).matching(identifier: "sign.result").firstMatch
        XCTAssertTrue(result.waitForPresence(timeout: 15))
        XCTAssertFalse(app.secureTextFields.firstMatch.exists)
    }

    func testGuideAndSimpleCardScreen() {
        let app = launch(cards: "none")
        defer { app.terminate() }
        app.buttons["signing.nfc.help"].tapWhenReady()
        XCTAssertTrue(app.staticTexts["Choose your document"].waitForPresence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Confirm your PIN"].exists)
        let tap = app.staticTexts["Tap and hold your card"]
        for _ in 0..<3 where !tap.isHittable { app.swipeUp() }
        XCTAssertTrue(tap.isHittable)
        app.buttons["nfc.help.close"].tapWhenReady()
        app.selectMainTab("Settings")
        app.buttons["settings.card"].tapWhenReady()
        XCTAssertTrue(app.buttons["signing.nfc.help"].waitForPresence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["signing.steps"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["card.pin.status"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "simple-nfc-card-screen"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.buttons["signing.nfc.help"].tapWhenReady()
        XCTAssertTrue(app.buttons["nfc.help.close"].waitForPresence(timeout: 5))
    }

    func testFirstScreenHasOneClearNextAction() throws {
        let app = launch(cards: "none", files: false)
        defer { app.terminate() }
        let choose = app.buttons["sign.pickFiles"]
        XCTAssertTrue(choose.waitForPresence(timeout: 15))
        XCTAssertTrue(choose.isHittable)
        XCTAssertFalse(app.buttons["sign.submit"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["signing.steps"].exists)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "guided-start-one-action"; attachment.lifetime = .keepAlways; add(attachment)
        choose.tapWhenReady()
        try app.cancelFilePicker()
        XCTAssertTrue(choose.waitForPresence(timeout: 10))
    }

    func testReaderSetupIsVisibleOnSignAndCard() {
        for (scenario, instruction) in [("no-reader", "Connect the reader"), ("empty-reader", "Insert the card")] {
            let app = launch(cards: "none", files: false, scenario: scenario)
            app.selectSigningMethod("reader")
            XCTAssertTrue(app.staticTexts[instruction].firstMatch.waitForPresence(timeout: 5))
            XCTAssertTrue(app.staticTexts[instruction].firstMatch.isHittable)
            XCTAssertTrue(app.buttons["sign.pickFiles"].isHittable)
            app.selectMainTab("Settings")
            app.buttons["settings.card"].tapWhenReady()
            XCTAssertTrue(app.staticTexts[instruction].firstMatch.waitForPresence(timeout: 5))
            XCTAssertTrue(app.staticTexts[instruction].firstMatch.isHittable)
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "inline-reader-\(scenario)"; attachment.lifetime = .keepAlways; add(attachment)
            app.terminate()
        }
    }

    func testPhoneReaderHeroOpensCardDetails() {
        let app = launch(cards: "2", files: false)
        defer { app.terminate() }
        let choiceY = app.buttons["signing.method"].frame.minY
        let chooseY = app.buttons["sign.pickFiles"].frame.minY
        app.selectSigningMethod("reader")
        XCTAssertEqual(app.buttons["signing.method"].frame.minY, choiceY, accuracy: 1)
        XCTAssertEqual(app.buttons["sign.pickFiles"].frame.minY, chooseY, accuracy: 1)
        let details = app.buttons["sign.cardDetails"]
        XCTAssertTrue(details.waitForPresence(timeout: 5))
        XCTAssertTrue(details.isHittable)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "phone-reader-card-with-details"; image.lifetime = .keepAlways; add(image)
        details.tapWhenReady()
        XCTAssertTrue(app.navigationBars["Card details"].waitForPresence(timeout: 5))
        let detailImage = XCTAttachment(screenshot: app.screenshot())
        detailImage.name = "phone-card-details"; detailImage.lifetime = .keepAlways; add(detailImage)
    }

    func testAddAnotherDocumentIsInOptionsMenu() throws {
        for fixture in ["fixture-single", "fixture"] {
            try checkAddDocumentMenu(fixture: fixture)
        }
    }

    private func checkAddDocumentMenu(fixture: String) throws {
        let app = launch(cards: "2", fileFixture: fixture)
        defer { app.terminate() }
        XCTAssertTrue(app.buttons["sign.submit"].waitForPresence(timeout: 15))
        XCTAssertFalse(app.buttons["sign.addFiles"].exists)
        let review = XCTAttachment(screenshot: app.screenshot())
        review.name = "document-review-add-in-menu-\(fixture)"; review.lifetime = .keepAlways; add(review)
        if app.buttons["sign.batchOptions"].exists {
            app.buttons["sign.batchOptions"].tap()
        } else {
            app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "sign.options.")).firstMatch.tap()
        }
        XCTAssertTrue(app.buttons["sign.addFiles"].waitForPresence(timeout: 5))
        let menu = XCTAttachment(screenshot: app.screenshot())
        menu.name = "add-document-options-\(fixture)"; menu.lifetime = .keepAlways; add(menu)
        app.buttons["sign.addFiles"].tapWhenReady()
        try app.cancelFilePicker()
        XCTAssertTrue(app.buttons["sign.submit"].waitForPresence(timeout: 5))
        XCTAssertFalse(app.buttons["sign.addFiles"].exists)
    }

    private func launch(cards: String, files: Bool = true, scenario: String = "ready", fileFixture: String = "fixture") -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: "md.esemnbun.ios")
        app.launchEnvironment = ["MSIGN_QA_NO_HARDWARE": "1", "MSIGN_SCREENSHOT_CAPTURE": "1", "MSIGN_DEMO_CARDS": cards,
            "MSIGN_DEMO_FILES": fileFixture, "MSIGN_DEMO_SHARED_PINS": "1", "MSIGN_DEMO_TAB": "sign", "MSIGN_DEMO_SCENARIO": scenario,
            "MSIGN_UI_TEST_SCENARIO": "sign-success",
            "MSIGN_DEMO_PREFERENCES_SUITE": "md.esemnbun.qa.nfc.\(UUID())"]
        if !files { app.launchEnvironment.removeValue(forKey: "MSIGN_DEMO_FILES") }
        app.launchArguments = ["-appLanguage", "en", "-AppleLanguages", "(en)", "-bridgeEnabled", "NO", "-mainSection", "sign"]
        app.launch()
        return app
    }
}
#endif
