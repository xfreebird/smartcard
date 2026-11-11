import Foundation

struct JSONActivityStore: ActivityStoring {
    func loadActivity() -> [ActivityItem] { Store.loadActivity() }
    func loadDocuments() -> [ActivityItem] { Store.loadSignedDocuments() }
    func saveActivity(_ items: [ActivityItem]) { Store.save(items) }
    func saveDocuments(_ items: [ActivityItem]) -> Bool { Store.saveSignedDocuments(items) }
}
