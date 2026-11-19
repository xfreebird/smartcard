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
        XCTAssertTrue(documents.waitForPresence(timeout: 20))
        documents.tap()
        app.openProtection()
        let rsa = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "RSA certificate")).firstMatch
        XCTAssertTrue(rsa.waitForPresence(timeout: 5))
        rsa.tap()
        XCTAssertTrue(app.buttons["protect.chooseCertificate"].waitForPresence(timeout: 5))
        let passwordMethod = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Password")).firstMatch
        passwordMethod.tap()
        let keySize = app.descendants(matching: .any).matching(identifier: "protect.keySize").firstMatch
        XCTAssertTrue(keySize.waitForPresence(timeout: 5))
        XCTAssertTrue(keySize.label.contains("AES-256"))
        keySize.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        for size in ["AES-128", "AES-192", "AES-256"] {
            XCTAssertTrue(app.buttons[size].waitForPresence(timeout: 5))
        }
        app.buttons["AES-192"].tap()
        XCTAssertTrue(keySize.label.contains("AES-192"))
        XCTAssertFalse(app.buttons["protect.submit"].isEnabled)

        app.buttons["protect.chooseFile"].tapWhenReady()
        XCTAssertTrue(app.filePicker.waitForPresence(timeout: 30))
        try app.cancelFilePicker()
        XCTAssertTrue(app.buttons["protect.chooseFile"].waitForPresence(timeout: 5))
        XCTAssertFalse(app.buttons["protect.submit"].isEnabled)
        try chooseSource(in: app)

        let password = app.secureTextFields["protect.password"]
        XCTAssertTrue(password.waitForPresence(timeout: 8))
        password.tap()
        password.typeText("sample-roundtrip-2026")
        let confirmation = app.secureTextFields["protect.confirmPassword"]
        if !confirmation.isHittable { app.swipeUp() }
        // The keyboard can finish repositioning the form after the first tap.
        // Require focus before typing so a missed tap cannot send text to the password field.
        for _ in 0..<3 {
            confirmation.tap()
            if confirmation.waitForFocus(timeout: 3) { break }
        }
        if !confirmation.waitForFocus(timeout: 3) {
            attach(app, "confirmation-focus-failure")
            XCTFail("Confirmation field did not receive keyboard focus: \(app.debugDescription)")
            return
        }
        confirmation.typeText("sample-roundtrip")
        XCTAssertTrue(app.staticTexts["protect.passwordMismatch"].waitForPresence(timeout: 5), "A mismatched confirmation must be shown")
        confirmation.typeText("-2026")
        app.buttons["protect.dismissKeyboard"].tapWhenReady()
        app.buttons["protect.submit"].tapWhenReady()
        assertSaved(in: app)
        attach(app, "encrypted-saved")
        try closeDetails(in: app)

        let encrypted = document("ProtectionSource.pdf.symmetric.p7m", in: app)
        XCTAssertTrue(encrypted.waitForPresence(timeout: 8))
        encrypted.tap()
        app.buttons["documents.details.primaryAction"].tapWhenReady()
        XCTAssertTrue(password.waitForPresence(timeout: 8))
        XCTAssertFalse(keySize.exists)
        XCTAssertFalse(app.buttons["protect.submit"].isEnabled)
        password.tap()
        password.typeText("sample-roundtrip-2026")
        app.buttons["protect.dismissKeyboard"].tapWhenReady()
        app.buttons["protect.submit"].tapWhenReady()
        assertSaved(in: app)
        attach(app, "decrypted-saved")
        try closeDetails(in: app)
        // The encrypted document's detail sheet is below the protection sheet.
        if app.buttons["Done"].exists { try closeDetails(in: app) }

        app.terminate()
        app.launch()
        XCTAssertTrue(documents.waitForPresence(timeout: 10))
        documents.tap()
        XCTAssertTrue(document("decrypted-ProtectionSource.pdf", in: app).waitForPresence(timeout: 10), app.debugDescription)
        attach(app, "protected-documents-after-relaunch")
    }

    private func chooseSource(in app: XCUIApplication) throws {
        app.buttons["protect.chooseFile"].tapWhenReady()
        XCTAssertTrue(app.filePicker.waitForPresence(timeout: 30))
        try NativeFilePicker(app: app).selectFile(in: ["eSemnBun, Container"],
            namePrefix: "ProtectionSource", confirmSelection: false)
    }

    private func document(_ name: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "documents.openDetails", name)).firstMatch
    }

    private func assertSaved(in app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["Saved in Documents"].waitForPresence(timeout: 20), app.debugDescription)
        XCTAssertFalse(app.buttons["Cancel"].exists)
    }

    private func closeDetails(in app: XCUIApplication) throws {
        let buttons = app.buttons.matching(identifier: "Done")
        let ready = NSPredicate { _, _ in buttons.allElementsBoundByIndex.contains(where: \.isHittable) }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: app)], timeout: 10), .completed,
                       app.debugDescription)
        try XCTUnwrap(buttons.allElementsBoundByIndex.last(where: \.isHittable)).tap()
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

private extension XCUIElement {
    func waitForFocus(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "hasKeyboardFocus == true")
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if predicate.evaluate(with: self) { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline
        return false
    }
}
