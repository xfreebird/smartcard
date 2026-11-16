/// Isolates interactive demo preferences from the real app.
final class MemorySettingsStore: SettingsStoring {
    private var settings: AppSettings
    init(_ source: AppSettings) {
        settings = source
        settings.bridgeEnabled = false
        settings.agentApprovalEnabled = false
        settings.launchAtLogin = false
        settings.runInBackground = false
        settings.showOnCardInsertion = false
        settings.onboardingCompleted = true
    }
    func load() -> AppSettings { settings }
    func save(_ settings: AppSettings) { self.settings = settings }
}
