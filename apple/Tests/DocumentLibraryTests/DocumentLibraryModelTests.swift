import XCTest
@testable import DocumentLibrary

final class DocumentLibraryModelTests: XCTestCase {
    @MainActor
    func testSwitchingStoresKeepsHistoryAndDiscoveryIsolated() {
        let live = MemoryActivityStore()
        let demo = MemoryActivityStore()
        var discoveries = 0
        let model = DocumentLibraryModel(store: live) { discoveries += 1 }
        let real = ActivityItem(title: "real.pdf", subtitle: "", ok: true,
                                fileURL: URL(fileURLWithPath: "/tmp/real.pdf"), signedOutput: true)
        let preview = ActivityItem(title: "demo.pdf", subtitle: "", ok: true,
                                   fileURL: URL(fileURLWithPath: "/tmp/demo.pdf"), signedOutput: true)
        model.log(real)
        model.reload(store: demo, onDocumentsChanged: {})
        XCTAssertTrue(model.activity.isEmpty)
        XCTAssertTrue(model.savedDocuments.isEmpty)
        model.log(preview)
        model.clearActivity()
        XCTAssertEqual(model.savedDocuments, [preview])
        XCTAssertEqual(live.load(), [real])
        XCTAssertEqual(discoveries, 1)
        model.reload(store: live) { discoveries += 1 }
        XCTAssertEqual(model.activity, [real])
        XCTAssertEqual(model.savedDocuments, [real])
    }

    @MainActor
    func testDeletionCannotRemoveAFileOutsideTheLibrary() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("keep".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let model = DocumentLibraryModel(store: MemoryActivityStore(), onDocumentsChanged: {})
        let foreign = ActivityItem(title: "foreign", subtitle: "", ok: true, fileURL: url, signedOutput: true)
        XCTAssertTrue(model.deleteSavedDocuments([foreign]))
        XCTAssertEqual(try Data(contentsOf: url), Data("keep".utf8))
    }
}
