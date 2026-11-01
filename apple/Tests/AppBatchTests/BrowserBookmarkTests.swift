import XCTest
@testable import AppBatch

final class BrowserBookmarkTests: XCTestCase {
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
        defer { preferences.removePersistentDomain(forName: suite) }
        let repository = BookmarkRepository(preferences: preferences)
        let seed = try XCTUnwrap(BrowserBookmark.make(id: "seed", title: "MSign", address: "msign.gov.md", icon: "globe"))
        XCTAssertEqual(repository.load(defaults: [seed]), [seed])
        var custom = try XCTUnwrap(BrowserBookmark.make(title: "My portal", address: "https://example.md/portal", icon: "star"))
        repository.save([seed, custom])
        custom.title = "Updated portal"
        custom.icon = "building"
        repository.save([custom])
        XCTAssertEqual(BookmarkRepository(preferences: preferences).load(defaults: [seed]), [custom])
        repository.save([])
        XCTAssertEqual(BookmarkRepository(preferences: preferences).load(defaults: [seed]), [])
    }
}
