import CAdwaita
import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome

/// PIN, consent, confirmation, onboarding and preferences dialogs, answered through their real responses.
final class DialogTests: GnomeTestCase {
    private var window: UnsafeMutablePointer<GtkWindow>!
    private var harness: ControllerHarness?

    override func setUpWithError() throws {
        try GTKTest.require()
        L10n.language = "en"
        window = GTKTest.window()
    }

    override func tearDown() {
        harness?.controller.shutdown()
        GTKTest.pump()
        if let window { GTKTest.dismissDialogs(window); GTKTest.close(window) }
        harness = nil
        L10n.language = nil
    }

    private var dialog: UnsafeMutablePointer<AdwDialog>? {
        GTKTest.pump(until: { GTKTest.visibleDialog(self.window) != nil }, timeout: 2)
        return GTKTest.visibleDialog(window)
    }

    private func passwordEntry(_ dialog: UnsafeMutablePointer<AdwDialog>) -> Widget {
        GTKTest.widgets(dialog.cast(), ofType: gtk_password_entry_get_type()).first!
    }

    // MARK: - PIN

    func testPINDialogAcceptsOnlyFourToEightDigitsAndRemembers() throws {
        var entries: [PinEntry?] = []
        presentPINDialog(parent: window.widget, request: PinRequest(holder: "ION", purpose: "contract.pdf → PAdES-T", attemptsLeft: 2,
                                                                     canRemember: true, vaultProblem: nil)) { entries.append($0) }
        let pin = try XCTUnwrap(dialog)
        XCTAssertTrue(GTKTest.contains(pin.cast(), text: localized(.ui_attempts_remaining_value, "2")))
        XCTAssertEqual(adw_alert_dialog_get_response_enabled(pin.cast(), "sign"), 0)
        let entry = passwordEntry(pin)
        GTKTest.setText(entry, "12a3-45678901")
        XCTAssertEqual(String(cString: gtk_editable_get_text(entry.opaque)), "12345678")
        XCTAssertEqual(adw_alert_dialog_get_response_enabled(pin.cast(), "sign"), 1)
        GTKTest.setText(entry, "12")
        XCTAssertEqual(adw_alert_dialog_get_response_enabled(pin.cast(), "sign"), 0)
        GTKTest.setText(entry, "1234")
        let remember = GTKTest.row(pin.cast(), titled: L10n.text(.ui_remember_pin))
        GTKTest.setActive(remember, true)
        GTKTest.respond(pin, "sign")
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0]?.pin, "1234")
        XCTAssertEqual(entries[0]?.remember, true)
        XCTAssertEqual(String(cString: gtk_editable_get_text(entry.opaque)), "", "The PIN is cleared from the field")
    }

    func testPINDialogCancelAndKeyringProblem() throws {
        var entries: [PinEntry?] = []
        presentPINDialog(parent: window.widget, request: PinRequest(holder: "ION", purpose: "x", attemptsLeft: 3,
                                                                     canRemember: false, vaultProblem: "Keyring locked")) { entries.append($0) }
        let pin = try XCTUnwrap(dialog)
        XCTAssertTrue(GTKTest.contains(pin.cast(), text: "Keyring locked"))
        XCTAssertTrue(GTKTest.rows(pin.cast(), titled: L10n.text(.ui_remember_pin)).isEmpty)
        GTKTest.setText(passwordEntry(pin), "123456")
        GTKTest.respond(pin, "cancel")
        XCTAssertEqual(entries.count, 1)
        XCTAssertNil(entries[0])
        presentPINDialog(parent: window.widget, request: PinRequest(holder: "ION", purpose: "x", attemptsLeft: nil,
                                                                     canRemember: false, vaultProblem: nil)) { entries.append($0) }
        GTKTest.respond(dialog, "sign")
        XCTAssertNil(entries[1] ?? nil, "Sign without a valid PIN is no PIN")
    }

    // MARK: - Consent

    func testConsentDialogNamesTheOperationDocumentAndHolder() throws {
        var answers: [(Bool, Bool)] = []
        for (operation, text) in [(BridgeRequest.Operation.signPDF, L10n.text(.linux_sign_pdf_operation)),
                                  (.signFile, L10n.text(.ui_signing_files_on_this_computer)),
                                  (.signData, L10n.text(.ui_signing_data_sent_by_the_page))] {
            let request = BridgeRequest(origin: "https://msign.gov.md", operation: operation, documentName: operation == .signData ? nil : "cerere.pdf",
                                        format: operation == .signData ? nil : "XAdES-T", pinIncluded: operation == .signFile)
            presentConsentDialog(parent: window.widget, consent: ConsentRequest(request: request, holder: "POPESCU ION", hasStoredPIN: false)) {
                answers.append(($0, $1))
            }
            let consent = try XCTUnwrap(dialog)
            let body = adw_alert_dialog_get_body(consent.cast()).map { String(cString: $0) }
            XCTAssertEqual(body, text)
            XCTAssertTrue(String(cString: adw_alert_dialog_get_heading(consent.cast())).contains("msign.gov.md"))
            XCTAssertTrue(GTKTest.contains(consent.cast(), text: "POPESCU ION"))
            if operation == .signFile { XCTAssertTrue(GTKTest.contains(consent.cast(), text: L10n.text(.ui_pin_entered_on_the_page))) }
            if operation == .signData {
                XCTAssertTrue(GTKTest.contains(consent.cast(), text: L10n.text(.linux_data_to_sign)))
                GTKTest.setActive(GTKTest.row(consent.cast(), titled: L10n.text(.ui_trust_this_site_for_10_minutes)), true)
                GTKTest.respond(consent, "sign")
            } else {
                GTKTest.respond(consent, operation == .signPDF ? "deny" : "sign")
            }
        }
        XCTAssertEqual(answers.map(\.0), [false, true, true])
        XCTAssertEqual(answers.map(\.1), [false, false, true])
    }

    // MARK: - Confirmations

    func testConfirmationsReportTheChosenResponse() throws {
        var results: [Bool] = []
        presentConfirmDialog(parent: window.widget, heading: "Sign?", body: "Using the saved PIN", action: "Sign") { results.append($0) }
        GTKTest.respond(dialog, "ok")
        presentConfirmDialog(parent: window.widget, heading: "Approve?", body: "Agent", action: "Approve", defaultApprove: false) { results.append($0) }
        XCTAssertEqual(adw_alert_dialog_get_default_response(dialog!.cast()).map { String(cString: $0) }, "cancel")
        GTKTest.respond(dialog, "cancel")
        presentClearActivityDialog(parent: window.widget) { results.append($0) }
        GTKTest.respond(dialog, "clear")
        let item = ActivityItem(kind: .signed, title: "contract-semnat.pdf", subtitle: "", ok: true, filePath: "/tmp/x.pdf")
        presentDeleteSignedDocumentsDialog(parent: window.widget, items: [item]) { results.append($0) }
        XCTAssertTrue(String(cString: adw_alert_dialog_get_body(dialog!.cast())).contains("contract-semnat.pdf"))
        GTKTest.respond(dialog, "delete")
        presentDeleteSignedDocumentsDialog(parent: window.widget, items: [item, item]) { results.append($0) }
        XCTAssertEqual(String(cString: adw_alert_dialog_get_heading(dialog!.cast())), L10n.text(.saved_delete_all))
        GTKTest.respond(dialog, "cancel")
        XCTAssertEqual(results, [true, false, true, true, false])
    }

    // MARK: - Onboarding

    func testOnboardingAppliesBothChoicesLiveAndCompletesOnAnyDismissal() throws {
        let h = ControllerHarness(cards: 1)
        harness = h
        var closed = 0
        presentOnboardingDialog(parent: window.widget, controller: h.controller) { closed += 1 }
        let onboarding = try XCTUnwrap(dialog)
        GTKTest.setActive(GTKTest.row(onboarding.cast(), titled: L10n.text(.ui_start_at_sign_in)), true)
        XCTAssertEqual(h.loginRequests.map(\.enabled), [true])
        h.loginRequests[0].answer(true)
        GTKTest.pump()
        GTKTest.setActive(GTKTest.row(onboarding.cast(), titled: L10n.text(.ui_show_the_app_when_a_card_is_inserted)), true)
        XCTAssertTrue(h.settings.value.showOnCardInsertion)
        GTKTest.respond(onboarding, "start")
        XCTAssertTrue(h.settings.value.onboardingCompleted)
        XCTAssertTrue(h.settings.value.launchAtLogin)
        XCTAssertEqual(closed, 1)
    }

    // MARK: - Preferences

    func testPreferencesSwitchesDriveTheController() throws {
        let h = ControllerHarness(cards: 2)
        harness = h
        var demoRequests: [Bool] = []
        h.controller.requestDemoMode = { demoRequests.append($0) }
        presentPreferences(parent: window.widget, controller: h.controller)
        let preferences = try XCTUnwrap(dialog).cast(GtkWidget.self)
        XCTAssertTrue(GTKTest.contains(preferences, text: L10n.text(.linux_demo_mode_description)))
        XCTAssertTrue(GTKTest.contains(preferences, text: h.controller.status.title))
        func row(_ key: L10n.Key) -> Widget? { GTKTest.rows(preferences, titled: L10n.text(key)).first }
        GTKTest.setActive(row(.ui_browser_connection), true)
        XCTAssertTrue(h.controller.settings.bridgeEnabled)
        XCTAssertEqual(h.bridge.starts, 1)
        GTKTest.setActive(row(.stamp_browser), true)
        XCTAssertTrue(h.controller.settings.browserStampsEnabled)
        GTKTest.setActive(row(.legacy_client_title), true)
        XCTAssertTrue(h.controller.settings.legacyDesktopClientEnabled)
        GTKTest.setActive(row(.automation_enable), true)
        XCTAssertTrue(h.controller.settings.agentApprovalEnabled)
        GTKTest.setActive(row(.ui_run_in_the_background), false)
        XCTAssertFalse(h.controller.settings.runInBackground)
        GTKTest.setActive(row(.ui_start_at_sign_in), true)
        XCTAssertEqual(h.loginRequests.count, 1)
        h.loginRequests[0].answer(false)
        GTKTest.setActive(row(.ui_show_the_app_when_a_card_is_inserted), true)
        XCTAssertTrue(h.controller.settings.showOnCardInsertion)
        GTKTest.setActive(row(.linux_demo_mode), true)
        XCTAssertEqual(demoRequests, [true])
        XCTAssertEqual(adw_switch_row_get_active(row(.linux_demo_mode)!.opaque), 0, "The real app never switches into demo in place")
        // Restart is offered while the bridge is not running.
        h.bridge.stateOnStart = .portBusy
        h.controller.restartBridge()
        GTKTest.pump()
        GTKTest.click(GTKTest.button(preferences, labelled: L10n.text(.ui_restart)))
        XCTAssertEqual(h.bridge.starts, 4)
        // Theme and language combo rows.
        let combos = GTKTest.widgets(preferences, ofType: adw_combo_row_get_type())
        XCTAssertEqual(combos.count, 2)
        adw_combo_row_set_selected(combos[0].cast(), 2)
        GTKTest.pump()
        XCTAssertEqual(h.controller.settings.theme, "dark")
        adw_combo_row_set_selected(combos[0].cast(), 0)
        adw_combo_row_set_selected(combos[1].cast(), 2)
        GTKTest.pump()
        XCTAssertEqual(h.controller.settings.language, "en")
        adw_combo_row_set_selected(combos[1].cast(), 0)
        GTKTest.pump()
        L10n.language = "en"
        // The import button opens a PKCS#12 chooser; cancelling it keeps the identity.
        GTKTest.click(GTKTest.button(preferences, labelled: L10n.text(.ui_import)))
        GTKTest.answerFileChooser(nil)
        // Turning everything off again.
        for key: L10n.Key in [.ui_browser_connection, .stamp_browser, .legacy_client_title, .automation_enable] {
            GTKTest.setActive(row(key), false)
        }
        XCTAssertFalse(h.controller.settings.bridgeEnabled)
        XCTAssertFalse(h.controller.settings.agentApprovalEnabled)
    }

    func testPreferencesOpenCardsSavedPINsAndAbout() throws {
        let h = ControllerHarness(cards: 2)
        harness = h
        h.vault.stored = ["cert0": "1234"]
        h.cardData.stored = ["cert0"]
        h.controller.rereadCards()
        GTKTest.pump()
        presentPreferences(parent: window.widget, controller: h.controller)
        let preferences = try XCTUnwrap(dialog).cast(GtkWidget.self)
        GTKTest.activateRow(GTKTest.row(preferences, titled: L10n.text(.ui_saved_pins)))
        GTKTest.pump(0.2)
        let saved = try XCTUnwrap(GTKTest.visibleDialog(window)).cast(GtkWidget.self)
        XCTAssertTrue(GTKTest.contains(saved, text: "POPESCU ION"))
        XCTAssertTrue(GTKTest.contains(saved, text: "CIOBANU MARIA"))
        XCTAssertTrue(GTKTest.contains(saved, text: L10n.text(.ui_the_pin_is_saved_in_gnome_keyring)))
        let trash = GTKTest.buttons(saved, tooltip: L10n.text(.ui_delete_the_saved_pin))
        XCTAssertEqual(trash.count, 2)
        XCTAssertEqual(gtk_widget_get_sensitive(trash[1]), 0, "No saved PIN: nothing to delete")
        GTKTest.click(trash[0])
        XCTAssertTrue(GTKTest.pump(until: { h.vault.deleted == ["cert0"] }))
        var confirmed: ((Bool) -> Void)?
        h.controller.askConfirm = { _, _, _, answer in confirmed = answer }
        GTKTest.click(GTKTest.buttons(saved, tooltip: L10n.text(.ui_delete_all_pins)).first)
        confirmed?(true)
        XCTAssertTrue(GTKTest.pump(until: { h.vault.deletedAll == 1 }))
        h.monitor.emit(ReaderSnapshot())
        GTKTest.pump()
        XCTAssertTrue(GTKTest.contains(saved, text: L10n.text(.ui_no_card_connected)))
        GTKTest.dismissDialogs(window)
        presentPreferences(parent: window.widget, controller: h.controller)
        let again = try XCTUnwrap(dialog).cast(GtkWidget.self)
        GTKTest.activateRow(GTKTest.row(again, titled: L10n.text(.settings_card_reader)))
        GTKTest.pump(0.2)
        XCTAssertNotNil(GTKTest.visibleDialog(window))
        GTKTest.dismissDialogs(window)
        presentPreferences(parent: window.widget, controller: h.controller)
        GTKTest.activateRow(GTKTest.row(try XCTUnwrap(dialog).cast(), titled: L10n.text(.ui_about_esemnbun)))
        GTKTest.pump(0.2)
        let about = try XCTUnwrap(GTKTest.visibleDialog(window))
        XCTAssertTrue(GTKTest.isA(about, adw_about_dialog_get_type()))
        XCTAssertEqual(String(cString: adw_about_dialog_get_application_name(about.opaque)), "eSemnBun")
        GTKTest.dismissDialogs(window)
        L10n.language = "en"
        presentAbout(parent: window.widget)
        GTKTest.pump(0.2)
        XCTAssertTrue(GTKTest.texts(try XCTUnwrap(GTKTest.visibleDialog(window)).cast()).contains("Terms & Conditions"),
                      "Link titles are escaped markup, so an ampersand still renders")
        for language in ["ro", "ru", "de"] {
            L10n.language = language
            presentAbout(parent: window.widget)
            GTKTest.pump()
        }
    }
}
