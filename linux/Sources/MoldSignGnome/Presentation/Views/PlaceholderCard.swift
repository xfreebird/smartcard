import CAdwaita
import Foundation

// MARK: - Empty states are cards too

/// The wallet with no card: dashed "Introdu cardul", reader + cable "Conectează cititorul", or a red-tinted card
/// with the recovery text. `showsText: false` draws the illustration only (inside an AdwStatusPage).
final class PlaceholderCard {
    let root: Widget
    private let area: Widget
    private let title: Widget
    private let caption: Widget
    private let action: Widget?
    private var retry: (() -> Void)?
    private var kind: CardArt.Placeholder = .noReader
    private var compact = false
    private let showsText: Bool

    init(showsText: Bool = true) {
        self.showsText = showsText
        area = gtk_drawing_area_new()!
        title = label("", classes: ["placeholder-title"], xalign: 0.5, wrap: true)
        gtk_label_set_justify(title.opaque, GTK_JUSTIFY_CENTER)
        caption = label("", classes: ["placeholder-caption"], xalign: 0.5, wrap: true)
        gtk_label_set_justify(caption.opaque, GTK_JUSTIFY_CENTER)
        gtk_label_set_lines(caption.opaque, 3)
        gtk_label_set_ellipsize(caption.opaque, PANGO_ELLIPSIZE_END)

        let overlay = gtk_overlay_new()!
        gtk_overlay_set_child(overlay.opaque, area)
        if showsText {
            let retryButton = button(L10n.text(.ui_retry), classes: ["pill", "small-pill"]) {}
            gtk_widget_set_halign(retryButton, GTK_ALIGN_CENTER)
            gtk_widget_set_margin_top(retryButton, 6)
            action = retryButton
            let text = vbox(spacing: 2, [title, caption, retryButton])
            gtk_widget_set_valign(text, GTK_ALIGN_END)
            gtk_widget_set_margin_bottom(text, 22)
            gtk_widget_set_margin_start(text, 16)
            gtk_widget_set_margin_end(text, 16)
            gtk_overlay_add_overlay(overlay.opaque, text)
        } else {
            action = nil
        }
        root = overlay
        addClasses(root, ["wallet-placeholder"])
        if let action { onSignal(action, "clicked") { [weak self] in self?.retry?() } }
        setDrawFunc(area) { [weak self] cr, width, height in self?.draw(cr, Double(width), Double(height)) }
        setCompact(false)
    }

    func setCompact(_ on: Bool) {
        compact = on
        let size = on ? CardArt.compact : CardArt.large
        gtk_drawing_area_set_content_width(area.cast(), size.width)
        gtk_drawing_area_set_content_height(area.cast(), size.height)
        setClass(root, "compact", on)
        redraw()
    }

    func redraw() {
        gtk_widget_queue_draw(area)
    }

    /// Picks the placeholder for a no-card status (`.noReader`, `.empty`, `.error`).
    func show(status: ReaderStatus, retry: (() -> Void)?) {
        let next: CardArt.Placeholder
        let titleText: String
        let captionText: String
        switch status {
        case .error(let message, let recovery):
            next = .error
            titleText = message
            captionText = recovery
        case .empty(let reader):
            next = .insertCard
            titleText = L10n.text(.linux_insert_card)
            captionText = reader
        default:
            next = .noReader
            titleText = L10n.text(.ui_connect_the_reader)
            captionText = L10n.text(.ui_usb_smart_card_reader_e_g_bit4id_minilector)
        }
        self.retry = retry
        if next != kind {
            kind = next
            redraw()
        }
        setClass(root, "error-card", next == .error)
        setLabel(title, titleText)
        setLabel(caption, captionText)
        if let action { setVisible(action, next == .error && retry != nil && !compact) }
        setAccessibleLabel(showsText ? root : area, captionText.isEmpty ? titleText : "\(titleText). \(captionText)")
    }

    private func draw(_ cr: OpaquePointer, _ width: Double, _ height: Double) {
        // with text the glyph sits above it; illustration-only centres it and draws it larger
        let glyphY = showsText ? height * (kind == .error ? 0.30 : 0.40) : height * 0.5
        CardArt.drawPlaceholder(cr, kind, width: width, height: height, fg: foreground(area),
                                danger: danger(dark: isDark), glyphCenterY: glyphY, glyphScale: showsText ? 1 : 1.5)
    }
}

// MARK: - Theme helpers

private var isDark: Bool {
    guard let manager = adw_style_manager_get_default() else { return false }
    return adw_style_manager_get_dark(manager) != 0
}

/// The widget's CSS `color` (theme foreground), for drawing placeholders.
private func foreground(_ widget: Widget) -> CardArt.RGB {
    var color = GdkRGBA()
    gtk_widget_get_color(widget, &color)
    return CardArt.RGB(r: Double(color.red), g: Double(color.green), b: Double(color.blue))
}

/// docs/10 `danger`: #C62828 light, #F87171 dark.
private func danger(dark: Bool) -> CardArt.RGB {
    dark ? CardArt.RGB(r: 0xF8 / 255, g: 0x71 / 255, b: 0x71 / 255) : CardArt.RGB(r: 0xC6 / 255, g: 0x28 / 255, b: 0x28 / 255)
}
