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

/// How the helper hands an insertion to its containing app.
struct ReaderInsertionDelivery: Equatable {
    enum Route: Equatable {
        /// Launch the app with `--show-main-window` (direct-distribution cold launch).
        case launchApplication
        /// Send `esemnbun-reader://inserted`; the app applies its window policy.
        case readerURL
    }

    let route: Route
    /// Whether Launch Services activates the app. Activation alone reorders an open window and takes focus,
    /// so a running app decides for itself whether anything needs to come forward.
    let activates: Bool

    static func choose(appRunning: Bool, storeEdition: Bool) -> ReaderInsertionDelivery {
        if appRunning { return ReaderInsertionDelivery(route: .readerURL, activates: false) }
        return ReaderInsertionDelivery(route: storeEdition ? .readerURL : .launchApplication, activates: true)
    }
}
