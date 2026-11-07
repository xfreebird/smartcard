import XCTest
import UIKit
import Darwin

/// Presentation review only: all identities/results are gated Debug fixtures, never cryptographic evidence.
@MainActor
final class ScreenshotReviewUITests: XCTestCase {
    struct Scenario {
        let name: String
        let tab: String
        var fixture: String = "ready"
        var files = false
        var action: String = ""
    }
    private var cases: [Scenario] {
        [Scenario(name: "sign-empty", tab: "sign", fixture: "no-reader"),
         Scenario(name: "sign-ready", tab: "sign", files: true),
         Scenario(name: "sign-multiple-cards", tab: "sign", fixture: "multiple", files: true),
         Scenario(name: "sign-empty-reader", tab: "sign", fixture: "empty-reader", files: true),
         Scenario(name: "sign-unavailable", tab: "sign", fixture: "unavailable", files: true),
         Scenario(name: "sign-reading", tab: "sign", fixture: "reading", files: true),
         Scenario(name: "sign-card-error", tab: "sign", fixture: "error", files: true),
         Scenario(name: "sign-file-error", tab: "sign", fixture: "sign-failure", files: true),
         Scenario(name: "sign-progress", tab: "sign", fixture: "signing", files: true),
         Scenario(name: "sign-success", tab: "sign", fixture: "success", files: true),
         Scenario(name: "pin", tab: "sign", fixture: "pin", files: true),
         Scenario(name: "pin-warning", tab: "sign", fixture: "pin-warning", files: true),
         Scenario(name: "pin-empty", tab: "sign", fixture: "pin-empty"),
         Scenario(name: "consent", tab: "sign", fixture: "consent"),
         Scenario(name: "consent-batch", tab: "sign", fixture: "consent-batch"),
         Scenario(name: "verify-loading", tab: "verify", fixture: "verify-loading"),
         Scenario(name: "verify-empty", tab: "verify", fixture: "verify-empty"),
         Scenario(name: "verify-valid", tab: "verify", fixture: "verify-valid"),
         Scenario(name: "verify-invalid", tab: "verify", fixture: "verify-invalid"),
         Scenario(name: "verify-incomplete", tab: "verify", fixture: "verify-incomplete"),
         Scenario(name: "verify-untrusted", tab: "verify", fixture: "verify-untrusted"),
         Scenario(name: "verify-unsigned", tab: "verify", fixture: "verify-unsigned"),
         Scenario(name: "verify-multiple", tab: "verify", fixture: "verify-multiple"),
         Scenario(name: "verify-signature-expanded", tab: "verify", fixture: "verify-valid", action: "expand"),
         Scenario(name: "verify-certificate-expanded", tab: "verify", fixture: "verify-valid", action: "certificate"),
         Scenario(name: "verify-technical-expanded", tab: "verify", fixture: "verify-valid", action: "technical"),
         Scenario(name: "sign-stamp-editor", tab: "sign", files: true, action: "stamp"),
         Scenario(name: "documents-empty", tab: "documents", fixture: "documents-empty"),
         Scenario(name: "documents-populated", tab: "documents", fixture: "documents-populated"),
         Scenario(name: "documents-details-valid", tab: "documents", fixture: "documents-details-valid"),
         Scenario(name: "documents-details-invalid", tab: "documents", fixture: "documents-details-invalid"),
         Scenario(name: "documents-details-incomplete", tab: "documents", fixture: "documents-details-incomplete"),
         Scenario(name: "documents-details-untrusted", tab: "documents", fixture: "documents-details-untrusted"),
         Scenario(name: "documents-details-unsigned", tab: "documents", fixture: "documents-details-unsigned"),
         Scenario(name: "documents-details-unavailable", tab: "documents", fixture: "documents-details-unavailable"),
         Scenario(name: "history-empty", tab: "documents", fixture: "history-empty"),
         Scenario(name: "history-populated", tab: "documents", fixture: "history-populated"),
         Scenario(name: "card-ready", tab: "card"),
         Scenario(name: "card-multiple", tab: "card", fixture: "multiple"),
         Scenario(name: "browser-empty", tab: "browser"),
         Scenario(name: "settings", tab: "card", action: "settings"),
         Scenario(name: "about", tab: "card", action: "about"),
         Scenario(name: "documents-preview", tab: "documents", fixture: "documents-details-valid", action: "preview")]
    }

    func testPilot() throws {
        try capture(cases.filter { ["sign-ready", "documents-details-valid", "pin"].contains($0.name) })
    }

    func testAllStates() throws {
        if ProcessInfo.processInfo.environment["MSIGN_CAPTURE_SUPPLEMENT"] == "fixes" {
            try capture(cases.filter { ["sign-ready", "verify-valid", "card-ready", "documents-preview", "pin"].contains($0.name) })
        } else if ProcessInfo.processInfo.environment["MSIGN_CAPTURE_SUPPLEMENT"] == "pin" {
            try testKeyboardPIN()
        } else if ProcessInfo.processInfo.environment["MSIGN_CAPTURE_SUPPLEMENT"] == "1" {
            let name = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? ""
            if name.contains("Small") { try testAbout(); try testStamp() }
            if !name.contains("Tablet") { try testBrowser() }
            try testDetailSupplements()
            try testKeyboardPIN()
            try testSystemSheets()
        } else {
            try capture(cases)
        }
    }
    func testStamp() throws { try capture(cases.filter { $0.action == "stamp" }) }
    func testKeyboardPIN() throws {
        let pins = cases.filter { $0.name == "pin" }
        try capture(pins, requireKeyboard: true)
        try capture(pins, requireKeyboard: true, syntheticPIN: true)
    }
    func testBrowser() throws { try capture(cases.filter { $0.tab == "browser" }) }
    func testAbout() throws { try capture(cases.filter { $0.action == "about" }) }
    func testSystemSheets() throws {
        try capture([
            Scenario(name: "documents-share", tab: "documents", fixture: "documents-details-valid", action: "share"),
            Scenario(name: "documents-original-picker", tab: "documents", fixture: "documents-details-incomplete", action: "original-picker"),
            Scenario(name: "sign-file-picker", tab: "sign", action: "file-picker")])
    }
    func testDetailSupplements() throws {
        let isTablet = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"]?.contains("Tablet") == true
        try capture(cases.filter { !isTablet && $0.tab == "verify" && $0.action.isEmpty && $0.fixture != "verify-empty" }.map {
            Scenario(name: $0.name + "-result-content", tab: $0.tab, fixture: $0.fixture, action: "result-content")
        } + [
            Scenario(name: "verify-certificate-content", tab: "verify", fixture: "verify-valid", action: "certificate-content"),
            Scenario(name: "verify-technical-content", tab: "verify", fixture: "verify-valid", action: "technical-content"),
            Scenario(name: "card-certificate-content", tab: "card", action: "card-content")])
    }

    private func capture(_ scenarios: [Scenario], requireKeyboard: Bool = false, syntheticPIN: Bool = false) throws {
        guard ProcessInfo.processInfo.environment["MSIGN_SCREENSHOT_REVIEW"] == "1" else {
            throw XCTSkip("Screenshot matrix requires explicit MSIGN_SCREENSHOT_REVIEW=1 opt-in")
        }
        continueAfterFailure = false
        let deviceName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "simulator"
        let orientations: [(String, UIDeviceOrientation)] = [("portrait", .portrait), ("landscape-left", .landscapeLeft), ("landscape-right", .landscapeRight)]
        var unsupportedDuoOrientations = Set<String>()
        for theme in ["light", "dark"] {
            for scenario in scenarios {
                XCUIDevice.shared.orientation = .portrait
                let app = XCUIApplication(bundleIdentifier: "md.esemnbun.ios")
                app.launchEnvironment = ["MSIGN_QA_NO_HARDWARE": "1", "MSIGN_SCREENSHOT_CAPTURE": "1",
                    "MSIGN_DEMO_PREFERENCES_SUITE": "md.esemnbun.qa.capture.review", "MSIGN_DEMO_CARDS": scenario.fixture == "multiple" ? "3" : "1",
                    "MSIGN_DEMO_SCENARIO": scenario.fixture, "MSIGN_DEMO_TAB": scenario.tab,
                    "MSIGN_DEMO_FILES": scenario.files ? "fixture" : ":"]
                if ["settings", "about"].contains(scenario.action) { app.launchEnvironment["MSIGN_CAPTURE_SHEET"] = "settings" }
                if scenario.action == "stamp" {
                    app.launchEnvironment["MSIGN_QA_STAMP_PREVIEW"] = "1"
                    app.launchEnvironment["MSIGN_DEMO_FILES"] = "fixture-single"
                }
                if ["expand", "certificate", "technical", "certificate-content", "technical-content"].contains(scenario.action) {
                    app.launchEnvironment["MSIGN_CAPTURE_EXPAND"] = scenario.action == "expand" ? "signature" : scenario.action.replacingOccurrences(of: "-content", with: "")
                }
                app.launchArguments = ["-appTheme", theme, "-appLanguage", "ro", "-AppleLanguages", "(ro)", "-bridgeEnabled", "NO"]
                app.launch()
                XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
                XCTAssertFalse(app.descendants(matching: .any)["demo.banner"].exists, "Capture must hide only the demo banner")
                if scenario.action == "stamp" {
                    guard app.buttons["Aplică"].waitForExistence(timeout: 10) else {
                        print("MSIGN_CAPTURE_SKIP \(deviceName)|\(scenario.name)|\(theme)|stamp-editor-unavailable")
                        app.terminate(); continue
                    }
                }
                if scenario.action == "about" {
                    _ = app.buttons["Gata"].waitForExistence(timeout: 10)
                    let about = app.buttons["Despre eSemnBun"]
                    for _ in 0..<4 where !about.exists { app.swipeUp() }
                    guard about.waitForExistence(timeout: 5) else {
                        print("MSIGN_CAPTURE_SKIP \(deviceName)|\(scenario.name)|\(theme)|about-route-unavailable")
                        app.terminate(); continue
                    }
                    about.tap()
                }
                if scenario.action == "preview" {
                    let preview = app.buttons["Previzualizare"]
                    guard preview.waitForExistence(timeout: 10) else {
                        print("MSIGN_CAPTURE_SKIP \(deviceName)|\(scenario.name)|\(theme)|preview-route-unavailable")
                        app.terminate(); continue
                    }
                    preview.tap()
                }
                if ["share", "original-picker", "file-picker"].contains(scenario.action) {
                    let control = scenario.action == "share" ? app.buttons["Partajează"].firstMatch :
                        scenario.action == "original-picker" ? app.buttons["verify.chooseOriginals"].firstMatch : app.buttons["Alege fișiere…"].firstMatch
                    guard control.waitForExistence(timeout: 8) else {
                        print("MSIGN_CAPTURE_SKIP \(deviceName)|\(scenario.name)|\(theme)|sheet-control-unavailable")
                        app.terminate(); continue
                    }
                    control.tap()
                    let presented = scenario.action == "share" ? app.buttons["Copy"].firstMatch : app.navigationBars["Browse"].firstMatch
                    _ = presented.waitForExistence(timeout: 3)
                }
                if scenario.name.hasPrefix("documents-details-") {
                    guard app.buttons["Gata"].waitForExistence(timeout: 10) else {
                        print("MSIGN_CAPTURE_SKIP \(deviceName)|\(scenario.name)|\(theme)|details-route-unavailable")
                        app.terminate(); continue
                    }
                }
                if requireKeyboard && theme == "light" && !syntheticPIN,
                   let pause = Double(ProcessInfo.processInfo.environment["MSIGN_CAPTURE_KEYBOARD_PAUSE_SECONDS"] ?? ""), pause > 0 {
                    print("MSIGN_CAPTURE_PIN_READY \(deviceName)")
                    Thread.sleep(forTimeInterval: min(pause, 30))
                }
                if requireKeyboard {
                    let field = app.secureTextFields.firstMatch
                    if field.exists, field.frame.width > 0, field.frame.height > 0 {
                        app.coordinate(withNormalizedOffset: .zero)
                            .withOffset(CGVector(dx: field.frame.midX - app.frame.minX, dy: field.frame.midY - app.frame.minY)).tap()
                    }
                }
                if requireKeyboard, !app.keyboards.firstMatch.waitForExistence(timeout: 8) {
                    print("MSIGN_CAPTURE_SKIP \(deviceName)|pin-keyboard|\(theme)|software-keyboard-unavailable")
                    app.terminate(); continue
                }
                if syntheticPIN {
                    // Fixed fictional digits for masked-slot/enabled-action layout only; never submit.
                    app.typeText("123456")
                }
                for (label, orientation) in orientations {
                    if unsupportedDuoOrientations.contains(label) {
                        print("MSIGN_CAPTURE_SKIP \(deviceName)|\(scenario.name)|\(theme)|\(label)-native-rotation-unsupported")
                        continue
                    }
                    XCUIDevice.shared.orientation = orientation
                    let landscape = orientation.isLandscape
                    let geometry = NSPredicate { _, _ in (app.frame.width > app.frame.height) == landscape }
                    let condition = XCTNSPredicateExpectation(predicate: geometry, object: app)
                    let rotated = XCTWaiter.wait(for: [condition], timeout: 5) == .completed
                    if scenario.action == "result-content" {
                        app.swipeUp()
                    }
                    if scenario.action.hasSuffix("-content") && scenario.action != "result-content" {
                        let target: XCUIElement
                        if scenario.action == "certificate-content" { target = app.staticTexts["Subject"].firstMatch }
                        else if scenario.action == "technical-content" { target = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Signature1:")).firstMatch }
                        else { target = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "SHA")).firstMatch }
                        for _ in 0..<4 where !target.isHittable { app.swipeUp() }
                    }
                    let softwareSuffix = requireKeyboard && ProcessInfo.processInfo.environment["MSIGN_CAPTURE_SOFTWARE_KEYBOARD"] == "1" ? "-software-keyboard" : ""
                    let name = "\(scenario.name)\(requireKeyboard ? (syntheticPIN ? "-filled-synthetic" : "-focused") : "")\(softwareSuffix)--\(theme)--\(label)"
                    if requireKeyboard && ProcessInfo.processInfo.environment["MSIGN_CAPTURE_NATIVE_DISPLAY"] == "1" {
                        let ack = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("screenshot-review-\(UUID().uuidString).ack")
                        print("MSIGN_NATIVE_CAPTURE_READY|\(name)|\(ack.path)|geometry=\(rotated)|\(Int(app.frame.width))x\(Int(app.frame.height))")
                        fflush(stdout)
                        let deadline = Date().addingTimeInterval(20)
                        while !FileManager.default.fileExists(atPath: ack.path) && Date() < deadline { Thread.sleep(forTimeInterval: 0.05) }
                        XCTAssertTrue(FileManager.default.fileExists(atPath: ack.path), "Native display capture acknowledgement missing")
                        try? FileManager.default.removeItem(at: ack)
                        continue
                    }
                    let screenshot = XCUIScreen.main.screenshot()
                    let size = screenshot.image.size
                    if deviceName.contains("Duo") {
                        if !rotated {
                            unsupportedDuoOrientations.insert(label)
                        }
                    }
                    let attachment = XCTAttachment(screenshot: screenshot)
                    attachment.name = name
                    attachment.lifetime = .keepAlways
                    add(attachment)
                    print("MSIGN_CAPTURE_RESULT \(deviceName)|\(name)|\(Int(size.width))x\(Int(size.height))|geometry=\(rotated)")
                }
                app.terminate()
            }
        }
    }
}
