import Foundation

protocol SettingsStoring {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

/// Owns preference invariants and persistence; callers only apply their platform side effects.
final class SettingsCoordinator {
    private let store: any SettingsStoring
    private(set) var settings: AppSettings

    init(store: any SettingsStoring) {
        self.store = store
        self.settings = store.load()
    }

    func update(_ change: (inout AppSettings) -> Void) {
        change(&settings)
        store.save(settings)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        update { $0.launchAtLogin = enabled; if enabled { $0.runInBackground = true } }
    }

    func setShowOnCardInsertion(_ enabled: Bool) {
        update { $0.showOnCardInsertion = enabled; if enabled { $0.runInBackground = true } }
    }
}
