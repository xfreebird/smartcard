import CAdwaita
import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome

/// "Documents": the saved library, the history filter, details and the destructive actions.
final class ActivityPageTests: GnomeTestCase {
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
        if let main { GTKTest.dismissDialogs(main.window); GTKTest.close(main.window) }
        while let chooser = GTKTest.fileChooser() { gtk_window_destroy(chooser.cast()); GTKTest.pump() }
        main = nil
        harness = nil
        L10n.language = nil
    }

    private func page(activity: [ActivityItem], documents: [ActivityItem]) -> (ControllerHarness, ActivityPage) {
        let h = ControllerHarness(cards: 1, activity: activity, documents: documents)
        let window = MainWindow(app: GTKTest.application, controller: h.controller)
        window.present()
        window.show(page: "activity")
        GTKTest.pump(0.2)
        harness = h; main = window
        return (h, window.activityPage)
    }

    private func items() throws -> (signed: ActivityItem, xml: ActivityItem, encrypted: ActivityItem, decrypted: ActivityItem, history: [ActivityItem]) {
        let signed = ActivityItem(kind: .signed, title: "contract-semnat.pdf", subtitle: "Signed · PAdES-T", ok: true,
                                  filePath: try Fixtures.pdf(in: folder, name: "contract-semnat.pdf").path)
        let xml = ActivityItem(kind: .signed, title: "note-semnat.xml", subtitle: "Signed · XAdES-T", ok: true,
                               filePath: try Fixtures.file(in: folder, name: "note-semnat.xml", contents: "<xml/>").path)
        let encrypted = ActivityItem(kind: .encrypted, title: "a.p7m", subtitle: "", ok: true,
                                     filePath: try Fixtures.file(in: folder, name: "a.pdf.symmetric.p7m").path)
        let decrypted = ActivityItem(kind: .decrypted, title: "decrypted-a.pdf", subtitle: "", ok: true,
                                     filePath: try Fixtures.pdf(in: folder, name: "decrypted-a.pdf").path)
        let history = [
            signed, encrypted,
            ActivityItem(kind: .bridge, title: "msign.gov.md", subtitle: "Signed · XAdES-T", ok: true, date: Date().addingTimeInterval(-900)),
            ActivityItem(kind: .bridge, title: "example.org", subtitle: "Failed", ok: false, date: Date().addingTimeInterval(-90_000)),
            ActivityItem(kind: .failed, title: "broken.pdf", subtitle: "Card error", ok: false),
            ActivityItem(kind: .verified, title: "other.pdf", subtitle: "Invalid", ok: false, filePath: signed.filePath),
            ActivityItem(kind: .verified, title: "ok.pdf", subtitle: "Valid", ok: true),
            ActivityItem(kind: .signed, title: "gone-semnat.pdf", subtitle: "", ok: true, filePath: folder.appendingPathComponent("gone.pdf").path),
        ]
        return (signed, xml, encrypted, decrypted, history)
    }

    func testLibraryAndHistoryListOnlyExistingFiles() throws {
        let fixture = try items()
        let (h, page) = page(activity: fixture.history, documents: [fixture.signed, fixture.xml, fixture.encrypted, fixture.decrypted])
        XCTAssertTrue(GTKTest.contains(page.root, text: "contract-semnat.pdf"))
        XCTAssertTrue(GTKTest.contains(page.root, text: "XML"))
        XCTAssertTrue(GTKTest.contains(page.root, text: L10n.text(.protect_encrypted)))
        XCTAssertFalse(GTKTest.contains(page.root, text: "msign.gov.md"), "Browser requests are history, not documents")
        GTKTest.click(GTKTest.button(page.root, labelled: L10n.text(.saved_history)))
        XCTAssertTrue(GTKTest.contains(page.root, text: "msign.gov.md"))
        XCTAssertTrue(GTKTest.contains(page.root, text: "broken.pdf"))
        XCTAssertFalse(GTKTest.contains(page.root, text: "gone-semnat.pdf"), "Deleted files disappear")
        // Clear history asks first.
        GTKTest.click(GTKTest.buttons(page.root, tooltip: L10n.text(.ui_clear_the_list)).first)
        GTKTest.respond(GTKTest.visibleDialog(main!.window), "cancel")
        XCTAssertFalse(h.controller.activity.isEmpty)
        GTKTest.click(GTKTest.buttons(page.root, tooltip: L10n.text(.ui_clear_the_list)).first)
        GTKTest.respond(GTKTest.visibleDialog(main!.window), "clear")
        XCTAssertTrue(h.controller.activity.isEmpty)
        XCTAssertTrue(GTKTest.contains(page.root, text: L10n.text(.ui_no_activity_yet)))
        GTKTest.click(GTKTest.button(page.root, labelled: L10n.text(.saved_files)))
        XCTAssertFalse(h.controller.signedDocuments.isEmpty, "Clearing history keeps the library")
        // Delete all saved documents (confirmed).
        GTKTest.click(GTKTest.buttons(page.root, tooltip: L10n.text(.saved_delete_all)).first)
        GTKTest.respond(GTKTest.visibleDialog(main!.window), "delete")
        XCTAssertTrue(h.controller.signedDocuments.isEmpty)
        XCTAssertTrue(GTKTest.contains(page.root, text: L10n.text(.saved_empty)))
        GTKTest.emit(page.root, "map")
    }

    func testDetailsVerifyASavedSignatureAndOfferOriginalsForXML() throws {
        let fixture = try items()
        let (h, page) = page(activity: [], documents: [fixture.signed, fixture.xml])
        var missing = Fixtures.report(intact: false, kind: "XAdES-T")
        missing.missingDetachedReferences = ["note.txt"]
        h.verifier.reports = ["contract-semnat.pdf": [Fixtures.report()], "note-semnat.xml": [missing]]
        let row = try XCTUnwrap(GTKTest.rows(page.root, titled: "contract-semnat.pdf").first)
        let list = try XCTUnwrap(gtk_widget_get_parent(row))
        GTKTest.emit(list, "row-activated", [GTKTest.object(row, type: gtk_list_box_row_get_type())])
        GTKTest.pump(0.2)
        let details = try XCTUnwrap(GTKTest.visibleDialog(main!.window)).cast(GtkWidget.self)
        XCTAssertTrue(GTKTest.pump(until: { GTKTest.contains(details, text: L10n.text(.ui_valid_signature)) }, timeout: 3))
        XCTAssertTrue(GTKTest.contains(details, text: "POPESCU ION"))
        GTKTest.dismissDialogs(main!.window)
        // The options menu of the XML entry: details, then choose the original.
        GTKTest.click(GTKTest.buttons(page.root, labelled: L10n.text(.saved_details)).last)
        GTKTest.pump(0.2)
        let xmlDetails = try XCTUnwrap(GTKTest.visibleDialog(main!.window)).cast(GtkWidget.self)
        XCTAssertTrue(GTKTest.pump(until: { GTKTest.contains(xmlDetails, text: L10n.text(.ui_cannot_be_confirmed)) }, timeout: 3))
        GTKTest.click(GTKTest.button(xmlDetails, labelled: L10n.text(.verify_choose_originals)))
        GTKTest.answerFileChooser(fixture.signed.filePath!)
        GTKTest.pump(until: { h.verifier.requests.contains { !$0.companions.isEmpty } }, timeout: 3)
        GTKTest.dismissDialogs(main!.window)
        // A file deleted after listing: the inspector says it is unavailable.
        try FileManager.default.removeItem(atPath: fixture.signed.filePath!)
        GTKTest.click(GTKTest.buttons(page.root, labelled: L10n.text(.saved_details)).first)
        GTKTest.pump(0.2)
        if let gone = GTKTest.visibleDialog(main!.window) {
            XCTAssertTrue(GTKTest.pump(until: { GTKTest.contains(gone.cast(), text: L10n.text(.saved_unavailable)) }, timeout: 3))
        }
    }

    func testProtectedOutputsOpenTheirOwnDetailsAndDeleteAsksFirst() throws {
        let fixture = try items()
        let (h, page) = page(activity: [], documents: [fixture.encrypted, fixture.decrypted])
        h.verifier.reports = ["decrypted-a.pdf": []]
        // Library mode: the filter reads "History", so "Saved documents" buttons are the entries' detail choices.
        GTKTest.click(GTKTest.buttons(page.root, labelled: L10n.text(.saved_files)).last)
        GTKTest.pump(0.2)
        if let dialog = GTKTest.visibleDialog(main!.window) {
            XCTAssertTrue(GTKTest.contains(dialog.cast(), text: L10n.text(.protect_decrypted)) || GTKTest.contains(dialog.cast(), text: L10n.text(.protect_encrypted)))
            if let verify = GTKTest.buttons(dialog.cast(), labelled: L10n.text(.ui_verify)).first {
                GTKTest.click(verify)
                XCTAssertTrue(GTKTest.pump(until: { GTKTest.contains(dialog.cast(), text: L10n.text(.ui_no_signature_found)) }, timeout: 3))
            }
            GTKTest.dismissDialogs(main!.window)
        }
        // "Delete" from an entry's menu removes only that file, after confirmation.
        GTKTest.click(GTKTest.buttons(page.root, labelled: L10n.text(.saved_delete)).first)
        GTKTest.respond(GTKTest.visibleDialog(main!.window), "delete")
        XCTAssertEqual(h.controller.signedDocuments.count, 1)
        // The protection dialog opens from the entry's menu and from the page menu actions.
        GTKTest.click(GTKTest.buttons(page.root, labelled: L10n.text(.protect_title)).first)
        GTKTest.pump(0.2)
        XCTAssertNotNil(GTKTest.visibleDialog(main!.window))
        GTKTest.dismissDialogs(main!.window)
        page.showProtection(operation: 2)
        GTKTest.pump(0.2)
        XCTAssertNotNil(GTKTest.visibleDialog(main!.window))
    }
}
