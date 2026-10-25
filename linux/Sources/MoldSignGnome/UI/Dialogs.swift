import CAdwaita
import Foundation

// AdwAlertDialog-based sheets (docs/10 §4.3): PIN, browser consent, stored-PIN confirmation.
// Each completion runs exactly once, on the main thread.

private func alert(heading: String, body: String?) -> UnsafeMutablePointer<AdwDialog> {
    let dialog = adw_alert_dialog_new(heading, nil)!
    if let body { adw_alert_dialog_set_body(dialog.cast(), body) }
    return dialog
}

private func addResponse(_ dialog: UnsafeMutablePointer<AdwDialog>, _ id: String, _ label: String,
                         _ appearance: AdwResponseAppearance = ADW_RESPONSE_DEFAULT) {
    adw_alert_dialog_add_response(dialog.cast(), id, label)
    adw_alert_dialog_set_response_appearance(dialog.cast(), id, appearance)
}

/// Calls `handler` with the response id once (button, Escape → close response).
private func onResponse(_ dialog: UnsafeMutablePointer<AdwDialog>, _ handler: @escaping (String) -> Void) {
    var done = false
    onSignal(dialog, "response") { response in
        guard !done else { return }
        done = true
        handler(response.map { String(cString: $0.assumingMemoryBound(to: CChar.self)) } ?? "")
    }
}

// MARK: - PIN (PinField: 4–8 digits, remaining attempts, optional "remember")

func presentPINDialog(parent: Widget, request: PinRequest, completion: @escaping (PinEntry?) -> Void) {
    let dialog = alert(heading: "PIN QSCD", body: request.purpose)
    addResponse(dialog, "cancel", "Anulează")
    addResponse(dialog, "sign", "Semnează", ADW_RESPONSE_SUGGESTED)
    adw_alert_dialog_set_default_response(dialog.cast(), "sign")
    adw_alert_dialog_set_close_response(dialog.cast(), "cancel")
    adw_alert_dialog_set_response_enabled(dialog.cast(), "sign", 0)

    let content = vbox(spacing: 12)
    let entry = gtk_password_entry_new()!
    addClasses(entry, ["pin-entry"])
    gtk_editable_set_alignment(entry.opaque, 0.5)
    gtk_editable_set_max_width_chars(entry.opaque, 8)
    setProperty(entry, "activates-default", bool: true)   // Enter = "Semnează" (when enabled)
    setProperty(entry, "placeholder-text", string: "4–8 cifre")
    setAccessibleLabel(entry, "PIN QSCD")
    append(content, entry)

    if let left = request.attemptsLeft {
        let line = hbox(spacing: 6, [image("dialog-warning-symbolic"), label("Încercări rămase: \(left)")])
        gtk_widget_set_halign(line, GTK_ALIGN_CENTER)
        addClasses(line, [left <= 2 ? "warning" : "dim-label"])
        append(content, line)
    }

    var rememberRow: Widget?
    if request.canRemember {
        let list = boxedList()
        let row = adw_switch_row_new()!
        adw_preferences_row_set_title(row.cast(), "Ține minte PIN-ul")
        adw_action_row_set_subtitle(row.cast(), "În GNOME Keyring, doar pentru acest card")
        gtk_list_box_append(list.opaque, row)
        append(content, list)
        rememberRow = row
    } else if let problem = request.vaultProblem {
        append(content, label("PIN-ul nu poate fi salvat: \(problem)", classes: ["dim-label", "caption"], xalign: 0.5, wrap: true))
    }
    adw_alert_dialog_set_extra_child(dialog.cast(), content)

    // Digits only, at most 8; "Semnează" enabled for 4–8 digits.
    var filtering = false
    onSignal(entry, "changed") {
        guard !filtering else { return }
        let text = String(cString: gtk_editable_get_text(entry.opaque))
        let digits = String(text.filter(\.isASCII).filter(\.isNumber).prefix(8))
        if digits != text {
            filtering = true
            gtk_editable_set_text(entry.opaque, digits)
            gtk_editable_set_position(entry.opaque, -1)
            filtering = false
        }
        adw_alert_dialog_set_response_enabled(dialog.cast(), "sign", (4...8).contains(digits.count) ? 1 : 0)
    }

    onResponse(dialog) { response in
        let pin = String(cString: gtk_editable_get_text(entry.opaque))
        gtk_editable_set_text(entry.opaque, "")
        guard response == "sign", (4...8).contains(pin.count) else { return completion(nil) }
        let remember = rememberRow.map { adw_switch_row_get_active($0.opaque) != 0 } ?? false
        completion(PinEntry(pin: pin, remember: remember))
    }
    adw_dialog_set_focus(dialog, entry)
    adw_dialog_present(dialog, parent)
}

// MARK: - Consent (ConsentSheet, SEC-02)

func presentConsentDialog(parent: Widget, consent: ConsentRequest, completion: @escaping (_ approved: Bool, _ trust: Bool) -> Void) {
    let request = consent.request
    let operation: String
    switch request.operation {
    case .signPDF: operation = "Semnarea unui document PDF"
    case .signFile: operation = "Semnarea unor fișiere de pe acest calculator"
    case .signData: operation = "Semnarea unor date trimise de pagină"
    }
    let dialog = alert(heading: "\(consent.originHost) solicită o semnătură", body: operation)
    addResponse(dialog, "deny", "Refuză")
    addResponse(dialog, "sign", "Semnează", ADW_RESPONSE_SUGGESTED)
    adw_alert_dialog_set_default_response(dialog.cast(), "sign")
    adw_alert_dialog_set_close_response(dialog.cast(), "deny")

    let list = boxedList()
    gtk_list_box_append(list.opaque, actionRow(title: request.documentName ?? "Date de semnat",
                                               subtitle: request.format ?? "Semnătură electronică calificată",
                                               icon: "x-office-document-symbolic"))
    gtk_list_box_append(list.opaque, actionRow(title: consent.holder, subtitle: "Certificat MDQSign",
                                               icon: "auth-smartcard-symbolic"))
    if request.pinIncluded {
        gtk_list_box_append(list.opaque, actionRow(title: "PIN introdus pe pagină", icon: "dialog-password-symbolic"))
    }
    let trust = adw_switch_row_new()!
    adw_preferences_row_set_title(trust.cast(), "Ai încredere în site 10 minute")
    gtk_list_box_append(list.opaque, trust)
    adw_alert_dialog_set_extra_child(dialog.cast(), list)

    onResponse(dialog) { response in
        completion(response == "sign", response == "sign" && adw_switch_row_get_active(trust.opaque) != 0)
    }
    adw_dialog_present(dialog, parent)
}

// MARK: - Confirmation (stored PIN: the consent step before a local signature)

func presentConfirmDialog(parent: Widget, heading: String, body: String, action: String, completion: @escaping (Bool) -> Void) {
    let dialog = alert(heading: heading, body: body)
    addResponse(dialog, "cancel", "Anulează")
    addResponse(dialog, "ok", action, ADW_RESPONSE_SUGGESTED)
    adw_alert_dialog_set_default_response(dialog.cast(), "ok")
    adw_alert_dialog_set_close_response(dialog.cast(), "cancel")
    onResponse(dialog) { completion($0 == "ok") }
    adw_dialog_present(dialog, parent)
}

// MARK: - Clear the activity list

func presentClearActivityDialog(parent: Widget, completion: @escaping (Bool) -> Void) {
    let dialog = alert(heading: "Golești lista?", body: "Se șterge doar istoricul din aplicație. Documentele semnate rămân pe disc.")
    addResponse(dialog, "cancel", "Anulează")
    addResponse(dialog, "clear", "Golește lista", ADW_RESPONSE_DESTRUCTIVE)
    adw_alert_dialog_set_default_response(dialog.cast(), "cancel")
    adw_alert_dialog_set_close_response(dialog.cast(), "cancel")
    onResponse(dialog) { completion($0 == "clear") }
    adw_dialog_present(dialog, parent)
}

// MARK: - Preferences (AdwPreferencesDialog)

func presentPreferences(parent: Widget, controller: AppController) {
    let dialog = adw_preferences_dialog_new()!
    let page = adw_preferences_page_new()!
    adw_preferences_page_set_title(page.cast(), "General")
    adw_preferences_page_set_icon_name(page.cast(), "preferences-system-symbolic")

    let bridge = preferencesGroup(title: "Conexiune browser",
                                  description: "Permite site-urilor guvernamentale (de ex. msign.gov.md) să ceară semnături, " +
                                               "la fel ca MoldSign Desktop. Fiecare cerere îți cere acordul.")
    let bridgeRow = adw_switch_row_new()!
    adw_preferences_row_set_title(bridgeRow.cast(), "Conexiune browser")
    groupAdd(bridge, bridgeRow)
    let retry = button("Repornește", classes: ["flat"]) { controller.restartBridge() }
    gtk_widget_set_valign(retry, GTK_ALIGN_CENTER)
    adw_action_row_add_suffix(bridgeRow.cast(), retry)

    let background = preferencesGroup(title: "Fundal")
    let backgroundRow = adw_switch_row_new()!
    adw_preferences_row_set_title(backgroundRow.cast(), "Rulează în fundal")
    adw_action_row_set_subtitle(backgroundRow.cast(), "După închiderea ferestrei, conexiunea browser rămâne activă")
    groupAdd(background, backgroundRow)
    // TODO(LNX-12): "Pornește la autentificare" via the Background portal (RequestBackground autostart)
    // in Flatpak, or an XDG autostart entry outside the sandbox.

    adw_preferences_page_add(page.cast(), bridge.cast())
    adw_preferences_page_add(page.cast(), background.cast())
    adw_preferences_dialog_add(dialog.cast(), page.cast())

    var updating = false
    let token = controller.observe {
        updating = true
        adw_switch_row_set_active(bridgeRow.opaque, controller.settings.bridgeEnabled ? 1 : 0)
        adw_action_row_set_subtitle(bridgeRow.cast(), escapeMarkup(controller.bridgeState.description))
        setVisible(retry, controller.settings.bridgeEnabled && controller.bridgeState != .running)
        adw_switch_row_set_active(backgroundRow.opaque, controller.settings.runInBackground ? 1 : 0)
        updating = false
    }
    onSignal(bridgeRow, "notify::active") { _ in
        guard !updating else { return }
        controller.setBridgeEnabled(adw_switch_row_get_active(bridgeRow.opaque) != 0)
    }
    onSignal(backgroundRow, "notify::active") { _ in
        guard !updating else { return }
        controller.setRunInBackground(adw_switch_row_get_active(backgroundRow.opaque) != 0)
    }
    onSignal(dialog, "closed") { controller.unobserve(token) }
    adw_dialog_present(dialog, parent)
}

// MARK: - About

func presentAbout(parent: Widget) {
    let about = adw_about_dialog_new()!
    adw_about_dialog_set_application_name(about.opaque, "eSemnBun")
    adw_about_dialog_set_application_icon(about.opaque, "md.moldsign.MoldSign")
    adw_about_dialog_set_version(about.opaque, "0.2.0")
    adw_about_dialog_set_comments(about.opaque,
        "Semnătură electronică cu buletinul de identitate al Republicii Moldova (card IDEMIA CosmoX ID-A), " +
        "PAdES și XAdES, și conexiunea browser pentru msign.gov.md.")
    adw_dialog_present(about, parent)
}
