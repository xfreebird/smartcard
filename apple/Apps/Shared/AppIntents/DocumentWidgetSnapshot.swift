#if os(iOS)
import Foundation
import WidgetKit

@MainActor
enum DocumentWidgetSnapshot {
    static let kind = "eSemnBunDocuments"
    static func refresh() {
        guard let defaults = UserDefaults(suiteName: "group.md.esemnbun.shared") else { return }
        let rows = DocumentDiscovery.documents().sorted { $0.date > $1.date }.prefix(3).map {
            ["id": $0.id.uuidString, "name": String(($0.fileURL?.lastPathComponent ?? "").prefix(200))]
        }
        // Metadata only. Never put URLs, document bytes, certificates or credentials in the widget cache.
        defaults.set(AppPreferencesStore.defaults.string(forKey: "appLanguage") ?? "system", forKey: "widgetLanguage")
        defaults.set(rows, forKey: "widgetRecentDocuments")
        defaults.set(DocumentDiscovery.enabled, forKey: "widgetDiscoveryEnabled")
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }

    static func open(_ url: URL) -> Bool {
        guard url.scheme == "esemnbun", url.host == "widget" else { return false }
        switch url.path {
        case "/verify": ShortcutNavigation.shared.choosePDF(for: .verify)
        case "/documents":
            ShortcutNavigation.shared.selectedDocumentID = nil
            ShortcutNavigation.shared.documentSearch = ""
            ShortcutNavigation.shared.openDocuments()
        case "/document":
            let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "id" })?.value
            guard let id, let uuid = UUID(uuidString: id), DocumentDiscovery.documents().contains(where: { $0.id == uuid }) else {
                ShortcutNavigation.shared.selectedDocumentID = nil
                ShortcutNavigation.shared.openDocuments()
                refresh()
                return true
            }
            ShortcutNavigation.shared.documentSearch = ""
            ShortcutNavigation.shared.openDocument(uuid)
        default: return false
        }
        return true
    }
}
#endif
