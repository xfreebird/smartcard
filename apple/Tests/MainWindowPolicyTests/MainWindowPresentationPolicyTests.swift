import XCTest
@testable import MainWindowPolicy

final class MainWindowPresentationPolicyTests: XCTestCase {
    private let showing = MainWindowState(isOrderedIn: true, isMiniaturized: false, applicationHidden: false)

    func testInsertionLeavesAShowingWindowInPlace() {
        XCTAssertTrue(showing.isShowing)
        XCTAssertEqual(MainWindowPresentationPolicy.action(for: .cardInsertion, window: showing), .updateContentOnly)
    }

    func testInsertionOpensTheWindowWhenNoneExists() {
        XCTAssertEqual(MainWindowPresentationPolicy.action(for: .cardInsertion, window: nil), .bringForward)
    }

    func testInsertionBringsBackAClosedMiniaturizedOrHiddenWindow() {
        var closed = showing
        closed.isOrderedIn = false
        var miniaturized = showing
        miniaturized.isMiniaturized = true
        var hidden = showing
        hidden.applicationHidden = true
        for state in [closed, miniaturized, hidden] {
            XCTAssertFalse(state.isShowing)
            XCTAssertEqual(MainWindowPresentationPolicy.action(for: .cardInsertion, window: state), .bringForward)
        }
    }

    func testExplicitRequestsAlwaysBringTheWindowForward() {
        let states: [MainWindowState?] = [nil, showing,
                                          MainWindowState(isOrderedIn: false, isMiniaturized: false, applicationHidden: false),
                                          MainWindowState(isOrderedIn: true, isMiniaturized: true, applicationHidden: true)]
        for state in states {
            XCTAssertEqual(MainWindowPresentationPolicy.action(for: .userAction, window: state), .bringForward)
        }
    }
}
