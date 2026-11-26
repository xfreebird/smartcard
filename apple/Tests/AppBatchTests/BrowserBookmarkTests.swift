import XCTest
@testable import AppBatch

final class BrowserBookmarkTests: XCTestCase {
    private final class InMemoryCloudStore: BookmarkCloudStore {
        private var values: [String: Data] = [:]
        func data(forKey defaultName: String) -> Data? { values[defaultName] }
        func set(_ value: Any?, forKey defaultName: String) { values[defaultName] = value as? Data }
        @discardableResult func synchronize() -> Bool { true }
        var changeNotificationObject: AnyObject { self }
    }

    func testWebAddressesNormalizeAndRejectNonWebOrCredentialURLs() {
        XCTAssertEqual(BrowserBookmark.webURL(" example.md/path ")?.absoluteString, "https://example.md/path")
        for address in ["", "javascript:alert(1)", "file:///tmp/test", "data:text/html,test", "https://user:password@example.md/", "https://", "https://example.md/a b"] {
            XCTAssertNil(BrowserBookmark.webURL(address), address)
        }
        XCTAssertNil(BrowserBookmark.make(title: "  ", address: "https://example.md", icon: "globe"))
    }

    func testSavedEditsAndEmptyListSurviveRelaunch() throws {
        let suite = "md.esemnbun.qa.bookmarks.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        let key = "browserBookmarks.test.\(UUID().uuidString)"
        let cloud = NSUbiquitousKeyValueStore.default
        defer {
            preferences.removePersistentDomain(forName: suite)
            cloud.removeObject(forKey: key)
        }
        let repository = BookmarkRepository(preferences: preferences, key: key)
        let seed = try XCTUnwrap(BrowserBookmark.make(id: "seed", title: "MSign", address: "msign.gov.md", icon: "globe"))
        XCTAssertEqual(repository.load(defaults: [seed]), [seed])
        var custom = try XCTUnwrap(BrowserBookmark.make(title: "My portal", address: "https://example.md/portal", icon: "star"))
        repository.save([seed, custom])
        custom.title = "Updated portal"
        custom.icon = "building"
        repository.save([custom])
        XCTAssertEqual(BookmarkRepository(preferences: preferences, key: key).load(defaults: [seed]), [custom])
        repository.save([])
        XCTAssertEqual(BookmarkRepository(preferences: preferences, key: key).load(defaults: [seed]), [])
    }

    func testBookmarkChangesHydrateAnotherDeviceFromICloudKeyValueStore() throws {
        let sourceSuite = "md.esemnbun.qa.bookmarks.source.\(UUID().uuidString)"
        let destinationSuite = "md.esemnbun.qa.bookmarks.destination.\(UUID().uuidString)"
        let source = try XCTUnwrap(UserDefaults(suiteName: sourceSuite))
        let destination = try XCTUnwrap(UserDefaults(suiteName: destinationSuite))
        let key = "browserBookmarks.sync.\(UUID().uuidString)"
        let cloud = InMemoryCloudStore()
        defer {
            source.removePersistentDomain(forName: sourceSuite)
            destination.removePersistentDomain(forName: destinationSuite)
        }
        let item = try XCTUnwrap(BrowserBookmark.make(id: "evo", title: "EVO", address: "https://evomoldova.gov.md", icon: "star"))
        BookmarkRepository(preferences: source, cloud: cloud, key: key).save([item])
        XCTAssertEqual(BookmarkRepository(preferences: destination, cloud: cloud, key: key).load(defaults: []), [item])
    }

    func testEveryOfferedIconHasASymbolAndUnknownIconsFallBack() throws {
        let symbols = BrowserBookmark.icons.map(BrowserBookmark.symbol(for:))
        XCTAssertEqual(symbols, ["globe", "bookmark", "doc.text", "person.crop.circle", "building.2", "star"])
        XCTAssertEqual(BrowserBookmark.symbol(for: "unknown"), "globe")
        XCTAssertEqual(try XCTUnwrap(BrowserBookmark.make(title: "Docs", address: "pki.md", icon: "document")).symbol, "doc.text")
    }

    func testExternalCloudChangesReplaceLocalBookmarks() throws {
        let suite = "md.esemnbun.qa.bookmarks.observe.\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { preferences.removePersistentDomain(forName: suite) }
        let key = "browserBookmarks.observe"
        let cloud = InMemoryCloudStore()
        let repository = BookmarkRepository(preferences: preferences, cloud: cloud, key: key)
        var received: [[BrowserBookmark]] = []
        repository.observeChanges { received.append($0) }
        let remote = try XCTUnwrap(BrowserBookmark.make(id: "remote", title: "Remote", address: "https://msign.gov.md", icon: "star"))
        cloud.set(try JSONEncoder().encode([remote]), forKey: key)
        NotificationCenter.default.post(name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: cloud)
        // Another store's notification and undecodable data are ignored.
        NotificationCenter.default.post(name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: InMemoryCloudStore())
        cloud.set(Data("not json".utf8), forKey: key)
        NotificationCenter.default.post(name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: cloud)
        XCTAssertEqual(received, [[remote]])
        XCTAssertEqual(BookmarkRepository(preferences: preferences, cloud: InMemoryCloudStore(), key: key).load(defaults: []), [remote])
    }
}
