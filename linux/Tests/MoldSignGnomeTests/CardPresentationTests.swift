import XCTest
@testable import MoldSignGnome

final class CardPresentationTests: XCTestCase {
    func testReadingCardUsesPlaceholdersAndKeepsReaderIdentity() {
        let card = CardSlot(reader: "Reader A", generation: 1)
        let content = CardItemContent(card: card, index: 0, count: 2, busy: false, selected: true, expanded: false)
        XCTAssertEqual(content.face.state, .reading)
        XCTAssertNil(content.face.surname)
        XCTAssertNil(content.face.validUntil)
        XCTAssertEqual(content.face.reader, "Reader A")
        XCTAssertTrue(content.label.contains("Reader A"))
        XCTAssertFalse(content.face.chosen)
    }

    func testFailedReadKeepsProblemAndSelectedAccessibility() {
        let card = CardSlot(reader: "Reader B", generation: 2, problem: "Card unavailable")
        let collapsed = CardItemContent(card: card, index: 1, count: 2, busy: false, selected: true, expanded: false)
        XCTAssertEqual(collapsed.face.state, .problem("Card unavailable"))
        XCTAssertTrue(collapsed.label.contains("Card unavailable"))
        let expanded = CardItemContent(card: card, index: 1, count: 2, busy: false, selected: true, expanded: true)
        XCTAssertTrue(expanded.face.chosen)
        XCTAssertTrue(expanded.selected)
        XCTAssertTrue(expanded.label.contains("Reader B"))
    }

    func testEmptyReaderAndFailureHaveDifferentPlaceholders() {
        let empty = PlaceholderContent(status: .empty(reader: "Reader A"))
        XCTAssertEqual(empty.kind, .insertCard)
        XCTAssertEqual(empty.caption, "Reader A")
        let failed = PlaceholderContent(status: .error(message: "Read failed", recovery: "Retry"))
        XCTAssertEqual(failed.kind, .error)
        XCTAssertEqual(failed.title, "Read failed")
        XCTAssertEqual(failed.caption, "Retry")
        XCTAssertEqual(PlaceholderContent(status: .noReader).kind, .noReader)
    }
}
