import Foundation
import XCTest
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
