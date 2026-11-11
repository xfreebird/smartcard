import Foundation

/// Persistence is independent of signing and presentation and replaceable in tests/previews.
@MainActor
final class PreferencesActivityStore: ActivityStoring {
    private let defaults: UserDefaults
    private let documentsDirectory: URL?
    init(defaults: UserDefaults, documentsDirectory: URL? = nil) {
        self.defaults = defaults
        #if os(iOS)
        self.documentsDirectory = documentsDirectory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        #else
        self.documentsDirectory = documentsDirectory
        #endif
    }
    private func restored(_ items: [ActivityItem]) -> [ActivityItem] {
        guard let documentsDirectory else { return items }
        return items.map { SavedDocumentLocationPolicy.restored($0, documents: documentsDirectory) }
    }
    private func stored(_ items: [ActivityItem]) -> [ActivityItem] {
        guard let documentsDirectory else { return items }
        return items.map { SavedDocumentLocationPolicy.stored($0, documents: documentsDirectory) }
    }
    private func load(_ key: String) -> [ActivityItem]? {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ActivityItem].self, from: data) else { return nil }
        let values = restored(decoded)
        let normalized = stored(values)
        if normalized != decoded, let updated = try? JSONEncoder().encode(normalized) {
            defaults.set(updated, forKey: key)
        }
        return values
    }
    func load() -> [ActivityItem] { load("activity") ?? [] }
    func save(_ items: [ActivityItem]) {
        if let data = try? JSONEncoder().encode(stored(items)) { defaults.set(data, forKey: "activity") }
    }
    func loadDocuments() -> [ActivityItem]? { load("signedDocuments") }
    func saveDocuments(_ items: [ActivityItem]) {
        if let data = try? JSONEncoder().encode(stored(items)) { defaults.set(data, forKey: "signedDocuments") }
    }
    var recentsClearedAt: Date {
        get { defaults.object(forKey: "recentsClearedAt") as? Date ?? .distantPast }
        set { defaults.set(newValue, forKey: "recentsClearedAt") }
    }
}
