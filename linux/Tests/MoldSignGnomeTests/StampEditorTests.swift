import CAdwaita
import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome

/// The visible-signature editor: Poppler preview, drag/resize, keyboard resize, scope switches and answers.
final class StampEditorTests: GnomeTestCase {
    private var parent: UnsafeMutablePointer<GtkWindow>!
    private var folder: URL!

    override func setUpWithError() throws {
        try GTKTest.require()
        L10n.language = "ro"
        parent = GTKTest.window()
        folder = TestEnvironment.directory()
    }

    override func tearDown() {
        while let editor = GTKTest.toplevel(titled: L10n.text(.stamp_title)) { gtk_window_destroy(editor); GTKTest.pump() }
        GTKTest.close(parent)
        L10n.language = nil
    }

    private func editor() throws -> Widget { try XCTUnwrap(GTKTest.toplevel(titled: L10n.text(.stamp_title))).widget }

    func testDraggingResizingAndSavingAStampForAllPages() throws {
        let pdf = try Fixtures.pdf(in: folder)
        var saved: [PDFStampPlacement?] = []
        var queued: [PDFStampPlacement?] = []
        var item = SignItem(url: pdf)
        item.stamp = PDFStampPlacement(page: 0)
        presentPDFStampEditor(parent: parent, item: item, holder: "POPESCU ION", requester: "https://msign.gov.md",
                              applyQueue: { queued.append($0) }) { saved.append($0) }
        let window = try editor()
        GTKTest.pump(0.4)   // draws the page and the stamp
        XCTAssertTrue(GTKTest.contains(window, text: "https://msign.gov.md"))
        XCTAssertTrue(GTKTest.contains(window, text: "✓  1 / 1"))
        let area = try XCTUnwrap(GTKTest.widgets(window, ofType: gtk_drawing_area_get_type()).first)
        let drag = try XCTUnwrap(GTKTest.controllers(area, ofType: gtk_gesture_drag_get_type()).first)
        // Grab the stamp body and move it; then grab a corner and resize; then click outside to recentre.
        GTKTest.emit(drag, "drag-begin", [GTKTest.double(50), GTKTest.double(250)])
        GTKTest.emit(drag, "drag-update", [GTKTest.double(10), GTKTest.double(-20)])
        GTKTest.emit(drag, "drag-begin", [GTKTest.double(14), GTKTest.double(244)])
        GTKTest.emit(drag, "drag-update", [GTKTest.double(-5), GTKTest.double(-5)])
        GTKTest.emit(drag, "drag-begin", [GTKTest.double(200), GTKTest.double(40)])
        GTKTest.emit(drag, "drag-update", [GTKTest.double(500), GTKTest.double(500)])
        XCTAssertTrue(GTKTest.key(area, 43))     // "+"
        XCTAssertTrue(GTKTest.key(area, 45))     // "-"
        XCTAssertFalse(GTKTest.key(area, 0x61))
        GTKTest.pump(0.2)
        GTKTest.setActive(GTKTest.row(window, titled: L10n.text(.stamp_all_pages)), true)
        GTKTest.setActive(GTKTest.row(window, titled: L10n.text(.stamp_queue)), true)
        GTKTest.click(GTKTest.button(window, labelled: L10n.text(.stamp_save)))
        let placement = try XCTUnwrap(saved.first ?? nil)
        XCTAssertTrue(placement.allPages)
        XCTAssertNotNil(placement.documentSHA256, "The stamp is bound to the previewed bytes")
        XCTAssertTrue((0...1).contains(placement.x) && placement.x + placement.width <= 1.000001)
        XCTAssertTrue((0...1).contains(placement.y) && placement.y + placement.height <= 1.000001)
        XCTAssertEqual(queued.count, 1)
        XCTAssertNil(GTKTest.toplevel(titled: L10n.text(.stamp_title)))
    }

    func testHidingTheStampSavesNoAppearanceAndCancelPathsAnswerOnce() throws {
        let pdf = try Fixtures.pdf(in: folder)
        var saved: [PDFStampPlacement?] = []
        var cancelled = 0
        presentPDFStampEditor(parent: parent, item: SignItem(url: pdf), holder: "ION", cancelled: { cancelled += 1 }) { saved.append($0) }
        var window = try editor()
        GTKTest.setActive(GTKTest.row(window, titled: L10n.text(.stamp_visible)), false)
        let area = try XCTUnwrap(GTKTest.widgets(window, ofType: gtk_drawing_area_get_type()).first)
        XCTAssertFalse(GTKTest.key(area, 43), "A hidden stamp cannot be resized")
        GTKTest.click(GTKTest.button(window, labelled: L10n.text(.stamp_save)))
        XCTAssertEqual(saved.count, 1)
        XCTAssertNil(saved[0])
        // Cancel button.
        presentPDFStampEditor(parent: parent, item: SignItem(url: pdf), holder: "ION", cancelled: { cancelled += 1 }) { saved.append($0) }
        window = try editor()
        GTKTest.click(GTKTest.button(window, labelled: L10n.text(.ui_cancel)))
        // Window close.
        presentPDFStampEditor(parent: parent, item: SignItem(url: pdf), holder: "ION", cancelled: { cancelled += 1 }) { saved.append($0) }
        window = try editor()
        gtk_window_close(window.cast())
        GTKTest.pump()
        // Programmatic cancellation (the browser request went away), then a second call is a no-op.
        let cancel = presentPDFStampEditor(parent: parent, item: SignItem(url: pdf), holder: "ION", cancelled: { cancelled += 1 }) { saved.append($0) }
        cancel()
        cancel()
        GTKTest.pump()
        XCTAssertEqual(cancelled, 3)
        XCTAssertEqual(saved.count, 1)
    }

    func testAnUnreadableDocumentOffersOnlyCancel() throws {
        var cancelled = 0
        presentPDFStampEditor(parent: nil, item: SignItem(url: folder.appendingPathComponent("missing.pdf")), holder: "ION",
                              cancelled: { cancelled += 1 }) { _ in XCTFail("Nothing to save") }
        let window = try editor()
        XCTAssertTrue(GTKTest.contains(window, text: L10n.text(.stamp_unavailable)))
        GTKTest.click(GTKTest.button(window, labelled: L10n.text(.ui_cancel)))
        XCTAssertEqual(cancelled, 1)
    }
}
