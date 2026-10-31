struct JSONSettingsStore: SettingsStoring {
    func load() -> AppSettings { Store.loadSettings() }
    func save(_ settings: AppSettings) { Store.save(settings) }
}
