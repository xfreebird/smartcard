import XCTest
@testable import MobileServices

final class SharedDocumentInboxTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("inbox-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    /// The share extension's layout: ShareInbox/<delivery>/<item>/<file>, then `.ready` last.
    private func deliver(_ files: [String: String], ready: Bool) throws -> URL {
        let delivery = root.appendingPathComponent("ShareInbox/\(UUID().uuidString)", isDirectory: true)
        for (name, text) in files {
            let item = delivery.appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: item, withIntermediateDirectories: true)
            try Data(text.utf8).write(to: item.appendingPathComponent(name))
        }
        if ready { try Data().write(to: delivery.appendingPathComponent(".ready")) }
        return delivery
    }

    func testOnlyCompleteDeliveriesMoveIntoTheAppDocuments() throws {
        let complete = try deliver(["contract.pdf": "pdf", "request.xml": "xml"], ready: true)
        let pending = try deliver(["partial.pdf": "still copying"], ready: false)
        let destination = root.appendingPathComponent("Documents/Shared Imports", isDirectory: true)

        let taken = SharedDocumentInbox.takeDocuments(from: root.appendingPathComponent("ShareInbox"), into: destination)

        XCTAssertEqual(Set(taken.map(\.lastPathComponent)), ["contract.pdf", "request.xml"])
        for url in taken {
            let moved = destination.appendingPathComponent(complete.lastPathComponent).resolvingSymlinksInPath().path
            XCTAssertTrue(url.resolvingSymlinksInPath().path.hasPrefix(moved + "/"), url.path)
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: complete.path), "the delivery moved")
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: destination.appendingPathComponent("\(complete.lastPathComponent)/.ready").path), "the marker is consumed")
        XCTAssertTrue(FileManager.default.fileExists(atPath: pending.path), "an unfinished delivery waits")
        XCTAssertEqual(SharedDocumentInbox.takeDocuments(from: root.appendingPathComponent("ShareInbox"), into: destination), [])
    }

    func testMissingInboxAndBlockedDestinationReturnNothing() throws {
        XCTAssertEqual(SharedDocumentInbox.takeDocuments(from: root.appendingPathComponent("absent"), into: root), [])
        let delivery = try deliver(["a.pdf": "a"], ready: true)
        // A file where the destination folder should be: the move fails and the delivery is kept.
        let blocked = root.appendingPathComponent("blocked")
        try Data().write(to: blocked)
        XCTAssertEqual(SharedDocumentInbox.takeDocuments(from: root.appendingPathComponent("ShareInbox"), into: blocked), [])
        XCTAssertTrue(FileManager.default.fileExists(atPath: delivery.appendingPathComponent(".ready").path))
    }

    func testSystemInboxIsEmptyWithoutTheAppGroup() {
        // Test processes have no app-group entitlement, so nothing is taken from a real inbox.
        XCTAssertEqual(SharedDocumentInbox.takeDocuments(), [])
    }
}
