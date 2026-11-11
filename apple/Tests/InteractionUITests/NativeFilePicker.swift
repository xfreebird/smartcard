import XCTest

/// Files embeds a remote accessibility tree. Resolve an action from one snapshot so a
/// second query cannot replace the picker control with an obscured application control.
@MainActor
struct NativeFilePicker {
    let app: XCUIApplication

    func cancel() throws {
        let control = try waitForControl("Cancel") { $0.elementType == .button && ["Cancel", "Close"].contains($0.label) }
        tap(control.frame)
        waitForDismissal()
    }

    func selectFile(in folders: [String], namePrefix: String, labelContains: String? = nil,
                    confirmSelection: Bool) throws {
        let isLocal: (any XCUIElementSnapshot) -> Bool = {
            $0.elementType == .cell && ["On My iPhone", "On My iPad"].contains($0.label)
        }
        var location = try waitForControl("local storage or Browse") { isLocal($0) || ($0.elementType == .button && $0.label == "Browse") }
        if !isLocal(location) {
            tap(location.frame)
            location = try waitForControl("local storage", matching: isLocal)
        }
        tap(location.frame)
        for folder in folders { try openFolder(folder) }
        let document = try waitForControl("document \(namePrefix)") { node in
            guard node.elementType == .cell, node.label.hasPrefix(namePrefix) else { return false }
            return labelContains.map { node.label.contains($0) } ?? true
        }
        tap(document.frame)
        if confirmSelection {
            let open = try waitForControl("Open") { $0.elementType == .button && $0.label == "Open" && $0.isEnabled }
            tap(open.frame)
        }
        waitForDismissal()
    }

    private func waitForDismissal() {
        let dismissed = NSPredicate { _, _ in
            do { return try self.pickerSnapshot() == nil } catch { return false }
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: dismissed, object: app)], timeout: 10), .completed)
    }

    private func openFolder(_ identifier: String) throws {
        let folder = try waitForControl(identifier) { $0.elementType == .cell && $0.identifier == identifier }
        let icon = descendants(of: folder).first { $0.elementType == .image && valid($0.frame) }
        tap((icon ?? folder).frame)
    }

    private func waitForControl(_ name: String, matching matches: @escaping (any XCUIElementSnapshot) -> Bool) throws -> any XCUIElementSnapshot {
        var result: (any XCUIElementSnapshot)?
        var previous = CGRect.null
        var stable = 0
        let ready = NSPredicate { _, _ in
            guard let picker = try? self.pickerSnapshot(),
                  let control = self.descendants(of: picker).last(where: { matches($0) && self.valid($0.frame) }) else {
                stable = 0
                return false
            }
            stable = control.frame == previous ? stable + 1 : 0
            previous = control.frame
            result = control
            return stable >= 2
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: app)], timeout: 15), .completed,
                       "Native Files control did not become stable: \(name)")
        return try XCTUnwrap(result)
    }

    private func pickerSnapshot() throws -> (any XCUIElementSnapshot)? {
        let root = try app.snapshot()
        // Files can place its toolbar beside the Browse view, rather than inside it.
        return descendants(of: root).contains { $0.identifier == "Browse View (Picker)" } ? root : nil
    }

    private func descendants(of root: any XCUIElementSnapshot) -> [any XCUIElementSnapshot] {
        [root] + root.children.flatMap { descendants(of: $0) }
    }

    private func valid(_ frame: CGRect) -> Bool {
        !frame.isEmpty && !frame.isInfinite && !frame.isNull && app.frame.contains(frame)
    }

    private func tap(_ frame: CGRect) {
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX, dy: frame.midY)).tap()
    }
}
