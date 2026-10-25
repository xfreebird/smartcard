import CAdwaita
import Foundation

/// docs/10 §4.2 + §0 "Card" (LNX-09, UX-02, UX-07): the card wallet (pick the card here as well), then the selected
/// card's certificate, its stored PIN and troubleshooting. No card: an `AdwStatusPage` whose illustration is the
/// placeholder card (empty states are cards too) with a re-read action.
final class CardPage {
    let root: Widget
    let wallet: CardWallet
    private let controller: AppController
    private let stack: OpaquePointer
    private let empty: Widget
    private let emptyArt = PlaceholderCard(showsText: false)
    private let emptyRetry: Widget
    private let certGroup: Widget
    private let issuerRow: Widget
    private let validRow: Widget
    private let serialRow: Widget
    private let sha1Row: Widget
    private let readerRow: Widget
    private let pinGroup: Widget
    private let pinRow: Widget
    private let forget: Widget

    init(controller: AppController) {
        self.controller = controller

        // Empty state
        emptyRetry = button("Recitește", classes: ["pill"]) { controller.retryCard() }
        gtk_widget_set_halign(emptyRetry, GTK_ALIGN_CENTER)
        gtk_widget_set_halign(emptyArt.root, GTK_ALIGN_CENTER)
        let emptyTips = adw_clamp_new()!
        adw_clamp_set_maximum_size(emptyTips.opaque, 600)
        adw_clamp_set_child(emptyTips.opaque, tipsGroup())
        gtk_widget_set_margin_top(emptyTips, 12)
        empty = adw_status_page_new()!
        adw_status_page_set_child(empty.opaque, vbox(spacing: 24, [emptyArt.root, emptyRetry, emptyTips]))
        addClasses(empty, ["card-empty"])

        // Cards
        wallet = CardWallet(controller: controller)

        certGroup = preferencesGroup(title: "Certificat de semnătură")
        let certList = boxedList()
        issuerRow = actionRow(title: "Emitent", subtitleSelectable: true)
        validRow = actionRow(title: "Valabil până la")
        serialRow = actionRow(title: "Număr de serie", subtitleSelectable: true)
        sha1Row = actionRow(title: "Amprentă SHA-1", subtitleSelectable: true)
        readerRow = actionRow(title: "Cititor", subtitleSelectable: true)
        addClasses(sha1Row, ["monospace-subtitle"])
        for row in [issuerRow, validRow, serialRow, sha1Row, readerRow] {
            addClasses(row, ["property"])
            gtk_list_box_append(certList.opaque, row)
        }
        groupAdd(certGroup, certList)

        pinGroup = preferencesGroup(title: "PIN", description: "Un PIN salvat se păstrează în GNOME Keyring, legat de acest card. " +
                                                              "Înainte de fiecare semnătură ți se cere confirmarea.")
        forget = button("Șterge PIN-ul salvat", classes: ["destructive-action"]) { controller.forgetPIN() }
        pinRow = actionRow(title: "", icon: "dialog-password-symbolic", suffix: [forget])
        let pinList = boxedList()
        gtk_list_box_append(pinList.opaque, pinRow)
        groupAdd(pinGroup, pinList)

        let content = vbox(spacing: 24, [certGroup, pinGroup, tipsGroup()])
        gtk_widget_set_margin_top(wallet.root, 12)
        gtk_widget_set_margin_top(content, 6)
        gtk_widget_set_margin_bottom(content, 24)
        gtk_widget_set_margin_start(content, 24)
        gtk_widget_set_margin_end(content, 24)

        stack = OpaquePointer(gtk_stack_new()!)
        gtk_stack_set_transition_type(stack, GTK_STACK_TRANSITION_TYPE_CROSSFADE)
        gtk_stack_add_named(stack, empty, "empty")
        gtk_stack_add_named(stack, scrolledPage(content, top: wallet.root), "cards")
        root = stack.widget

        controller.observe { [weak self] in self?.render() }
    }

    private func render() {
        let c = controller
        guard !c.cards.isEmpty else {
            let status = c.status
            emptyArt.show(status: status, retry: nil)
            let title: String
            let description: String
            switch status {
            case .empty(let reader):
                title = "Introdu cardul în cititor"
                description = "\(reader)\nCertificatul se citește fără PIN."
            case .error(let message, let recovery):
                title = message
                description = recovery
            default:
                title = "Conectează cititorul"
                description = "Un cititor USB de carduri (de ex. bit4id miniLector). Pe Linux, serviciul pcscd trebuie să ruleze."
            }
            adw_status_page_set_title(empty.opaque, escapeMarkup(title))
            adw_status_page_set_description(empty.opaque, escapeMarkup(description))
            setClass(empty, "error-state", { if case .error = status { return true }; return false }())
            gtk_stack_set_visible_child_name(stack, "empty")
            return
        }
        gtk_stack_set_visible_child_name(stack, "cards")

        guard let card = c.selectedCard, let cert = card.certificate else {
            setVisible(certGroup, false)
            setVisible(pinGroup, false)
            return
        }
        setVisible(certGroup, true)
        setVisible(pinGroup, true)
        adw_preferences_group_set_title(certGroup.cast(), escapeMarkup("Certificatul lui \(cert.holder)"))
        adw_action_row_set_subtitle(issuerRow.cast(), escapeMarkup(cert.issuerName))
        adw_action_row_set_subtitle(validRow.cast(), cert.notAfter.map(Format.longDate) ?? "—")
        adw_action_row_set_subtitle(serialRow.cast(), escapeMarkup(cert.serialDecimal))
        adw_action_row_set_subtitle(sha1Row.cast(), cert.sha1Hex)
        adw_action_row_set_subtitle(readerRow.cast(), escapeMarkup(card.reader))

        let pinText: String
        if let problem = c.vaultProblem {
            pinText = problem
        } else {
            pinText = c.hasStoredPIN ? "PIN-ul este salvat în GNOME Keyring" : "PIN-ul nu este salvat"
        }
        adw_preferences_row_set_title(pinRow.cast(), escapeMarkup(pinText))
        setVisible(forget, c.hasStoredPIN)
    }
}

/// "Probleme cu cardul?" (shown under the wallet and on the empty state).
private func tipsGroup() -> Widget {
    let tips = preferencesGroup(title: "Probleme cu cardul?")
    let tipsList = boxedList()
    let tipRows: [(String, String, String)] = [
        ("Semnarea eșuează repetat", "Scoate și reintrodu cardul, apoi încearcă din nou.", "view-refresh-symbolic"),
        ("PIN-ul nu se reîncearcă automat", "După 3 încercări greșite cardul se blochează.", "dialog-warning-symbolic"),
        ("PIN blocat", "Deblocarea PIN-ului se face la CEV.", "changes-prevent-symbolic"),
        ("Cititorul nu apare", "Pornește serviciul: sudo systemctl enable --now pcscd.socket (pachetele pcscd și libccid).",
         "auth-smartcard-symbolic"),
    ]
    for (title, subtitle, icon) in tipRows {
        gtk_list_box_append(tipsList.opaque, actionRow(title: title, subtitle: subtitle, icon: icon, subtitleSelectable: true))
    }
    groupAdd(tips, tipsList)
    return tips
}
