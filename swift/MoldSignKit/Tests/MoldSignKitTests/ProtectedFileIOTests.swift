import XCTest
@testable import MoldSignKit

final class ProtectedFileIOTests: XCTestCase {
    func testExclusiveOutputAndInputPreservation() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("original")
        let original = Data("Keep this content".utf8)
        try ProtectedFileIO.saveNew(original, to: file)
        XCTAssertThrowsError(try ProtectedFileIO.saveNew(Data("replacement".utf8), to: file))
        XCTAssertEqual(try ProtectedFileIO.read(file), original)
        let link = directory.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: file)
        XCTAssertThrowsError(try ProtectedFileIO.read(link))
        XCTAssertThrowsError(try ProtectedFileIO.saveNew(Data(), to: link))
        XCTAssertThrowsError(try ProtectedFileIO.overwriteAndRemove(link))
        XCTAssertEqual(try Data(contentsOf: file), original)
    }
    func testHardLinksRefusedAndExplicitRemoval() throws {
        #if !os(iOS)
        // Container /tmp may be overlayfs, deliberately unsupported for removal.
        // Linux /dev/shm is tmpfs, an explicitly supported local filesystem.
        #if os(Linux)
        let base = URL(fileURLWithPath: "/dev/shm", isDirectory: true)
        #else
        let base = FileManager.default.temporaryDirectory
        #endif
        let directory = base.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("original")
        let original = Data(repeating: 42, count: 65537)
        try ProtectedFileIO.saveNew(original, to: file)
        let linked = directory.appendingPathComponent("hardlink")
        try FileManager.default.linkItem(at: file, to: linked)
        XCTAssertThrowsError(try ProtectedFileIO.overwriteAndRemove(file))
        XCTAssertEqual(try Data(contentsOf: linked), original)
        try FileManager.default.removeItem(at: linked)
        try ProtectedFileIO.overwriteAndRemove(file)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        #endif
    }
}
