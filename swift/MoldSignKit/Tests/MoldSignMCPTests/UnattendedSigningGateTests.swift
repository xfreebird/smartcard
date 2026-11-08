import Foundation
import XCTest
@testable import MoldSignMCP

final class UnattendedSigningGateTests: XCTestCase {
    private var directory: URL!
    private var root: TrustedRoot!

    override func setUpWithError() throws {
        let canonical = try XCTUnwrap(realpath(FileManager.default.temporaryDirectory.path, nil))
        defer { free(canonical) }
        directory = URL(fileURLWithPath: String(cString: canonical))
            .appendingPathComponent("signing-gate-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false,
            attributes: [.posixPermissions: 0o700])
        root = try TrustedRoot(path: directory.path, privateDirectory: true)
    }

    override func tearDownWithError() throws {
        root = nil
        try FileManager.default.removeItem(at: directory)
    }

    func testFailureMarkerSurvivesNewGateAndRoot() throws {
        try UnattendedSigningGate(root: root).begin()
        let restartedRoot = try TrustedRoot(path: directory.path, privateDirectory: true)
        let restarted = UnattendedSigningGate(root: restartedRoot)
        XCTAssertThrowsError(try restarted.begin()) { error in
            guard case MCPFailure.signingDisabled = error else { return XCTFail("Expected signingDisabled") }
        }
        XCTAssertThrowsError(try restarted.complete(), "another process must not clear the previous marker")
    }

    func testSuccessfulCompletionAllowsTheNextOperation() throws {
        let gate = UnattendedSigningGate(root: root)
        try gate.begin()
        XCTAssertThrowsError(try gate.begin())
        try gate.complete()
        let restarted = UnattendedSigningGate(root: root)
        try restarted.begin()
        try restarted.complete()
    }

    func testOldOperationCannotClearAReplacementMarker() throws {
        let old = UnattendedSigningGate(root: root)
        try old.begin()
        try root.remove(UnattendedSigningGate.markerName) // Explicit operator reset.
        let replacement = UnattendedSigningGate(root: root)
        try replacement.begin()
        XCTAssertThrowsError(try old.complete())
        XCTAssertThrowsError(try UnattendedSigningGate(root: root).begin())
        try replacement.complete()
    }

    func testRemovalRejectsTraversal() {
        XCTAssertThrowsError(try root.remove("../outside"))
    }
}
