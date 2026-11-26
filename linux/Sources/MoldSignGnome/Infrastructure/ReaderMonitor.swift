import Dispatch
import Foundation
import MoldSignKit

/// Readers, cards and card *changes* by polling PC/SC (docs/09 §3.7, LNX-08); the GNOME counterpart of the
/// CryptoTokenKit monitor in apple/Apps/Shared/Services/ReaderMonitor.swift.
///
/// Linux has no CryptoTokenKit, so this polls `PCSCTransport.readerStates()` (SCardGetStatusChange
/// with a zero timeout on its own context: cheap, never connects, safe next to a signing session)
/// once a second on a background queue, and reports changes on the GTK main thread.
///
/// Every reader is reported (several eID cards can be connected). Each inserted card gets a new
/// `generation`: bumped when a reader goes no-card → card, or when pcsc-lite's card event counter
/// (`eventCount`, upper 16 bits of dwEventState) moves while a card is present, which catches a
/// remove + reinsert or a swap that happened entirely between two polls.
/// TODO(LNX-08): block in SCardGetStatusChange on `\\?PnP?\Notification` + the reader list
/// (INFINITE timeout, cancelled with SCardCancel) instead of polling, once the core exposes it.
final class ReaderMonitor: CardMonitoring {
    /// One reader as PC/SC reports it, without connecting.
    struct Observation: Equatable {
        let name: String
        let cardPresent: Bool
        let mute: Bool
        let eventCount: Int
    }

    /// Called on the GTK main thread, only when the snapshot changes.
    var onChange: ((ReaderSnapshot) -> Void)?

    private let readerStates: () -> [Observation]
    private let serviceAvailable: () -> Bool
    private let queue = DispatchQueue(label: "md.moldsign.reader-monitor")
    private var timer: DispatchSourceTimer?
    private var last: ReaderSnapshot?
    // touched only on `queue`
    private var generations: [String: Int] = [:]
    private var present: [String: Bool] = [:]
    private var eventCounts: [String: Int] = [:]

    init(readerStates: @escaping () -> [Observation] = {
            PCSCTransport.readerStates().map {
                Observation(name: $0.name, cardPresent: $0.cardPresent, mute: $0.mute, eventCount: $0.eventCount)
            }
         },
         serviceAvailable: @escaping () -> Bool = PCSCTransport.isServiceAvailable) {
        self.readerStates = readerStates
        self.serviceAvailable = serviceAvailable
    }

    func start(interval: DispatchTimeInterval = .seconds(1)) {
        guard timer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(200))
        timer.setEventHandler { [weak self] in self?.poll() }
        timer.resume()
        self.timer = timer
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    /// Re-emits the current state even if unchanged (after a card operation finished).
    func refresh() {
        queue.async { [weak self] in
            self?.last = nil
            self?.poll()
        }
    }

    private func poll() {
        let states = readerStates()
        for state in states {
            let wasPresent = present[state.name] ?? false
            let counterMoved = eventCounts[state.name].map { $0 != state.eventCount } ?? false
            if state.cardPresent && (!wasPresent || counterMoved) {
                generations[state.name, default: 0] += 1
            }
            present[state.name] = state.cardPresent
            eventCounts[state.name] = state.eventCount
        }
        let names = Set(states.map(\.name))
        for gone in present.keys where !names.contains(gone) {
            present[gone] = nil
            eventCounts[gone] = nil
        }

        var snapshot = ReaderSnapshot(slots: states.map { state in
            let kind: ReaderSlot.State = !state.cardPresent ? .empty : (state.mute ? .mute : .card)
            return ReaderSlot(name: state.name, state: kind, generation: generations[state.name] ?? 0)
        })
        if states.isEmpty { snapshot.serviceAvailable = serviceAvailable() }
        guard snapshot != last else { return }
        last = snapshot
        onMain { [weak self] in self?.onChange?(snapshot) }
    }
}
