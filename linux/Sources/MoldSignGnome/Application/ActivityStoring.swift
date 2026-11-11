import Foundation

/// Demo and live sessions use independent stores; callers never branch on persistence mode.
protocol ActivityStoring {
    func loadActivity() -> [ActivityItem]
    func loadDocuments() -> [ActivityItem]
    func saveActivity(_ items: [ActivityItem])
    @discardableResult func saveDocuments(_ items: [ActivityItem]) -> Bool
}
