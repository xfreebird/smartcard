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

protocol BookmarkCloudStore: AnyObject {
    func data(forKey defaultName: String) -> Data?
    func set(_ value: Any?, forKey defaultName: String)
    @discardableResult func synchronize() -> Bool
    var changeNotificationObject: AnyObject { get }
}

extension NSUbiquitousKeyValueStore: BookmarkCloudStore {
    var changeNotificationObject: AnyObject { self }
}

/// Persists an explicit empty collection so removing the last bookmark never re-seeds defaults.
/// The iCloud key-value store is deliberately limited to bookmark records: browser history, cookies and page data
/// remain local to the device. A last completed edit wins if the same bookmark collection is changed concurrently.
final class BookmarkRepository {
    let preferences: UserDefaults
    private let key: String
    private let cloud: any BookmarkCloudStore
    private var changeObserver: NSObjectProtocol?

    init(preferences: UserDefaults, cloud: any BookmarkCloudStore = NSUbiquitousKeyValueStore.default, key: String = "browserBookmarks.v1") {
        self.preferences = preferences
        self.cloud = cloud
        self.key = key
    }

    deinit {
        if let changeObserver { NotificationCenter.default.removeObserver(changeObserver) }
    }

    func load(defaults: [BrowserBookmark]) -> [BrowserBookmark] {
        cloud.synchronize()
        if let cloudItems = decoded(cloud.data(forKey: key)) {
            persistLocally(cloudItems)
            return cloudItems
        }
        if let localItems = decoded(preferences.data(forKey: key)) {
            persistInCloud(localItems)
            return localItems
        }
        save(defaults)
        return defaults
    }

    func observeChanges(_ handler: @escaping ([BrowserBookmark]) -> Void) {
        changeObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud.changeNotificationObject,
            queue: .main
        ) { [weak self] _ in
            guard let self, let items = self.decoded(self.cloud.data(forKey: self.key)) else { return }
            self.persistLocally(items)
            handler(items)
        }
    }

    private func decoded(_ data: Data?) -> [BrowserBookmark]? {
        guard let data, let items = try? JSONDecoder().decode([BrowserBookmark].self, from: data) else { return nil }
        var seen = Set<String>()
        let valid = items.filter { item in
            !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && BrowserBookmark.webURL(item.url.absoluteString) != nil
                && BrowserBookmark.icons.contains(item.icon)
                && seen.insert(item.id).inserted
        }
        return valid.count == items.count ? valid : nil
    }

    func save(_ items: [BrowserBookmark]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        preferences.set(data, forKey: key)
        cloud.set(data, forKey: key)
        cloud.synchronize()
    }

    private func persistLocally(_ items: [BrowserBookmark]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        preferences.set(data, forKey: key)
    }

    private func persistInCloud(_ items: [BrowserBookmark]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        cloud.set(data, forKey: key)
        cloud.synchronize()
    }
}
