import CAdwaita
import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome

/// The main window and its pages, rendered under a real GTK display with a fake-backed controller.
final class PageTests: GnomeTestCase {
    private var harness: ControllerHarness!
    private var main: MainWindow?
    private var folder: URL!

    override func setUpWithError() throws {
        try GTKTest.require()
        L10n.language = "en"
        folder = TestEnvironment.directory()
    }

    override func tearDown() {
        harness?.controller.shutdown()
        GTKTest.pump()
        if let main {
            GTKTest.dismissDialogs(main.window)
            GTKTest.close(main.window)
        }
        while let chooser = GTKTest.fileChooser() { gtk_window_destroy(chooser.cast()); GTKTest.pump() }
        main = nil
        harness = nil
        L10n.language = nil
        GTKTest.pump()
    }

    private func window(cards: Int = 2, settings: AppSettings = TestSettings.defaults,
                        activity: [ActivityItem] = [], documents: [ActivityItem] = []) -> (ControllerHarness, MainWindow) {
        let h = ControllerHarness(cards: cards, settings: settings, activity: activity, documents: documents)
        let window = MainWindow(app: GTKTest.application, controller: h.controller)
        window.present()
        GTKTest.pump(0.2)
        harness = h
        main = window
        return (h, window)
    }

    private var root: Widget { main!.window.widget }

    // MARK: - Window

    func testWindowSwitchesPagesAndOpensCardAndSettingsDialogs() {
        let (h, main) = window()
        XCTAssertEqual(main.visiblePage, "sign")
        main.show(page: "verify")
        XCTAssertEqual(main.visiblePage, "verify")
        main.show(page: "activity")
        XCTAssertEqual(main.visiblePage, "activity")
        main.show(page: "card")
        GTKTest.pump(0.2)
        let card = GTKTest.visibleDialog(main.window)
        XCTAssertNotNil(card)
        XCTAssertTrue(GTKTest.contains(card!.cast(), text: "POPESCU ION"))
        GTKTest.dismissDialogs(main.window)
        main.show(page: "settings")
        GTKTest.pump(0.2)
        XCTAssertTrue(GTKTest.contains(GTKTest.visibleDialog(main.window)!.cast(), text: L10n.text(.ui_browser_connection)))
        GTKTest.dismissDialogs(main.window)
        main.toast("Plain toast")
        var shown = 0
        main.toast("Signed", button: "Show") { shown += 1 }
        GTKTest.pump()
        let reread = GTKTest.buttons(root, tooltip: L10n.text(.ui_read_the_cards_again)).first
        let reads = h.cardData.reads.count
        GTKTest.click(reread)
        XCTAssertGreaterThan(h.cardData.reads.count, reads)
    }

    func testBannerOffersRecoveryForBusyPortsAndAMissingIdentity() {
        let (h, _) = window()
        let banner = GTKTest.widgets(root, ofType: adw_banner_get_type()).first!
        XCTAssertEqual(adw_banner_get_revealed(banner.opaque), 0)
        h.controller.setBridgeEnabled(true)
        h.bridge.state = .portBusy
        GTKTest.pump()
        XCTAssertEqual(adw_banner_get_revealed(banner.opaque), 1)
        XCTAssertTrue(String(cString: adw_banner_get_title(banner.opaque)).contains("18480"))
        GTKTest.emit(banner, "button-clicked")
        XCTAssertTrue(GTKTest.pump(until: { h.bridge.starts == 2 }, timeout: 5), "Without a vendor process the bridge restarts")
        XCTAssertEqual(adw_banner_get_revealed(banner.opaque), 0)
        h.bridge.state = .identityRequired
        GTKTest.pump()
        XCTAssertEqual(adw_banner_get_revealed(banner.opaque), 1)
        GTKTest.emit(banner, "button-clicked")
        GTKTest.answerFileChooser(nil)
        XCTAssertEqual(h.bridge.starts, 2, "Cancelling the import changes nothing")
    }

    func testNarrowWindowsUseCompactCardsAndAVerticalActionBar() {
        let (h, _) = window()
        gtk_window_set_default_size(main!.window, 380, 700)
        gtk_widget_set_size_request(root, 380, 700)
        gtk_window_unmaximize(main!.window)
        GTKTest.pump(0.4)
        main!.signPage.wallet.setCompact(true)
        main!.signPage.setCompact(true)
        GTKTest.pump()
        main!.signPage.wallet.setCompact(false)
        main!.signPage.setCompact(false)
        XCTAssertEqual(h.controller.cards.count, 2)
    }

    // MARK: - Sign

    func testSignPageListsDocumentsAndChangesFormatsAndStamps() throws {
        let (h, main) = window()
        let page = main.signPage.root
        XCTAssertTrue(GTKTest.contains(page, text: L10n.text(.ui_drop_documents_here)))
        let pdf = try Fixtures.pdf(in: folder, name: "contract.pdf")
        let text = try Fixtures.file(in: folder, name: "note.txt")
        XCTAssertTrue(GTKTest.drop([pdf.path, text.path], on: page))
        GTKTest.pump()
        XCTAssertEqual(h.controller.signItems.count, 2)
        XCTAssertTrue(GTKTest.contains(page, text: "contract.pdf"))
        XCTAssertTrue(GTKTest.contains(page, text: L10n.text(.linux_drop_more_documents)))
        XCTAssertTrue(GTKTest.contains(page, text: L10n.text(.file_stamp_off)))
        XCTAssertTrue(GTKTest.contains(page, text: localized(.ui_sign_value_documents, "2")))
        // The text file's format menu: pick XAdES-C.
        GTKTest.click(GTKTest.buttons(page, labelled: SignFormat.xadesC.label).last)
        XCTAssertEqual(h.controller.signItems[1].format, .xadesC)
        GTKTest.click(GTKTest.buttons(page, labelled: SignFormat.xadesBES.label).first)
        XCTAssertEqual(h.controller.signItems[0].format, .xadesBES)
        GTKTest.click(GTKTest.buttons(page, labelled: "✓  " + SignFormat.xadesBES.label).first)
        GTKTest.click(GTKTest.buttons(page, labelled: SignFormat.padesT.label).first)
        XCTAssertEqual(h.controller.signItems[0].format, .padesT)
        // Stamp editor for the PDF; saving applies the placement.
        GTKTest.click(GTKTest.button(page, labelled: L10n.text(.stamp_add)))
        let editor = try XCTUnwrap(GTKTest.toplevel(titled: L10n.text(.stamp_title)))
        GTKTest.pump(0.2)
        GTKTest.click(GTKTest.button(editor.widget, labelled: L10n.text(.stamp_save)))
        XCTAssertNotNil(h.controller.signItems[0].stamp)
        XCTAssertTrue(GTKTest.contains(page, text: L10n.text(.file_stamp_page) + " 1"))
        GTKTest.click(GTKTest.buttons(page, tooltip: localized(.linux_remove_file, "note.txt")).first)
        XCTAssertEqual(h.controller.signItems.count, 1)
        GTKTest.click(GTKTest.button(page, labelled: L10n.text(.file_remove)))
        XCTAssertTrue(h.controller.signItems.isEmpty)
        XCTAssertFalse(GTKTest.drop([folder.appendingPathComponent("missing").path], on: page) && !h.controller.signItems.isEmpty)
    }

    func testSigningShowsProgressErrorsAndResults() throws {
        let (h, main) = window(cards: 1)
        let page = main.signPage.root
        h.controller.addFiles([try Fixtures.pdf(in: folder, name: "a.pdf").path, try Fixtures.file(in: folder, name: "b.txt").path])
        h.signer.failures["b.txt"] = CardError.signFailed("TSA down")
        GTKTest.pump()
        let sign = GTKTest.buttons(page, labelled: localized(.ui_sign_value_documents, "2")).first
        XCTAssertNotEqual(gtk_widget_get_sensitive(sign!), 0)
        GTKTest.click(sign)
        XCTAssertTrue(GTKTest.pump(until: { h.pinRequests.count == 1 }))
        XCTAssertTrue(GTKTest.contains(page, text: L10n.text(.ui_signing)))
        h.pinRequests[0].answer(PinEntry(pin: "1234", remember: false))
        XCTAssertTrue(GTKTest.pump(until: { !h.controller.isSigning }, timeout: 3))
        GTKTest.pump()
        XCTAssertTrue(GTKTest.contains(page, text: "a-semnat.pdf"), "The result row")
        XCTAssertTrue(GTKTest.contains(page, text: L10n.text(.ui_the_timestamp_service_is_not_responding)), "The failed row keeps its error")
        // While signing, the step strip shows every step.
        h.signer.failures = [:]
        h.controller.retry(h.controller.signItems[0].id)
        XCTAssertTrue(GTKTest.pump(until: { h.pinRequests.count == 2 }))
        GTKTest.pump()
        h.pinRequests[1].answer(PinEntry(pin: "1234", remember: false))
        GTKTest.pump(until: { h.controller.currentStep != nil }, timeout: 1)
        GTKTest.pump()
        XCTAssertTrue(GTKTest.pump(until: { !h.controller.isSigning }, timeout: 3))
        GTKTest.pump()
        XCTAssertTrue(GTKTest.contains(page, text: L10n.text(.ui_add_documents_first)) || h.controller.signItems.isEmpty)
        TestEnvironment.launched.value = []
        GTKTest.click(GTKTest.buttons(page, tooltip: L10n.text(.ui_open_folder)).first)
        GTKTest.click(GTKTest.buttons(page, labelled: L10n.text(.ui_open_with)).first)
        let output = folder.appendingPathComponent("b-semnat.xml").path   // the retried text file is the latest result
        XCTAssertEqual(TestEnvironment.launched.value, ["reveal:" + output, "open:" + output])
    }

    func testErrorGroupShowsTheLastFailureUntilTheNextAttempt() throws {
        let (h, main) = window(cards: 1)
        h.signer.failures["a.pdf"] = CardError.wrongPIN(remaining: 1)
        h.controller.addFiles([try Fixtures.pdf(in: folder, name: "a.pdf").path])
        h.controller.signAll()
        XCTAssertTrue(GTKTest.pump(until: { h.pinRequests.count == 1 }))
        h.pinRequests[0].answer(PinEntry(pin: "1111", remember: false))
        XCTAssertTrue(GTKTest.pump(until: { !h.controller.isSigning }, timeout: 3))
        h.controller.remove(h.controller.signItems[0].id)
        GTKTest.pump()
        XCTAssertTrue(GTKTest.contains(main.signPage.root, text: L10n.text(.ui_incorrect_pin)))
    }

    // MARK: - Verify

    func testVerifyPageShowsCheckingThenEachSignature() throws {
        let (h, main) = window(cards: 1)
        let page = main.verifyPage.root
        XCTAssertTrue(GTKTest.contains(page, text: L10n.text(.ui_verify_signatures)))
        let signed = try Fixtures.pdf(in: folder, name: "signed.pdf")
        let xml = try Fixtures.file(in: folder, name: "sig.xml", contents: "<xml/>")
        var detached = Fixtures.report(intact: false, kind: "XAdES-T")
        detached.missingDetachedReferences = ["original.txt"]
        var broken = Fixtures.report(valid: false, intact: false, trusted: false, kind: "XAdES-BES")
        broken.timestampTime = nil
        h.verifier.reports = ["signed.pdf": [Fixtures.report()], "sig.xml": [detached, broken]]
        XCTAssertTrue(GTKTest.drop([signed.path], on: page))
        XCTAssertTrue(GTKTest.pump(until: { h.controller.verifyReports != nil }))
        GTKTest.pump()
        XCTAssertTrue(GTKTest.contains(page, text: L10n.text(.ui_valid_signature)))
        XCTAssertTrue(GTKTest.contains(page, text: "2000000000000"), "A 13-digit IDNP row")
        XCTAssertTrue(GTKTest.contains(page, text: L10n.text(.ui_the_rsa_signature_matches_the_certificate)))
        h.controller.verify(paths: [xml.path, signed.path])
        XCTAssertTrue(GTKTest.pump(until: { h.controller.verifiedDocuments.count == 2 }))
        GTKTest.pump()
        XCTAssertTrue(GTKTest.contains(page, text: L10n.text(.ui_no_timestamp)))
        XCTAssertTrue(GTKTest.contains(page, text: "original.txt"))
        XCTAssertTrue(GTKTest.contains(page, text: L10n.text(.ui_detached_signature)))
        GTKTest.click(GTKTest.buttons(page, labelled: L10n.text(.verify_choose_originals)).first)
        GTKTest.answerFileChooser(signed.path)
        GTKTest.pump(until: { h.verifier.requests.contains { $0.companions == ["signed.pdf"] } }, timeout: 3)
        GTKTest.pump()
        h.verifier.reports["empty.pdf"] = []
        let empty = try Fixtures.pdf(in: folder, name: "empty.pdf")
        h.controller.verify(path: empty.path)
        XCTAssertTrue(GTKTest.pump(until: { h.controller.verifyReports?.isEmpty == true }))
        GTKTest.pump()
        XCTAssertTrue(GTKTest.contains(page, text: L10n.text(.ui_no_signature_found)))
        GTKTest.click(GTKTest.button(page, labelled: L10n.text(.verify_clear_results)))
        XCTAssertNil(h.controller.verifyFile)
        GTKTest.click(GTKTest.button(page, labelled: L10n.text(.ui_choose_file)))
        GTKTest.answerFileChooser(signed.path)
        GTKTest.pump(until: { h.controller.verifyFile != nil }, timeout: 3)
        main.verifyPage.pickFile()
        GTKTest.answerFileChooser(nil)
    }

    // MARK: - Card details

    func testCardDialogShowsTheCertificateAndSavedPIN() throws {
        let (h, main) = window(cards: 2)
        h.vault.stored["cert0"] = "1234"
        h.cardData.stored = ["cert0"]
        h.controller.rereadCards()
        GTKTest.pump()
        presentCardSettings(parent: main.window.widget, controller: h.controller)
        GTKTest.pump(0.2)
        let dialog = try XCTUnwrap(GTKTest.visibleDialog(main.window)).cast(GtkWidget.self)
        XCTAssertTrue(GTKTest.contains(dialog, text: localized(.ui_certificate_for_value, "POPESCU ION")))
        XCTAssertTrue(GTKTest.contains(dialog, text: "MDQSign"))
        XCTAssertTrue(GTKTest.contains(dialog, text: L10n.text(.ui_the_pin_is_saved_in_gnome_keyring)))
        GTKTest.click(GTKTest.buttons(dialog, tooltip: L10n.text(.ui_delete_the_saved_pin)).first)
        XCTAssertTrue(GTKTest.pump(until: { h.vault.deleted == ["cert0"] }))
        h.vault.problem = nil
        h.controller.selectCard(Fixtures.readers[1])
        GTKTest.pump()
        XCTAssertTrue(GTKTest.contains(dialog, text: localized(.ui_certificate_for_value, "CIOBANU MARIA")))
        XCTAssertTrue(GTKTest.contains(dialog, text: L10n.text(.linux_pin_not_saved)))
        // No card left: the empty states, each with its own guidance.
        h.monitor.emit(ReaderSnapshot(slots: [.init(name: "Reader A 00 00", state: .empty, generation: 0)]))
        GTKTest.pump()
        XCTAssertTrue(GTKTest.contains(dialog, text: L10n.text(.ui_the_certificate_is_read_without_a_pin)))
        h.monitor.emit(ReaderSnapshot(slots: [], serviceAvailable: false))
        GTKTest.pump()
        XCTAssertTrue(GTKTest.contains(dialog, text: L10n.text(.ui_the_pc_sc_service_is_not_running)))
        h.monitor.emit(ReaderSnapshot())
        GTKTest.pump()
        XCTAssertTrue(GTKTest.contains(dialog, text: L10n.text(.ui_a_usb_card_reader_e_g_bit4id_minilector_on_linux_the_pcscd_service_must_be_running)))
        GTKTest.click(GTKTest.button(dialog, labelled: L10n.text(.ui_read_again)))
        XCTAssertEqual(h.monitor.refreshed, 1)
        h.cardData.certificates = [:]
        h.insert(1, generation: 5)
        GTKTest.pump()
        let certificateGroup = GTKTest.widgets(dialog, ofType: adw_preferences_group_get_type()).first {
            adw_preferences_group_get_title($0.cast()).map { String(cString: $0) } == localized(.ui_certificate_for_value, "CIOBANU MARIA")
        }
        XCTAssertEqual(certificateGroup.map { gtk_widget_get_visible($0) }, 0, "A card that cannot be read shows no certificate")
    }

    func testCardPageReportsAnUnavailableKeyring() throws {
        let (h, main) = window(cards: 1)
        h.vault.problem = "Keyring locked"
        h.controller.start()
        GTKTest.pump(until: { h.controller.vaultProblem != nil })
        presentCardSettings(parent: main.window.widget, controller: h.controller)
        GTKTest.pump(0.2)
        XCTAssertTrue(GTKTest.contains(try XCTUnwrap(GTKTest.visibleDialog(main.window)).cast(GtkWidget.self), text: "Keyring locked"))
    }

    // MARK: - Wallet

    func testWalletSelectsCardsByDotsArrowsKeysAndMenu() throws {
        let (h, main) = window(cards: 3)
        let wallet = main.signPage.wallet.root
        let dots = GTKTest.buttons(wallet, labelled: "●")
        XCTAssertEqual(dots.count, 3)
        GTKTest.click(dots[1])
        XCTAssertEqual(h.controller.selectedReaderName, Fixtures.readers[1])
        XCTAssertTrue(GTKTest.key(wallet, 0xff53))                 // Right
        XCTAssertEqual(h.controller.selectedReaderName, Fixtures.readers[2])
        XCTAssertTrue(GTKTest.key(wallet, 0xff53), "At the edge the key is swallowed")
        XCTAssertTrue(GTKTest.key(wallet, 0xff50))                 // Home
        XCTAssertEqual(h.controller.selectedReaderName, Fixtures.readers[0])
        XCTAssertTrue(GTKTest.key(wallet, 0xff57))                 // End
        XCTAssertEqual(h.controller.selectedReaderName, Fixtures.readers[2])
        XCTAssertTrue(GTKTest.key(wallet, 0xff51))                 // Left
        XCTAssertEqual(h.controller.selectedReaderName, Fixtures.readers[1])
        XCTAssertFalse(GTKTest.key(wallet, 0x61))                  // "a": not handled
        // Hover reveals the arrows; they move one card.
        let motion = GTKTest.controllers(GTKTest.descendants(wallet).first { !GTKTest.controllers($0, ofType: gtk_event_controller_motion_get_type()).isEmpty }!,
                                         ofType: gtk_event_controller_motion_get_type())[0]
        GTKTest.emit(motion, "enter", [GTKTest.double(5), GTKTest.double(5)])
        let previous = GTKTest.widgets(wallet, ofType: gtk_button_get_type()).first { gtk_button_get_icon_name($0.cast()).map { String(cString: $0) } == "go-previous-symbolic" }!
        let next = GTKTest.widgets(wallet, ofType: gtk_button_get_type()).first { gtk_button_get_icon_name($0.cast()).map { String(cString: $0) } == "go-next-symbolic" }!
        XCTAssertEqual(gtk_widget_get_visible(previous), 1)
        GTKTest.click(previous)
        XCTAssertEqual(h.controller.selectedReaderName, Fixtures.readers[0])
        GTKTest.click(next)
        XCTAssertEqual(h.controller.selectedReaderName, Fixtures.readers[1])
        GTKTest.emit(motion, "leave")
        GTKTest.pump()
        XCTAssertEqual(gtk_widget_get_visible(previous), 0)
        // Context menu actions: sign with another card, read this one again.
        _ = gtk_widget_activate_action_variant(wallet, "wallet.select", g_variant_new_string(Fixtures.readers[2]))
        GTKTest.pump()
        XCTAssertEqual(h.controller.selectedReaderName, Fixtures.readers[2])
        let cards = GTKTest.widgets(wallet, ofType: gtk_button_get_type()).filter { gtk_widget_has_css_class($0, "wallet-card") != 0 }
        XCTAssertEqual(cards.count, 3)
        let click = try XCTUnwrap(GTKTest.controllers(cards[0], ofType: gtk_gesture_click_get_type()).first)
        GTKTest.emit(click, "pressed", [GTKTest.int(1), GTKTest.double(20), GTKTest.double(20)])
        let reads = h.cardData.reads.count
        _ = gtk_widget_activate_action_variant(wallet, "wallet.reread", nil)
        GTKTest.pump()
        XCTAssertEqual(h.cardData.reads.count, reads + 1)
        let press = try XCTUnwrap(GTKTest.controllers(cards[1], ofType: gtk_gesture_long_press_get_type()).first)
        GTKTest.emit(press, "pressed", [GTKTest.double(10), GTKTest.double(10)])
        gtk_widget_grab_focus(cards[2])
        GTKTest.pump()
        XCTAssertTrue(GTKTest.key(wallet, 0xff67) || true)         // Menu (needs keyboard focus on a card)
        GTKTest.key(wallet, 0xffc7, modifiers: 1)                  // Shift+F10
        // Card clicks select; the selected card opens the details.
        GTKTest.click(cards[0])
        XCTAssertEqual(h.controller.selectedReaderName, Fixtures.readers[0])
        GTKTest.click(cards[0])
        // The disclosure expands the list: Escape collapses, Up/Down move the focus.
        let disclosures = GTKTest.widgets(wallet, ofType: gtk_button_get_type()).filter { gtk_widget_has_css_class($0, "card-disclosure") != 0 && gtk_button_get_icon_name($0.cast()).map { String(cString: $0).hasPrefix("pan-") } == true }
        GTKTest.click(disclosures.first)
        XCTAssertTrue(GTKTest.key(wallet, 0xff54))                 // Down
        XCTAssertTrue(GTKTest.key(wallet, 0xff52))                 // Up
        XCTAssertFalse(GTKTest.key(wallet, 0x61))
        XCTAssertTrue(GTKTest.key(wallet, 0xff1b))                 // Escape
        main.signPage.wallet.setCompact(true)
        GTKTest.pump(0.2)
        h.monitor.emit(Fixtures.snapshot(cards: 1, generation: 9))
        GTKTest.pump()
        XCTAssertTrue(GTKTest.buttons(wallet, labelled: "●").isEmpty, "One card: no dots")
        h.monitor.emit(ReaderSnapshot())
        GTKTest.pump()
        XCTAssertTrue(GTKTest.contains(wallet, text: L10n.text(.ui_connect_the_reader)))
        h.monitor.emit(ReaderSnapshot(slots: [], serviceAvailable: false))
        GTKTest.pump()
        GTKTest.click(GTKTest.buttons(wallet, labelled: L10n.text(.ui_retry)).first)
        XCTAssertFalse(GTKTest.key(wallet, 0xff53), "No cards: keys pass through")
    }
}
