import CAdwaita
import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome

/// Encrypt / decrypt / remove through the protection dialog with the core's password processor.
final class FileProtectionTests: GnomeTestCase {
    private var window: UnsafeMutablePointer<GtkWindow>!
    private var harness: ControllerHarness!
    private var folder: URL!
    private var dialog: FileProtectionDialog?
    private var closed = 0

    override func setUpWithError() throws {
        try GTKTest.require()
        L10n.language = "en"
        window = GTKTest.window()
        harness = ControllerHarness(cards: 1)
        folder = TestEnvironment.directory()
    }

    override func tearDown() {
        harness?.controller.shutdown()
        GTKTest.pump()
        if let window { GTKTest.dismissDialogs(window); GTKTest.close(window) }
        while let chooser = GTKTest.fileChooser() { gtk_window_destroy(chooser.cast()); GTKTest.pump() }
        dialog = nil
        harness = nil
        L10n.language = nil
    }

    private func open(operation: Int, source: URL?) -> Widget {
        dialog = FileProtectionDialog(controller: harness.controller, parent: window, operation: operation, initialSource: source,
                                      preview: nil) { [weak self] in self?.closed += 1 }
        GTKTest.pump(0.2)
        return GTKTest.visibleDialog(window)!.cast()
    }

    private func entries(_ root: Widget) -> [Widget] { GTKTest.widgets(root, ofType: gtk_password_entry_get_type()) }

    private func check(_ root: Widget, _ text: String) -> Widget? {
        GTKTest.widgets(root, ofType: gtk_check_button_get_type()).first {
            gtk_check_button_get_label($0.cast()).map { String(cString: $0) } == text
        }
    }

    private func notice(_ root: Widget, _ key: L10n.Key, timeout: Double = 5) -> Bool {
        GTKTest.pump(until: { GTKTest.contains(root, text: L10n.text(key)) }, timeout: timeout)
    }

    func testPasswordEncryptionThenDecryptionRoundTrip() throws {
        let original = try Fixtures.file(in: folder, name: "contract.txt", contents: "Synthetic contract ăîșț")
        var root = open(operation: 0, source: original)
        XCTAssertTrue(GTKTest.contains(root, text: "contract.txt"))
        let run = { GTKTest.buttons(root, labelled: L10n.text(.protect_encrypt)).last }
        XCTAssertEqual(gtk_widget_get_sensitive(run()!), 0)
        let fields = entries(root)
        GTKTest.setText(fields[0], "test-only-password")
        GTKTest.setText(fields[1], "different")
        XCTAssertTrue(GTKTest.contains(root, text: L10n.text(.protect_mismatch)))
        XCTAssertEqual(gtk_widget_get_sensitive(run()!), 0)
        GTKTest.setText(fields[1], "test-only-password")
        for size in ["AES-128", "AES-192", "AES-256"] { gtk_check_button_set_active(check(root, size)?.cast(), 1); GTKTest.pump() }
        XCTAssertNotEqual(gtk_widget_get_sensitive(run()!), 0)
        GTKTest.click(run())
        XCTAssertTrue(notice(root, .protect_ready))
        XCTAssertEqual(String(cString: gtk_editable_get_text(fields[0].opaque)), "", "Secrets are cleared once used")
        let encrypted = folder.appendingPathComponent("contract.txt" + PasswordFileProtection.suffix)
        GTKTest.click(GTKTest.button(root, labelled: L10n.text(.protect_save_file)))
        GTKTest.answerFileChooser(encrypted.path)
        XCTAssertTrue(notice(root, .protect_saved))
        XCTAssertTrue(FileManager.default.fileExists(atPath: encrypted.path))
        XCTAssertEqual(harness.controller.signedDocuments.first?.kind, .encrypted)
        GTKTest.click(GTKTest.button(root, labelled: L10n.text(.saved_close)))
        XCTAssertTrue(GTKTest.pump(until: { self.closed == 1 }))

        // Decrypt: the method is detected from the file; a wrong password is an error, the right one works.
        root = open(operation: 1, source: encrypted)
        XCTAssertTrue(GTKTest.contains(root, text: L10n.text(.protect_detect_algorithm)))
        GTKTest.pump(0.3)
        let decryptRun = { GTKTest.buttons(root, labelled: L10n.text(.protect_decrypt)).last }
        GTKTest.setText(entries(root)[0], "wrong")
        GTKTest.click(decryptRun())
        XCTAssertTrue(notice(root, .protect_error))
        GTKTest.setText(entries(root)[0], "test-only-password")
        GTKTest.click(decryptRun())
        XCTAssertTrue(notice(root, .protect_ready))
        let decrypted = folder.appendingPathComponent("decrypted-contract.txt")
        GTKTest.click(GTKTest.button(root, labelled: L10n.text(.protect_save_file)))
        GTKTest.answerFileChooser(decrypted.path)
        XCTAssertTrue(notice(root, .protect_saved))
        XCTAssertEqual(try String(contentsOf: decrypted, encoding: .utf8), "Synthetic contract ăîșț")
        XCTAssertEqual(harness.controller.signedDocuments.first?.kind, .decrypted)
    }

    func testRemovalNeedsExplicitConfirmation() throws {
        let doomed = try Fixtures.file(in: folder, name: "old.txt")
        let root = open(operation: 2, source: doomed)
        let run = GTKTest.buttons(root, labelled: L10n.text(.protect_remove)).last!
        XCTAssertNotEqual(gtk_widget_has_css_class(run, "destructive-action"), 0)
        XCTAssertEqual(gtk_widget_get_sensitive(run), 0)
        gtk_check_button_set_active(check(root, L10n.text(.protect_remove_confirm))?.cast(), 1)
        GTKTest.pump()
        XCTAssertNotEqual(gtk_widget_get_sensitive(run), 0)
        GTKTest.click(run)
        XCTAssertTrue(notice(root, .protect_removed))
        XCTAssertFalse(FileManager.default.fileExists(atPath: doomed.path))
    }

    func testCertificateModeValidatesRecipientsAndCardReadsReportErrors() throws {
        let source = try Fixtures.file(in: folder, name: "a.txt")
        var root = open(operation: 0, source: source)
        gtk_check_button_set_active(check(root, L10n.text(.protect_rsa_recipient))?.cast(), 1)
        GTKTest.pump()
        XCTAssertTrue(GTKTest.contains(root, text: L10n.text(.protect_certificate_encrypt_guide)))
        gtk_check_button_set_active(check(root, L10n.text(.protect_card_public_key))?.cast(), 1)
        GTKTest.pump()
        XCTAssertTrue(GTKTest.contains(root, text: L10n.text(.protect_card_public_key_help)))
        gtk_check_button_set_active(check(root, L10n.text(.protect_card_public_key))?.cast(), 0)
        let notACertificate = try Fixtures.file(in: folder, name: "recipient.cer", contents: "not DER")
        GTKTest.click(GTKTest.button(root, labelled: L10n.text(.protect_choose_certificate)))
        GTKTest.answerFileChooser(notACertificate.path)
        XCTAssertTrue(notice(root, .protect_error))
        // Decrypting for a card: reading it fails without a reader and is reported, never retried.
        GTKTest.click(GTKTest.buttons(root, labelled: L10n.text(.protect_decrypt)).first)
        GTKTest.click(GTKTest.button(root, labelled: L10n.text(.protect_read_card)))
        XCTAssertTrue(notice(root, .protect_error))
        GTKTest.click(GTKTest.buttons(root, labelled: L10n.text(.protect_remove)).first)
        GTKTest.click(GTKTest.buttons(root, labelled: L10n.text(.protect_encrypt)).first)
        gtk_check_button_set_active(check(root, L10n.text(.protect_password))?.cast(), 1)
        GTKTest.pump()
        XCTAssertTrue(GTKTest.contains(root, text: L10n.text(.protect_password_encrypt_guide)))
        // Choosing the file from the dialog.
        GTKTest.dismissDialogs(window)
        root = open(operation: 0, source: nil)
        GTKTest.click(GTKTest.button(root, labelled: L10n.text(.protect_choose_file)))
        GTKTest.answerFileChooser(source.path)
        XCTAssertTrue(GTKTest.pump(until: { GTKTest.contains(root, text: "a.txt") }, timeout: 3))
        // A file that is not an envelope cannot be decrypted.
        GTKTest.dismissDialogs(window)
        root = open(operation: 1, source: source)
        XCTAssertTrue(notice(root, .protect_error))
    }
}
