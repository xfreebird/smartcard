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

    @MainActor
    func testRecentsListExistingFilesUntilClearedAndPruningDropsMissingOnes() throws {
        let suite = "md.esemnbun.qa.recents.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: directory)
        }
        let present = directory.appendingPathComponent("present-semnat.pdf")
        try Data("%PDF".utf8).write(to: present)
        let model = DocumentLibraryModel(store: PreferencesActivityStore(defaults: defaults)) {}
        model.log(ActivityItem(title: "present-semnat.pdf", subtitle: "", ok: true, fileURL: present, signedOutput: true))
        model.log(ActivityItem(title: "gone.pdf", subtitle: "", ok: true,
                               fileURL: directory.appendingPathComponent("gone.pdf"), signedOutput: true))
        model.log(ActivityItem(title: "portal request", subtitle: "", ok: true))

        XCTAssertEqual(model.recentDocuments.map(\.title), ["present-semnat.pdf"])
        model.pruneMissingFiles()
        XCTAssertEqual(model.activity.map(\.title), ["portal request", "present-semnat.pdf"])
        model.pruneMissingFiles()
        XCTAssertEqual(model.activity.count, 2)

        model.clearRecents()
        XCTAssertTrue(model.recentDocuments.isEmpty, "clearing recents keeps the history")
        XCTAssertEqual(model.activity.count, 2)
        let relaunched = DocumentLibraryModel(store: PreferencesActivityStore(defaults: defaults)) {}
        XCTAssertEqual(relaunched.recentsClearedAt, model.recentsClearedAt)
        XCTAssertTrue(relaunched.recentDocuments.isEmpty)
        XCTAssertEqual(relaunched.activity.map(\.title), ["portal request", "present-semnat.pdf"])
    }

    @MainActor
    func testDeletingAnAlreadyRemovedSavedFileForgetsIt() {
        let store = MemoryActivityStore()
        var changes = 0
        let model = DocumentLibraryModel(store: store) { changes += 1 }
        let missing = ActivityItem(title: "moved-semnat.pdf", subtitle: "", ok: true,
                                   fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf"),
                                   signedOutput: true)
        model.log(missing)
        XCTAssertEqual(model.savedDocuments, [missing])
        XCTAssertTrue(model.deleteSavedDocuments([missing]))
        XCTAssertTrue(model.savedDocuments.isEmpty)
        XCTAssertEqual(store.loadOrMigrateDocuments(), [])
        XCTAssertEqual(changes, 2)
    }
}
