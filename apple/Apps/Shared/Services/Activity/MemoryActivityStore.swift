import Foundation

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
