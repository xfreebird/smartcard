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

    @MainActor
    func testDeletionRejectsSubstitutedURLForSavedIdentifier() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let savedURL = root.appendingPathComponent("saved.pdf")
        let otherURL = root.appendingPathComponent("other.pdf")
        try Data("saved".utf8).write(to: savedURL)
        try Data("keep".utf8).write(to: otherURL)
        let store = MemoryActivityStore()
        let model = DocumentLibraryModel(store: store, onDocumentsChanged: {})
        let saved = ActivityItem(title: "saved.pdf", subtitle: "", ok: true,
                                 fileURL: savedURL, signedOutput: true)
        model.log(saved)
        var substituted = saved
        substituted.fileURL = otherURL

        XCTAssertFalse(model.deleteSavedDocuments([substituted]))
        XCTAssertEqual(try Data(contentsOf: otherURL), Data("keep".utf8))
        XCTAssertEqual(try Data(contentsOf: savedURL), Data("saved".utf8))
        XCTAssertEqual(store.loadOrMigrateDocuments(), [saved])

        XCTAssertTrue(model.deleteSavedDocuments([saved]))
        XCTAssertFalse(FileManager.default.fileExists(atPath: savedURL.path))
        XCTAssertEqual(try Data(contentsOf: otherURL), Data("keep".utf8))
        XCTAssertTrue(store.loadOrMigrateDocuments().isEmpty)
    }
}
