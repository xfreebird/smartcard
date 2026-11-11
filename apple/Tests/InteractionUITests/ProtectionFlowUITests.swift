import XCTest

/// The runner supplies a synthetic PDF through Files and verifies restored bytes after this test.
@MainActor
final class ProtectionFlowUITests: XCTestCase {
    func testEncryptDecryptSavedDocuments() throws {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "md.esemnbun.ios")
        defer { app.terminate() }
        app.launchEnvironment["MSIGN_QA_NO_HARDWARE"] = "1"
        app.launchEnvironment["MSIGN_DEMO_PREFERENCES_SUITE"] = "md.esemnbun.qa.protection.\(UUID().uuidString)"
        app.launchArguments = ["-AppleLanguages", "(en)", "-appLanguage", "en", "-appTheme", "light"]
        app.launch()
        let documents = app.buttons["Documents"].firstMatch
        XCTAssertTrue(documents.waitForExistence(timeout: 20))
        documents.tap()
        app.openProtection()
        XCTAssertFalse(app.buttons["Certificate / card"].exists)
        XCTAssertFalse(app.buttons["protect.submit"].isEnabled)

        app.buttons["protect.chooseFile"].tapWhenReady()
        XCTAssertTrue(app.collectionViews["File View"].waitForExistence(timeout: 10))
        try app.cancelFilePicker()
        XCTAssertTrue(app.buttons["protect.chooseFile"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["protect.submit"].isEnabled)
        try chooseSource(in: app)

        let password = app.secureTextFields["protect.password"]
        XCTAssertTrue(password.waitForExistence(timeout: 8))
        password.tap()
        password.typeText("sample-roundtrip-2026")
        let confirmation = app.secureTextFields["protect.confirmPassword"]
        if !confirmation.isHittable { app.swipeUp() }
        confirmation.tap()
        confirmation.typeText("sample-roundtrip")
        XCTAssertFalse(app.buttons["protect.submit"].isEnabled, "A mismatched confirmation must not encrypt")
        confirmation.typeText("-2026")
        app.buttons["protect.submit"].tap()
        assertSaved(in: app)
        attach(app, "encrypted-saved")
        try closeDetails(in: app)

        let encrypted = document("ProtectionSource.pdf.symmetric.p7m", in: app)
        XCTAssertTrue(encrypted.waitForExistence(timeout: 8))
        encrypted.tap()
        app.buttons["Decrypt"].tap()
        XCTAssertTrue(password.waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["protect.submit"].isEnabled)
        password.tap()
        password.typeText("sample-roundtrip-2026")
        app.buttons["protect.submit"].tap()
        assertSaved(in: app)
        attach(app, "decrypted-saved")
        try closeDetails(in: app)
        // The encrypted document's detail sheet is below the protection sheet.
        if app.buttons["Done"].exists { try closeDetails(in: app) }

        app.terminate()
        app.launch()
        XCTAssertTrue(documents.waitForExistence(timeout: 10))
        documents.tap()
        XCTAssertTrue(document("decrypted-ProtectionSource.pdf", in: app).waitForExistence(timeout: 10), app.debugDescription)
        attach(app, "protected-documents-after-relaunch")
    }

    private func chooseSource(in app: XCUIApplication) throws {
        app.buttons["protect.chooseFile"].tapWhenReady()
        XCTAssertTrue(app.collectionViews["File View"].waitForExistence(timeout: 10))
        let browse = app.buttons["Browse"].firstMatch
        if browse.exists { browse.tapWhenReady() }
        let container = app.cells["eSemnBun, Container"]
        for _ in 0..<5 where !container.isHittable {
            let back = app.navigationBars.buttons["BackButton"].firstMatch
            if back.exists {
                back.tap()
            } else {
                let local = app.staticTexts.matching(NSPredicate(format: "label IN %@", ["On My iPhone", "On My iPad"])).firstMatch
                if local.waitForExistence(timeout: 3) { local.tap() }
            }
        }
        XCTAssertTrue(container.waitForExistence(timeout: 5), app.debugDescription)
        container.openFilePickerFolder()
        let file = app.cells.matching(NSPredicate(format: "label BEGINSWITH %@", "ProtectionSource")).firstMatch
        XCTAssertTrue(file.waitForExistence(timeout: 8), app.debugDescription)
        file.tapWhenReady()
        if app.buttons["Open"].waitForExistence(timeout: 2) { app.buttons["Open"].tap() }
    }

    private func document(_ name: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "documents.openDetails", name)).firstMatch
    }

    private func assertSaved(in app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["Saved in Documents"].waitForExistence(timeout: 20), app.debugDescription)
        XCTAssertFalse(app.buttons["Cancel"].exists)
    }

    private func closeDetails(in app: XCUIApplication) throws {
        try XCTUnwrap(app.buttons.matching(identifier: "Done").allElementsBoundByIndex.first(where: \.isHittable)).tap()
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
