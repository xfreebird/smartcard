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
