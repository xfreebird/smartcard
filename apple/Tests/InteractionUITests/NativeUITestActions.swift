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
    var filePicker: XCUIElement { otherElements["Browse View (Picker)"].firstMatch }
    private var toolbarOverflow: XCUIElement {
        buttons.matching(NSPredicate(format: "identifier IN %@",
            ["TopOverflowBarButtonItem", "OverflowBarButtonItem"])).firstMatch
    }

    func cancelFilePicker() throws {
        try NativeFilePicker(app: self).cancel()
    }

    func openProtection() {
        let direct = buttons["documents.protectFiles"].firstMatch
        if direct.waitForExistence(timeout: 3), direct.isHittable {
            direct.tapWhenReady()
            return
        }
        let menu = buttons["documents.menu"].firstMatch
        if menu.waitForExistence(timeout: 3) {
            menu.tapWhenReady()
        } else {
            let overflow = toolbarOverflow
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
        #if os(macOS)
        buttons["documents.menu"].firstMatch.tapWhenReady()
        #endif
        #if os(iOS)
        // iPad can move primary toolbar actions into its native overflow menu.
        let overflow = toolbarOverflow
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
        guard waitUntilReady(file: file, line: line) else { return }
        activateControl()
    }

    @MainActor
    private func waitUntilReady(file: StaticString, line: UInt) -> Bool {
        var previous = CGRect.null
        var stable = 0
        let ready = NSPredicate { _, _ in
            guard self.exists, self.isEnabled, self.isHittable, !self.frame.isEmpty else { stable = 0; return false }
            if self.frame == previous { stable += 1 } else { stable = 0 }
            previous = self.frame
            return stable >= 2
        }
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: self)], timeout: 10)
        XCTAssertEqual(result, .completed, "Control must be visible and stable before tapping: \(self)", file: file, line: line)
        return result == .completed
    }
}

#if os(iOS)
@MainActor
extension XCUIApplication {
    func selectSigningMethod(_ method: String) {
        buttons["signing.method"].tapWhenReady()
        buttons["signing.method." + method].tapWhenReady()
    }
}
#endif
