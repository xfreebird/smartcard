import CAdwaita
import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// MoldSignApp: startup wiring, activation, application actions, opened files and the background hold.
final class AppLifecycleTests: GnomeTestCase {
    private var harness: ControllerHarness!
    private var app: MoldSignApp!
    private let launch = LaunchFlag()

    override func setUpWithError() throws {
        try GTKTest.require()
        L10n.language = "en"
    }

    override func tearDown() {
        if let app {
            harness.controller.shutdown()
            GTKTest.pump()
            for window in windows(app) { GTKTest.dismissDialogs(window); gtk_window_destroy(window) }
            while let chooser = GTKTest.fileChooser() { gtk_window_destroy(chooser.cast()) }
            // The app's dialog hooks capture its window, which owns the controller: break the cycle.
            let controller = harness.controller
            controller.askPIN = nil; controller.askStamp = nil; controller.askConsent = nil
            controller.askAgentApproval = nil; controller.askConfirm = nil; controller.toast = nil
            controller.toastWithAction = nil; controller.reveal = nil; controller.presentWindow = nil
            controller.requestDemoMode = nil; controller.configureLoginStartup = nil
            GTKTest.pump()
        }
        app = nil
        harness = nil
        L10n.language = nil
    }

    private func start(settings: AppSettings, startHidden: Bool = false, presented: Bool = false) throws {
        harness = ControllerHarness(cards: 1, settings: settings, hooks: false, start: false)
        launch.value = presented
        let updates = UpdateChecker(stamp: TestEnvironment.directory().appendingPathComponent("stamp"), installedVersion: { "9.9.9" }) { request in
            let body = #"{"version":"1.0.0","downloadURL":"https://esemnbun.md/d"}"#
            return (Data(body.utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        }
        app = MoldSignApp(startHidden: startHidden, launchState: launch, controller: harness.controller, updates: updates, nonUnique: true)
        var error: UnsafeMutablePointer<GError>?
        XCTAssertNotEqual(g_application_register(app.app.cast(), nil, &error), 0)
        XCTAssertNil(takeError(error))
        harness.insert(1)
    }

    private func windows(_ app: MoldSignApp) -> [UnsafeMutablePointer<GtkWindow>] {
        var result: [UnsafeMutablePointer<GtkWindow>] = []
        var node = gtk_application_get_windows(app.app.cast())
        while let current = node {
            if let data = current.pointee.data { result.append(data.assumingMemoryBound(to: GtkWindow.self)) }
            node = current.pointee.next
        }
        return result
    }

    private var main: UnsafeMutablePointer<GtkWindow> { windows(app).first! }

    private func activate(_ action: String, _ parameter: OpaquePointer? = nil) {
        g_action_group_activate_action(app.app.opaque, action, parameter)
        GTKTest.pump(0.2)
    }

    private var visiblePage: String? {
        GTKTest.widgets(main.widget, ofType: adw_view_stack_get_type()).first
            .flatMap { adw_view_stack_get_visible_child_name(OpaquePointer($0)) }.map { String(cString: $0) }
    }

    func testFirstActivationPresentsTheWindowWithOnboardingAndActionsWork() throws {
        var settings = TestSettings.defaults
        settings.onboardingCompleted = false
        try start(settings: settings)
        XCTAssertEqual(harness.monitor.started, 1, "Startup starts the controller")
        g_application_activate(app.app.cast())
        GTKTest.pump(0.3)
        XCTAssertEqual(gtk_widget_get_visible(main.widget), 1)
        XCTAssertTrue(GTKTest.pump(until: { self.launch.value }), "The first presentation is recorded once mapped")
        let onboarding = try XCTUnwrap(GTKTest.visibleDialog(main))
        XCTAssertTrue(GTKTest.contains(onboarding.cast(), text: L10n.text(.onboarding_welcome_title)))
        GTKTest.respond(onboarding, "start")
        XCTAssertTrue(harness.settings.value.onboardingCompleted)
        g_application_activate(app.app.cast())
        GTKTest.pump()
        XCTAssertNil(GTKTest.visibleDialog(main), "Onboarding is shown once")

        activate("preferences")
        XCTAssertNotNil(GTKTest.visibleDialog(main))
        GTKTest.dismissDialogs(main)
        activate("about")
        XCTAssertNotNil(GTKTest.visibleDialog(main))
        GTKTest.dismissDialogs(main)
        for action in ["encrypt", "decrypt", "remove-file"] {
            activate(action)
            XCTAssertTrue(GTKTest.contains(try XCTUnwrap(GTKTest.visibleDialog(main)).cast(), text: L10n.text(.protect_title)), action)
            GTKTest.dismissDialogs(main)
        }
        activate("check-updates")
        GTKTest.pump(0.3)
        activate("page", g_variant_new_string("verify"))
        XCTAssertEqual(visiblePage, "verify")
        activate("open")
        GTKTest.answerFileChooser(nil)
        activate("page", g_variant_new_string("sign"))
        activate("open")
        GTKTest.answerFileChooser(nil)
        activate("page", g_variant_new_string("card"))
        XCTAssertNotNil(GTKTest.visibleDialog(main))
        GTKTest.dismissDialogs(main)
        activate("sign")
        XCTAssertFalse(harness.controller.isSigning, "Nothing queued: nothing to sign")
    }

    func testOpenedFilesGoToSignAndTheRealDialogsAnswerTheController() throws {
        try start(settings: TestSettings.defaults)
        let folder = TestEnvironment.directory()
        let pdf = try Fixtures.pdf(in: folder, name: "opened.pdf")
        var files: [OpaquePointer?] = [g_file_new_for_path(pdf.path)]
        files.withUnsafeMutableBufferPointer { g_application_open(app.app.cast(), $0.baseAddress, 1, "") }
        g_object_unref(files[0]?.raw)
        GTKTest.pump(0.3)
        XCTAssertEqual(harness.controller.signItems.map(\.url.lastPathComponent), ["opened.pdf"])
        XCTAssertEqual(visiblePage, "sign")
        harness.controller.signAll()
        XCTAssertTrue(GTKTest.pump(until: { GTKTest.visibleDialog(self.main) != nil }), "The PIN dialog")
        XCTAssertTrue(GTKTest.contains(GTKTest.visibleDialog(main)!.cast(), text: L10n.text(.ui_qscd_pin)))
        GTKTest.respond(GTKTest.visibleDialog(main), "cancel")
        XCTAssertTrue(GTKTest.pump(until: { !self.harness.controller.isSigning }))
        harness.vault.stored["cert0"] = "1234"
        harness.controller.signAll()
        XCTAssertTrue(GTKTest.pump(until: { GTKTest.visibleDialog(self.main) != nil }), "The stored-PIN confirmation")
        GTKTest.respond(GTKTest.visibleDialog(main), "cancel")
        // Demo mode is offered as a separate preview; the real window never shows demo-data copy.
        harness.controller.requestDemoMode?(true)
        GTKTest.pump()
        let confirm = try XCTUnwrap(GTKTest.visibleDialog(main))
        XCTAssertEqual(adw_alert_dialog_get_body(confirm.cast()).map { String(cString: $0) }, L10n.text(.linux_demo_mode_description))
        GTKTest.respond(confirm, "cancel")
        harness.controller.requestDemoMode?(false)
        harness.controller.toast?("toast")
        harness.controller.toastWithAction?("Signed", "Show") {}
        harness.controller.reveal?(pdf)
        GTKTest.pump(0.2)
        // Browser consent and the stamp editor come from the same window.
        let request = BridgeRequest(origin: "https://msign.gov.md", operation: .signPDF, documentName: "a.pdf", format: "PAdES", pinIncluded: false)
        var consent: (Bool, Bool)?
        harness.controller.askConsent?(ConsentRequest(request: request, holder: "ION", hasStoredPIN: false)) { consent = ($0, $1) }
        GTKTest.respond(GTKTest.visibleDialog(main), "deny")
        XCTAssertEqual(consent?.0, false)
        var approval: Bool?
        harness.controller.askAgentApproval?("Approve", "agent.pdf", "Sign") { approval = $0 }
        GTKTest.respond(GTKTest.visibleDialog(main), "ok")
        XCTAssertEqual(approval, true)
        var stamp: PDFStampDecision?
        let cancel = harness.controller.askStamp?(SignItem(url: pdf), "ION", nil) { stamp = $0 }
        GTKTest.pump(0.2)
        cancel?()
        guard case .cancel? = stamp else { return XCTFail("Cancelling the editor answers cancel") }
        var loginAnswer: Bool?
        harness.controller.configureLoginStartup?(false) { loginAnswer = $0 }
        XCTAssertEqual(loginAnswer, true)
    }

    func testClosingWithBackgroundWorkHidesAndActivationShowsAgain() throws {
        var settings = TestSettings.defaults
        settings.showOnCardInsertion = true
        try start(settings: settings)
        g_application_activate(app.app.cast())
        GTKTest.pump(0.3)
        gtk_window_close(main)
        GTKTest.pump()
        XCTAssertEqual(gtk_widget_get_visible(main.widget), 0, "The window hides; the app keeps running")
        g_application_activate(app.app.cast())
        GTKTest.pump()
        XCTAssertEqual(gtk_widget_get_visible(main.widget), 1)
        harness.controller.setShowOnCardInsertion(false)
        harness.controller.setRunInBackground(false)
        GTKTest.pump()
        gtk_window_close(main)
        GTKTest.pump()
        XCTAssertTrue(windows(app).isEmpty, "Without background work closing ends the window")
    }

    func testBackgroundLaunchStaysHiddenOnlyAfterTheFirstPresentation() throws {
        var settings = TestSettings.defaults
        settings.showOnCardInsertion = true
        try start(settings: settings, startHidden: true, presented: true)
        g_application_activate(app.app.cast())
        GTKTest.pump(0.3)
        XCTAssertFalse(windows(app).contains { gtk_widget_get_visible($0.widget) != 0 }, "Autostart stays in the background")
        harness.insert(2, generation: 3)
        XCTAssertTrue(GTKTest.pump(until: { self.windows(self.app).contains { gtk_widget_get_visible($0.widget) != 0 } }),
                      "A card insertion shows the window")
        activate("quit")
    }
}

private final class LaunchFlag: LaunchStateStoring {
    var value = false
    var hasPresentedMainWindow: Bool { value }
    func recordMainWindowPresentation() { value = true }
}
