import Foundation

/// Emits only insertion transitions. The initial snapshot and removals are deliberately silent.
struct ReaderInsertionPolicy {
    private var previous: [String: Bool]?
    mutating func shouldOpen(for current: [String: Bool], demoMode: Bool = false) -> Bool {
        defer { previous = current }
        guard !demoMode, let previous else { return false }
        return current.contains { name, card in
            previous[name] == nil || (card && previous[name] == false)
        }
    }
}
