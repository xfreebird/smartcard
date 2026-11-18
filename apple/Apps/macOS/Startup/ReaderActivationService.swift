import SwiftUI
import ServiceManagement

/// The reader watcher is its own launchd process: quitting the UI does not stop insertion detection.
@MainActor
protocol ReaderActivationManaging {
    var enabled: Bool { get }
    var requiresApproval: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

@MainActor
struct ReaderActivationService: ReaderActivationManaging {
    #if APP_STORE
    private let service = SMAppService.agent(plistName: "md.esemnbun.mac.reader-watcher.plist")
    #else
    private let service = SMAppService.agent(plistName: "md.esemnbun.reader-watcher.plist")
    #endif
    var active: Bool { service.status == .enabled }
    var enabled: Bool { active || service.status == .requiresApproval }
    var requiresApproval: Bool { service.status == .requiresApproval }
    func setEnabled(_ enabled: Bool) throws {
        if enabled { try service.register() } else { try service.unregister() }
    }
    #if APP_STORE
    static func publishDemoMode(_ enabled: Bool) {
        guard let suite = Bundle.main.object(forInfoDictionaryKey: "ReaderWatcherPreferencesSuite") as? String,
              let defaults = UserDefaults(suiteName: suite) else { return }
        #if DEBUG
        guard ProcessInfo.processInfo.environment["MSIGN_DEMO_PREFERENCES_SUITE"] == nil else { return }
        #endif
        defaults.set(enabled, forKey: "demoModeEnabled")
    }
    #endif
}

struct ReaderActivationToggle: View {
    let showsForegroundOption: Bool
    #if APP_STORE
    @AppStorage("openOnCardInsertion", store: AppPreferencesStore.defaults) private var openOnInsertion = false
    #endif
    private let watcher = ReaderActivationService()
    @State private var enabled = false
    @State private var needsApproval = false
    @State private var errorMessage: String?

    init(showsForegroundOption: Bool = false) {
        self.showsForegroundOption = showsForegroundOption
    }

    var body: some View {
        Toggle(L10n.text(.ui_open_app_on_reader_or_card_insertion), isOn: Binding(
            get: { enabled },
            set: { requested in
                do {
                    try watcher.setEnabled(requested)
                    errorMessage = nil
                } catch { errorMessage = error.localizedDescription }
                refresh()
            }))
            .onAppear(perform: refresh)
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in refresh() }
        Text(L10n.text(.ui_insertion_helper_explanation)).font(.caption).foregroundStyle(.secondary)
        if needsApproval {
            Button(L10n.text(.ui_allow_helper_in_system_settings)) { SMAppService.openSystemSettingsLoginItems() }
        }
        #if APP_STORE
        if showsForegroundOption && (!enabled || needsApproval) {
            Toggle(L10n.text(.store_while_running), isOn: $openOnInsertion)
        }
        #endif
        if let errorMessage { Text(errorMessage).font(.caption).foregroundStyle(Theme.danger) }
    }

    private func refresh() {
        enabled = watcher.enabled
        needsApproval = watcher.requiresApproval
    }
}
