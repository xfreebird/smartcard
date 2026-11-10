import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome

final class DocumentsStoreTests: XCTestCase {
    func testIndependentInvalidSignatureOrDigestOutranksMissingOriginal() {
        var missing = SignatureReport()
        missing.signatureValid = true
        missing.chainTrusted = true
        missing.missingDetachedReferences = ["original.txt"]
        var invalidCrypto = SignatureReport()
        invalidCrypto.contentIntact = true
        invalidCrypto.signatureValid = false
        var invalidDigest = SignatureReport()
        invalidDigest.contentIntact = false
        invalidDigest.signatureValid = true
        for invalid in [invalidCrypto, invalidDigest] {
            if case .invalid = Verdict([missing, invalid]) {} else { XCTFail("Missing original must not hide independent invalidity") }
        }
    }

    func testMissingDetachedOriginalIsIncompleteRatherThanModified() {
        var report = SignatureReport()
        report.signatureValid = true
        report.chainTrusted = true
        report.missingDetachedReferences = ["original.txt"]
        if case .incomplete = Verdict([report]) {} else { XCTFail("Missing original must remain incomplete") }
        XCTAssertFalse(Verdict([report]).isValid)
    }

    func testLegacyMigrationSurvivesHistoryClearAndReload() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let output = root.appendingPathComponent("sample-semnat.pdf")
        try Data("synthetic fixture".utf8).write(to: output)
        let history = root.appendingPathComponent("activity.json")
        let library = root.appendingPathComponent("signed-documents.json")
        let item = ActivityItem(kind: .signed, title: "sample-semnat.pdf", subtitle: "signed", ok: true,
                                filePath: output.path)
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        try encoder.encode([item, item]).write(to: history)
        let migrated = Store.loadSignedDocuments(from: library, historyURL: history)
        XCTAssertEqual(migrated.count, 1)
        XCTAssertEqual(migrated.first?.filePath, output.path)
        try encoder.encode([ActivityItem]()).write(to: history)
        XCTAssertEqual(Store.loadSignedDocuments(from: library, historyURL: history).map(\.filePath), [output.path])
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))
        XCTAssertTrue(Store.saveSignedDocuments([], to: library))
        try encoder.encode([item]).write(to: history)
        XCTAssertTrue(Store.loadSignedDocuments(from: library, historyURL: history).isEmpty)
    }

    func testProtectionOutputsPersistWithoutBecomingSignedDocuments() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let items = [ActivityItem.Kind.encrypted, .decrypted].map { kind in
            ActivityItem(kind: kind, title: "output", subtitle: "", ok: true, filePath: root.appendingPathComponent(kind.rawValue).path)
        }
        XCTAssertTrue(items.allSatisfy(\.isSavedDocument))
        XCTAssertTrue(items.allSatisfy { !$0.isSignedDocument })
        let library = root.appendingPathComponent("documents.json")
        XCTAssertTrue(Store.saveSignedDocuments(items, to: library))
        let restored = Store.loadSignedDocuments(from: library, historyURL: root.appendingPathComponent("history.json"))
        XCTAssertEqual(restored.map(\.id), items.map(\.id))
        XCTAssertEqual(restored.map(\.kind), items.map(\.kind))
        XCTAssertEqual(restored.map(\.filePath), items.map(\.filePath))
        XCTAssertTrue(restored.allSatisfy(\.isSavedDocument))
    }

    func testPasswordRoundTripSavedLibraryAndDeletion() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let original = root.appendingPathComponent("input.txt")
        let encrypted = root.appendingPathComponent("input.txt.symmetric.p7m")
        let decrypted = root.appendingPathComponent("decrypted-input.txt")
        let bytes = Data("Synthetic document\nUnicode: ăîșț\n".utf8)
        try bytes.write(to: original)
        let password = "test-only-roundtrip"
        try ProtectedFileIO.saveNew(PasswordFileProtection.encrypt(ProtectedFileIO.read(original), password: password), to: encrypted)
        XCTAssertNotEqual(try Data(contentsOf: encrypted), bytes)
        try ProtectedFileIO.saveNew(PasswordFileProtection.decrypt(ProtectedFileIO.read(encrypted), password: password), to: decrypted)
        XCTAssertEqual(try Data(contentsOf: decrypted), bytes)
        let items = [ActivityItem(kind: .encrypted, title: encrypted.lastPathComponent, subtitle: "", ok: true, filePath: encrypted.path),
                     ActivityItem(kind: .decrypted, title: decrypted.lastPathComponent, subtitle: "", ok: true, filePath: decrypted.path)]
        let library = root.appendingPathComponent("documents.json")
        let history = root.appendingPathComponent("activity.json")
        XCTAssertTrue(Store.saveSignedDocuments(items, to: library))
        try Data("[]".utf8).write(to: history)
        var restored = Store.loadSignedDocuments(from: library, historyURL: history)
        XCTAssertEqual(restored.map(\.kind), [.encrypted, .decrypted])
        XCTAssertTrue(restored.allSatisfy { $0.isSavedDocument && !$0.isSignedDocument })
        try FileManager.default.removeItem(at: encrypted)
        restored.removeAll { $0.filePath == encrypted.path }
        XCTAssertTrue(Store.saveSignedDocuments(restored, to: library))
        XCTAssertEqual(Store.loadSignedDocuments(from: library, historyURL: history).map(\.filePath), [decrypted.path])
        XCTAssertFalse(FileManager.default.fileExists(atPath: encrypted.path))
        XCTAssertEqual(try Data(contentsOf: original), bytes)
        XCTAssertEqual(try Data(contentsOf: decrypted), bytes)
    }

    func testSavedLibraryHasNoHistoryLimit() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let library = root.appendingPathComponent("signed-documents.json")
        let items = (0..<120).map { ActivityItem(kind: .signed, title: "\($0).pdf", subtitle: "signed", ok: true,
                                               filePath: "/tmp/\($0).pdf") }
        XCTAssertTrue(Store.saveSignedDocuments(items, to: library))
        XCTAssertEqual(Store.loadSignedDocuments(from: library, historyURL: root.appendingPathComponent("empty.json")).count, 120)
    }
}
