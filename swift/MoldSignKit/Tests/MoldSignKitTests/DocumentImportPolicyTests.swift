import Foundation
import XCTest
@testable import MoldSignKit

final class DocumentImportPolicyTests: XCTestCase {
    func testDuplicateInputsAndExistingFilesDoNotCreateExtraWork() {
        let first = URL(fileURLWithPath: "/documents/first.pdf")
        let second = URL(fileURLWithPath: "/documents/second.pdf")
        let alias = URL(fileURLWithPath: "/documents/temporary/../second.pdf")
        XCTAssertEqual(DocumentImportPolicy.newFiles([first, second, second, alias], excluding: [first]), [second])
    }

    func testRejectsDirectoriesAndRemoteURLsAndPreservesSelectionOrder() {
        let first = URL(fileURLWithPath: "/documents/a.pdf")
        let second = URL(fileURLWithPath: "/documents/b.xml")
        let folder = URL(fileURLWithPath: "/documents/folder", isDirectory: true)
        let remote = URL(string: "https://example.invalid/document.pdf")!
        XCTAssertEqual(DocumentImportPolicy.newFiles([second, folder, remote, first], excluding: []), [second, first])
        XCTAssertEqual(DocumentImportPolicy.newFiles([], excluding: [first]), [])
    }
}
