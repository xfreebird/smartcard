import Foundation

@MainActor
protocol ActivityStoring: AnyObject {
    func load() -> [ActivityItem]
    func save(_ items: [ActivityItem])
    /// nil means an existing installation has not migrated its signed-document library yet.
    func loadDocuments() -> [ActivityItem]?
    func saveDocuments(_ items: [ActivityItem])
    var recentsClearedAt: Date { get set }
}

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

@MainActor
final class MemoryActivityStore: ActivityStoring {
    private var items: [ActivityItem] = []
    private var documents: [ActivityItem]?
    var recentsClearedAt = Date.distantPast
    func load() -> [ActivityItem] { items }
    func save(_ items: [ActivityItem]) { self.items = items }
    func loadDocuments() -> [ActivityItem]? { documents }
    func saveDocuments(_ items: [ActivityItem]) { documents = items }
}

@MainActor
extension ActivityStoring {
    /// Seed once, before history is pruned. An intentionally empty library stays empty.
    func loadOrMigrateDocuments() -> [ActivityItem] {
        if let documents = loadDocuments() { return documents }
        var seen = Set<URL>()
        let documents = load().filter { item in
            item.isSignedDocument && seen.insert(item.fileURL!.standardizedFileURL).inserted
        }
        saveDocuments(documents)
        return documents
    }
}
