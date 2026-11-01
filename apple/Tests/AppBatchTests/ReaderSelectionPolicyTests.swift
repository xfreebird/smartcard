import XCTest
@testable import AppBatch

final class ReaderSelectionPolicyTests: XCTestCase {
    func testPreferredReaderReturnsAfterTransientCardAbsence() {
        let both = ["reader-one", "reader-two"]
        var preferred = ReaderSelectionPolicy.preferredReader(previous: nil, available: both)
        XCTAssertEqual(preferred, "reader-one")
        // The user selects the second reader, then its card briefly leaves the ready state.
        preferred = "reader-two"
        preferred = ReaderSelectionPolicy.preferredReader(previous: preferred, available: ["reader-one"])
        XCTAssertEqual(preferred, "reader-two")
        XCTAssertEqual(ReaderSelectionPolicy.activeReader(preferred: preferred, available: ["reader-one"]), "reader-one")
        preferred = ReaderSelectionPolicy.preferredReader(previous: preferred, available: [])
        XCTAssertNil(ReaderSelectionPolicy.activeReader(preferred: preferred, available: []))
        preferred = ReaderSelectionPolicy.preferredReader(previous: preferred, available: both)
        XCTAssertEqual(ReaderSelectionPolicy.activeReader(preferred: preferred, available: both), "reader-two")
    }
}
