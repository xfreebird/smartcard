import XCTest

/// Real controls and app state with a replaceable signer. Results are explicitly unsigned fixtures.
@MainActor
final class MockWorkflowUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testSigningSuccessMixedFailureAndFatalStop() {
        for (scenario, outputs, queued) in [("sign-success", 2, 0), ("sign-mixed", 1, 1), ("sign-fatal", 0, 2)] {
            let app = launch(scenario)
            defer { app.terminate() }
            let sign = app.buttons["sign.submit"].firstMatch
            XCTAssertTrue(sign.waitForPresence(timeout: 15))
            XCTAssertTrue(sign.isEnabled)
            sign.activateControl()
            let results = app.descendants(matching: .any).matching(identifier: "sign.result")
            let options = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "sign.options."))
            wait("\(scenario) completes", in: app) {
                results.count == outputs && options.count == queued && (queued == 0 ||
                    app.descendants(matching: .any)["sign.error.Sample-contract.pdf"].firstMatch.exists)
            }
            XCTAssertFalse(app.secureTextFields.firstMatch.exists, "Mock signer must never acquire a real credential")
            if queued > 0 {
                XCTAssertTrue(app.descendants(matching: .any)["sign.error.Sample-contract.pdf"].firstMatch.exists)
                XCTAssertTrue(app.descendants(matching: .any)["sign.options.Sample-contract.pdf"].exists)
            }
            if scenario == "sign-mixed" {
                XCTAssertFalse(app.descendants(matching: .any)["sign.options.Sample-request.txt"].exists)
            }
            attach(app, name: scenario)
        }
    }

    func testRemoveInputThroughItsMenuDoesNotSignAnything() {
        let app = launch("sign-success")
        defer { app.terminate() }
        expand(app)
        let options = app.descendants(matching: .any)["sign.options.Sample-contract.pdf"].firstMatch
        XCTAssertTrue(options.waitForPresence(timeout: 10))
        options.activateControl()
        let remove = app.descendants(matching: .any)["sign.remove"].firstMatch
        XCTAssertTrue(remove.waitForPresence(timeout: 5))
        remove.activateControl()
        wait("removed document", in: app) { !options.exists }
        XCTAssertTrue(app.descendants(matching: .any)["sign.options.Sample-request.txt"].firstMatch.exists)
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "sign.result").count, 0)
        attach(app, name: "remove-queue-item")
    }

    func testChangingFormatThenRemovingBatch() {
        let app = launch("sign-success")
        defer { app.terminate() }
        let menu = app.buttons["sign.batchOptions"].firstMatch
        // Desktop and wide layouts expose per-file options when no collapsed group is needed.
        if menu.waitForPresence(timeout: 3) {
            menu.activateControl()
            selectXMLFormat(in: app)
            expand(app)
        } else {
            expand(app)
            app.descendants(matching: .any)["sign.options.Sample-contract.pdf"].firstMatch.activateControl()
            selectXMLFormat(in: app)
        }
        XCTAssertTrue(app.descendants(matching: .any)["sign.selectedFormat.xadesBES"].firstMatch.waitForPresence(timeout: 5))
        for name in ["Sample-contract.pdf", "Sample-request.txt"] {
            let options = app.descendants(matching: .any)["sign.options." + name].firstMatch
            XCTAssertTrue(options.exists)
            options.activateControl()
            let remove = app.descendants(matching: .any)["sign.remove"].firstMatch
            XCTAssertTrue(remove.waitForPresence(timeout: 5)); remove.activateControl()
            wait("removed \(name)", in: app) { !options.exists }
        }
        let sign = app.buttons["sign.submit"].firstMatch
        XCTAssertTrue(!sign.exists || !sign.isEnabled)
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "sign.result").count, 0)
    }

    func testCancelStampDoesNotSignOrRemoveInputs() {
        let app = launch("sign-success")
        defer { app.terminate() }
        expand(app)
        app.descendants(matching: .any)["sign.options.Sample-contract.pdf"].firstMatch.activateControl()
        let edit = app.descendants(matching: .any)["sign.editStamp"].firstMatch
        XCTAssertTrue(edit.waitForPresence(timeout: 5)); edit.activateControl()
        let cancel = app.buttons["stamp.cancel"].firstMatch
        XCTAssertTrue(cancel.waitForPresence(timeout: 10)); cancel.activateControl()
        XCTAssertTrue(cancel.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["sign.options.Sample-contract.pdf"].exists)
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "sign.result").count, 0)
    }

    func testHistoryCancellationAndClearPreserveSavedLibrary() {
        #if os(macOS)
        let tab = "activity"
        #else
        let tab = "documents"
        #endif
        let app = launch("sign-success", fixture: "history-populated", tab: tab)
        defer { app.terminate() }
        openHistoryClear(in: app)
        let confirm = app.buttons["documents.confirmClear"].firstMatch
        XCTAssertTrue(confirm.waitForPresence(timeout: 5))
        let cancel = app.buttons["documents.cancelClear"].firstMatch
        if cancel.exists { cancel.activateControl() }
        else {
            #if os(macOS)
            app.typeKey(.escape, modifierFlags: [])
            #else
            // SwiftUI popovers omit cancel-role actions; tapping their outside dismissal area cancels.
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.75)).tap()
            #endif
        }
        XCTAssertTrue(confirm.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Contract-semnat.pdf"].exists, "Cancel must retain history")
        openHistoryClear(in: app)
        XCTAssertTrue(confirm.waitForPresence(timeout: 5)); confirm.activateControl()
        XCTAssertTrue(app.staticTexts["No activity yet"].waitForPresence(timeout: 5))
        app.descendants(matching: .any)["Saved documents"].firstMatch.activateControl()
        let saved = app.buttons.matching(identifier: "documents.openDetails")
        wait("saved library retained", in: app) { saved.count == 3 }
        XCTAssertFalse(app.staticTexts["No activity yet"].exists)
        attach(app, name: "history-clear-keeps-library")
    }

    func testRefuseSingleAndBatchWebsiteConsent() {
        for fixture in ["consent", "consent-batch"] {
            let app = launch("sign-success", fixture: fixture)
            defer { app.terminate() }
            let refuse = app.buttons["consent.refuse"].firstMatch
            XCTAssertTrue(refuse.waitForPresence(timeout: 15)); refuse.activateControl()
            XCTAssertTrue(refuse.waitForNonExistence(timeout: 5))
            XCTAssertFalse(app.secureTextFields.firstMatch.exists)
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "sign.result").count, 0)
        }
    }

    private func selectXMLFormat(in app: XCUIApplication) {
        #if os(macOS)
        // AppKit menu titles survive even when SwiftUI's item identifiers are replaced.
        let format = app.menuItems["XML signature"].firstMatch
        #else
        let format = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier == %@ OR label == %@", "sign.format.xadesBES", "XML signature")).firstMatch
        #endif
        XCTAssertTrue(format.waitForPresence(timeout: 5))
        format.activateControl()
    }
    private func expand(_ app: XCUIApplication) {
        let expand = app.buttons["sign.expandBatch"].firstMatch
        if expand.waitForPresence(timeout: 2) { expand.activateControl() }
    }
    private func openHistoryClear(in app: XCUIApplication) { app.openHistoryClear() }
    private func wait(_ message: String, in app: XCUIApplication, condition: @escaping () -> Bool) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: app)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 15), .completed, message)
    }
    private func attach(_ app: XCUIApplication, name: String) {
        let image = XCTAttachment(screenshot: app.screenshot()); image.name = name; image.lifetime = .keepAlways; add(image)
    }
    private func launch(_ scenario: String, fixture: String = "ready", tab: String = "sign") -> XCUIApplication {
        #if os(macOS)
        let app = XCUIApplication(bundleIdentifier: "md.esemnbun.mac")
        #else
        let app = XCUIApplication(bundleIdentifier: "md.esemnbun.ios")
        XCUIDevice.shared.orientation = .portrait
        #endif
        app.launchEnvironment = ["MSIGN_QA_NO_HARDWARE": "1", "MSIGN_SCREENSHOT_CAPTURE": "1", "MSIGN_DEMO_PREVIEW": "0",
            "MSIGN_DEMO_CARDS": "2", "MSIGN_DEMO_FILES": "fixture", "MSIGN_DEMO_TAB": tab,
            "MSIGN_DEMO_SCENARIO": fixture, "MSIGN_UI_TEST_SCENARIO": scenario,
            "MSIGN_DEMO_PREFERENCES_SUITE": "md.esemnbun.qa.workflows.\(UUID().uuidString)"]
        app.launchArguments = ["-appLanguage", "en", "-AppleLanguages", "(en)", "-bridgeEnabled", "NO", "-mainSection", tab]
        #if os(macOS)
        app.launchArguments.append("--show-main-window")
        #endif
        app.launch()
        return app
    }
}
