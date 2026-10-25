import CAdwaita
import Foundation

// Thin helpers over the GTK 4 / libadwaita C API. Nothing here hides GTK: call sites still use the
// real C functions, these only fill the gaps Swift's C importer leaves (cast macros, the
// g_signal_connect macro, closures as C callbacks, main-loop hops).

typealias Widget = UnsafeMutablePointer<GtkWidget>

// MARK: - Pointer casts (GTK_WIDGET(), GTK_BOX()... are macros and don't import)

/// Any GObject instance pointer. Derivable GTK types import as `UnsafeMutablePointer<T>`,
/// final (opaque) ones as `OpaquePointer`; both convert to the other through a raw pointer.
protocol GPointer {
    var raw: UnsafeMutableRawPointer { get }
}

extension UnsafeMutablePointer: GPointer {
    var raw: UnsafeMutableRawPointer { UnsafeMutableRawPointer(self) }
}

extension OpaquePointer: GPointer {
    var raw: UnsafeMutableRawPointer { UnsafeMutableRawPointer(self) }
}

extension GPointer {
    /// Unchecked up/down-cast, like the C `GTK_BOX (w)` macros (the type is inferred at the call site).
    func cast<T>(_: T.Type = T.self) -> UnsafeMutablePointer<T> { raw.assumingMemoryBound(to: T.self) }
    var opaque: OpaquePointer { OpaquePointer(raw) }
    var widget: Widget { cast() }
    var object: UnsafeMutablePointer<GObject> { cast() }
}

// MARK: - Closures as C callbacks

/// Heap box that carries a Swift closure through a `gpointer user_data`.
final class Box<T> {
    let value: T
    init(_ value: T) { self.value = value }
}

private func retained<T>(_ value: T) -> gpointer {
    Unmanaged.passRetained(Box(value)).toOpaque()
}

private func unbox<T>(_ data: gpointer?, as _: T.Type = T.self) -> T {
    Unmanaged<Box<T>>.fromOpaque(data!).takeUnretainedValue().value
}

/// GClosureNotify / GDestroyNotify that drops the box when the handler or source goes away.
private let releaseClosure: GClosureNotify = { data, _ in
    if let data { Unmanaged<AnyObject>.fromOpaque(data).release() }
}
private let releaseData: GDestroyNotify = { data in
    if let data { Unmanaged<AnyObject>.fromOpaque(data).release() }
}

private func connectRaw(_ instance: GPointer, _ signal: String, _ thunk: GCallback, _ data: gpointer) -> gulong {
    g_signal_connect_data(instance.raw, signal, thunk, data, releaseClosure, GConnectFlags(rawValue: 0))
}

/// `g_signal_connect` for signals shaped `void (*)(Instance *, gpointer)`: clicked, activate, destroy…
@discardableResult
func onSignal(_ instance: GPointer, _ signal: String, _ handler: @escaping () -> Void) -> gulong {
    let thunk: @convention(c) (gpointer?, gpointer?) -> Void = { _, data in
        unbox(data, as: (() -> Void).self)()
    }
    return connectRaw(instance, signal, unsafeBitCast(thunk, to: GCallback.self), retained(handler))
}

/// Signals with one pointer argument: `response` (const char *), `notify::prop` (GParamSpec *),
/// `row-activated` (GtkListBoxRow *)…
@discardableResult
func onSignal(_ instance: GPointer, _ signal: String, _ handler: @escaping (UnsafeMutableRawPointer?) -> Void) -> gulong {
    let thunk: @convention(c) (gpointer?, gpointer?, gpointer?) -> Void = { _, arg, data in
        unbox(data, as: ((UnsafeMutableRawPointer?) -> Void).self)(arg)
    }
    return connectRaw(instance, signal, unsafeBitCast(thunk, to: GCallback.self), retained(handler))
}

/// Signals returning gboolean with no extra arguments, e.g. GtkWindow `close-request`.
@discardableResult
func onSignalBool(_ instance: GPointer, _ signal: String, _ handler: @escaping () -> Bool) -> gulong {
    let thunk: @convention(c) (gpointer?, gpointer?) -> gboolean = { _, data in
        unbox(data, as: (() -> Bool).self)() ? 1 : 0
    }
    return connectRaw(instance, signal, unsafeBitCast(thunk, to: GCallback.self), retained(handler))
}

/// `GtkDropTarget::drop` — `gboolean (*)(GtkDropTarget *, const GValue *, double, double, gpointer)`.
@discardableResult
func onDrop(_ target: GPointer, _ handler: @escaping (UnsafePointer<GValue>) -> Bool) -> gulong {
    let thunk: @convention(c) (gpointer?, UnsafePointer<GValue>?, Double, Double, gpointer?) -> gboolean = { _, value, _, _, data in
        guard let value else { return 0 }
        return unbox(data, as: ((UnsafePointer<GValue>) -> Bool).self)(value) ? 1 : 0
    }
    return connectRaw(target, "drop", unsafeBitCast(thunk, to: GCallback.self), retained(handler))
}

/// `GApplication::open` — `void (*)(GApplication *, GFile **, gint, gchar *, gpointer)`.
@discardableResult
func onOpenFiles(_ app: GPointer, _ handler: @escaping ([String]) -> Void) -> gulong {
    let thunk: @convention(c) (gpointer?, UnsafeMutablePointer<OpaquePointer?>?, gint, UnsafePointer<gchar>?, gpointer?) -> Void = { _, files, count, _, data in
        var paths: [String] = []
        for i in 0..<Int(count) {
            if let file = files?[i], let path = filePath(file) { paths.append(path) }
        }
        unbox(data, as: (([String]) -> Void).self)(paths)
    }
    return connectRaw(app, "open", unsafeBitCast(thunk, to: GCallback.self), retained(handler))
}

/// One-shot `GAsyncReadyCallback` + user_data for the GIO-style async APIs
/// (GtkFileDialog, GtkFileLauncher). The closure gets the `GAsyncResult *`.
func asyncReady(_ body: @escaping (OpaquePointer?) -> Void) -> (GAsyncReadyCallback, gpointer) {
    let thunk: GAsyncReadyCallback = { _, result, data in
        Unmanaged<Box<(OpaquePointer?) -> Void>>.fromOpaque(data!).takeRetainedValue().value(result)
    }
    return (thunk, retained(body))
}

// MARK: - Main loop

/// Runs `block` on the GTK main thread on the next main-loop iteration. GLib owns the main loop,
/// so DispatchQueue.main is never drained on Linux; always come back through here.
func onMain(_ block: @escaping () -> Void) {
    let thunk: GSourceFunc = { data in
        unbox(data, as: (() -> Void).self)()
        return 0 // G_SOURCE_REMOVE
    }
    g_idle_add_full(G_PRIORITY_DEFAULT, thunk, retained(block), releaseData)
}

/// Repeating main-loop timer; return false from `tick` to stop it.
@discardableResult
func every(seconds: UInt32, _ tick: @escaping () -> Bool) -> guint {
    let thunk: GSourceFunc = { data in
        unbox(data, as: (() -> Bool).self)() ? 1 : 0
    }
    return g_timeout_add_seconds_full(G_PRIORITY_DEFAULT, seconds, thunk, retained(tick), releaseData)
}

// MARK: - GLib values

/// Takes ownership of a newly allocated `gchar *` (g_free'd here).
func takeString(_ p: UnsafeMutablePointer<gchar>?) -> String? {
    guard let p else { return nil }
    defer { g_free(p) }
    return String(cString: p)
}

/// Local path of a `GFile *` (nil for non-native URIs).
func filePath(_ file: OpaquePointer) -> String? {
    takeString(g_file_get_path(file))
}

/// Message of a GError, freeing it.
func takeError(_ error: UnsafeMutablePointer<GError>?) -> String? {
    guard let error else { return nil }
    defer { g_error_free(error) }
    return error.pointee.message.map { String(cString: $0) }
}

/// The user data directory (`$XDG_DATA_HOME`, `~/.local/share`, or the Flatpak sandbox's own).
var userDataDir: String { String(cString: g_get_user_data_dir()) }
var userConfigDir: String { String(cString: g_get_user_config_dir()) }

// MARK: - Widget builders

func label(_ text: String, classes: [String] = [], xalign: Float = 0, wrap: Bool = false, selectable: Bool = false) -> Widget {
    let l = gtk_label_new(text)!
    gtk_label_set_xalign(l.opaque, xalign)
    if wrap {
        gtk_label_set_wrap(l.opaque, 1)
        gtk_label_set_wrap_mode(l.opaque, PANGO_WRAP_WORD_CHAR)
    }
    if selectable { gtk_label_set_selectable(l.opaque, 1) }
    addClasses(l, classes)
    return l
}

func setLabel(_ l: Widget, _ text: String) {
    gtk_label_set_text(l.opaque, text)
}

func box(_ orientation: GtkOrientation, spacing: Int32 = 0, classes: [String] = [], _ children: [Widget] = []) -> Widget {
    let b = gtk_box_new(orientation, spacing)!
    addClasses(b, classes)
    for child in children { gtk_box_append(b.cast(), child) }
    return b
}

func vbox(spacing: Int32 = 0, classes: [String] = [], _ children: [Widget] = []) -> Widget {
    box(GTK_ORIENTATION_VERTICAL, spacing: spacing, classes: classes, children)
}

func hbox(spacing: Int32 = 0, classes: [String] = [], _ children: [Widget] = []) -> Widget {
    box(GTK_ORIENTATION_HORIZONTAL, spacing: spacing, classes: classes, children)
}

func append(_ parent: Widget, _ child: Widget) {
    gtk_box_append(parent.cast(), child)
}

/// Removes every child of a GtkBox.
func clearBox(_ b: Widget) {
    while let child = gtk_widget_get_first_child(b) {
        gtk_box_remove(b.cast(), child)
    }
}

/// Removes every row of a GtkListBox.
func clearList(_ list: Widget) {
    gtk_list_box_remove_all(list.opaque)
}

func button(_ text: String, classes: [String] = [], action: @escaping () -> Void) -> Widget {
    let b = gtk_button_new_with_label(text)!
    addClasses(b, classes)
    onSignal(b, "clicked", action)
    return b
}

func iconButton(_ icon: String, tooltip: String, classes: [String] = ["flat"], action: @escaping () -> Void) -> Widget {
    let b = gtk_button_new_from_icon_name(icon)!
    gtk_widget_set_tooltip_text(b, tooltip)
    setAccessibleLabel(b, tooltip)
    addClasses(b, classes)
    onSignal(b, "clicked", action)
    return b
}

func image(_ icon: String, size: Int32 = 16, classes: [String] = []) -> Widget {
    let i = gtk_image_new_from_icon_name(icon)!
    gtk_image_set_pixel_size(i.opaque, size)
    addClasses(i, classes)
    return i
}

/// A `boxed-list` GtkListBox (the libadwaita card-style list) without selection.
func boxedList() -> Widget {
    let list = gtk_list_box_new()!
    gtk_list_box_set_selection_mode(list.opaque, GTK_SELECTION_NONE)
    addClasses(list, ["boxed-list"])
    return list
}

/// AdwActionRow with optional prefix icon and suffix widgets.
func actionRow(title: String, subtitle: String? = nil, icon: String? = nil, iconClasses: [String] = [],
               suffix: [Widget] = [], subtitleSelectable: Bool = false) -> Widget {
    let row = adw_action_row_new()!
    adw_preferences_row_set_title(row.cast(), escapeMarkup(title))
    if let subtitle { adw_action_row_set_subtitle(row.cast(), escapeMarkup(subtitle)) }
    if subtitleSelectable { adw_action_row_set_subtitle_selectable(row.cast(), 1) }
    if let icon { adw_action_row_add_prefix(row.cast(), image(icon, classes: iconClasses)) }
    for s in suffix {
        gtk_widget_set_valign(s, GTK_ALIGN_CENTER)
        adw_action_row_add_suffix(row.cast(), s)
    }
    return row
}

func preferencesGroup(title: String?, description: String? = nil) -> Widget {
    let g = adw_preferences_group_new()!
    if let title { adw_preferences_group_set_title(g.cast(), escapeMarkup(title)) }
    if let description { adw_preferences_group_set_description(g.cast(), escapeMarkup(description)) }
    return g
}

func groupAdd(_ group: Widget, _ child: Widget) {
    adw_preferences_group_add(group.cast(), child)
}

/// Row titles/subtitles in libadwaita are Pango markup by default: escape user data
/// (file names like "R&D.pdf" would otherwise render empty).
func escapeMarkup(_ text: String) -> String {
    takeString(g_markup_escape_text(text, -1)) ?? text
}

func addClasses(_ w: Widget, _ classes: [String]) {
    for c in classes { gtk_widget_add_css_class(w, c) }
}

func setClass(_ w: Widget, _ name: String, _ on: Bool) {
    on ? gtk_widget_add_css_class(w, name) : gtk_widget_remove_css_class(w, name)
}

func setVisible(_ w: Widget, _ visible: Bool) {
    gtk_widget_set_visible(w, visible ? 1 : 0)
}

func setSensitive(_ w: Widget, _ sensitive: Bool) {
    gtk_widget_set_sensitive(w, sensitive ? 1 : 0)
}

func margins(_ w: Widget, _ all: Int32) {
    gtk_widget_set_margin_top(w, all)
    gtk_widget_set_margin_bottom(w, all)
    gtk_widget_set_margin_start(w, all)
    gtk_widget_set_margin_end(w, all)
}

/// Scrolled page body: AdwClamp (readable max width) inside a vertical-only GtkScrolledWindow.
func scrolledPage(_ content: Widget, maxWidth: Int32 = 720) -> Widget {
    let clamp = adw_clamp_new()!
    adw_clamp_set_maximum_size(clamp.opaque, maxWidth)
    adw_clamp_set_child(clamp.opaque, content)
    let scroll = gtk_scrolled_window_new()!
    gtk_scrolled_window_set_policy(scroll.opaque, GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC)
    gtk_scrolled_window_set_child(scroll.opaque, clamp)
    gtk_widget_set_vexpand(scroll, 1)
    return scroll
}

// MARK: - CSS

/// Installs app CSS for the default display (accent colors come from libadwaita's own variables).
func installCSS(_ css: String) {
    let provider = gtk_css_provider_new()
    gtk_css_provider_load_from_string(provider, css)
    gtk_style_context_add_provider_for_display(gdk_display_get_default(), provider.map { OpaquePointer($0) },
                                               UInt32(GTK_STYLE_PROVIDER_PRIORITY_APPLICATION))
}

// MARK: - GObject properties (g_object_set is variadic; set one property through a GValue)

func setProperty(_ object: GPointer, _ name: String, bool value: Bool) {
    var v = GValue()
    g_value_init(&v, g_type_from_name("gboolean"))
    g_value_set_boolean(&v, value ? 1 : 0)
    g_object_set_property(object.object, name, &v)
    g_value_unset(&v)
}

func setProperty(_ object: GPointer, _ name: String, string value: String) {
    var v = GValue()
    g_value_init(&v, g_type_from_name("gchararray"))
    g_value_set_string(&v, value)
    g_object_set_property(object.object, name, &v)
    g_value_unset(&v)
}

/// `const char * const *` (NULL-terminated) for the duration of `body`.
func withCStringArray<R>(_ strings: [String], _ body: (UnsafePointer<UnsafePointer<CChar>?>) -> R) -> R {
    let copies = strings.map { strdup($0) }
    defer { copies.forEach { free($0) } }
    let array: [UnsafePointer<CChar>?] = copies.map { UnsafePointer($0) } + [nil]
    return array.withUnsafeBufferPointer { body($0.baseAddress!) }
}

/// Accessible name for icon-only controls and unlabeled entries (gtk_accessible_update_property is variadic).
func setAccessibleLabel(_ widget: GPointer, _ text: String) {
    var property = GTK_ACCESSIBLE_PROPERTY_LABEL
    var value = GValue()
    g_value_init(&value, g_type_from_name("gchararray"))
    g_value_set_string(&value, text)
    gtk_accessible_update_property_value(widget.opaque, 1, &property, &value)
    g_value_unset(&value)
}

/// AdwStatusPage look (large icon, title-1, wrapped description) for use *inside* scrolled content:
/// AdwStatusPage has its own scrolled window and collapses to a sliver when placed in a box.
struct StatusHeader {
    let root: Widget
    let icon: Widget
    let title: Widget
    let body: Widget

    init(icon name: String, size: Int32 = 96) {
        icon = image(name, size: size, classes: ["dim-label"])
        title = label("", classes: ["title-1"], xalign: 0.5, wrap: true)
        body = label("", classes: ["body"], xalign: 0.5, wrap: true)
        gtk_label_set_justify(body.opaque, GTK_JUSTIFY_CENTER)
        gtk_label_set_justify(title.opaque, GTK_JUSTIFY_CENTER)
        root = vbox(spacing: 12, [icon, title, body])
        gtk_widget_set_margin_top(root, 24)
        gtk_widget_set_margin_bottom(icon, 12)
    }

    func set(icon name: String? = nil, title text: String, body bodyText: String) {
        if let name { gtk_image_set_from_icon_name(icon.opaque, name) }
        setLabel(title, text)
        setLabel(body, bodyText)
        setVisible(body, !bodyText.isEmpty)
    }
}
