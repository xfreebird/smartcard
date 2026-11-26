import CryptoTokenKit
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

/// The watcher's per-sample decisions, separate from CryptoTokenKit polling and Launch Services.
struct ReaderInsertionMonitor {
    let storeEdition: Bool
    private var policy = ReaderInsertionPolicy()
    private var lastDelivery = Date.distantPast

    init(storeEdition: Bool) { self.storeEdition = storeEdition }

    /// Probing, unresponsive and valid cards all count as physically present.
    static func cardPresent(_ state: TKSmartCardSlot.State?) -> Bool {
        guard let state else { return false }
        return state != .missing && state != .empty
    }

    /// A Debug fixture snapshot: slot names mapped to card presence.
    static func mockSnapshot(_ data: Data) -> [String: Bool]? {
        try? JSONDecoder().decode([String: Bool].self, from: data)
    }

    /// The Store helper waits until its app has published a mode; the direct edition defaults to live.
    func demoMode(stored: Any?, flag: Bool) -> Bool {
        storeEdition ? (stored as? Bool ?? true) : flag
    }

    /// True for an insertion transition outside demo mode, at most once per second.
    mutating func shouldDeliver(for current: [String: Bool], demoMode: Bool, at now: Date) -> Bool {
        guard policy.shouldOpen(for: current, demoMode: demoMode), now.timeIntervalSince(lastDelivery) > 1 else { return false }
        lastDelivery = now
        return true
    }

    func delivery(appRunning: Bool) -> ReaderInsertionDelivery {
        .choose(appRunning: appRunning, storeEdition: storeEdition)
    }
}
