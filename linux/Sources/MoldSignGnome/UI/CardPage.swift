import CAdwaita
import Foundation

/// docs/10 §4.2 "Card": holder, issuer, validity, serial, SHA-1; stored PIN; troubleshooting (LNX-09).
final class CardPage {
    let root: Widget
    private let controller: AppController
    private let header = StatusHeader(icon: "auth-smartcard-symbolic")   // card glyph + holder + state
    private let retry: Widget
    private let selector: CardSelector
    private let selectorGroup: Widget
    private let certGroup: Widget
    private let issuerRow: Widget
    private let validRow: Widget
    private let serialRow: Widget
    private let sha1Row: Widget
    private let pinGroup: Widget
    private let pinRow: Widget
    private let forget: Widget

    init(controller: AppController) {
        self.controller = controller

        // after removing/swapping a card, or when a read failed: read every inserted card again
        retry = button("Recitește cardul", classes: ["pill"]) { controller.retryCard() }
        gtk_widget_set_halign(retry, GTK_ALIGN_CENTER)
        gtk_widget_set_tooltip_text(retry, "Citește din nou cardurile din cititoare (după ce ai scos sau schimbat un card)")
        append(header.root, retry)

        // several eID cards connected: pick the one to sign with
        selector = CardSelector(controller: controller, style: .row)
        selectorGroup = preferencesGroup(title: nil)
        let selectorList = boxedList()
        gtk_list_box_append(selectorList.opaque, selector.root)
        groupAdd(selectorGroup, selectorList)

        certGroup = preferencesGroup(title: "Certificat de semnătură")
        let certList = boxedList()
        issuerRow = actionRow(title: "Emitent", subtitleSelectable: true)
        validRow = actionRow(title: "Valabil până la")
        serialRow = actionRow(title: "Număr de serie", subtitleSelectable: true)
        sha1Row = actionRow(title: "Amprentă SHA-1", subtitleSelectable: true)
        addClasses(sha1Row, ["monospace-subtitle"])
        for row in [issuerRow, validRow, serialRow, sha1Row] {
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

        let content = vbox(spacing: 24, [header.root, selectorGroup, certGroup, pinGroup, tips])
        gtk_widget_set_margin_bottom(content, 24)
        gtk_widget_set_margin_start(content, 24)
        gtk_widget_set_margin_end(content, 24)
        root = scrolledPage(content)

        controller.observe { [weak self] in self?.render() }
    }

    private func render() {
        let c = controller
        let status = c.status
        header.set(title: c.certificate?.holder ?? status.title,
                   body: [status.subtitle, status.validityText].compactMap { $0 }.joined(separator: "\n"))
        setClass(header.icon, "dim-label", !status.cardPresent)
        setClass(header.icon, "accent", status.cardPresent)
        setVisible(retry, !c.cards.isEmpty || { if case .error = status { return true }; return false }())
        selector.render()
        setVisible(selectorGroup, c.cards.count > 1)

        guard let cert = c.certificate else {
            setVisible(certGroup, false)
            setVisible(pinGroup, false)
            return
        }
        setVisible(certGroup, true)
        setVisible(pinGroup, true)
        let issuerCN = cert.issuerName
        adw_action_row_set_subtitle(issuerRow.cast(), escapeMarkup(issuerCN))
        adw_action_row_set_subtitle(validRow.cast(), cert.notAfter.map(Format.longDate) ?? "—")
        adw_action_row_set_subtitle(serialRow.cast(), escapeMarkup(cert.serialDecimal))
        adw_action_row_set_subtitle(sha1Row.cast(), cert.sha1Hex)

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
