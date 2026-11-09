import XCTest
@testable import MoldSignKit

final class DetachedDocumentAccessTests: XCTestCase {
    func testReferencesStayBeneathSelectedDirectory() throws {
        let fm = FileManager.default
        let temp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let root = temp.appendingPathComponent("documents")
        let nested = root.appendingPathComponent("nested")
        try fm.createDirectory(at: nested, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: temp) }
        let bytes = Data("synthetic document".utf8)
        try bytes.write(to: root.appendingPathComponent("șablon.pdf"))
        try bytes.write(to: nested.appendingPathComponent("document.pdf"))
        let outside = temp.appendingPathComponent("outside.pdf")
        try bytes.write(to: outside)
        try fm.createSymbolicLink(at: root.appendingPathComponent("link.pdf"), withDestinationURL: outside)
        try fm.createSymbolicLink(at: root.appendingPathComponent("linked"), withDestinationURL: temp)

        XCTAssertEqual(try DetachedDocumentAccess.read("șablon.pdf", beneath: root), bytes)
        XCTAssertEqual(try DetachedDocumentAccess.read("nested/document.pdf", beneath: root), bytes)
        for name in ["../outside.pdf", "nested/../../outside.pdf", outside.path,
                     "link.pdf", "linked/outside.pdf", "nested", "", "a\0b", "C:\\outside.pdf"] {
            XCTAssertThrowsError(try DetachedDocumentAccess.read(name, beneath: root), name)
        }
    }
    func testExplicitCompanionsDoNotGrantSiblingAccessAndRejectSymlinks() throws {
        let fm = FileManager.default
        let temp = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let signatures = temp.appendingPathComponent("signatures")
        let originals = temp.appendingPathComponent("originals")
        try fm.createDirectory(at: signatures, withIntermediateDirectories: true)
        try fm.createDirectory(at: originals, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: temp) }
        let selected = originals.appendingPathComponent("original.txt")
        let bytes = Data("chosen original".utf8)
        try bytes.write(to: selected)
        try bytes.write(to: originals.appendingPathComponent("private.txt"))
        try fm.createSymbolicLink(at: originals.appendingPathComponent("link.txt"), withDestinationURL: selected)
        let signature = signatures.appendingPathComponent("signature.xml")
        let names: Set<String> = ["original.txt", "private.txt", "link.txt", "../originals/private.txt"]
        let files = DetachedDocumentAccess.companions(named: names, near: signature,
            selected: [selected, originals.appendingPathComponent("link.txt")])
        XCTAssertEqual(files, ["original.txt": bytes])
        XCTAssertTrue(DetachedDocumentAccess.companions(named: names, near: signature, selected: []).isEmpty)
    }
    func testSelectedFileDoesNotRequireReadingItsParentDirectory() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let originals = root.appendingPathComponent("originals")
        try fm.createDirectory(at: originals, withIntermediateDirectories: true)
        defer {
            try? fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: originals.path)
            try? fm.removeItem(at: root)
        }
        let selected = originals.appendingPathComponent("original.txt")
        let bytes = Data("selected original".utf8)
        try bytes.write(to: selected)
        // Model a picker grant: the file is readable but the parent cannot be opened for reading.
        try fm.setAttributes([.posixPermissions: 0o111], ofItemAtPath: originals.path)
        let files = DetachedDocumentAccess.companions(named: ["original.txt"],
            near: root.appendingPathComponent("signature.xml"), selected: [selected])
        XCTAssertEqual(files, ["original.txt": bytes])
    }

}
