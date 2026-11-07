import XCTest
@testable import DocumentLibrary

final class SavedDocumentLocationPolicyTests: XCTestCase {
    private let old = "11111111-1111-1111-1111-111111111111"
    private let new = "22222222-2222-2222-2222-222222222222"
    private var current: URL { URL(fileURLWithPath: "/var/mobile/Containers/Data/Application/\(new)/Documents") }

    func testLegacyDeviceAndSimulatorContainersRebaseOnlyDocuments() {
        let paths = ["/var/mobile/Containers/Data/Application/\(old)/Documents/nested/result.pdf",
                     "/private/var/mobile/Containers/Data/Application/\(old)/Documents/nested/result.pdf",
                     "/Users/test/Library/Developer/CoreSimulator/Devices/\(new)/data/Containers/Data/Application/\(old)/Documents/nested/result.pdf"]
        for path in paths {
            let item = ActivityItem(title: "result", subtitle: "", ok: true, fileURL: URL(fileURLWithPath: path), signedOutput: true)
            let restored = SavedDocumentLocationPolicy.restored(item, documents: current)
            XCTAssertEqual(restored.fileURL, current.appendingPathComponent("nested/result.pdf"))
            XCTAssertEqual(restored.documentRelativePath, "nested/result.pdf")
            XCTAssertNil(SavedDocumentLocationPolicy.stored(restored, documents: current).fileURL)
        }
        for path in ["/tmp/result.pdf", "/var/mobile/Containers/Data/Application/not-a-uuid/Documents/result.pdf",
                     "/var/mobile/Containers/Data/Application/\(old)/Library/result.pdf",
                     "/tmp/Containers/Data/Application/\(old)/Documents/result.pdf"] {
            let item = ActivityItem(title: "external", subtitle: "", ok: true, fileURL: URL(fileURLWithPath: path))
            XCTAssertEqual(SavedDocumentLocationPolicy.restored(item, documents: current), item)
            XCTAssertEqual(SavedDocumentLocationPolicy.stored(item, documents: current), item)
        }
    }

    func testStoredReferencesRejectTraversalAndIgnoreExternalFallback() {
        for unsafe in ["../secret", "/absolute", "nested/../../secret", "nested//file", "", "a\\b", "file:secret", "a\0b"] {
            var item = ActivityItem(title: "unsafe", subtitle: "", ok: true, fileURL: URL(fileURLWithPath: "/tmp/fallback"))
            item.documentRelativePath = unsafe
            XCTAssertNil(SavedDocumentLocationPolicy.restored(item, documents: current).fileURL, unsafe)
        }
    }

    @MainActor
    func testStoreMigratesLegacyURLsThenSurvivesAnotherContainerChange() throws {
        let suite = "md.esemnbun.qa.locations.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let legacy = ActivityItem(title: "result", subtitle: "signed", ok: true,
            fileURL: URL(fileURLWithPath: "/var/mobile/Containers/Data/Application/\(old)/Documents/result.pdf"), signedOutput: true)
        let data = try JSONEncoder().encode([legacy])
        defaults.set(data, forKey: "activity")
        defaults.set(data, forKey: "signedDocuments")
        let store = PreferencesActivityStore(defaults: defaults, documentsDirectory: current)
        XCTAssertEqual(store.load().first?.fileURL, current.appendingPathComponent("result.pdf"))
        XCTAssertEqual(store.loadDocuments()?.first?.fileURL, current.appendingPathComponent("result.pdf"))
        let encoded = try JSONDecoder().decode([ActivityItem].self, from: XCTUnwrap(defaults.data(forKey: "signedDocuments")))
        XCTAssertNil(encoded.first?.fileURL)
        XCTAssertEqual(encoded.first?.documentRelativePath, "result.pdf")
        store.save([])
        let next = URL(fileURLWithPath: "/var/mobile/Containers/Data/Application/33333333-3333-3333-3333-333333333333/Documents")
        let relaunched = PreferencesActivityStore(defaults: defaults, documentsDirectory: next)
        XCTAssertTrue(relaunched.load().isEmpty)
        XCTAssertEqual(relaunched.loadDocuments()?.first?.fileURL, next.appendingPathComponent("result.pdf"))
        XCTAssertEqual(relaunched.loadDocuments()?.first?.id, legacy.id)
    }
}
