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
    func cancelFilePicker() throws {
        let picker = collectionViews["File View"]
        XCTAssertTrue(picker.waitForExistence(timeout: 10))
        let navigation = navigationBars.matching(NSPredicate(format: "identifier IN %@",
            ["FullDocumentManagerViewControllerNavigationBar", "DOCSidebarView"]))
        let cancel = navigation.buttons.matching(NSPredicate(format: "label IN %@", ["Cancel", "Close"])).firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 10), debugDescription)
        // Files overlays its toolbar with a second accessibility proxy on some runtimes.
        // Tap the observed native control's center; do not target the underlying form's Cancel.
        let point = cancel.frame
        XCTAssertFalse(point.isEmpty)
        XCTAssertTrue(frame.contains(point))
        coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: point.midX, dy: point.midY)).tap()
        XCTAssertTrue(picker.waitForNonExistence(timeout: 10))
    }

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
        guard waitUntilReady(file: file, line: line) else { return }
        activateControl()
    }

    @MainActor
    func openFilePickerFolder(file: StaticString = #filePath, line: UInt = #line) {
        guard waitUntilReady(file: file, line: line) else { return }
        let icon = images.firstMatch
        // Files can include metadata below the tappable folder icon in the cell's frame.
        let target = icon.exists && !icon.frame.isEmpty ? icon : self
        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    @MainActor
    private func waitUntilReady(file: StaticString, line: UInt) -> Bool {
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
        return result == .completed
    }
}
