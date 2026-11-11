import Foundation
import XCTest
@testable import MoldSignGnome

final class VerificationWorkspaceTests: XCTestCase {
    func testBatchResultCannotAppearUnderAnotherFilename() {
        let workspace = VerificationWorkspace()
        let first = URL(fileURLWithPath: "/first.pdf")
        let second = URL(fileURLWithPath: "/second.pdf")
        let generation = workspace.begin(clearDocuments: true)
        workspace.select(first)
        workspace.select(second)
        var report = SignatureReport()
        report.signer = "First signer"
        XCTAssertTrue(workspace.complete([report], for: first, generation: generation))
        XCTAssertEqual(workspace.file, second)
        XCTAssertNil(workspace.reports)
        XCTAssertEqual(workspace.documents.first?.url, first)
        XCTAssertTrue(workspace.complete([], for: second, generation: generation))
        XCTAssertEqual(workspace.reports?.count, 0)
    }

    func testResetRejectsPendingResultAndClearsSelection() {
        let workspace = VerificationWorkspace()
        let url = URL(fileURLWithPath: "/first.pdf")
        let generation = workspace.begin(clearDocuments: true)
        workspace.select(url)
        workspace.begin(clearDocuments: true)
        XCTAssertFalse(workspace.complete([], for: url, generation: generation))
        XCTAssertNil(workspace.file)
        XCTAssertTrue(workspace.documents.isEmpty)
    }
}
