import CAdwaita
import Foundation

/// Which inserted card to sign with; hidden unless several eID cards are connected.
/// `.row` = AdwComboRow (Card page), `.dropDown` = compact GtkDropDown (Sign page footer).
final class CardSelector {
    enum Style { case row, dropDown }

    let root: Widget
    private let style: Style
    private let controller: AppController
    private var readers: [String] = []
    private var labels: [String] = []
    private var updating = false

    init(controller: AppController, style: Style) {
        self.controller = controller
        self.style = style
        switch style {
        case .row:
            root = adw_combo_row_new()
            adw_preferences_row_set_title(root.cast(), "Cardul folosit")
            adw_action_row_set_subtitle(root.cast(), "Mai multe carduri sunt conectate")
        case .dropDown:
            root = withCStringArray([]) { gtk_drop_down_new_from_strings($0) }
            gtk_widget_set_valign(root, GTK_ALIGN_CENTER)
            gtk_widget_set_tooltip_text(root, "Cardul cu care semnezi")
        }
        setAccessibleLabel(root, "Alege cardul cu care semnezi")
        setVisible(root, false)
        onSignal(root, "notify::selected") { [weak self] _ in self?.picked() }
    }

    /// Rebuilds the list only when readers or holder names changed; keeps the selection in sync.
    func render() {
        let cards = controller.cards
        setVisible(root, cards.count > 1)
        let newReaders = cards.map(\.reader)
        let newLabels = cards.map { card in
            card.certificate?.holder ?? (card.problem != nil ? "Card necitit · \(card.reader)" : "Se citește…")
        }
        updating = true
        defer { updating = false }
        if newReaders != readers || newLabels != labels {
            readers = newReaders
            labels = newLabels
            let model = withCStringArray(newLabels) { gtk_string_list_new($0) }
            switch style {
            case .row: adw_combo_row_set_model(root.cast(), model)
            case .dropDown: gtk_drop_down_set_model(root.opaque, model)
            }
            if let model { g_object_unref(UnsafeMutableRawPointer(model)) }
        }
        guard let reader = controller.selectedCard?.reader, let index = readers.firstIndex(of: reader) else { return }
        switch style {
        case .row:
            if adw_combo_row_get_selected(root.cast()) != guint(index) { adw_combo_row_set_selected(root.cast(), guint(index)) }
        case .dropDown:
            if gtk_drop_down_get_selected(root.opaque) != guint(index) { gtk_drop_down_set_selected(root.opaque, guint(index)) }
        }
    }

    private func picked() {
        guard !updating else { return }
        let selected: guint
        switch style {
        case .row: selected = adw_combo_row_get_selected(root.cast())
        case .dropDown: selected = gtk_drop_down_get_selected(root.opaque)
        }
        let index = Int(selected)
        guard index < readers.count else { return }
        controller.selectCard(readers[index])
    }
}
