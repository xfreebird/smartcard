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
        XCTAssertTrue(documents.waitForExistence(timeout: 20))
        documents.tap()
        let entry = app.buttons.matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "documents.openDetails", "QA-synthetic-semnat.pdf")).firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 10), app.debugDescription)
        attach(app, "01-documents-migrated")
        entry.tap()
        XCTAssertTrue(app.navigationBars["Signing details"].waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(app.staticTexts["Cannot be confirmed"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["No supported signature was recognized."].exists)
        attach(app, "02-unsigned-current-file-details")
        app.buttons["Done"].tap()
        app.buttons["History"].tap()
        app.openHistoryClear()
        XCTAssertTrue(app.buttons["documents.confirmClear"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["documents.confirmClear"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["No activity yet"].waitForExistence(timeout: 5), app.debugDescription)
        attach(app, "03-history-empty")
        app.buttons["Saved documents"].tap()
        XCTAssertTrue(entry.waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        app.buttons["Documents"].firstMatch.tap()
        XCTAssertTrue(entry.waitForExistence(timeout: 10), "Saved document must survive history clear and relaunch")
        attach(app, "04-documents-after-relaunch")
        app.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["No activity yet"].waitForExistence(timeout: 5))
        app.buttons["Saved documents"].tap()
        let xml = app.buttons.matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "documents.openDetails", "detached-signature.xml")).firstMatch
        XCTAssertTrue(xml.exists)
        xml.tap()
        XCTAssertTrue(app.staticTexts["Cannot be confirmed"].waitForExistence(timeout: 10))
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
        XCTAssertTrue(xml.waitForExistence(timeout: 10))
        xml.tap()
        let choose = app.buttons["verify.chooseOriginals"]
        XCTAssertTrue(choose.waitForExistence(timeout: 10))
        choose.tap()
        XCTAssertTrue(app.collectionViews["File View"].waitForExistence(timeout: 15), app.debugDescription)
        attach(app, "06-original-picker")
        try XCTUnwrap(app.buttons.matching(identifier: "Cancel").allElementsBoundByIndex.last(where: \.isHittable)).tapWhenReady()
        XCTAssertTrue(app.collectionViews["File View"].waitForNonExistence(timeout: 10))
        XCTAssertTrue(choose.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Cannot be confirmed"].exists)
        choose.tap()
        XCTAssertTrue(app.collectionViews["File View"].waitForExistence(timeout: 10))
        let browse = app.buttons["Browse"].firstMatch
        if browse.exists { browse.tapWhenReady() }
        let container = app.cells["eSemnBun, Container"]
        for _ in 0..<4 where !container.isHittable {
            let back = app.navigationBars.buttons["BackButton"].firstMatch
            if back.exists { back.tap() }
            else {
                let local = app.staticTexts.matching(NSPredicate(format: "label IN %@", ["On My iPhone", "On My iPad"])).firstMatch
                XCTAssertTrue(local.waitForExistence(timeout: 5), app.debugDescription)
                local.tap()
            }
        }
        XCTAssertTrue(container.waitForExistence(timeout: 5))
        container.tapWhenReady()
        let folder = app.cells["Originals, Folder"]
        let visibleFolder = NSPredicate { _, _ in
            folder.isHittable && folder.frame.minX >= 0 && folder.frame.maxX <= app.frame.width
        }
        expectation(for: visibleFolder, evaluatedWith: app)
        waitForExpectations(timeout: 10)
        folder.tapWhenReady()
        let original = app.cells.matching(NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS %@", "detached-", "txt")).firstMatch
        XCTAssertTrue(original.waitForExistence(timeout: 5), app.debugDescription)
        original.tapWhenReady()
        let open = app.buttons["Open"]
        XCTAssertTrue(open.waitForExistence(timeout: 5), app.debugDescription)
        open.tap()
        XCTAssertTrue(choose.waitForExistence(timeout: 10))
        let missing = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Verification is incomplete."))
        let resolved = NSPredicate { _, _ in missing.count == 0 && !app.activityIndicators.firstMatch.exists }
        expectation(for: resolved, evaluatedWith: app)
        waitForExpectations(timeout: 10)
        let author = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Author: TEST SEMNATAR")).firstMatch
        author.tap()
        XCTAssertTrue(app.staticTexts["Document integrity"].waitForExistence(timeout: 5))
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
        XCTAssertTrue(documents.waitForExistence(timeout: 20), app.debugDescription)
        documents.tap()
        let entry = app.buttons.matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "documents.openDetails", "detached-signature.xml")).firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 10))
        entry.tap()
        XCTAssertTrue(app.buttons["verify.chooseOriginals"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Cannot be confirmed"].exists)
        attach(app, "08-duo-document-modal-default")
        // The same detail assertions run on the active phone and tablet layouts.
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
