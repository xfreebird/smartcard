import XCTest

/// G10–G12, G20: presentation fixtures plus actual clear/relaunch interactions, never signing evidence.
@MainActor
final class VerificationJourneyUITests: XCTestCase {
    func testVerificationStatesClearWithoutLeavingStaleResults() {
        continueAfterFailure = false
        for (scenario, title) in [
            ("verify-valid", "Valid signature"), ("verify-invalid", "Invalid signature"),
            ("verify-untrusted", "Cannot be confirmed"), ("verify-unsigned", "Cannot be confirmed"),
            ("verify-incomplete", "Cannot be confirmed"), ("verify-multiple", "Valid signature")
        ] {
            let app = launch(scenario)
            defer { app.terminate() }
            XCTAssertTrue(app.staticTexts[title].firstMatch.waitForExistence(timeout: 15), scenario)
            let clear = app.buttons["verify.clearResults"].firstMatch
            XCTAssertTrue(clear.waitForExistence(timeout: 5), scenario)
            XCTAssertTrue(clear.isEnabled)
            clear.activateControl()
            XCTAssertTrue(app.descendants(matching: .any)["verify.dropZone"].firstMatch.exists)
            XCTAssertFalse(app.staticTexts[title].exists, "Cleared verdict must disappear: \(scenario)")
            XCTAssertFalse(app.buttons["verify.clearResults"].exists)
            XCTAssertFalse(app.secureTextFields.firstMatch.exists, "Verification must never ask for PIN")
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "cleared-\(scenario)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    func testCertificateAndTechnicalDetailsExpandAndCollapse() {
        let app = launch("verify-valid")
        defer { app.terminate() }
        for name in ["signature", "certificate", "technical"] {
            let disclosure = app.buttons["verify.disclosure." + name].firstMatch
            XCTAssertTrue(disclosure.waitForExistence(timeout: 15), name)
            #if os(iOS)
            for _ in 0..<5 where !disclosure.isHittable { app.swipeUp() }
            #else
            let viewport = app.scrollViews["verify.workspace"].firstMatch
            XCTAssertTrue(viewport.exists)
            // Existence/hittability alone includes a row clipped by the window's resize edge.
            for _ in 0..<5 where !viewport.frame.insetBy(dx: 0, dy: 12).contains(disclosure.frame) {
                viewport.scroll(byDeltaX: 0, deltaY: -160)
            }
            XCTAssertTrue(viewport.frame.insetBy(dx: 0, dy: 12).contains(disclosure.frame),
                          "\(name): row \(disclosure.frame), workspace \(viewport.frame)")
            #endif
            XCTAssertEqual(disclosure.value as? String, "Collapsed")
            disclosure.tapWhenReady()
            XCTAssertEqual(disclosure.value as? String, "Expanded")
            if name != "signature" {
                disclosure.activateControl()
                XCTAssertEqual(disclosure.value as? String, "Collapsed")
            }
        }
        XCTAssertFalse(app.secureTextFields.firstMatch.exists)
    }

    func testClearingLoadingStateRemovesPendingPresentation() {
        let app = launch("verify-loading")
        defer { app.terminate() }
        let clear = app.buttons["verify.clearResults"].firstMatch
        XCTAssertTrue(clear.waitForExistence(timeout: 15))
        clear.activateControl()
        XCTAssertFalse(clear.exists)
        XCTAssertFalse(app.progressIndicators.firstMatch.exists)
    }

    func testReaderFailuresNeverOfferCredentialEntry() {
        for (scenario, title) in [("no-reader", "Connect the reader"), ("empty-reader", "Insert the card"),
                                  ("reading", "Reading the card…"), ("unavailable", "Reader access unavailable"),
                                  ("error", "The card does not respond")] {
            let app = launch(scenario, tab: "sign")
            defer { app.terminate() }
            #if os(iOS)
            // NFC is the initial method, even when a reader fixture is present.
            app.selectSigningMethod("reader")
            #endif
            #if os(macOS)
            // Native cards expose one combined accessibility label on desktop.
            let label = scenario == "reading" ? "reading" : title
            let state = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@", label, label)).firstMatch
            XCTAssertTrue(state.waitForExistence(timeout: 15), scenario)
            #else
            XCTAssertTrue(app.staticTexts[title].firstMatch.waitForExistence(timeout: 15), scenario)
            #endif
            XCTAssertFalse(app.secureTextFields.firstMatch.exists)
        }
    }

    func testPinCancellationDismissesBothNormalAndLastAttemptPresentation() {
        for scenario in ["pin", "pin-warning"] {
            let app = launch(scenario, tab: "sign")
            defer { app.terminate() }
            XCTAssertTrue(app.secureTextFields.firstMatch.waitForExistence(timeout: 15))
            let cancel = app.buttons["Cancel"].firstMatch
            XCTAssertTrue(cancel.exists)
            cancel.activateControl()
            XCTAssertTrue(app.secureTextFields.firstMatch.waitForNonExistence(timeout: 5))
        }
    }

    private func launch(_ scenario: String, tab: String = "verify") -> XCUIApplication {
        #if os(macOS)
        let app = XCUIApplication(bundleIdentifier: "md.esemnbun.mac")
        #else
        let app = XCUIApplication(bundleIdentifier: "md.esemnbun.ios")
        #endif
        app.launchEnvironment = ["MSIGN_QA_NO_HARDWARE": "1", "MSIGN_SCREENSHOT_CAPTURE": "1", "MSIGN_DEMO_PREVIEW": "0",
            "MSIGN_DEMO_PREFERENCES_SUITE": "md.esemnbun.qa.verify.\(UUID().uuidString)",
            "MSIGN_DEMO_CARDS": "2", "MSIGN_DEMO_SCENARIO": scenario, "MSIGN_DEMO_TAB": tab]
        app.launchArguments = ["-appLanguage", "en", "-AppleLanguages", "(en)", "-bridgeEnabled", "NO", "-mainSection", tab]
        #if os(iOS)
        XCUIDevice.shared.orientation = .portrait
        #endif
        #if os(macOS)
        app.launchArguments.append("--show-main-window")
        #endif
        app.launch()
        return app
    }
}
