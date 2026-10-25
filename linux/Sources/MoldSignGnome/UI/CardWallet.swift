import CAdwaita
import Foundation

/// The card wallet (docs/10 §0.2b, UX-09, UX-10 revised, UX-07): the card and the selector are ONE component.
///
/// * Collapsed it shows only the selected card, drawn as a Moldovan ID-card illustration (CardArt).
/// * With more than one card a round disclosure button sits inside the card (right edge, vertically centred).
///   It expands the component in place (`GtkRevealer` slide-down, 250 ms, off when animations are off) into
///   a vertical list of every card, same size, 12 px apart, in reader order. The selected card keeps an accent
///   outline and the disclosure button, and its status strip reads "✓ Folosit pentru semnare" (brand blue).
/// * Expanded: click a card → it signs from now on and the list collapses; the disclosure, Escape or a click on
///   the selected card collapse without a change. ↑/↓ move between the cards.
/// * Collapsed: ←/→ (Home/End) switch cards; a click on the card opens the Card page.
/// * Right-click, long-press, Menu or Shift+F10: "Recitește cardul", and the other cards as "Semnează cu {holder}".
///
/// With no card the component is the placeholder card: dashed "Introdu cardul", reader and cable "Conectează
/// cititorul", or a red-tinted card with the recovery text.
final class CardWallet {
    let root: Widget
    private let controller: AppController
    private let stack: OpaquePointer
    private let list: Widget
    private let placeholder: PlaceholderCard
    private let popover: Widget
    private var items: [CardItem] = []
    private var keys: [String] = []
    private var compact = false
    private var expanded = false
    private var lastSelected: String?
    /// Reader whose context menu is open.
    private var menuReader: String?
    private let selectAction: OpaquePointer    // "s": "Semnează cu …" in the context menu
    private let rereadAction: OpaquePointer    // the context-menu card

    init(controller: AppController) {
        self.controller = controller

        list = vbox(spacing: 0, classes: ["wallet-list"])
        gtk_widget_set_halign(list, GTK_ALIGN_CENTER)
        setAccessibleLabel(list, "Cardul folosit pentru semnare")

        placeholder = PlaceholderCard()
        gtk_widget_set_halign(placeholder.root, GTK_ALIGN_CENTER)
        gtk_widget_set_margin_top(placeholder.root, CardItem.margin.top)
        gtk_widget_set_margin_bottom(placeholder.root, CardItem.margin.bottom)

        stack = OpaquePointer(gtk_stack_new()!)
        gtk_stack_set_transition_type(stack, GTK_STACK_TRANSITION_TYPE_CROSSFADE)
        gtk_stack_set_vhomogeneous(stack, 0)
        gtk_stack_set_interpolate_size(stack, 1)
        gtk_stack_add_named(stack, list, "cards")
        gtk_stack_add_named(stack, placeholder.root, "placeholder")

        root = vbox(spacing: 0, classes: ["wallet"], [stack.widget])
        gtk_widget_set_margin_bottom(root, 6)

        // Context menu: actions live on the wallet (`wallet.*`); the popover is a child of `root`.
        let group = g_simple_action_group_new()!
        let stringType = g_variant_type_new("s")
        selectAction = g_simple_action_new("select", stringType)!
        g_variant_type_free(stringType)
        rereadAction = g_simple_action_new("reread", nil)!
        g_action_map_add_action(group.opaque, selectAction)
        g_action_map_add_action(group.opaque, rereadAction)
        gtk_widget_insert_action_group(root, "wallet", group.opaque)
        g_object_unref(group.raw)
        popover = gtk_popover_menu_new_from_model(nil)!
        gtk_widget_set_parent(popover, root)

        onSignal(selectAction, "activate") { [weak self] value in
            guard let value else { return }
            self?.controller.selectCard(String(cString: g_variant_get_string(OpaquePointer(value), nil)))
        }
        onSignal(rereadAction, "activate") { [weak self] _ in
            guard let self, let reader = self.menuReader else { return }
            self.controller.rereadCard(reader: reader)
        }

        let keys = gtk_event_controller_key_new()!
        onKeyPressed(keys) { [weak self] keyval, modifiers in self?.keyPressed(keyval, modifiers) ?? false }
        gtk_widget_add_controller(root, keys)

        // the placeholders follow light/dark (the ID-card face has fixed colors)
        if let manager = adw_style_manager_get_default() {
            onSignal(manager, "notify::dark") { [weak self] _ in self?.placeholder.redraw() }
        }

        controller.observe { [weak self] in self?.render() }
    }

    /// Narrow windows: 260 × 164 cards instead of 340 × 214.
    func setCompact(_ on: Bool) {
        guard on != compact else { return }
        compact = on
        items.forEach { $0.setCompact(on) }
        placeholder.setCompact(on)
        render()
    }

    // MARK: - Rendering

    private func render() {
        let c = controller
        let cards = c.cards

        guard !cards.isEmpty else {
            if !items.isEmpty { rebuild([]) }
            expanded = false
            lastSelected = nil
            placeholder.show(status: c.status, retry: { [weak self] in self?.controller.retryCard() })
            gtk_stack_set_visible_child_name(stack, "placeholder")
            return
        }

        if cards.map(\.key) != keys { rebuild(cards) }
        if cards.count < 2 { expanded = false }
        gtk_stack_set_visible_child_name(stack, "cards")
        layout(animated: false)

        let selected = c.selectedCard?.reader
        if let selected, let previous = lastSelected, selected != previous, gtk_widget_get_mapped(root) != 0,
           let holder = c.selectedCard?.certificate?.holder {
            announce(root, "Semnezi cu cardul \(holder)")
        }
        lastSelected = selected
    }

    /// Faces, disclosure, outline and which cards are revealed. `animated`: the user expanded or collapsed the list
    /// (a selection change while collapsed swaps the card without a slide).
    private func layout(animated: Bool) {
        let cards = controller.cards
        let selected = controller.selectedCard?.reader
        let busy = controller.isSigning || controller.bridgeSigning
        for (index, (item, card)) in zip(items, cards).enumerated() {
            let isSelected = card.reader == selected
            item.update(card, index: index, count: cards.count, busy: busy && isSelected,
                        selected: isSelected, expanded: expanded)
            item.setRevealed(expanded || isSelected, animated: animated)
        }
    }

    private func setExpanded(_ on: Bool) {
        guard on != expanded, controller.cards.count > 1 || !on else { return }
        expanded = on
        layout(animated: true)
        if !on, let item = items.first(where: { $0.reader == controller.selectedCard?.reader }) {
            gtk_widget_grab_focus(item.button)
        }
    }

    /// The set of inserted cards changed: one item per card, in reader order.
    private func rebuild(_ cards: [CardSlot]) {
        for item in items { gtk_box_remove(list.cast(), item.root) }
        items = cards.map { card in
            let item = CardItem(reader: card.reader, compact: compact)
            onSignal(item.button, "clicked") { [weak self] in self?.cardClicked(card.reader) }
            onSignal(item.disclosure, "clicked") { [weak self] in
                guard let self else { return }
                self.setExpanded(!self.expanded)
            }
            item.onMenu = { [weak self, weak item] x, y in
                guard let self, let item else { return }
                self.openMenu(for: item, x: x, y: y)
            }
            append(list, item.root)
            return item
        }
        keys = cards.map(\.key)
    }

    /// Expanded: pick this card (or keep the selected one) and collapse. Collapsed: open the Card page.
    private func cardClicked(_ reader: String) {
        if expanded {
            if reader != controller.selectedCard?.reader { controller.selectCard(reader) }   // updates synchronously
            setExpanded(false)
        } else {
            _ = gtk_widget_activate_action_variant(root, "app.page", g_variant_new_string("card"))
        }
    }

    // MARK: - Keyboard (collapsed ←/→ Home/End switch cards; expanded ↑/↓ move, Escape collapses; Menu / Shift+F10)

    private func keyPressed(_ keyval: UInt32, _ modifiers: UInt32) -> Bool {
        guard !items.isEmpty else { return false }
        switch keyval {
        case 0xff67:                                     // Menu
            return openMenuForFocusedCard()
        case 0xffc7 where modifiers & 1 != 0:            // Shift+F10
            return openMenuForFocusedCard()
        default:
            break
        }
        if expanded {
            let focused = items.firstIndex { gtk_widget_has_focus($0.button) != 0 || gtk_widget_has_focus($0.disclosure) != 0 }
            switch keyval {
            case 0xff1b:                                 // Escape
                setExpanded(false)
                return true
            case 0xff52, 0xff97:                         // Up, KP_Up
                guard let index = focused, index > 0 else { return true }
                gtk_widget_grab_focus(items[index - 1].button)
                return true
            case 0xff54, 0xff99:                         // Down, KP_Down
                let next = focused.map { $0 + 1 } ?? 0
                guard next < items.count else { return true }
                gtk_widget_grab_focus(items[next].button)
                return true
            default:
                return false
            }
        }
        let current = items.firstIndex { $0.reader == controller.selectedCard?.reader } ?? 0
        var target: Int?
        switch keyval {
        case 0xff51, 0xff96: target = current - 1        // Left, KP_Left
        case 0xff53, 0xff98: target = current + 1        // Right, KP_Right
        case 0xff50, 0xff95: target = 0                  // Home, KP_Home
        case 0xff57, 0xff9c: target = items.count - 1    // End, KP_End
        default: return false
        }
        guard let index = target, items.indices.contains(index) else { return true }   // at the edge: swallow
        controller.selectCard(items[index].reader)
        layout(animated: false)
        gtk_widget_grab_focus(items[index].button)
        return true
    }

    private func openMenuForFocusedCard() -> Bool {
        guard let item = items.first(where: { gtk_widget_has_focus($0.button) != 0 }) else { return false }
        openMenu(for: item, x: nil, y: nil)
        return true
    }

    // MARK: - Context menu ("Recitește cardul", the other cards as "Semnează cu {holder}")

    private func openMenu(for item: CardItem, x: Double?, y: Double?) {
        menuReader = item.reader
        let menu = g_menu_new()
        let this = g_menu_new()
        g_menu_append(this, "Recitește cardul", "wallet.reread")
        g_menu_append_section(menu, nil, this?.cast())
        let others = g_menu_new()
        for card in controller.cards where card.reader != controller.selectedCard?.reader {
            guard let holder = card.certificate?.holder else { continue }
            let entry = g_menu_item_new("Semnează cu \(holder)", nil)
            g_menu_item_set_action_and_target_value(entry, "wallet.select", g_variant_new_string(card.reader))
            g_menu_append_item(others, entry)
            g_object_unref(entry?.raw)
        }
        g_menu_append_section(menu, nil, others?.cast())
        gtk_popover_menu_set_menu_model(popover.opaque, menu?.cast())
        for model in [this, others, menu] { g_object_unref(model?.raw) }
        g_simple_action_set_enabled(rereadAction, controller.isSigning ? 0 : 1)

        var bounds = graphene_rect_t()
        guard gtk_widget_compute_bounds(item.button, root, &bounds) != 0 else { return }
        var rect: GdkRectangle
        if let x, let y {
            rect = GdkRectangle(x: Int32(Double(bounds.origin.x) + x), y: Int32(Double(bounds.origin.y) + y), width: 1, height: 1)
        } else {
            rect = GdkRectangle(x: Int32(bounds.origin.x), y: Int32(bounds.origin.y),
                                width: Int32(bounds.size.width), height: Int32(bounds.size.height))
        }
        gtk_popover_set_pointing_to(popover.cast(), &rect)
        gtk_popover_popup(popover.cast())
    }
}

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

    func update(_ card: CardSlot, index: Int, count: Int, busy: Bool, selected: Bool, expanded: Bool) {
        var next = face
        let cert = card.certificate
        next.surname = cert?.surname
        next.givenNames = cert?.givenNames
        next.validUntil = cert?.notAfter
        next.issuer = cert?.issuerName
        next.hueShift = CardArt.hueShift(sha1Hex: cert?.sha1Hex, fallback: card.reader)
        next.reservesDisclosure = count > 1
        next.chosen = selected && expanded
        if cert != nil {
            next.state = busy ? .busy : .ready
        } else if let problem = card.problem {
            next.state = .problem(problem)
        } else {
            next.state = .reading
        }
        if next != face {
            face = next
            gtk_widget_queue_draw(area)
        }

        // disclosure on the selected card (more than one card); outline (and the blue status strip) while expanded
        setVisible(disclosure, selected && count > 1)
        gtk_button_set_icon_name(disclosure.cast(), expanded ? "pan-down-symbolic" : "pan-end-symbolic")
        setAccessibleLabel(disclosure, "Alege cardul (\(count) carduri)")
        setAccessibleState(disclosure, GTK_ACCESSIBLE_STATE_EXPANDED, expanded)
        gtk_widget_set_tooltip_text(disclosure, expanded ? "Închide lista" : "Alege cardul (\(count) carduri)")
        setClass(button, "chosen", selected && expanded)

        // accessibility: collapsed, one element "{holder}, card de identitate, valabil până la …, {i} din {n}";
        // expanded, each card is a button "Semnează cu {holder}" and the selected one reports selected
        let holder = cert?.holder
        if expanded {
            setAccessibleLabel(button, holder.map { "Semnează cu \($0)" } ?? "Card din \(card.reader)")
            setAccessibleState(button, GTK_ACCESSIBLE_STATE_SELECTED, selected)
            gtk_widget_set_tooltip_text(button, selected ? "Folosit pentru semnare" : holder.map { "Semnează cu \($0)" })
            return
        }
        var parts: [String]
        switch next.state {
        case .ready, .busy:
            parts = ["\(holder ?? "—"), card de identitate"]
            if let until = cert?.notAfter { parts.append("valabil până la \(Format.monthYear(until))") }
            parts.append(next.state == .busy ? "se semnează" : "pregătit pentru semnare")
        case .reading:
            parts = ["Card de identitate în \(card.reader)", "se citește"]
        case .problem(let problem):
            parts = ["Card de identitate în \(card.reader)", problem, "scoate și reintrodu cardul"]
        }
        if count > 1 { parts.append("\(index + 1) din \(count)") }
        setAccessibleLabel(button, parts.joined(separator: ", "))
        setAccessibleState(button, GTK_ACCESSIBLE_STATE_SELECTED, false)
        gtk_widget_set_tooltip_text(button, count > 1 ? "Detalii card · ←/→ schimbă cardul" : "Detalii card")
    }
}

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
            let retryButton = button("Reîncearcă", classes: ["pill", "small-pill"]) {}
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
            titleText = "Introdu cardul"
            captionText = reader
        default:
            next = .noReader
            titleText = "Conectează cititorul"
            captionText = "Cititor USB de carduri (de ex. bit4id miniLector)"
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
