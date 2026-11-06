import SwiftUI
import ServiceManagement
import MoldSignKit

/// First-run onboarding (MAC-17, docs/10 §4.7): welcome plus how eSemnBun stays available —
/// start at sign-in and open on reader/card insertion. The toggles apply immediately, exactly
/// like Settings › General, so the sheet only has to close.
struct OnboardingView: View {
    let completion: () -> Void

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var launchError: String?
    #if !APP_STORE
    @State private var launchOnInsertion = ReaderActivationService().enabled
    @State private var watcherNeedsApproval = ReaderActivationService().requiresApproval
    @State private var watcherError: String?
    #else
    @AppStorage("openOnCardInsertion", store: AppPreferencesStore.defaults) private var openOnInsertion = false
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable().frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text(.onboarding_welcome_title))
                        .font(.title2.bold()).fixedSize(horizontal: false, vertical: true)
                    Text(L10n.text(.onboarding_welcome_body))
                        .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
            Toggle(isOn: $launchAtLogin) {
                Text(L10n.text(.ui_start_at_sign_in)).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
                .onChange(of: launchAtLogin) { _, enabled in
                    do {
                        if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                        launchError = nil
                    } catch {
                        launchError = error.localizedDescription
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }
            #if !APP_STORE
            Toggle(isOn: $launchOnInsertion) {
                Text(L10n.text(.ui_open_app_on_reader_or_card_insertion)).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
                .onChange(of: launchOnInsertion) { _, enabled in
                    let watcher = ReaderActivationService()
                    do {
                        try watcher.setEnabled(enabled)
                        launchOnInsertion = watcher.enabled
                        watcherNeedsApproval = watcher.requiresApproval
                        watcherError = nil
                    } catch {
                        launchOnInsertion = watcher.enabled
                        watcherNeedsApproval = watcher.requiresApproval
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
            Toggle(isOn: $openOnInsertion) {
                Text(L10n.text(.ui_open_window_on_card_insertion)).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Text(L10n.text(.ui_the_menu_bar_app_detects_your_card_enable_launch_at_login_to_keep_it_available))
                .font(.caption).foregroundStyle(.secondary)
            #endif
            if let launchError { Text(launchError).font(.caption).foregroundStyle(Theme.danger) }
            Text(L10n.text(.onboarding_change_anytime))
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button(L10n.text(.onboarding_get_started), action: completion)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .toggleStyle(.switch)
        .padding(24)
        .frame(width: 440)
    }
}
