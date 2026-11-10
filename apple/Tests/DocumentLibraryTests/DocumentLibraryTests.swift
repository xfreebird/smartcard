import XCTest
@testable import DocumentLibrary

final class DocumentLibraryTests: XCTestCase {
    @MainActor
    func testHistoryClearDoesNotRemoveMigratedDocumentsAfterRelaunch() throws {
        let suite = "md.esemnbun.qa.documents.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = PreferencesActivityStore(defaults: defaults)
        let signed = ActivityItem(title: "result.pdf", subtitle: "signed", ok: true,
                                  fileURL: URL(fileURLWithPath: "/tmp/result.pdf"), signedOutput: true)
        let verified = ActivityItem(title: "verified-semnat.pdf", subtitle: "verified", ok: true,
                                    fileURL: URL(fileURLWithPath: "/tmp/verified-semnat.pdf"), signedOutput: false)
        store.save([signed, verified])
        XCTAssertEqual(store.loadOrMigrateDocuments(), [signed])
        store.save([])
        let reloaded = PreferencesActivityStore(defaults: defaults)
        XCTAssertTrue(reloaded.load().isEmpty)
        XCTAssertEqual(reloaded.loadOrMigrateDocuments(), [signed])
    }

    @MainActor
    func testMigrationDeduplicatesLegacyOutputsAndDoesNotReseedExistingLibrary() {
        let store = MemoryActivityStore()
        let url = URL(fileURLWithPath: "/tmp/test-semnat.pdf")
        let latest = ActivityItem(title: "signed", subtitle: "", ok: true, fileURL: url)
        let older = ActivityItem(title: "older", subtitle: "", ok: true, fileURL: url)
        let failure = ActivityItem(title: "failed", subtitle: "", ok: false, fileURL: url)
        store.save([latest, older, failure])
        XCTAssertEqual(store.loadOrMigrateDocuments(), [latest])
        store.saveDocuments([])
        XCTAssertTrue(store.loadOrMigrateDocuments().isEmpty)
    }

    @MainActor
    func testLibraryDoesNotInheritHistoryLimitOrPruning() {
        let store = MemoryActivityStore()
        let documents = (0..<120).map { index in
            ActivityItem(title: "\(index).pdf", subtitle: "", ok: true,
                         fileURL: URL(fileURLWithPath: "/tmp/\(index).pdf"), signedOutput: true)
        }
        store.saveDocuments(documents)
        store.save(Array(documents.prefix(100)))
        store.save([])
        XCTAssertEqual(store.loadOrMigrateDocuments(), documents)
    }
    @MainActor
    func testProtectedOutputsPersistWithoutBecomingSignedDocuments() throws {
        let suite = "md.esemnbun.qa.protected.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let root = URL(fileURLWithPath: "/tmp/old-container/Documents")
        let store = PreferencesActivityStore(defaults: defaults, documentsDirectory: root)
        let outputs = ["encrypt", "decrypt"].map { operation in
            ActivityItem(title: "file", subtitle: "", ok: true,
                         fileURL: root.appendingPathComponent("Protected/unique/\(operation).pdf"),
                         signedOutput: false, protectionOperation: operation)
        }
        XCTAssertTrue(outputs.allSatisfy(\.isSavedDocument))
        XCTAssertFalse(outputs.contains(where: \.isSignedDocument))
        store.saveDocuments(outputs)
        store.save([])
        let newRoot = URL(fileURLWithPath: "/tmp/new-container/Documents")
        let restored = PreferencesActivityStore(defaults: defaults, documentsDirectory: newRoot).loadOrMigrateDocuments()
        XCTAssertEqual(restored.map(\.protectionOperation), ["encrypt", "decrypt"])
        XCTAssertTrue(restored.allSatisfy(\.isSavedDocument))
        XCTAssertFalse(restored.contains(where: \.isSignedDocument))
        XCTAssertTrue(restored.allSatisfy { $0.fileURL!.path.hasPrefix(newRoot.path + "/") })
        var failed = outputs[0]; failed.ok = false
        XCTAssertFalse(failed.isSavedDocument)
    }

}
