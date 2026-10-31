import Foundation

@MainActor
protocol ActivityStoring: AnyObject {
    func load() -> [ActivityItem]
    func save(_ items: [ActivityItem])
    var recentsClearedAt: Date { get set }
}

/// Persistence is independent of signing and presentation and replaceable in tests/previews.
@MainActor
final class PreferencesActivityStore: ActivityStoring {
    private let defaults: UserDefaults
    init(defaults: UserDefaults = AppPreferencesStore.defaults) { self.defaults = defaults }
    func load() -> [ActivityItem] {
        guard let data = defaults.data(forKey: "activity") else { return [] }
        return (try? JSONDecoder().decode([ActivityItem].self, from: data)) ?? []
    }
    func save(_ items: [ActivityItem]) {
        if let data = try? JSONEncoder().encode(items) { defaults.set(data, forKey: "activity") }
    }
    var recentsClearedAt: Date {
        get { defaults.object(forKey: "recentsClearedAt") as? Date ?? .distantPast }
        set { defaults.set(newValue, forKey: "recentsClearedAt") }
    }
}

@MainActor
final class MemoryActivityStore: ActivityStoring {
    private var items: [ActivityItem] = []
    var recentsClearedAt = Date.distantPast
    func load() -> [ActivityItem] { items }
    func save(_ items: [ActivityItem]) { self.items = items }
}
