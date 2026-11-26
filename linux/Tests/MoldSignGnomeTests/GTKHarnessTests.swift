import CAdwaita
import Foundation
import XCTest
@testable import MoldSignGnome

/// The thin C-API helper layer (Infrastructure/GTK/Gtk.swift), exercised on real widgets.
final class GTKHarnessTests: GnomeTestCase {
    override func setUpWithError() throws { try GTKTest.require() }

    func testBuildersSetTextClassesAndSignals() {
        var clicks = 0
        let b = button("Go", classes: ["pill"]) { clicks += 1 }
        let l = label("Hello", classes: ["title-1"], xalign: 0.5, wrap: true, selectable: true)
        let row = vbox(spacing: 4, classes: ["outer"], [l, b])
        XCTAssertEqual(Set(GTKTest.texts(row)), ["Hello", "Go"])
        XCTAssertNotEqual(gtk_widget_has_css_class(b, "pill"), 0)
        XCTAssertNotEqual(gtk_widget_has_css_class(row, "outer"), 0)
        XCTAssertNotEqual(gtk_label_get_selectable(l.opaque), 0)
        GTKTest.click(b)
        XCTAssertEqual(clicks, 1)
        setLabel(l, "Bye")
        XCTAssertTrue(GTKTest.contains(row, text: "Bye"))
        setClass(b, "pill", false)
        XCTAssertEqual(gtk_widget_has_css_class(b, "pill"), 0)
        setVisible(b, false)
        XCTAssertEqual(gtk_widget_get_visible(b), 0)
        setSensitive(b, false)
        XCTAssertEqual(gtk_widget_get_sensitive(b), 0)
        clearBox(row)
        XCTAssertTrue(GTKTest.descendants(row).isEmpty)
        margins(row, 7)
        XCTAssertEqual(gtk_widget_get_margin_start(row), 7)
    }

    func testRowsEscapeMarkupAndListsClear() {
        var tapped = 0
        let suffix = iconButton("edit-delete-symbolic", tooltip: "Delete") { tapped += 1 }
        let row = actionRow(title: "R&D <draft>.pdf", subtitle: "A & B", icon: "x-office-document-symbolic",
                            iconClasses: ["accent"], suffix: [suffix], subtitleSelectable: true)
        XCTAssertEqual(adw_preferences_row_get_title(row.cast()).map { String(cString: $0) }, "R&amp;D &lt;draft&gt;.pdf")
        XCTAssertEqual(escapeMarkup("<b>"), "&lt;b&gt;")
        GTKTest.click(GTKTest.buttons(row, tooltip: "Delete").first)
        XCTAssertEqual(tapped, 1)
        let list = boxedList()
        gtk_list_box_append(list.opaque, row)
        XCTAssertFalse(GTKTest.descendants(list).isEmpty)
        clearList(list)
        XCTAssertTrue(GTKTest.descendants(list).isEmpty)
        let group = preferencesGroup(title: "Group & co", description: "About <this>")
        groupAdd(group, list)
        XCTAssertTrue(GTKTest.contains(group, text: "Group & co"))
        XCTAssertNotNil(image("dialog-warning-symbolic", size: 32, classes: ["warning"]))
    }

    func testDisclosureTitleFollowsExpansionAndStatusHeaderHidesEmptyBody() {
        L10n.language = "en"
        defer { L10n.language = nil }
        let disclosure = technicalDetailsDisclosure()
        XCTAssertEqual(adw_preferences_row_get_title(disclosure.cast()).map { String(cString: $0) }, L10n.text(.tech_details_show))
        adw_expander_row_set_expanded(disclosure.cast(), 1)
        GTKTest.pump()
        XCTAssertEqual(adw_preferences_row_get_title(disclosure.cast()).map { String(cString: $0) }, L10n.text(.tech_details_hide))
        let header = StatusHeader(icon: "security-high-symbolic", size: 64)
        header.set(icon: "dialog-error-symbolic", title: "Invalid", body: "")
        XCTAssertEqual(gtk_widget_get_visible(header.body), 0)
        header.set(title: "Valid", body: "Checked")
        XCTAssertEqual(gtk_widget_get_visible(header.body), 1)
        XCTAssertTrue(GTKTest.contains(header.root, text: "Checked"))
    }

    func testMainLoopHelpersRunOnTheGTKThread() {
        var order: [String] = []
        onMain { order.append("idle") }
        after(milliseconds: 10) { order.append("timer") }
        var ticks = 0
        every(seconds: 1) { ticks += 1; return ticks < 2 }
        XCTAssertTrue(GTKTest.pump(until: { order.count == 2 }))
        XCTAssertEqual(order, ["idle", "timer"])
        XCTAssertTrue(GTKTest.pump(until: { ticks == 2 }, timeout: 4))
    }

    func testPropertiesAccessibilityAndScrolledPage() {
        let entry = gtk_entry_new()!
        setProperty(entry, "placeholder-text", string: "PIN")
        XCTAssertEqual(gtk_entry_get_placeholder_text(entry.cast()).map { String(cString: $0) }, "PIN")
        setProperty(entry, "activates-default", bool: true)
        XCTAssertNotEqual(gtk_entry_get_activates_default(entry.cast()), 0)
        setAccessibleLabel(entry, "Card PIN")
        setAccessibleState(entry, GTK_ACCESSIBLE_STATE_EXPANDED, true)
        setAccessibleState(entry, GTK_ACCESSIBLE_STATE_DISABLED, false)
        let page = scrolledPage(label("Body"), maxWidth: 500, top: label("Top"))
        XCTAssertTrue(GTKTest.contains(page, text: "Top"))
        XCTAssertTrue(GTKTest.contains(page, text: "Body"))
        let joined = withCStringArray(["a", "b"]) { strings in [String(cString: strings[0]!), String(cString: strings[1]!)] }
        XCTAssertEqual(joined, ["a", "b"])
        XCTAssertNil(takeString(nil))
        XCTAssertNil(takeError(nil))
        XCTAssertFalse(userDataDir.isEmpty)
        XCTAssertTrue(userConfigDir.hasPrefix(TestEnvironment.root.path))
        XCTAssertFalse(documentsDir.isEmpty)
        let window = GTKTest.window()
        defer { GTKTest.close(window) }
        adw_application_window_set_content(window.cast(), entry)
        announce(entry, "Changed")
        installCSS(".test-only { color: red; }")
        var frames = 0
        onFrame(entry) { frames += 1 }
        XCTAssertTrue(GTKTest.pump(until: { frames > 0 }))
    }
}
