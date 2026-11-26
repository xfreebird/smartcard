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
    let dialog = alert(heading: L10n.text(.ui_qscd_pin), body: request.purpose)
    addResponse(dialog, "cancel", L10n.text(.ui_cancel))
    addResponse(dialog, "sign", L10n.text(.ui_sign), ADW_RESPONSE_SUGGESTED)
    adw_alert_dialog_set_default_response(dialog.cast(), "sign")
    adw_alert_dialog_set_close_response(dialog.cast(), "cancel")
    adw_alert_dialog_set_response_enabled(dialog.cast(), "sign", 0)

    let content = vbox(spacing: 18)
    gtk_widget_set_margin_top(content, 12)
    gtk_widget_set_margin_bottom(content, 12)
    let entry = gtk_password_entry_new()!
    addClasses(entry, ["pin-entry"])
    gtk_editable_set_alignment(entry.opaque, 0.5)
    gtk_editable_set_max_width_chars(entry.opaque, 12)
    gtk_widget_set_size_request(entry, 320, 64)
    gtk_widget_set_halign(entry, GTK_ALIGN_CENTER)
    setProperty(entry, "activates-default", bool: true)   // Enter = "Semnează" (when enabled)
    setProperty(entry, "placeholder-text", string: L10n.text(.ui_48_digits))
    setAccessibleLabel(entry, L10n.text(.ui_qscd_pin))
    append(content, entry)

    if let left = request.attemptsLeft {
        let line = hbox(spacing: 6, [image("dialog-warning-symbolic"), label(localized(.ui_attempts_remaining_value, String(left)))])
        gtk_widget_set_halign(line, GTK_ALIGN_CENTER)
        addClasses(line, [left <= 2 ? "warning" : "dim-label"])
        append(content, line)
    }

    var rememberRow: Widget?
    if request.canRemember {
        let list = boxedList()
        let row = adw_switch_row_new()!
        adw_preferences_row_set_title(row.cast(), L10n.text(.ui_remember_pin))
        adw_action_row_set_subtitle(row.cast(), L10n.text(.ui_in_gnome_keyring_only_for_this_card))
        gtk_list_box_append(list.opaque, row)
        append(content, list)
        rememberRow = row
    } else if let problem = request.vaultProblem {
        append(content, label(localized(.ui_pin_cannot_be_saved_value, problem), classes: ["dim-label", "caption"], xalign: 0.5, wrap: true))
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
    case .signPDF: operation = L10n.text(.linux_sign_pdf_operation)
    case .signFile: operation = L10n.text(.ui_signing_files_on_this_computer)
    case .signData: operation = L10n.text(.ui_signing_data_sent_by_the_page)
    }
    let dialog = alert(heading: localized(.linux_consent_heading, consent.originHost), body: operation)
    addResponse(dialog, "deny", L10n.text(.ui_refuse))
    addResponse(dialog, "sign", L10n.text(.ui_sign), ADW_RESPONSE_SUGGESTED)
    adw_alert_dialog_set_default_response(dialog.cast(), "sign")
    adw_alert_dialog_set_close_response(dialog.cast(), "deny")

    let list = boxedList()
    gtk_list_box_append(list.opaque, actionRow(title: request.documentName ?? L10n.text(.linux_data_to_sign),
                                               subtitle: signatureLabels(request.format ?? L10n.text(.ui_qualified_electronic_signature)),
                                               icon: "x-office-document-symbolic"))
    gtk_list_box_append(list.opaque, actionRow(title: consent.holder, subtitle: L10n.text(.ui_mdqsign_certificate),
                                               icon: "auth-smartcard-symbolic"))
    if request.pinIncluded {
        gtk_list_box_append(list.opaque, actionRow(title: L10n.text(.ui_pin_entered_on_the_page), icon: "dialog-password-symbolic"))
    }
    let trust = adw_switch_row_new()!
    adw_preferences_row_set_title(trust.cast(), L10n.text(.ui_trust_this_site_for_10_minutes))
    gtk_list_box_append(list.opaque, trust)
    adw_alert_dialog_set_extra_child(dialog.cast(), list)

    onResponse(dialog) { response in
        completion(response == "sign", response == "sign" && adw_switch_row_get_active(trust.opaque) != 0)
    }
    adw_dialog_present(dialog, parent)
}

// MARK: - Confirmation (stored PIN: the consent step before a local signature)

func presentConfirmDialog(parent: Widget, heading: String, body: String, action: String, defaultApprove: Bool = true, completion: @escaping (Bool) -> Void) {
    let dialog = alert(heading: heading, body: body)
    addResponse(dialog, "cancel", L10n.text(.ui_cancel))
    addResponse(dialog, "ok", action, ADW_RESPONSE_SUGGESTED)
    adw_alert_dialog_set_default_response(dialog.cast(), defaultApprove ? "ok" : "cancel")
    adw_alert_dialog_set_close_response(dialog.cast(), "cancel")
    onResponse(dialog) { completion($0 == "ok") }
    adw_dialog_present(dialog, parent)
}

// MARK: - Clear the activity list

func presentClearActivityDialog(parent: Widget, completion: @escaping (Bool) -> Void) {
    let dialog = alert(heading: L10n.text(.ui_clear_the_list), body: L10n.text(.ui_only_the_app_history_is_cleared_signed_documents_remain_on_disk))
    addResponse(dialog, "cancel", L10n.text(.ui_cancel))
    addResponse(dialog, "clear", L10n.text(.ui_clear_list), ADW_RESPONSE_DESTRUCTIVE)
    adw_alert_dialog_set_default_response(dialog.cast(), "cancel")
    adw_alert_dialog_set_close_response(dialog.cast(), "cancel")
    onResponse(dialog) { completion($0 == "clear") }
    adw_dialog_present(dialog, parent)
}

func presentDeleteSignedDocumentsDialog(parent: Widget, items: [ActivityItem], completion: @escaping (Bool) -> Void) {
    let title = L10n.text(items.count == 1 ? .saved_delete : .saved_delete_all)
    let name = items.count == 1 ? items[0].title + "\n\n" : ""
    let dialog = alert(heading: title, body: name + L10n.text(.saved_delete_warning))
    addResponse(dialog, "cancel", L10n.text(.ui_cancel))
    addResponse(dialog, "delete", L10n.text(.saved_delete), ADW_RESPONSE_DESTRUCTIVE)
    adw_alert_dialog_set_default_response(dialog.cast(), "cancel")
    adw_alert_dialog_set_close_response(dialog.cast(), "cancel")
    onResponse(dialog) { completion($0 == "delete") }
    adw_dialog_present(dialog, parent)
}

// MARK: - First-run onboarding (docs/10 §4.7)

/// Welcome plus the two availability choices (start at sign-in, show on card insertion). The switches
/// apply immediately, exactly like Preferences; any dismissal (Get started or Escape) completes it.
func presentOnboardingDialog(parent: Widget, controller: AppController, onClose: @escaping () -> Void) {
    let dialog = alert(heading: L10n.text(.onboarding_welcome_title), body: L10n.text(.onboarding_welcome_body))
    addResponse(dialog, "start", L10n.text(.onboarding_get_started), ADW_RESPONSE_SUGGESTED)
    adw_alert_dialog_set_default_response(dialog.cast(), "start")
    adw_alert_dialog_set_close_response(dialog.cast(), "start")

    let login = adw_switch_row_new()!
    adw_preferences_row_set_title(login.cast(), L10n.text(.ui_start_at_sign_in))
    adw_action_row_set_subtitle(login.cast(), L10n.text(.ui_start_in_the_background_to_detect_inserted_cards))
    adw_switch_row_set_active(login.opaque, controller.settings.launchAtLogin ? 1 : 0)
    var updating = false
    onSignal(login, "notify::active") { _ in
        guard !updating else { return }
        controller.setLaunchAtLogin(adw_switch_row_get_active(login.opaque) != 0)
    }

    let insertion = adw_switch_row_new()!
    adw_preferences_row_set_title(insertion.cast(), L10n.text(.ui_show_the_app_when_a_card_is_inserted))
    adw_action_row_set_subtitle(insertion.cast(), L10n.text(.ui_works_while_the_app_runs_in_the_background))
    adw_switch_row_set_active(insertion.opaque, controller.settings.showOnCardInsertion ? 1 : 0)
    onSignal(insertion, "notify::active") { _ in
        controller.setShowOnCardInsertion(adw_switch_row_get_active(insertion.opaque) != 0)
    }

    let list = boxedList()
    gtk_list_box_append(list.opaque, login)
    gtk_list_box_append(list.opaque, insertion)
    // Keep both choices visible above the response on smaller screens and larger text scales.
    let content = vbox(spacing: 0, [list])
    gtk_widget_set_margin_top(content, 6)
    gtk_widget_set_margin_bottom(content, 6)
    adw_alert_dialog_set_extra_child(dialog.cast(), content)

    let token = controller.observe {
        updating = true
        adw_switch_row_set_active(login.opaque, controller.settings.launchAtLogin ? 1 : 0)
        gtk_widget_set_sensitive(login, controller.configuringLoginStartup ? 0 : 1)
        updating = false
    }

    onResponse(dialog) { _ in
        controller.completeOnboarding()
    }
    onSignal(dialog, "closed") {
        controller.unobserve(token)
        onClose()
    }
    adw_dialog_present(dialog, parent)
}

// MARK: - Preferences (AdwPreferencesDialog)

func presentPreferences(parent: Widget, controller: AppController) {
    let dialog = adw_preferences_dialog_new()!
    // The app language may differ from the desktop locale used by libadwaita's default title.
    adw_dialog_set_title(dialog, L10n.text(.ui_preferences))
    adw_dialog_set_content_width(dialog, 640)
    adw_dialog_set_content_height(dialog, 720)
    let page = adw_preferences_page_new()!
    adw_preferences_page_set_title(page.cast(), L10n.text(.linux_general))
    adw_preferences_page_set_icon_name(page.cast(), "preferences-system-symbolic")

    let demoGroup = preferencesGroup(title: nil)
    let demo = adw_switch_row_new()!
    adw_preferences_row_set_title(demo.cast(), L10n.text(.linux_demo_mode))
    // The demo-data notice belongs to the preview window only; the real app describes the option.
    adw_action_row_set_subtitle(demo.cast(), L10n.text(controller.isDemo ? .ui_demo_data_no_real_card_pin_or_signatures : .linux_demo_mode_description))
    adw_switch_row_set_active(demo.opaque, controller.isDemo ? 1 : 0)
    gtk_widget_set_sensitive(demo, controller.isSigning || controller.bridgeSigning ? 0 : 1)
    var updatingDemo = false
    onSignal(demo, "notify::active") { _ in
        let enabled = adw_switch_row_get_active(demo.opaque) != 0
        // Resetting the switch below may notify again after `updatingDemo` is cleared: only a change of mode counts.
        guard !updatingDemo, enabled != controller.isDemo else { return }
        controller.requestDemoMode?(enabled)
        // The preview has its own window and cannot modify real settings or saved PINs.
        updatingDemo = true
        adw_switch_row_set_active(demo.opaque, controller.isDemo ? 1 : 0)
        updatingDemo = false
    }
    groupAdd(demoGroup, demo)
    adw_preferences_page_add(page.cast(), demoGroup.cast())

    let cardsGroup = preferencesGroup(title: L10n.text(.settings_signing))
    let cards = preferencesAction(title: L10n.text(.settings_card_reader), icon: "auth-smartcard-symbolic") {
        presentCardSettings(parent: parent, controller: controller)
    }
    groupAdd(cardsGroup, cards)
    groupAdd(cardsGroup, preferencesAction(title: L10n.text(.ui_saved_pins), icon: "dialog-password-symbolic") {
        presentSavedPINSettings(parent: parent, controller: controller)
    })
    adw_preferences_page_add(page.cast(), cardsGroup.cast())

    let bridge = preferencesGroup(title: L10n.text(.ui_browser_connection),
                                  description: L10n.text(.ui_allows_government_sites_e_g_msign_gov_md_to_request_signatures) +
                                               L10n.text(.ui_just_like_moldsign_desktop_each_request_requires_your_consent))
    let bridgeRow = adw_switch_row_new()!
    adw_preferences_row_set_title(bridgeRow.cast(), L10n.text(.ui_browser_connection))
    groupAdd(bridge, bridgeRow)
    let stamps = adw_switch_row_new()!
    adw_preferences_row_set_title(stamps.cast(), L10n.text(.stamp_browser))
    adw_action_row_set_subtitle(stamps.cast(), L10n.text(.stamp_batch_hint))
    groupAdd(bridge, stamps)
    let retry = button(L10n.text(.ui_restart), classes: ["flat"]) { controller.restartBridge() }
    gtk_widget_set_valign(retry, GTK_ALIGN_CENTER)
    adw_action_row_add_suffix(bridgeRow.cast(), retry)

    let legacy = adw_switch_row_new()!
    adw_preferences_row_set_title(legacy.cast(), L10n.text(.legacy_client_title))
    adw_action_row_set_subtitle(legacy.cast(), L10n.text(.legacy_client_description))
    let bridgeDetails = technicalDetailsDisclosure()
    adw_expander_row_add_row(bridgeDetails.cast(), legacy)

    let identityRow = actionRow(title: L10n.text(.ui_moldsign_https_identity),
        subtitle: L10n.text(.ui_the_bundled_identity_is_used_automatically_import_only_to_replace_it),
        icon: "network-server-symbolic")
    let importIdentity = button(L10n.text(.ui_import), classes: ["flat"]) {
        chooseBridgeIdentity(parent: parent, controller: controller)
    }
    gtk_widget_set_valign(importIdentity, GTK_ALIGN_CENTER)
    adw_action_row_add_suffix(identityRow.cast(), importIdentity)
    adw_expander_row_add_row(bridgeDetails.cast(), identityRow)
    groupAdd(bridge, bridgeDetails)

    let automation = preferencesGroup(title: L10n.text(.automation_title),
                                      description: L10n.text(.automation_hint))
    let agents = adw_switch_row_new()!
    adw_preferences_row_set_title(agents.cast(), L10n.text(.automation_enable))
    adw_action_row_set_subtitle(agents.cast(), AgentApprovalBroker.directory.path)
    groupAdd(automation, agents)

    let background = preferencesGroup(title: L10n.text(.ui_background))
    let backgroundRow = adw_switch_row_new()!
    adw_preferences_row_set_title(backgroundRow.cast(), L10n.text(.ui_run_in_the_background))
    adw_action_row_set_subtitle(backgroundRow.cast(), L10n.text(.ui_the_browser_connection_remains_active_after_closing_the_window))
    groupAdd(background, backgroundRow)
    let login = adw_switch_row_new()!
    adw_preferences_row_set_title(login.cast(), L10n.text(.ui_start_at_sign_in))
    adw_action_row_set_subtitle(login.cast(), L10n.text(.ui_start_in_the_background_to_detect_inserted_cards))
    groupAdd(background, login)

    let appearance = preferencesGroup(title: L10n.text(.ui_appearance))
    func choice(_ title: String, values: [String], labels: [String], current: String,
                changed: @escaping (String) -> Void) {
        let row = adw_combo_row_new()!
        adw_preferences_row_set_title(row.cast(), title)
        withCStringArray(labels) { strings in
            let model = gtk_string_list_new(strings)!
            adw_combo_row_set_model(row.cast(), model.opaque)
            g_object_unref(model.raw)
        }
        adw_combo_row_set_selected(row.cast(), UInt32(values.firstIndex(of: current) ?? 0))
        onSignal(row, "notify::selected") { _ in
            let index = Int(adw_combo_row_get_selected(row.cast()))
            if values.indices.contains(index) { changed(values[index]) }
        }
        groupAdd(appearance, row)
    }
    choice(L10n.text(.ui_theme), values: ["system", "light", "dark"], labels: [L10n.text(.ui_system), L10n.text(.ui_light), L10n.text(.ui_dark)],
           current: controller.settings.theme, changed: controller.setTheme)
    choice(L10n.text(.ui_language), values: ["system", "ro", "en", "ru"], labels: [L10n.text(.ui_system), L10n.text(.ui_romanian), "English", "Русский"],
           current: controller.settings.language, changed: controller.setLanguage)
    let insertion = adw_switch_row_new()!
    adw_preferences_row_set_title(insertion.cast(), L10n.text(.ui_show_the_app_when_a_card_is_inserted))
    adw_action_row_set_subtitle(insertion.cast(), L10n.text(.ui_works_while_the_app_runs_in_the_background))
    adw_switch_row_set_active(insertion.opaque, controller.settings.showOnCardInsertion ? 1 : 0)
    onSignal(insertion, "notify::active") { _ in
        controller.setShowOnCardInsertion(adw_switch_row_get_active(insertion.opaque) != 0)
    }
    groupAdd(background, insertion)

    adw_preferences_page_add(page.cast(), appearance.cast())
    adw_preferences_page_add(page.cast(), background.cast())
    adw_preferences_page_add(page.cast(), bridge.cast())
    adw_preferences_page_add(page.cast(), automation.cast())

    let about = preferencesGroup(title: nil)
    groupAdd(about, preferencesAction(title: L10n.text(.ui_about_esemnbun), icon: "help-about-symbolic") {
        presentAbout(parent: parent)
    })
    adw_preferences_page_add(page.cast(), about.cast())
    adw_preferences_dialog_add(dialog.cast(), page.cast())

    var updating = false
    let token = controller.observe {
        updating = true
        adw_action_row_set_subtitle(cards.cast(), escapeMarkup(controller.status.title))
        adw_switch_row_set_active(agents.opaque, controller.settings.agentApprovalEnabled ? 1 : 0)
        gtk_widget_set_sensitive(agents, controller.isDemo ? 0 : 1)
        adw_switch_row_set_active(stamps.opaque, controller.settings.browserStampsEnabled ? 1 : 0)
        adw_switch_row_set_active(bridgeRow.opaque, controller.settings.bridgeEnabled ? 1 : 0)
        adw_switch_row_set_active(legacy.opaque, controller.settings.legacyDesktopClientEnabled ? 1 : 0)
        adw_action_row_set_subtitle(bridgeRow.cast(), escapeMarkup(controller.bridgeState.description))
        setVisible(retry, controller.settings.bridgeEnabled && controller.bridgeState != .running)
        adw_switch_row_set_active(backgroundRow.opaque, controller.settings.runInBackground ? 1 : 0)
        adw_switch_row_set_active(login.opaque, controller.settings.launchAtLogin ? 1 : 0)
        gtk_widget_set_sensitive(login, controller.configuringLoginStartup || controller.isDemo ? 0 : 1)
        updating = false
    }
    onSignal(agents, "notify::active") { _ in
        guard !updating else { return }
        controller.setAgentApprovalEnabled(adw_switch_row_get_active(agents.opaque) != 0)
    }
    onSignal(stamps, "notify::active") { _ in
        guard !updating else { return }
        controller.setBrowserStampsEnabled(adw_switch_row_get_active(stamps.opaque) != 0)
    }
    onSignal(bridgeRow, "notify::active") { _ in
        guard !updating else { return }
        controller.setBridgeEnabled(adw_switch_row_get_active(bridgeRow.opaque) != 0)
    }
    onSignal(legacy, "notify::active") { _ in
        guard !updating else { return }
        controller.setLegacyDesktopClientEnabled(adw_switch_row_get_active(legacy.opaque) != 0)
    }
    onSignal(login, "notify::active") { _ in
        guard !updating else { return }
        controller.setLaunchAtLogin(adw_switch_row_get_active(login.opaque) != 0)
    }
    onSignal(backgroundRow, "notify::active") { _ in
        guard !updating else { return }
        controller.setRunInBackground(adw_switch_row_get_active(backgroundRow.opaque) != 0)
    }
    onSignal(dialog, "closed") { controller.unobserve(token) }
    adw_dialog_present(dialog, parent)
}

/// A full-row action opens a focused native dialog without replacing the preferences page.
private func preferencesAction(title: String, icon: String, action: @escaping () -> Void) -> Widget {
    let row = actionRow(title: title, icon: icon, suffix: [image("go-next-symbolic")])
    gtk_list_box_row_set_activatable(row.cast(), 1)
    onSignal(row, "activated", action)
    return row
}

private func presentSavedPINSettings(parent: Widget, controller: AppController) {
    let dialog = adw_preferences_dialog_new()!
    adw_dialog_set_title(dialog, L10n.text(.ui_saved_pins))
    adw_dialog_set_content_width(dialog, 540)
    adw_dialog_set_content_height(dialog, 360)
    let page = adw_preferences_page_new()!
    let pins = preferencesGroup(title: nil, description: L10n.text(.ui_pins_remain_in_the_system_keyring))
    let cardList = boxedList()
    groupAdd(pins, cardList)
    let clear = iconButton("user-trash-symbolic", tooltip: L10n.text(.ui_delete_all_pins), classes: ["flat", "error"]) {
        controller.askConfirm?(L10n.text(.ui_delete_all_saved_pins),
            L10n.text(.ui_you_will_enter_the_pin_again_the_next_time_you_sign), L10n.text(.ui_delete)) { approved in
                if approved { controller.forgetAllPINs() }
            }
    }
    let clearGroup = preferencesGroup(title: nil)
    groupAdd(clearGroup, actionRow(title: L10n.text(.ui_delete_all_pins), subtitle: L10n.text(.ui_all_cards), suffix: [clear]))
    adw_preferences_page_add(page.cast(), pins.cast())
    adw_preferences_page_add(page.cast(), clearGroup.cast())
    adw_preferences_dialog_add(dialog.cast(), page.cast())
    let token = controller.observe {
        clearList(cardList)
        var seen = Set<String>()
        for card in controller.cards {
            guard let certificate = card.certificate, seen.insert(certificate.sha1Hex).inserted else { continue }
            let remove = iconButton("user-trash-symbolic", tooltip: L10n.text(.ui_delete_the_saved_pin), classes: ["flat", "error"]) {
                controller.forgetPIN(forCertificateID: certificate.sha1Hex)
            }
            gtk_widget_set_sensitive(remove, card.hasStoredPIN ? 1 : 0)
            let status = L10n.text(card.hasStoredPIN ? .ui_the_pin_is_saved_in_gnome_keyring : .linux_pin_not_saved)
            gtk_list_box_append(cardList.opaque, actionRow(title: certificate.holder, subtitle: status,
                icon: "auth-smartcard-symbolic", suffix: [remove]))
        }
        if seen.isEmpty {
            gtk_list_box_append(cardList.opaque, actionRow(title: L10n.text(.ui_no_card_connected),
                subtitle: L10n.text(.ui_connect_the_reader), icon: "auth-smartcard-symbolic"))
        }
    }
    onSignal(dialog, "closed") { controller.unobserve(token) }
    adw_dialog_present(dialog, parent)
}

func chooseBridgeIdentity(parent: Widget, controller: AppController) {
    chooseFiles(parent: parent.cast(), title: L10n.text(.ui_moldsign_https_identity), multiple: false,
                filters: [(name: "PKCS#12", suffixes: ["p12", "pfx"])]) { paths in
        if let path = paths.first { controller.importBridgeIdentity(from: URL(fileURLWithPath: path)) }
    }
}

// MARK: - About

func presentAbout(parent: Widget) {
    let about = adw_about_dialog_new()!
    adw_about_dialog_set_application_name(about.opaque, "eSemnBun")
    adw_about_dialog_set_application_icon(about.opaque, "md.moldsign.MoldSign")
    adw_about_dialog_set_version(about.opaque, UpdateChecker.currentVersion)
    adw_about_dialog_set_developer_name(about.opaque, "Nicolae Ghimbovschi")
    adw_about_dialog_set_website(about.opaque, "https://esemnbun.md")
    adw_about_dialog_set_comments(about.opaque,
        L10n.text(.ui_electronic_signature_using_the_republic_of_moldova_identity_card_idemia_cosmox_id_a_card) +
        L10n.text(.ui_pades_and_xades_and_the_browser_connection_for_msign_gov_md))
    let language = L10n.language ?? Locale.current.language.languageCode?.identifier ?? "ro"
    let legalBase = "https://esemnbun.md" + (["ro", "ru"].contains(language) ? "/\(language)" : "")
    // Link titles are Pango markup: "Terms & Conditions" would otherwise render empty.
    adw_about_dialog_add_legal_section(about.opaque, L10n.text(.about_legal_title), nil,
                                     GTK_LICENSE_CUSTOM, escapeMarkup(L10n.text(.about_disclaimer_body)))
    adw_about_dialog_add_link(about.opaque, escapeMarkup(L10n.text(.about_terms)), legalBase + "/terms/")
    adw_about_dialog_add_link(about.opaque, escapeMarkup(L10n.text(.about_privacy)), legalBase + "/privacy/")
    adw_about_dialog_add_link(about.opaque, escapeMarkup(L10n.text(.about_disclaimer)), legalBase + "/terms/")
    adw_dialog_present(about, parent)
}

/// Card management is reachable from Preferences or the signing card without a main Card tab.
func presentCardSettings(parent: Widget, controller: AppController) {
    let dialog = adw_dialog_new()!
    adw_dialog_set_title(dialog, L10n.text(.settings_card_reader))
    adw_dialog_set_content_width(dialog, 620)
    adw_dialog_set_content_height(dialog, 640)
    let toolbar = adw_toolbar_view_new()!
    adw_toolbar_view_add_top_bar(toolbar.opaque, adw_header_bar_new()!)
    var cardPage: CardPage? = CardPage(controller: controller)
    adw_toolbar_view_set_content(toolbar.opaque, cardPage!.root)
    adw_dialog_set_child(dialog, toolbar)
    // Retain the live page until its dialog closes; its model observer is weak.
    onSignal(dialog, "closed") { cardPage = nil }
    adw_dialog_present(dialog, parent)
}
