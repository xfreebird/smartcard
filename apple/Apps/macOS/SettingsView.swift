import SwiftUI
import ServiceManagement
import MoldSignKit

/// docs/10 §4.2 Settings (MAC-09).
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings().tabItem { Label(L10n.text(.ui_general), systemImage: "gearshape") }
            SavedPINSettings().tabItem { Label(L10n.text(.ui_saved_pins), systemImage: "key") }
            #if !APP_STORE
            BridgeSettings().tabItem { Label(L10n.text(.ui_browser_connection), systemImage: "globe") }
            #endif
            AboutContent().tabItem { Label(L10n.text(.about_app_title), systemImage: "info.circle") }
        }
        .frame(width: 560, height: 480)
        .background(WindowReader { WindowPresentation.shared.register($0, for: .settings) })
    }
}

private struct GeneralSettings: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchError: String?
    #if !APP_STORE
    @State private var watcherEnabled = ReaderActivationService().enabled
    @State private var watcherNeedsApproval = ReaderActivationService().requiresApproval
    @State private var watcherError: String?
    #endif
    @AppStorage("appLanguage", store: AppPreferencesStore.defaults) private var language = "system"
    @AppStorage("appTheme", store: AppPreferencesStore.defaults) private var theme = "system"
    @AppStorage("openOnCardInsertion", store: AppPreferencesStore.defaults) private var openOnInsertion = false

    private var languageChoice: Binding<String> {
        Binding(get: { language }, set: { value in
            if value == "system" { AppPreferencesStore.defaults.removeObject(forKey: "AppleLanguages") }
            language = value
        })
    }

    var body: some View {
        Form {
            Section(L10n.text(.ui_appearance_and_language)) {
                Picker(L10n.text(.ui_language), selection: languageChoice) {
                    Text(L10n.text(.ui_system)).tag("system")
                    Text(verbatim: L10n.text(.ui_romanian)).tag("ro")
                    Text(verbatim: "English").tag("en")
                    Text(verbatim: "Русский").tag("ru")
                }
                Picker(L10n.text(.ui_theme), selection: $theme) {
                    Text(L10n.text(.ui_system)).tag("system")
                    Text(L10n.text(.ui_light)).tag("light")
                    Text(L10n.text(.ui_dark)).tag("dark")
                }
            }
            DemoModeSettings()
            #if !APP_STORE
            Toggle(L10n.text(.ui_open_app_on_reader_or_card_insertion), isOn: $watcherEnabled)
                .onChange(of: watcherEnabled) { _, enabled in
                    let watcher = ReaderActivationService()
                    do {
                        try watcher.setEnabled(enabled)
                        watcherEnabled = watcher.enabled
                        watcherNeedsApproval = watcher.requiresApproval
                        watcherError = nil
                    } catch {
                        watcherEnabled = watcher.enabled
                        watcherError = error.localizedDescription
                    }
                }
            Text(L10n.text(.ui_insertion_helper_explanation))
                .font(.caption).foregroundStyle(.secondary)
            if watcherNeedsApproval {
                Button(L10n.text(.ui_allow_helper_in_system_settings)) { SMAppService.openSystemSettingsLoginItems() }
            }
            if let watcherError { Text(watcherError).font(.caption).foregroundStyle(Theme.danger) }
            #else
            Toggle(L10n.text(.ui_open_window_on_card_insertion), isOn: $openOnInsertion)
            Text(L10n.text(.ui_the_menu_bar_app_detects_your_card_enable_launch_at_login_to_keep_it_available))
                .font(.caption).foregroundStyle(.secondary)
            #endif
            Toggle(L10n.text(.ui_start_at_sign_in), isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in
                    do {
                        if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                        launchError = nil
                    } catch {
                        launchError = error.localizedDescription
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }
            if let launchError { Text(launchError).font(.caption).foregroundStyle(Theme.danger) }
            LabeledContent(L10n.text(.ui_pdf_format), value: "PAdES-T")
            LabeledContent(L10n.text(.ui_other_files), value: L10n.text(.ui_xades_t_detached))
            LabeledContent(L10n.text(.ui_saving), value: L10n.text(AppDistribution.writesBesideInput
                ? .ui_beside_the_original_semnat_without_overwriting : .store_output_location))
            #if APP_STORE
            Text(L10n.text(.store_features_explanation)).font(.caption).foregroundStyle(.secondary)
            #endif
        }
        .formStyle(.grouped)
    }
}

#if !APP_STORE
private struct BridgeSettings: View {
    @Environment(AppModel.self) private var model
    @State private var vendorListening = false
    @State private var confirmQuitVendor = false
    @State private var quitFailed = false

    var body: some View {
        @Bindable var model = model
        Form {
            Toggle(L10n.text(.ui_respond_to_signing_requests_from_the_browser), isOn: $model.bridgeEnabled)
            LabeledContent(L10n.text(.ui_addresses), value: "127.0.0.1:18480 · localhost.cts.md:18443")
            if model.bridgeState == .portBusy {
                Text(L10n.text(vendorListening ? .ui_the_ports_are_in_use_by_moldsign_desktop_suite_java_quit_it_to_use_this_application : .vendor_other_conflict))
                    .font(.caption).foregroundStyle(Theme.warning)
                if vendorListening {
                    Button(L10n.text(.vendor_quit_action)) { confirmQuitVendor = true }
                } else {
                    Button(L10n.text(.vendor_retry)) { retryBridge() }
                }
                if quitFailed { Text(L10n.text(.vendor_quit_failed)).font(.caption).foregroundStyle(Theme.warning) }
            }
            Section(L10n.text(.ui_allowed_sites)) {
                Text(BridgeOriginPolicy.vendorDefault.patterns.prefix(12).joined(separator: "\n") + "\n…")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .task(id: model.bridgeState == .portBusy) {
            guard model.bridgeState == .portBusy else { return }
            vendorListening = await Task.detached { !VendorPortConflict.listeners().isEmpty }.value
        }
        .alert(L10n.text(.vendor_quit_confirmation), isPresented: $confirmQuitVendor) {
            Button(L10n.text(.vendor_quit_action), role: .destructive) {
                VendorPortConflict.terminateListeners()
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1))
                    quitFailed = await Task.detached { !VendorPortConflict.listeners().isEmpty }.value
                    retryBridge()
                }
            }
            Button(L10n.text(.ui_cancel), role: .cancel) { }
        } message: {
            Text(L10n.text(.vendor_quit_explanation))
        }
    }

    private func retryBridge() {
        model.stopBridge()
        if model.bridgeEnabled { model.startBridge() }
    }
}

#endif

/// Lists only keychain account metadata; PIN values are never read for management.
private struct SavedPINSettings: View {
    @Environment(AppModel.self) private var model
    @State private var accounts: [String] = []
    var body: some View {
        Group {
            if accounts.isEmpty {
                ContentUnavailableView(L10n.text(.ui_no_saved_pins), systemImage: "key")
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(24)
            } else {
                Form {
                    ForEach(accounts, id: \.self) { account in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(model.cards.first { $0.certificate?.sha1Hex == account }?.certificate?.holder ?? L10n.text(.ui_identity_card))
                                Text(String(account.prefix(12)) + "…").font(.caption.monospaced()).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(L10n.text(.ui_delete), role: .destructive) {
                                model.forgetPIN(certID: account)
                                accounts = model.vault.savedAccounts()
                            }
                        }
                    }
                    Button(L10n.text(.ui_delete_all_pins), role: .destructive) {
                        for account in accounts { model.forgetPIN(certID: account) }
                        accounts = model.vault.savedAccounts()
                    }
                }
                .formStyle(.grouped)
            }
        }
        .onAppear { accounts = model.vault.savedAccounts() }
    }
}
