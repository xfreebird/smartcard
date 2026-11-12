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
        let isDocument: (any XCUIElementSnapshot) -> Bool = { node in
            node.elementType == .cell && node.label.hasPrefix(namePrefix)
                && (labelContains.map { node.label.contains($0) } ?? true)
        }
        let isLocal: (any XCUIElementSnapshot) -> Bool = {
            $0.elementType == .cell && ["On My iPhone", "On My iPad"].contains($0.label)
        }
        let isBrowse: (any XCUIElementSnapshot) -> Bool = { $0.elementType == .button && $0.label == "Browse" }
        let targets: [(any XCUIElementSnapshot) -> Bool] = [isDocument] + folders.reversed().map { folder in
            { $0.elementType == .cell && $0.identifier == folder }
        }
        // Browse can restore its previous location directly, without a Locations list.
        // Prefer the deepest visible destination so an already-open container is honored.
        var destination = try waitForControl("file location", priorities: targets + [isLocal, isBrowse])
        if isBrowse(destination) {
            tap(destination.frame)
            destination = try waitForControl("local location or restored folder", priorities: targets + [isLocal])
        }
        if isLocal(destination) {
            tap(destination.frame)
            destination = try waitForControl("app folder or restored file", priorities: targets)
        }
        if let index = folders.firstIndex(of: destination.identifier) {
            for folder in folders[index...] { try openFolder(folder) }
        }
        let document = try waitForControl("document \(namePrefix)", matching: isDocument)
        tapItem(document)
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
        tapItem(folder)
    }

    private func tapItem(_ item: any XCUIElementSnapshot) {
        let cell = app.filePicker.cells.matching(NSPredicate(format: "identifier == %@ AND label == %@",
            item.identifier, item.label)).firstMatch
        let ready = NSPredicate { _, _ in cell.exists && cell.isEnabled && cell.isHittable }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: cell)], timeout: 10), .completed,
                       "Files item must be hittable: \(item.label)")
        var target = item.frame
        if let icon = descendants(of: item).first(where: { $0.elementType == .image && valid($0.frame) }) {
            target = icon.frame
        } else {
            // Grid cells include metadata below the thumbnail; list rows keep their center.
            target.size.height = min(target.width, target.height)
        }
        // Anchor the event to the remote Files cell, not the presenting application.
        cell.coordinate(withNormalizedOffset: CGVector(
            dx: (target.midX - item.frame.minX) / item.frame.width,
            dy: (target.midY - item.frame.minY) / item.frame.height)).tap()
    }

    private func waitForControl(_ name: String, matching matches: @escaping (any XCUIElementSnapshot) -> Bool) throws -> any XCUIElementSnapshot {
        try waitForControl(name, priorities: [matches])
    }

    private func waitForControl(_ name: String, priorities: [(any XCUIElementSnapshot) -> Bool]) throws -> any XCUIElementSnapshot {
        var result: (any XCUIElementSnapshot)?
        var previous = CGRect.null
        var previousIdentity = ""
        var stable = 0
        let ready = NSPredicate { _, _ in
            guard let picker = try? self.pickerSnapshot() else { stable = 0; return false }
            let bounds = self.app.frame
            let controls = self.descendants(of: picker)
            guard let control = priorities.lazy.compactMap({ matches in
                controls.last { matches($0) && self.valid($0.frame, within: bounds) }
            }).first else {
                stable = 0
                return false
            }
            let identity = control.identifier + "\n" + control.label
            stable = control.frame == previous && identity == previousIdentity ? stable + 1 : 0
            previous = control.frame
            previousIdentity = identity
            result = control
            return stable >= 2
        }
        let outcome = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: app)], timeout: 15)
        if outcome != .completed {
            let tree = app.filePicker.exists ? app.filePicker.debugDescription : app.debugDescription
            print("Native Files failure (\(name)):\n\(tree)")
        }
        XCTAssertEqual(outcome, .completed, "Native Files control did not become stable: \(name)")
        return try XCTUnwrap(result)
    }

    private func pickerSnapshot() throws -> (any XCUIElementSnapshot)? {
        let root = try app.snapshot()
        // Files can place its toolbar beside the Browse view, rather than inside it.
        if descendants(of: root).contains(where: { $0.identifier == "Browse View (Picker)" }) { return root }
        // The iPad remote hierarchy can omit attributes in a whole-app snapshot.
        // Resolving its named root requests a complete snapshot of that subtree.
        let picker = app.filePicker
        return picker.exists ? try picker.snapshot() : nil
    }

    private func descendants(of root: any XCUIElementSnapshot) -> [any XCUIElementSnapshot] {
        [root] + root.children.flatMap { descendants(of: $0) }
    }

    private func valid(_ frame: CGRect, within bounds: CGRect? = nil) -> Bool {
        !frame.isEmpty && !frame.isInfinite && !frame.isNull && (bounds ?? app.frame).contains(frame)
    }

    private func tap(_ frame: CGRect) {
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: frame.midX, dy: frame.midY)).tap()
    }
}
