import Foundation

struct BrowserBookmark: Codable, Equatable, Identifiable {
    let id: String
    var title: String
    var url: URL
    var icon: String
    var assetName: String?

    static let icons = ["globe", "bookmark", "document", "person", "building", "star"]
    var symbol: String { Self.symbol(for: icon) }
    static func symbol(for icon: String) -> String {
        switch icon {
        case "document": return "doc.text"
        case "person": return "person.crop.circle"
        case "building": return "building.2"
        case "star": return "star"
        case "bookmark": return "bookmark"
        default: return "globe"
        }
    }

    static func webURL(_ input: String) -> URL? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !text.contains(where: { $0.isWhitespace || $0.isNewline }) else { return nil }
        if let scheme = URLComponents(string: text)?.scheme, !["https", "http"].contains(scheme.lowercased()) {
            return nil
        }
        let candidate = text.contains("://") ? text : "https://" + text
        guard let url = URL(string: candidate), ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, !host.isEmpty, url.user == nil, url.password == nil else { return nil }
        return url
    }

    static func make(id: String = UUID().uuidString, title: String, address: String, icon: String) -> BrowserBookmark? {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, let url = webURL(address), icons.contains(icon) else { return nil }
        return .init(id: id, title: title, url: url, icon: icon)
    }
}

/// Persist an explicit empty collection so removing the last bookmark never re-seeds defaults.
struct BookmarkRepository {
    let preferences: UserDefaults
    private let key = "browserBookmarks.v1"

    func load(defaults: [BrowserBookmark]) -> [BrowserBookmark] {
        guard let data = preferences.data(forKey: key),
              let items = try? JSONDecoder().decode([BrowserBookmark].self, from: data) else { return defaults }
        var seen = Set<String>()
        return items.filter { item in
            !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && BrowserBookmark.webURL(item.url.absoluteString) != nil
                && BrowserBookmark.icons.contains(item.icon)
                && seen.insert(item.id).inserted
        }
    }

    func save(_ items: [BrowserBookmark]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        preferences.set(data, forKey: key)
    }
}
