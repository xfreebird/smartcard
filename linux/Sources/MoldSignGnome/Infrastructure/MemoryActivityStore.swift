import Foundation

final class MemoryActivityStore: ActivityStoring {
    private var activity: [ActivityItem] = []
    private var documents: [ActivityItem] = []
    func loadActivity() -> [ActivityItem] { activity }
    func loadDocuments() -> [ActivityItem] { documents }
    func saveActivity(_ items: [ActivityItem]) { activity = items }
    func saveDocuments(_ items: [ActivityItem]) -> Bool {
        documents = items
        return true
    }
}
