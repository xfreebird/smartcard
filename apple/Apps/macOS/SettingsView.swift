import SwiftUI
import ServiceManagement
import MoldSignKit

/// docs/10 §4.2 Settings (MAC-09).
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings().tabItem { Label(L10n.text(.ui_general), systemImage: "gearshape") }
            SavedCardPINsView().tabItem { Label(L10n.text(.card_saved_identities_title), systemImage: "key") }
            BridgeSettings().tabItem { Label(L10n.text(.ui_browser_connection), systemImage: "globe") }
            AboutContent().tabItem { Label(L10n.text(.about_app_title), systemImage: "info.circle") }
        }
        .frame(width: 560, height: 480)
        .background(WindowReader { WindowPresentation.shared.register($0, for: .settings) })
    }
}

private struct GeneralSettings: View {
    @State private var showsCards = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchError: String?
    @State private var launchNeedsApproval = SMAppService.mainApp.status == .requiresApproval
    @AppStorage("appLanguage", store: AppPreferencesStore.defaults) private var language = "system"
    @AppStorage("appTheme", store: AppPreferencesStore.defaults) private var theme = "system"

    private var languageChoice: Binding<String> {
        Binding(get: { language }, set: { value in
            if value == "system" { AppPreferencesStore.defaults.removeObject(forKey: "AppleLanguages") }
            language = value
        })
    }

    var body: some View {
        Form {
            DemoModeSettings()
            Section(L10n.text(.settings_signing)) {
                Button { showsCards = true } label: {
                    Label(L10n.text(.settings_card_reader), systemImage: "person.text.rectangle")
                }.accessibilityIdentifier("settings.card")
            }
            ExperimentalTokenSettings()
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
            Section(L10n.text(.ui_documents)) {
                DocumentDiscoverySettings()
                LabeledContent(L10n.text(.ui_pdf_format), value: L10n.text(.format_pdf_time))
                LabeledContent(L10n.text(.ui_other_files), value: L10n.text(.ui_xades_t_detached))
                LabeledContent(L10n.text(.ui_saving), value: L10n.text(AppDistribution.writesBesideInput
                    ? .ui_beside_the_original_semnat_without_overwriting : .store_output_location))
                #if APP_STORE
                StoreExportFolderSettings()
                #endif
            }
            Section {
                ReaderActivationToggle(showsForegroundOption: true)
                Toggle(L10n.text(.ui_start_at_sign_in), isOn: Binding(
                    get: { launchAtLogin }, set: setLaunchAtLogin))
                if launchNeedsApproval {
                    Button(L10n.text(.startup_allow)) { SMAppService.openSystemSettingsLoginItems() }
                }
                if let launchError { Text(launchError).font(.caption).foregroundStyle(Theme.danger) }
            }.accessibilityIdentifier("settings.background")
            #if !APP_STORE
            Section {
                SettingsDisclosure(title: .automation_title) { AgentBrokerSettingsView() }
                    .accessibilityIdentifier("settings.automation")
            }
            #endif
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showsCards) {
            NavigationStack {
                CardScreen()
                    .navigationTitle(L10n.text(.settings_card_reader))
                    .toolbar { ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.text(.ui_done)) { showsCards = false }
                            .accessibilityIdentifier("settings.cards.done")
                    } }
            }.frame(width: 560, height: 600)
        }
        .onAppear(perform: refreshStartupStatus)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshStartupStatus()
        }
    }

    /// Reading OS state never re-registers an item disabled in System Settings.
    private func refreshStartupStatus() {
        launchAtLogin = SMAppService.mainApp.status == .enabled
        launchNeedsApproval = SMAppService.mainApp.status == .requiresApproval
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            launchError = nil
        } catch { launchError = error.localizedDescription }
        refreshStartupStatus()
    }

}

private struct BridgeSettings: View {
    @AppStorage("browserStampsEnabled", store: AppPreferencesStore.defaults) private var browserStamps = false
    @AppStorage("legacyDesktopClientEnabled", store: AppPreferencesStore.defaults) private var legacyDesktop = false
    @Environment(AppModel.self) private var model
    #if !APP_STORE
    @State private var vendorListening = false
    @State private var confirmQuitVendor = false
    @State private var quitFailed = false
    @State private var quittingVendor = false
    #endif

    var body: some View {
        @Bindable var model = model
        Form {
            Toggle(L10n.text(.ui_respond_to_signing_requests_from_the_browser), isOn: $model.bridgeEnabled)
            Toggle(L10n.text(.stamp_browser), isOn: $browserStamps)
            Text(L10n.text(.stamp_batch_hint)).font(.caption).foregroundStyle(.secondary)
            if model.bridgeState == .portBusy {
                #if !APP_STORE
                Text(L10n.text(vendorListening ? .ui_the_ports_are_in_use_by_moldsign_desktop_suite_java_quit_it_to_use_this_application : .vendor_other_conflict))
                    .font(.caption).foregroundStyle(Theme.warning)
                if vendorListening {
                    Button(L10n.text(.vendor_quit_action)) { confirmQuitVendor = true }.disabled(quittingVendor)
                } else {
                    Button(L10n.text(.vendor_retry)) { retryBridge() }
                }
                if quittingVendor { ProgressView().controlSize(.small) }
                if quitFailed { Text(L10n.text(.vendor_quit_failed)).font(.caption).foregroundStyle(Theme.warning) }
                #else
                Text(L10n.text(.vendor_other_conflict)).font(.caption).foregroundStyle(Theme.warning)
                Button(L10n.text(.vendor_retry)) { retryBridge() }
                #endif
            }
            Section {
                SettingsDisclosure(title: .ui_technical_details) {
                    #if !APP_STORE
                    Toggle(L10n.text(.vendor_desktop_access), isOn: $legacyDesktop)
                        .onChange(of: legacyDesktop) { _, _ in retryBridge() }
                    Text(L10n.text(.vendor_desktop_access_detail)).font(.callout).foregroundStyle(.secondary)
                    #endif
                    LabeledContent(L10n.text(.ui_addresses), value: "127.0.0.1:18480 · localhost.cts.md:18443")
                    LabeledContent(L10n.text(.ui_allowed_sites)) {
                        Text(BridgeOriginPolicy.vendorDefault.patterns.prefix(12).joined(separator: "\n") + "\n…")
                            .font(.caption.monospaced()).foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }.accessibilityIdentifier("settings.browser.details")
            }
        }
        .formStyle(.grouped)
        #if !APP_STORE
        .task(id: model.bridgeState == .portBusy) {
            guard model.bridgeState == .portBusy else { return }
            vendorListening = await Task.detached { !VendorPortConflict.listeners().isEmpty }.value
        }
        .alert(L10n.text(.vendor_quit_confirmation), isPresented: $confirmQuitVendor) {
            Button(L10n.text(.vendor_quit_action), role: .destructive) {
                quittingVendor = true
                Task { @MainActor in
                    defer { quittingVendor = false }
                    let stopped = await Task.detached { VendorPortConflict.terminateListeners() }.value
                    quitFailed = !stopped
                    if stopped { retryBridge() }
                }
            }
            Button(L10n.text(.ui_cancel), role: .cancel) { }
        } message: {
            Text(L10n.text(.vendor_quit_explanation))
        }
        #endif
    }

    private func retryBridge() {
        model.stopBridge()
        if model.bridgeEnabled { model.startBridge() }
    }
}
