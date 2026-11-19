import XCTest

/// Requires an isolated live QA preferences suite seeded with synthetic Documents entries.
/// Unlike demo-mode tests this exercises the real persisted document library and migration.
@MainActor
final class DocumentsUITests: XCTestCase {
    func testSavedDetailsAndHistoryClearPersistAcrossRelaunch() throws {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "md.esemnbun.ios")
        defer { app.terminate() }
        app.launchEnvironment["MSIGN_QA_NO_HARDWARE"] = "1"
        app.launchEnvironment["MSIGN_DEMO_PREFERENCES_SUITE"] = "md.esemnbun.qa.documents.history"
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-appLanguage", "en"]
        app.launch()
        let documents = app.buttons["Documents"].firstMatch
        XCTAssertTrue(documents.waitForPresence(timeout: 20))
        documents.tap()
        let entry = app.buttons.matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "documents.openDetails", "QA-synthetic-semnat.pdf")).firstMatch
        XCTAssertTrue(entry.waitForPresence(timeout: 10), app.debugDescription)
        attach(app, "01-documents-migrated")
        entry.tap()
        XCTAssertTrue(app.navigationBars["Signing details"].waitForPresence(timeout: 10), app.debugDescription)
        XCTAssertTrue(app.staticTexts["Cannot be confirmed"].waitForPresence(timeout: 10))
        XCTAssertTrue(app.staticTexts["No supported signature was recognized."].exists)
        attach(app, "02-unsigned-current-file-details")
        app.buttons["Done"].tap()
        app.buttons["History"].tap()
        app.openHistoryClear()
        XCTAssertTrue(app.buttons["documents.confirmClear"].firstMatch.waitForPresence(timeout: 5))
        app.buttons["documents.confirmClear"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["No activity yet"].waitForPresence(timeout: 5), app.debugDescription)
        attach(app, "03-history-empty")
        app.buttons["Saved documents"].tap()
        XCTAssertTrue(entry.waitForPresence(timeout: 5))
        app.terminate()
        app.launch()
        app.buttons["Documents"].firstMatch.tap()
        XCTAssertTrue(entry.waitForPresence(timeout: 10), "Saved document must survive history clear and relaunch")
        attach(app, "04-documents-after-relaunch")
        app.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["No activity yet"].waitForPresence(timeout: 5))
        app.buttons["Saved documents"].tap()
        let xml = app.buttons.matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "documents.openDetails", "detached-signature.xml")).firstMatch
        XCTAssertTrue(xml.exists)
        xml.tap()
        XCTAssertTrue(app.staticTexts["Cannot be confirmed"].waitForPresence(timeout: 10))
        XCTAssertTrue(app.buttons["verify.chooseOriginals"].exists)
        XCTAssertFalse(app.staticTexts["Invalid signature"].exists)
        attach(app, "05-missing-original-unconfirmed")
        app.terminate()
    }

    func testDetachedOriginalPicker() throws {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "md.esemnbun.ios")
        defer { app.terminate() }
        app.launchEnvironment["MSIGN_QA_NO_HARDWARE"] = "1"
        app.launchEnvironment["MSIGN_DEMO_PREFERENCES_SUITE"] = "md.esemnbun.qa.documents.final"
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-appLanguage", "en"]
        app.launch()
        app.buttons["Documents"].firstMatch.tap()
        let xml = app.buttons.matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "documents.openDetails", "detached-signature.xml")).firstMatch
        XCTAssertTrue(xml.waitForPresence(timeout: 10))
        xml.tap()
        let choose = app.buttons["verify.chooseOriginals"]
        XCTAssertTrue(choose.waitForPresence(timeout: 10))
        choose.tap()
        XCTAssertTrue(app.filePicker.waitForPresence(timeout: 30), app.debugDescription)
        attach(app, "06-original-picker")
        try app.cancelFilePicker()
        XCTAssertTrue(choose.waitForPresence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Cannot be confirmed"].exists)
        choose.tap()
        XCTAssertTrue(app.filePicker.waitForPresence(timeout: 30))
        try NativeFilePicker(app: app).selectFile(in: ["eSemnBun, Container", "Originals, Folder"],
            namePrefix: "detached-", labelContains: "txt", confirmSelection: true)
        XCTAssertTrue(choose.waitForPresence(timeout: 10))
        let missing = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Verification is incomplete."))
        let resolved = NSPredicate { _, _ in missing.count == 0 && !app.activityIndicators.firstMatch.exists }
        expectation(for: resolved, evaluatedWith: app)
        waitForExpectations(timeout: 10)
        let signature = app.buttons["verify.disclosure.signature"].firstMatch
        XCTAssertTrue(signature.waitForPresence(timeout: 5))
        XCTAssertTrue(signature.label.contains("Author: TEST SEMNATAR"), signature.label)
        signature.tap()
        XCTAssertTrue(app.staticTexts["Document integrity"].waitForPresence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["verify.missingOriginal"].exists)
        attach(app, "07-original-selected-integrity")
        app.terminate()
    }

    func testDuoDocumentModal() throws {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "md.esemnbun.ios")
        defer { app.terminate() }
        app.launchEnvironment["MSIGN_QA_NO_HARDWARE"] = "1"
        app.launchEnvironment["MSIGN_DEMO_PREFERENCES_SUITE"] = "md.esemnbun.qa.documents.duo"
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-appLanguage", "en"]
        app.launch()
        let documents = app.buttons["Documents"].firstMatch
        XCTAssertTrue(documents.waitForPresence(timeout: 20), app.debugDescription)
        documents.tap()
        let entry = app.buttons.matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "documents.openDetails", "detached-signature.xml")).firstMatch
        XCTAssertTrue(entry.waitForPresence(timeout: 10))
        entry.tap()
        XCTAssertTrue(app.buttons["verify.chooseOriginals"].waitForPresence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Cannot be confirmed"].exists)
        attach(app, "08-duo-document-modal-default")
        // The same detail assertions run on the active phone and tablet layouts.
        app.terminate()
        app.launchEnvironment = ["MSIGN_QA_NO_HARDWARE": "1", "MSIGN_SCREENSHOT_CAPTURE": "1",
            "MSIGN_DEMO_PREFERENCES_SUITE": "md.esemnbun.qa.document-actions.layout",
            "MSIGN_DEMO_CARDS": "1", "MSIGN_DEMO_SCENARIO": "documents-details-unsigned", "MSIGN_DEMO_TAB": "documents"]
        app.launchArguments = ["-appTheme", "light", "-appLanguage", "ro", "-AppleLanguages", "(ro)", "-bridgeEnabled", "NO"]
        app.launch()
        let preview = app.buttons["documents.details.primaryAction"]
        let share = app.buttons["documents.details.share"]
        XCTAssertTrue(preview.waitForPresence(timeout: 15))
        XCTAssertTrue(share.waitForPresence(timeout: 5))
        XCTAssertTrue(preview.isHittable && share.isHittable)
        XCTAssertTrue(app.frame.contains(preview.frame) && app.frame.contains(share.frame))
        XCTAssertEqual(preview.frame.height, share.frame.height, accuracy: 2,
                       "The Romanian preview label must not wrap into a taller capsule")
        attach(app, "09-romanian-document-actions")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
