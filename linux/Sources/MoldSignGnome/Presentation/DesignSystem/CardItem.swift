import CAdwaita
import Foundation

// MARK: - One inserted card

/// One card of the component: a `GtkRevealer` (hidden while collapsed unless selected) holding an overlay of the
/// ID-card face (a GtkButton around the cairo drawing: focus ring, keyboard, one accessible element) and the round
/// disclosure button (selected card, more than one card).
final class CardItem {
    /// Around each face, inside its revealer (which clips): room for the outline and the shadow; vertically
    /// 4 + 8 = 12 px between listed cards.
    static let margin = (top: Int32(4), bottom: Int32(8), start: Int32(12), end: Int32(12))

    let reader: String
    let root: Widget
    let button: Widget
    let disclosure: Widget
    var onMenu: ((_ x: Double?, _ y: Double?) -> Void)?

    private let area: Widget
    private var face: CardArt.Face
    private var compact: Bool
    private var revealed: Bool?

    init(reader: String, compact: Bool) {
        self.reader = reader
        self.compact = compact
        face = CardArt.Face(surname: nil, givenNames: nil, validUntil: nil, issuer: nil, state: .reading, reader: reader,
                            hueShift: CardArt.hueShift(sha1Hex: nil, fallback: reader), showsReader: !compact,
                            reservesDisclosure: false)

        area = gtk_drawing_area_new()!
        button = gtk_button_new()!
        gtk_button_set_child(button.cast(), area)
        addClasses(button, ["wallet-card"])
        gtk_widget_set_margin_top(button, Self.margin.top)
        gtk_widget_set_margin_bottom(button, Self.margin.bottom)
        gtk_widget_set_margin_start(button, Self.margin.start)
        gtk_widget_set_margin_end(button, Self.margin.end)

        // round disclosure: chevron right (collapsed) / down (expanded)
        disclosure = gtk_button_new_from_icon_name("pan-end-symbolic")!
        addClasses(disclosure, ["circular", "card-disclosure"])
        gtk_widget_set_halign(disclosure, GTK_ALIGN_START)
        gtk_widget_set_valign(disclosure, GTK_ALIGN_START)
        setVisible(disclosure, false)

        let overlay = gtk_overlay_new()!
        gtk_overlay_set_child(overlay.opaque, button)
        gtk_overlay_add_overlay(overlay.opaque, disclosure)
        addClasses(overlay, ["wallet-item"])

        root = gtk_revealer_new()!
        gtk_revealer_set_transition_type(root.opaque, GTK_REVEALER_TRANSITION_TYPE_SLIDE_DOWN)
        gtk_revealer_set_transition_duration(root.opaque, 250)
        gtk_revealer_set_reveal_child(root.opaque, 0)
        gtk_revealer_set_child(root.opaque, overlay)

        setDrawFunc(area) { [weak self] cr, width, height in
            guard let self else { return }
            let font = pango_context_get_font_description(gtk_widget_get_pango_context(self.area))
            CardArt.drawIDCard(cr, width: Double(width), height: Double(height), face: self.face, font: font)
        }

        // context menu: right click and long press (touch)
        let rightClick = gtk_gesture_click_new()!
        gtk_gesture_single_set_button(rightClick.opaque, 3)
        onClickPressed(rightClick) { [weak self] x, y in self?.onMenu?(x, y) }
        gtk_widget_add_controller(button, rightClick.opaque)
        let longPress = gtk_gesture_long_press_new()!
        gtk_gesture_single_set_touch_only(longPress.opaque, 1)
        onLongPressed(longPress) { [weak self] x, y in self?.onMenu?(x, y) }
        gtk_widget_add_controller(button, longPress.opaque)

        setCompact(compact)
    }

    func setCompact(_ on: Bool) {
        compact = on
        let size = on ? CardArt.compact : CardArt.large
        let W = Double(size.width), H = Double(size.height)
        gtk_drawing_area_set_content_width(area.cast(), size.width)
        gtk_drawing_area_set_content_height(area.cast(), size.height)
        setClass(button, "compact", on)
        // disclosure: centre (0.935 W, 0.50 H), diameter 0.085 W (docs/10 §0.2b)
        let diameter = Int32((0.085 * W).rounded())
        gtk_widget_set_size_request(disclosure, diameter, diameter)
        gtk_widget_set_margin_start(disclosure, Self.margin.start + Int32((0.935 * W).rounded()) - diameter / 2)
        gtk_widget_set_margin_top(disclosure, Self.margin.top + Int32((0.50 * H).rounded()) - diameter / 2)
        face.showsReader = !on
        gtk_widget_queue_draw(area)
    }

    /// Show (selected, or the list is expanded) or hide this card; slides only when `animated`.
    func setRevealed(_ on: Bool, animated: Bool) {
        guard on != revealed else { return }
        gtk_revealer_set_transition_duration(root.opaque, animated && revealed != nil ? 250 : 0)
        gtk_revealer_set_reveal_child(root.opaque, on ? 1 : 0)
        revealed = on
    }

    func update(_ content: CardItemContent) {
        var next = content.face
        next.showsReader = !compact
        if next != face {
            face = next
            gtk_widget_queue_draw(area)
        }
        setVisible(disclosure, false)
        gtk_button_set_icon_name(disclosure.cast(), content.expanded ? "pan-down-symbolic" : "pan-end-symbolic")
        setAccessibleLabel(disclosure, content.disclosureLabel)
        setAccessibleState(disclosure, GTK_ACCESSIBLE_STATE_EXPANDED, content.expanded)
        gtk_widget_set_tooltip_text(disclosure, content.disclosureTooltip)
        setClass(button, "chosen", content.selected && content.expanded)
        setAccessibleLabel(button, content.label)
        setAccessibleState(button, GTK_ACCESSIBLE_STATE_SELECTED, content.selected && content.expanded)
        gtk_widget_set_tooltip_text(button, content.tooltip)
    }
}
