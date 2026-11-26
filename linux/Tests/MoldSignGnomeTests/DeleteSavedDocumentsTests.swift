import Foundation
import XCTest
@testable import MoldSignGnome

final class DeleteSavedDocumentsTests: GnomeTestCase {
    func testSubstitutedPathCannotDeleteEitherFile() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let savedURL = root.appendingPathComponent("saved.pdf")
        let otherURL = root.appendingPathComponent("other.pdf")
        try Data("saved".utf8).write(to: savedURL)
        try Data("keep".utf8).write(to: otherURL)
        let saved = ActivityItem(kind: .signed, title: "saved.pdf", subtitle: "", ok: true, filePath: savedURL.path)
        var substituted = saved
        substituted.filePath = otherURL.path
        let rejected = DeleteSavedDocuments().execute([substituted], saved: [saved])
        XCTAssertTrue(rejected.failed)
        XCTAssertEqual(rejected.documents, [saved])
        XCTAssertEqual(try Data(contentsOf: savedURL), Data("saved".utf8))
        XCTAssertEqual(try Data(contentsOf: otherURL), Data("keep".utf8))

        let deleted = DeleteSavedDocuments().execute([saved, saved], saved: [saved])
        XCTAssertFalse(deleted.failed)
        XCTAssertTrue(deleted.documents.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: savedURL.path))
        XCTAssertEqual(try Data(contentsOf: otherURL), Data("keep".utf8))
    }

    func testForeignEntryCannotRemoveAFile() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("keep".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let foreign = ActivityItem(kind: .signed, title: "foreign", subtitle: "", ok: true, filePath: url.path)
        let result = DeleteSavedDocuments().execute([foreign], saved: [])
        XCTAssertFalse(result.failed)
        XCTAssertTrue(result.documents.isEmpty)
        XCTAssertEqual(try Data(contentsOf: url), Data("keep".utf8))
    }

    func testMissingFileIsRemovedFromTheLibrary() {
        let missing = ActivityItem(kind: .signed, title: "missing", subtitle: "", ok: true,
                                   filePath: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path)
        let result = DeleteSavedDocuments().execute([missing], saved: [missing])
        XCTAssertFalse(result.failed)
        XCTAssertTrue(result.documents.isEmpty)
    }

    func testSymbolicLinkAndTargetArePreserved() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let target = root.appendingPathComponent("target.pdf")
        let link = root.appendingPathComponent("link.pdf")
        try Data("keep".utf8).write(to: target)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)
        let saved = ActivityItem(kind: .signed, title: "link.pdf", subtitle: "", ok: true, filePath: link.path)
        let result = DeleteSavedDocuments().execute([saved], saved: [saved])
        XCTAssertTrue(result.failed)
        XCTAssertEqual(result.documents, [saved])
        XCTAssertEqual(try FileManager.default.destinationOfSymbolicLink(atPath: link.path), target.path)
        XCTAssertEqual(try Data(contentsOf: target), Data("keep".utf8))
    }
}
