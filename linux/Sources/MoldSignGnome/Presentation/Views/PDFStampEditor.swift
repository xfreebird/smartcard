import CAdwaita
import CPoppler
import Foundation
import MoldSignKit

/// Poppler paints a preview only; all saved changes are made by the core's incremental signer.
private final class StampState {
    let document: OpaquePointer
    var placement: PDFStampPlacement
    var enabled = true
    var changed: (() -> Void)?
    init?(item: SignItem) {
        guard let data = try? Data(contentsOf: item.url) else { return nil }
        let bytes = data.withUnsafeBytes { g_bytes_new($0.baseAddress, UInt($0.count)) }!
        defer { g_bytes_unref(bytes) }
        guard let document = poppler_document_new_from_bytes(bytes, nil, nil) else { return nil }
        self.document = document
        placement = (item.stamp ?? PDFStampPlacement()).bound(to: data)
        placement.language = PDFStampLanguage(localeIdentifier: L10n.language ?? Locale.current.identifier)
    }
    deinit { g_object_unref(document.raw) }
}

private final class StampPreview {
    let area: Widget
    let state: StampState
    let index: Int
    let holder: String
    var document: OpaquePointer { state.document }
    var placement: PDFStampPlacement { get { state.placement } set { state.placement = newValue } }
    var enabled: Bool { state.enabled }
    var dragStart: PDFStampPlacement?
    var dragCorner: Int?
    var origin = (0.0, 0.0)
    var size = (1.0, 1.0)
    init(state: StampState, index: Int, holder: String) {
        self.state = state; self.index = index; self.holder = holder
        area = gtk_drawing_area_new()!
        var w = 595.0, h = 842.0
        if let page = poppler_document_get_page(state.document, Int32(index)) {
            poppler_page_get_size(page, &w, &h); g_object_unref(page.raw)
        }
        gtk_drawing_area_set_content_width(area.cast(), 240)
        gtk_drawing_area_set_content_height(area.cast(), Int32(240 * h / max(w, 1)))
    }

    func install() {
        let data = Unmanaged.passRetained(self).toOpaque()
        gtk_drawing_area_set_draw_func(area.cast(), { _, context, width, height, raw in
            guard let context, let raw else { return }
            let preview = Unmanaged<StampPreview>.fromOpaque(raw).takeUnretainedValue()
            guard let page = poppler_document_get_page(preview.document, Int32(preview.index)) else { return }
            defer { g_object_unref(page.raw) }
            var w = 0.0, h = 0.0; poppler_page_get_size(page, &w, &h)
            guard w > 0, h > 0 else { return }
            let scale = min(Double(width) / w, Double(height) / h)
            let ox = (Double(width) - w * scale) / 2, oy = (Double(height) - h * scale) / 2
            preview.origin = (ox, oy); preview.size = (w * scale, h * scale)
            cairo_save(context)
            cairo_translate(context, ox, oy); cairo_scale(context, scale, scale)
            cairo_set_source_rgb(context, 1, 1, 1); cairo_rectangle(context, 0, 0, w, h); cairo_fill(context)
            poppler_page_render(page, context)
            if preview.enabled && (preview.placement.allPages || preview.placement.page == preview.index) {
                let p = preview.placement
                cairo_set_source_rgb(context, 0, 0.45, 0.5); cairo_set_line_width(context, 0.75/scale)
                cairo_rectangle(context, w*p.x, h*p.y, w*p.width, h*p.height); cairo_stroke(context)
                cairo_save(context)
                cairo_translate(context, w*p.x, h*p.y)
                cairo_scale(context, w*p.width/240, h*p.height/96)
                cairo_set_source_rgb(context, 0.65, 0.65, 0.65)
                cairo_set_line_width(context, 0.5); cairo_rectangle(context, 0.5, 65, 174, 21); cairo_stroke(context)
                cairo_set_source_rgb(context, 0, 0, 0)
                let lines = preview.placement.language.lines(holder: preview.holder, date: Date())
                for (index, line) in lines.enumerated() {
                    if let layout = pango_cairo_create_layout(context) {
                        pango_layout_set_text(layout, line, -1)
                        if let font = pango_font_description_from_string(index == 5 ? "Liberation Serif 5.25" : "Liberation Serif 9.75") {
                            pango_layout_set_font_description(layout, font); pango_font_description_free(font)
                        }
                        cairo_move_to(context, index == 4 ? 5 : 0, [2.0,17,32,47,68,87][index])
                        var textWidth: Int32 = 0
                        pango_layout_get_pixel_size(layout, &textWidth, nil)
                        let maximumWidth = index == 4 ? 164.0 : 228.0
                        cairo_save(context)
                        if Double(textWidth) > maximumWidth { cairo_scale(context, maximumWidth / Double(textWidth), 1) }
                        pango_cairo_show_layout(context, layout)
                        cairo_restore(context); g_object_unref(layout.raw)
                    }
                }
                cairo_restore(context)
                for corner in 0..<4 {
                    let x = w * (p.x + (corner % 2 == 1 ? p.width : 0))
                    let y = h * (p.y + (corner >= 2 ? p.height : 0))
                    cairo_set_source_rgb(context, 0.15, 0.45, 0.85)
                    cairo_arc(context, x, y, 4.5/scale, 0, 2 * Double.pi); cairo_fill_preserve(context)
                    cairo_set_source_rgb(context, 1, 1, 1); cairo_set_line_width(context, 1/scale); cairo_stroke(context)
                }
            }
            cairo_restore(context)
        }, data, { raw in if let raw { Unmanaged<StampPreview>.fromOpaque(raw).release() } })
        let drag = gtk_gesture_drag_new()!
        onDragCoordinates(drag, "drag-begin") { [weak self] x, y in
            guard let self, self.enabled else { return }
            self.placement.page = self.index
            self.dragCorner = (0..<4).first { corner in
                let cx = self.origin.0 + self.size.0 * (self.placement.x + (corner % 2 == 1 ? self.placement.width : 0))
                let cy = self.origin.1 + self.size.1 * (self.placement.y + (corner >= 2 ? self.placement.height : 0))
                return abs(x-cx) <= 14 && abs(y-cy) <= 14
            }
            if self.dragCorner == nil {
                let u = (x-self.origin.0)/self.size.0, v = (y-self.origin.1)/self.size.1
                if u < self.placement.x || u > self.placement.x+self.placement.width || v < self.placement.y || v > self.placement.y+self.placement.height {
                    self.placement.x = min(max(0,u-self.placement.width/2),1-self.placement.width)
                    self.placement.y = min(max(0,v-self.placement.height/2),1-self.placement.height)
                }
            }
            self.dragStart = self.placement
            gtk_widget_grab_focus(self.area); self.state.changed?()
        }
        onDragCoordinates(drag, "drag-update") { [weak self] dx, dy in
            guard let self, self.enabled, let start = self.dragStart else { return }
            if let corner = self.dragCorner {
                self.placement = start.resized(corner: corner, dx: dx/self.size.0, dy: dy/self.size.1)
            } else {
                self.placement.x = min(max(0,start.x+dx/self.size.0),1-start.width)
                self.placement.y = min(max(0,start.y+dy/self.size.1),1-start.height)
            }
            self.state.changed?()
        }
        gtk_widget_add_controller(area, drag)
        gtk_widget_set_focusable(area, 1)
        setAccessibleLabel(area, L10n.text(.stamp_move_hint))
        let keys = gtk_event_controller_key_new()!
        onKeyPressed(keys) { [weak self] key, _ in
            guard let self, self.enabled, key == 43 || key == 45 else { return false }
            self.placement = self.placement.resized(corner: 3, dx: key == 43 ? 0.02 : -0.02, dy: 0)
            self.state.changed?(); return true
        }
        gtk_widget_add_controller(area, keys)

    }
}

@discardableResult
func presentPDFStampEditor(parent: UnsafeMutablePointer<GtkWindow>?, item: SignItem, holder: String,
                           requester: String? = nil,
                           cancelled: (() -> Void)? = nil,
                           applyQueue: ((PDFStampPlacement?) -> Void)? = nil,
                           completion: @escaping (PDFStampPlacement?) -> Void) -> () -> Void {
    let window = gtk_window_new()!
    gtk_window_set_title(window.cast(), L10n.text(.stamp_title))
    gtk_window_set_default_size(window.cast(), 820, 620)
    gtk_window_set_modal(window.cast(), 1)
    if let parent { gtk_window_set_transient_for(window.cast(), parent) }
    let content = vbox(spacing: 16); margins(content, 20)
    gtk_window_set_child(window.cast(), content)
    var answered = false
    if let requester { append(content, label(requester, wrap: true)) }
    func switchRow(_ title: String, active: Bool = false) -> Widget {
        let row = adw_switch_row_new()!
        adw_preferences_row_set_title(row.cast(), title)
        adw_action_row_set_title_lines(row.cast(), 2)
        adw_switch_row_set_active(row.opaque, active ? 1 : 0)
        return row
    }
    let visible = switchRow(L10n.text(.stamp_visible), active: true)
    let queue = switchRow(L10n.text(.stamp_queue))
    let state = StampState(item: item)
    if let state {
        let pageCount = Int(poppler_document_get_n_pages(state.document))
        let previewColumn = vbox(spacing: 16); margins(previewColumn, 16)
        var previews: [StampPreview] = []
        var badges: [Widget] = []
        for index in 0..<pageCount {
            let preview = StampPreview(state: state, index: index, holder: holder)
            preview.install(); previews.append(preview)
            let card = vbox(spacing: 8, [preview.area])
            let badge = label("", classes: ["caption"], xalign: 0.5)
            badges.append(badge); append(card, badge); append(previewColumn, card)
        }
        let scroll = gtk_scrolled_window_new()!
        gtk_scrolled_window_set_policy(scroll.opaque, GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC)
        gtk_scrolled_window_set_child(scroll.opaque, previewColumn)
        gtk_widget_set_size_request(scroll, 272, -1); gtk_widget_set_vexpand(scroll, 1)
        addClasses(scroll, ["view"])
        let options = vbox(spacing: 16); margins(options, 16)
        gtk_widget_set_hexpand(options, 1)
        let rows = gtk_list_box_new()!; gtk_list_box_set_selection_mode(rows.opaque, GTK_SELECTION_NONE)
        addClasses(rows, ["boxed-list"]); append(options, rows)
        gtk_list_box_append(rows.opaque, visible)
        let documentRow = adw_action_row_new()!
        adw_preferences_row_set_title(documentRow.cast(), item.url.lastPathComponent)
        adw_action_row_set_title_lines(documentRow.cast(), 2)
        gtk_list_box_append(rows.opaque, documentRow)
        let scopeRows = gtk_list_box_new()!; gtk_list_box_set_selection_mode(scopeRows.opaque, GTK_SELECTION_NONE)
        addClasses(scopeRows, ["boxed-list"]); append(options, scopeRows)
        let all = switchRow(L10n.text(.stamp_all_pages), active: state.placement.allPages)
        gtk_list_box_append(scopeRows.opaque, all)
        if applyQueue != nil { gtk_list_box_append(scopeRows.opaque, queue) }
        append(options, label(L10n.text(.stamp_move_hint), classes: ["dim-label"], wrap: true))
        let spacer = vbox(); gtk_widget_set_vexpand(spacer, 1); append(options, spacer)
        let workspace = hbox(spacing: 0, [scroll, options]); gtk_widget_set_vexpand(workspace, 1)
        append(content, workspace)
        func update() {
            setSensitive(all, state.enabled)
            for (index, preview) in previews.enumerated() {
                setLabel(badges[index], "\(state.enabled && (state.placement.allPages || state.placement.page == index) ? "✓  " : "")\(index + 1) / \(pageCount)")
                gtk_widget_queue_draw(preview.area)
            }
        }
        state.changed = { [weak state] in if state != nil { update() } }
        // notify:: passes the GParamSpec: the one-argument handler form, or the user data is read from it.
        onSignal(all, "notify::active") { _ in state.placement.allPages = adw_switch_row_get_active(all.opaque) != 0; update() }
        onSignal(visible, "notify::active") { _ in state.enabled = adw_switch_row_get_active(visible.opaque) != 0; update() }
        let save = button(L10n.text(.stamp_save), classes: ["suggested-action"]) {
            state.placement.allPages = adw_switch_row_get_active(all.opaque) != 0
            answered = true
            let value = state.enabled ? state.placement : nil
            completion(value)
            if adw_switch_row_get_active(queue.opaque) != 0 { applyQueue?(value) }
            state.changed = nil; gtk_window_destroy(window.cast())
        }
        let cancel = button(L10n.text(.ui_cancel)) { answered = true; cancelled?(); state.changed = nil; gtk_window_destroy(window.cast()) }
        let footer = hbox(spacing: 12, [cancel, save]); gtk_widget_set_halign(footer, GTK_ALIGN_END)
        append(options, footer); update()
    } else {
        append(content, label(L10n.text(.stamp_unavailable), wrap: true))
        append(content, button(L10n.text(.ui_cancel)) { answered = true; cancelled?(); gtk_window_destroy(window.cast()) })
    }

    onSignalBool(window, "close-request") {
        state?.changed = nil
        if !answered { answered = true; cancelled?() }
        return false
    }
    gtk_window_present(window.cast())
    return {
        guard !answered else { return }
        answered = true; cancelled?(); state?.changed = nil; gtk_window_destroy(window.cast())
    }
}
