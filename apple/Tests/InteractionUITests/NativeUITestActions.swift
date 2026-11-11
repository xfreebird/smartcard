import XCTest

extension XCUIElement {
    @MainActor
    func activateControl() {
        #if os(macOS)
        click()
        #else
        tap()
        #endif
    }
}

@MainActor
extension XCUIApplication {
    func openProtection() {
        let menu = buttons["documents.menu"].firstMatch
        if menu.waitForExistence(timeout: 3) {
            menu.tapWhenReady()
        } else {
            let overflow = buttons["TopOverflowBarButtonItem"].firstMatch
            XCTAssertTrue(overflow.waitForExistence(timeout: 5))
            overflow.tapWhenReady()
            let action = descendants(matching: .any).matching(NSPredicate(
                format: "identifier == %@ OR label == %@", "documents.menu", "Protect files")).firstMatch
            action.tapWhenReady()
        }
        let protect = buttons["documents.protectFiles"].firstMatch
        protect.tapWhenReady()
    }

    func openHistoryClear() {
        let direct = buttons["documents.clear"].firstMatch
        if direct.waitForExistence(timeout: 3) {
            XCTAssertTrue(direct.isEnabled)
            direct.activateControl()
            return
        }
        #if os(iOS)
        // iPad can move primary toolbar actions into its native overflow menu.
        let overflow = buttons["TopOverflowBarButtonItem"].firstMatch
        XCTAssertTrue(overflow.waitForExistence(timeout: 5))
        overflow.activateControl()
        #endif
        let clear = descendants(matching: .any).matching(NSPredicate(
            format: "identifier == %@ OR label == %@", "documents.clear", "Clear list")).firstMatch
        XCTAssertTrue(clear.waitForExistence(timeout: 5))
        XCTAssertTrue(clear.isEnabled)
        clear.activateControl()
    }
}

extension XCUIElement {
    @MainActor
    func tapWhenReady(file: StaticString = #filePath, line: UInt = #line) {
        var previous = CGRect.null
        var stable = 0
        let ready = NSPredicate { _, _ in
            guard self.exists, self.isHittable, !self.frame.isEmpty else { stable = 0; return false }
            if self.frame == previous { stable += 1 } else { stable = 0 }
            previous = self.frame
            return stable >= 2
        }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: self)], timeout: 10)
        XCTAssertEqual(result, .completed, "Control must be visible and stable before tapping: \(self)", file: file, line: line)
        guard result == .completed else { return }
        activateControl()
    }
}
