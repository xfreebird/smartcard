import CAdwaita
import Foundation
import XCTest
@testable import MoldSignGnome

extension UnsafeMutableRawPointer: GPointer {
    public var raw: UnsafeMutableRawPointer { self }
}

/// Process-wide GTK harness for widget tests. Widgets need a display: CI runs these tests under `xvfb-run`.
/// Without one they skip, unless `MSIGN_REQUIRE_DISPLAY=1` (the coverage job) turns a missing display into a failure.
enum GTKTest {
    static let available: Bool = {
        TestEnvironment.isolate()
        // No accessibility bus, portal or dconf in a test process: keep GTK and libadwaita local.
        setenv("GTK_A11Y", "none", 0)
        setenv("NO_AT_BRIDGE", "1", 0)
        setenv("GSETTINGS_BACKEND", "memory", 0)
        setenv("ADW_DISABLE_PORTAL", "1", 0)
        setenv("GTK_USE_PORTAL", "0", 0)
        guard gtk_init_check() != 0 else { return false }
        adw_init()
        return true
    }()

    static func require(file: StaticString = #filePath, line: UInt = #line) throws {
        guard available else {
            if ProcessInfo.processInfo.environment["MSIGN_REQUIRE_DISPLAY"] == "1" {
                XCTFail("GTK could not open a display (MSIGN_REQUIRE_DISPLAY=1)", file: file, line: line)
            }
            throw XCTSkip("GTK widget tests need a display (run under xvfb-run)")
        }
    }

    /// A registered, non-unique application, so application windows can be created without D-Bus.
    static let application: UnsafeMutablePointer<AdwApplication> = {
        let app = adw_application_new("md.moldsign.MoldSign.Tests", GApplicationFlags(rawValue: 1 << 5))!
        var error: UnsafeMutablePointer<GError>?
        _ = g_application_register(app.cast(), nil, &error)
        if let message = takeError(error) { XCTFail("Test application did not register: \(message)") }
        return app
    }()

    /// A presented application window that tests attach dialogs to; destroyed by `close`.
    static func window(width: Int32 = 900, height: Int32 = 700) -> UnsafeMutablePointer<GtkWindow> {
        let window: UnsafeMutablePointer<GtkWindow> = adw_application_window_new(application.cast())!.cast()
        gtk_window_set_default_size(window, width, height)
        gtk_window_present(window)
        pump()
        return window
    }

    static func close(_ window: UnsafeMutablePointer<GtkWindow>?) {
        guard let window else { return }
        gtk_window_destroy(window)
        pump()
    }

    // MARK: - Main loop

    /// Runs pending main-loop work (idle callbacks, timers, frames) for about `seconds`.
    static func pump(_ seconds: Double = 0.05) {
        let deadline = Date().addingTimeInterval(seconds)
        repeat {
            while g_main_context_iteration(nil, 0) != 0 {}
            usleep(2_000)
        } while Date() < deadline
    }

    /// Iterates the main loop until `condition` holds (true) or the timeout expires (false).
    @discardableResult
    static func pump(until condition: () -> Bool, timeout: Double = 5) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else { return false }
            while g_main_context_iteration(nil, 0) != 0 {}
            usleep(2_000)
        }
        return true
    }

    // MARK: - Widget tree

    static func typeName(_ instance: GPointer) -> String {
        String(cString: g_type_name_from_instance(instance.raw.assumingMemoryBound(to: GTypeInstance.self)))
    }

    static func instanceType(_ instance: GPointer) -> GType {
        instance.raw.assumingMemoryBound(to: GTypeInstance.self).pointee.g_class.pointee.g_type
    }

    static func isA(_ instance: GPointer, _ type: GType) -> Bool {
        g_type_check_instance_is_a(instance.raw.assumingMemoryBound(to: GTypeInstance.self), type) != 0
    }

    /// Depth-first descendants (not including `root`), across internal children as GTK exposes them.
    static func descendants(_ root: Widget) -> [Widget] {
        var result: [Widget] = []
        var child = gtk_widget_get_first_child(root)
        while let current = child {
            result.append(current)
            result += descendants(current)
            child = gtk_widget_get_next_sibling(current)
        }
        return result
    }

    static func widgets(_ root: Widget, ofType type: GType) -> [Widget] {
        descendants(root).filter { isA($0, type) }
    }

    /// Visible text of every GtkLabel and libadwaita row title/subtitle below `root`.
    static func texts(_ root: Widget) -> [String] {
        var values: [String] = []
        for widget in [root] + descendants(root) {
            if isA(widget, gtk_label_get_type()), let text = gtk_label_get_text(widget.opaque) {
                values.append(String(cString: text))
            }
            if isA(widget, adw_preferences_row_get_type()), let title = adw_preferences_row_get_title(widget.cast()) {
                values.append(String(cString: title))
            }
            if isA(widget, adw_action_row_get_type()), let subtitle = adw_action_row_get_subtitle(widget.cast()) {
                values.append(String(cString: subtitle))
            }
            if isA(widget, gtk_button_get_type()), let label = gtk_button_get_label(widget.cast()) {
                values.append(String(cString: label))
            }
        }
        return values
    }

    static func contains(_ root: Widget, text: String) -> Bool {
        texts(root).contains { $0.contains(text) }
    }

    /// Buttons whose label (own or of a child GtkLabel) equals `text`.
    static func buttons(_ root: Widget, labelled text: String) -> [Widget] {
        widgets(root, ofType: gtk_button_get_type()).filter { button in
            if let label = gtk_button_get_label(button.cast()), String(cString: label) == text { return true }
            return descendants(button).contains { child in
                isA(child, gtk_label_get_type()) && gtk_label_get_text(child.opaque).map { String(cString: $0) } == text
            }
        }
    }

    static func button(_ root: Widget, labelled text: String, file: StaticString = #filePath, line: UInt = #line) -> Widget? {
        let matches = buttons(root, labelled: text)
        if matches.isEmpty { XCTFail("No button labelled \(text)", file: file, line: line) }
        return matches.first
    }

    /// Buttons whose tooltip equals `text` (icon-only buttons).
    static func buttons(_ root: Widget, tooltip text: String) -> [Widget] {
        widgets(root, ofType: gtk_button_get_type()).filter {
            gtk_widget_get_tooltip_text($0).map { String(cString: $0) } == text
        }
    }

    /// Rows whose title equals `title`.
    static func rows(_ root: Widget, titled title: String) -> [Widget] {
        widgets(root, ofType: adw_preferences_row_get_type()).filter {
            adw_preferences_row_get_title($0.cast()).map { String(cString: $0) } == title
        }
    }

    static func row(_ root: Widget, titled title: String, file: StaticString = #filePath, line: UInt = #line) -> Widget? {
        let matches = rows(root, titled: title)
        if matches.isEmpty { XCTFail("No row titled \(title)", file: file, line: line) }
        return matches.first
    }

    static func toplevels() -> [Widget] {
        let model = gtk_window_get_toplevels()
        var windows: [Widget] = []
        for index in 0..<g_list_model_get_n_items(model) {
            guard let item = g_list_model_get_item(model, index) else { continue }
            windows.append(item.assumingMemoryBound(to: GtkWidget.self))
            g_object_unref(item)
        }
        return windows
    }

    static func toplevel(titled title: String) -> UnsafeMutablePointer<GtkWindow>? {
        toplevels().first { gtk_window_get_title($0.cast()).map { String(cString: $0) } == title }?.cast()
    }

    static func visibleDialog(_ window: UnsafeMutablePointer<GtkWindow>) -> UnsafeMutablePointer<AdwDialog>? {
        adw_application_window_get_visible_dialog(window.cast())
    }

    /// Closes every dialog and extra toplevel the test opened over `window`.
    static func dismissDialogs(_ window: UnsafeMutablePointer<GtkWindow>) {
        while let dialog = visibleDialog(window) {
            adw_dialog_force_close(dialog)
            pump()
        }
    }

    // MARK: - Signals

    /// `g_signal_emit_by_name` (variadic in C) through `g_signal_emitv`; `arguments` are consumed.
    @discardableResult
    static func emit(_ instance: GPointer, _ signal: String, _ arguments: [GValue] = [],
                     returning returnType: GType? = nil) -> GValue {
        let type = instanceType(instance)
        var id: guint = 0
        var detail: GQuark = 0
        guard g_signal_parse_name(signal, type, &id, &detail, 1) != 0 else {
            XCTFail("Unknown signal \(signal) on \(typeName(instance))")
            return GValue()
        }
        var values = [GValue](repeating: GValue(), count: arguments.count + 1)
        g_value_init(&values[0], type)
        g_value_set_object(&values[0], instance.raw)
        for (index, argument) in arguments.enumerated() { values[index + 1] = argument }
        var result = GValue()
        if let returnType { g_value_init(&result, returnType) }
        values.withUnsafeBufferPointer { buffer in
            if returnType == nil {
                g_signal_emitv(buffer.baseAddress, id, detail, nil)
            } else {
                withUnsafeMutablePointer(to: &result) { g_signal_emitv(buffer.baseAddress, id, detail, $0) }
            }
        }
        for index in values.indices { g_value_unset(&values[index]) }
        return result
    }

    static func click(_ button: Widget?) {
        guard let button else { return }
        emit(button, "clicked")
        pump()
    }

    /// Delivers an AdwAlertDialog response as if its button was pressed.
    static func respond(_ dialog: UnsafeMutablePointer<AdwDialog>?, _ response: String) {
        guard let dialog else { return XCTFail("No dialog to respond to") }
        adw_alert_dialog_set_response_enabled(dialog.cast(), response, 1)
        emit(dialog, "response::\(response)", [string(response)])
        adw_dialog_force_close(dialog)
        pump()
    }

    static func string(_ value: String) -> GValue {
        var v = GValue()
        g_value_init(&v, g_type_from_name("gchararray"))
        g_value_set_string(&v, value)
        return v
    }

    static func double(_ value: Double) -> GValue {
        var v = GValue()
        g_value_init(&v, g_type_from_name("gdouble"))
        g_value_set_double(&v, value)
        return v
    }

    static func uint(_ value: UInt32) -> GValue {
        var v = GValue()
        g_value_init(&v, g_type_from_name("guint"))
        g_value_set_uint(&v, value)
        return v
    }

    static func int(_ value: Int32) -> GValue {
        var v = GValue()
        g_value_init(&v, g_type_from_name("gint"))
        g_value_set_int(&v, value)
        return v
    }

    static func object(_ instance: GPointer, type: GType) -> GValue {
        var v = GValue()
        g_value_init(&v, type)
        g_value_set_object(&v, instance.raw)
        return v
    }

    static func flags(_ value: UInt32, type: GType) -> GValue {
        var v = GValue()
        g_value_init(&v, type)
        g_value_set_flags(&v, value)
        return v
    }

    /// Sends a `key-pressed` to the first key controller attached to `widget`; returns whether it was handled.
    @discardableResult
    static func key(_ widget: Widget, _ keyval: UInt32, modifiers: UInt32 = 0) -> Bool {
        guard let controller = controllers(widget, ofType: gtk_event_controller_key_get_type()).first else {
            XCTFail("No key controller on \(typeName(widget))")
            return false
        }
        var result = emit(controller, "key-pressed",
                          [uint(keyval), uint(0), flags(modifiers, type: gdk_modifier_type_get_type())],
                          returning: g_type_from_name("gboolean"))
        defer { g_value_unset(&result) }
        pump()
        return g_value_get_boolean(&result) != 0
    }

    static func controllers(_ widget: Widget, ofType type: GType) -> [OpaquePointer] {
        let model = gtk_widget_observe_controllers(widget)
        defer { g_object_unref(model?.raw) }
        var result: [OpaquePointer] = []
        for index in 0..<g_list_model_get_n_items(model) {
            guard let item = g_list_model_get_item(model, index) else { continue }
            if isA(item, type) { result.append(OpaquePointer(item)) }
            g_object_unref(item)
        }
        return result
    }

    // MARK: - Files (GtkFileDialog falls back to an in-process GtkFileChooserDialog without a portal)

    static func fileChooser() -> Widget? {
        toplevels().first { isA($0, gtk_file_chooser_dialog_get_type()) && gtk_widget_get_visible($0) != 0 }
    }

    /// Answers the open file chooser: `path` selects (open) or names (save) a file; nil cancels.
    @discardableResult
    static func answerFileChooser(_ path: String?, file: StaticString = #filePath, line: UInt = #line) -> Bool {
        guard pump(until: { fileChooser() != nil }, timeout: 5), let dialog = fileChooser() else {
            XCTFail("No file chooser appeared", file: file, line: line)
            return false
        }
        guard let path else {
            gtk_dialog_response(dialog.cast(), GTK_RESPONSE_CANCEL.rawValue)
            pump(0.2)
            return true
        }
        let url = URL(fileURLWithPath: path)
        let chooser = dialog.opaque
        if gtk_file_chooser_get_action(chooser) == GTK_FILE_CHOOSER_ACTION_SAVE {
            let folder = g_file_new_for_path(url.deletingLastPathComponent().path)
            _ = gtk_file_chooser_set_current_folder(chooser, folder, nil)
            g_object_unref(folder?.raw)
            gtk_file_chooser_set_current_name(chooser, url.lastPathComponent)
        } else {
            let target = g_file_new_for_path(path)
            _ = gtk_file_chooser_set_file(chooser, target, nil)
            g_object_unref(target?.raw)
        }
        pump(0.5)
        gtk_dialog_response(dialog.cast(), GTK_RESPONSE_ACCEPT.rawValue)
        pump(0.3)
        return true
    }

    /// Drops `paths` on the first GtkDropTarget attached to `widget`, as the file manager would.
    @discardableResult
    static func drop(_ paths: [String], on widget: Widget) -> Bool {
        guard let target = controllers(widget, ofType: gtk_drop_target_get_type()).first else {
            XCTFail("No drop target")
            return false
        }
        var files: UnsafeMutablePointer<GSList>?
        for path in paths { files = g_slist_append(files, g_file_new_for_path(path)?.raw) }
        let list = gdk_file_list_new_from_list(files)
        g_slist_free_full(files) { g_object_unref($0) }
        var inner = GValue()
        g_value_init(&inner, gdk_file_list_get_type())
        g_value_take_boxed(&inner, list.map { UnsafeRawPointer($0) })
        var outer = GValue()
        g_value_init(&outer, g_value_get_type())
        withUnsafeMutablePointer(to: &inner) { g_value_set_boxed(&outer, $0) }
        g_value_unset(&inner)
        var result = emit(target, "drop", [outer, double(10), double(10)], returning: g_type_from_name("gboolean"))
        defer { g_value_unset(&result) }
        pump()
        return g_value_get_boolean(&result) != 0
    }

    static func setText(_ editable: Widget, _ text: String) {
        gtk_editable_set_text(editable.opaque, text)
        pump()
    }

    static func setActive(_ row: Widget?, _ active: Bool) {
        guard let row else { return XCTFail("No switch row") }
        adw_switch_row_set_active(row.opaque, active ? 1 : 0)
        pump()
    }

    static func activateRow(_ row: Widget?) {
        guard let row else { return XCTFail("No row") }
        emit(row, "activated")
        pump()
    }
}
