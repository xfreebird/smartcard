import CAdwaita
import Foundation

/// Horizontally scrollable card selector. Every inserted card remains discoverable, with
/// an accent outline on the signing card. Mouse/touch scrolling and arrow keys select cards.
final class CardWallet {
    let root: Widget
    private let controller: AppController
    private let stack: OpaquePointer
    private let list: Widget
    private let carousel: Widget
    private let previousButton: Widget
    private let nextButton: Widget
    private var hovering = false
    private let pageDots: Widget
    private let leadingSpace: Widget
    private let trailingSpace: Widget
    private var centeredReader: String?
    private var viewportWidth: Int32 = 0
    private var centerAfterFrames = 0
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

        list = hbox(spacing: 12, classes: ["wallet-list"])
        leadingSpace = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0)!
        trailingSpace = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0)!
        _ = g_object_ref_sink(leadingSpace.raw)
        _ = g_object_ref_sink(trailingSpace.raw)
        gtk_widget_set_halign(list, GTK_ALIGN_CENTER)
        setAccessibleLabel(list, L10n.text(.linux_signing_card))

        placeholder = PlaceholderCard()
        gtk_widget_set_halign(placeholder.root, GTK_ALIGN_CENTER)
        gtk_widget_set_margin_top(placeholder.root, CardItem.margin.top)
        gtk_widget_set_margin_bottom(placeholder.root, CardItem.margin.bottom)

        stack = OpaquePointer(gtk_stack_new()!)
        gtk_stack_set_transition_type(stack, GTK_STACK_TRANSITION_TYPE_CROSSFADE)
        gtk_stack_set_vhomogeneous(stack, 0)
        gtk_stack_set_interpolate_size(stack, 1)
        carousel = gtk_scrolled_window_new()!
        // Show a complete card in the centered viewport; dots select the other cards.
        gtk_widget_set_margin_start(carousel, 24)
        gtk_widget_set_margin_end(carousel, 24)
        gtk_widget_set_halign(carousel, GTK_ALIGN_CENTER)
        gtk_scrolled_window_set_policy(carousel.opaque, GTK_POLICY_AUTOMATIC, GTK_POLICY_NEVER)
        gtk_scrolled_window_set_propagate_natural_width(carousel.opaque, 1)
        gtk_scrolled_window_set_max_content_width(carousel.opaque, 444)
        gtk_scrolled_window_set_min_content_width(carousel.opaque, 444)
        gtk_scrolled_window_set_propagate_natural_height(carousel.opaque, 1)
        gtk_scrolled_window_set_child(carousel.opaque, list)
        let cardOverlay = gtk_overlay_new()!
        gtk_widget_set_halign(cardOverlay, GTK_ALIGN_CENTER)
        gtk_overlay_set_child(cardOverlay.opaque, carousel)
        previousButton = gtk_button_new_from_icon_name("go-previous-symbolic")!
        nextButton = gtk_button_new_from_icon_name("go-next-symbolic")!
        for (button, alignment, title) in [(previousButton, GTK_ALIGN_START, L10n.text(.ui_previous_card)),
                                            (nextButton, GTK_ALIGN_END, L10n.text(.ui_next_card))] {
            addClasses(button, ["circular", "card-disclosure"])
            gtk_widget_set_halign(button, alignment)
            gtk_widget_set_valign(button, GTK_ALIGN_CENTER)
            gtk_widget_set_margin_start(button, 20)
            gtk_widget_set_margin_end(button, 20)
            gtk_widget_set_size_request(button, 32, 32)
            setAccessibleLabel(button, title)
            setVisible(button, false)
            gtk_overlay_add_overlay(cardOverlay.opaque, button)
        }
        gtk_stack_add_named(stack, cardOverlay, "cards")
        gtk_stack_add_named(stack, placeholder.root, "placeholder")

        pageDots = hbox(spacing: 0)
        gtk_widget_set_halign(pageDots, GTK_ALIGN_CENTER)
        gtk_widget_set_margin_top(pageDots, 2)
        gtk_widget_set_margin_bottom(pageDots, 2)
        root = vbox(spacing: 0, classes: ["wallet"], [stack.widget, pageDots])
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

        let motion = gtk_event_controller_motion_new()!
        onMotionEnter(motion) { [weak self] in self?.hovering = true; self?.updateArrows() }
        onSignal(motion, "leave") { [weak self] in self?.hovering = false; self?.updateArrows() }
        gtk_widget_add_controller(cardOverlay, motion)
        onSignal(previousButton, "clicked") { [weak self] in self?.selectAdjacent(-1) }
        onSignal(nextButton, "clicked") { [weak self] in self?.selectAdjacent(1) }

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

        onFrame(root) { [weak self] in self?.centerSelection() }
        controller.observe { [weak self] in self?.render() }
    }

    deinit {
        g_object_unref(leadingSpace.raw)
        g_object_unref(trailingSpace.raw)
    }

    /// Narrow windows use compact cards.
    func setCompact(_ on: Bool) {
        guard on != compact else { return }
        compact = on
        viewportWidth = 0
        let width = on
            ? CardArt.compact.width + 2 * CardItem.margin.start
            : 444
        // Clear the old minimum before lowering the maximum when the window narrows.
        gtk_scrolled_window_set_min_content_width(carousel.opaque, -1)
        gtk_scrolled_window_set_max_content_width(carousel.opaque, width)
        gtk_scrolled_window_set_min_content_width(carousel.opaque, width)
        items.forEach { $0.setCompact(on) }
        placeholder.setCompact(on)
        render()
    }

    // MARK: - Rendering

    private func render() {
        let c = controller
        let cards = c.cards
        while let child = gtk_widget_get_first_child(pageDots) { gtk_box_remove(pageDots.cast(), child) }
        setVisible(pageDots, cards.count > 1)
        if cards.count > 1 {
            for card in cards {
                let dot = gtk_button_new_with_label("●")!
                addClasses(dot, ["flat", card.reader == c.selectedCard?.reader ? "accent" : "dim-label"])
                addClasses(dot, ["wallet-dot"])
                setAccessibleLabel(dot, card.certificate?.holder ?? card.reader)
                onSignal(dot, "clicked") { [weak self] in self?.controller.selectCard(card.reader) }
                gtk_box_append(pageDots.cast(), dot)
            }
        }
        updateArrows()

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
            announce(root, localized(.ui_signing_with_the_card_of_value, holder))
        }
        lastSelected = selected
    }

    private func updateArrows() {
        let cards = controller.cards
        let index = cards.firstIndex { $0.reader == controller.selectedCard?.reader } ?? 0
        let show = hovering && cards.count > 1
        setVisible(previousButton, show)
        setVisible(nextButton, show)
        setSensitive(previousButton, index > 0 && !controller.isSigning && !controller.bridgeSigning)
        setSensitive(nextButton, index + 1 < cards.count && !controller.isSigning && !controller.bridgeSigning)
    }

    private func selectAdjacent(_ delta: Int) {
        let cards = controller.cards
        guard !controller.isSigning, !controller.bridgeSigning,
              let current = cards.firstIndex(where: { $0.reader == controller.selectedCard?.reader }) else { return }
        let next = current + delta
        guard cards.indices.contains(next) else { return }
        controller.selectCard(cards[next].reader)
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
                        selected: isSelected, expanded: true)
            item.setRevealed(true, animated: false)
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

    private func centerSelection() {
        guard let selected = controller.selectedCard?.reader,
              let item = items.first(where: { $0.reader == selected }) else { return }
        let width = gtk_widget_get_width(carousel)
        guard width > 0 else { return }
        if viewportWidth != width || centeredReader != selected {
            viewportWidth = width
            centeredReader = selected
            let cardWidth = compact ? CardArt.compact.width : CardArt.large.width
            let inset = max(0, (width - cardWidth) / 2 - 12 - CardItem.margin.start)
            gtk_widget_set_size_request(leadingSpace, inset, 1)
            gtk_widget_set_size_request(trailingSpace, inset, 1)
            centerAfterFrames = 2
        }
        guard centerAfterFrames > 0 else { return }
        centerAfterFrames -= 1
        guard centerAfterFrames == 0 else { return }
        var bounds = graphene_rect_t()
        guard gtk_widget_compute_bounds(item.root, list, &bounds) != 0 else { return }
        let adjustment = gtk_scrolled_window_get_hadjustment(carousel.opaque)!
        let desired = Double(bounds.origin.x + bounds.size.width / 2) - Double(width) / 2
        let maximum = max(0, gtk_adjustment_get_upper(adjustment) - gtk_adjustment_get_page_size(adjustment))
        gtk_adjustment_set_value(adjustment, min(maximum, max(0, desired)))
    }

    /// The set of inserted cards changed: one item per card, in reader order.
    private func rebuild(_ cards: [CardSlot]) {
        for item in items { gtk_box_remove(list.cast(), item.root) }
        if gtk_widget_get_parent(leadingSpace) != nil { gtk_box_remove(list.cast(), leadingSpace) }
        if gtk_widget_get_parent(trailingSpace) != nil { gtk_box_remove(list.cast(), trailingSpace) }
        append(list, leadingSpace)
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
        append(list, trailingSpace)
        centeredReader = nil
        keys = cards.map(\.key)
    }

    /// Expanded: pick this card (or keep the selected one) and collapse. Collapsed: open the Card page.
    private func cardClicked(_ reader: String) {
        if reader != controller.selectedCard?.reader {
            controller.selectCard(reader)
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
        g_menu_append(this, L10n.text(.ui_read_the_card_again), "wallet.reread")
        g_menu_append_section(menu, nil, this?.cast())
        let others = g_menu_new()
        for card in controller.cards where card.reader != controller.selectedCard?.reader {
            guard let holder = card.certificate?.holder else { continue }
            let entry = g_menu_item_new(localized(.linux_sign_with_holder, holder), nil)
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
