import Foundation
import CryptoTokenKit

/// Readers, cards, and card *changes*, via CryptoTokenKit (docs/09 §3.7, MAC-02).
/// macOS needs the `com.apple.security.smartcard` entitlement or `TKSmartCardSlotManager.default` is nil.
///
/// Every reader is reported (several eID cards can be connected). Each inserted card gets a new
/// `generation`. A quick remove + reinsert (or a swap) can coalesce the slot's state into "valid → valid",
/// so the monitor also holds a `TKSmartCard` per inserted card and watches its `valid` flag, which drops
/// when that physical card is removed. Hosts re-read the certificate whenever the generation changes.
final class ReaderMonitor {
    struct Slot: Equatable {
        enum State: Equatable { case empty, probing, card, mute }
        let name: String
        var state: State
        /// Bumped on every card insertion in this reader.
        var generation: Int
    }

    struct Snapshot: Equatable {
        var available = true
        var slots: [Slot] = []
    }

    /// Called on the main queue.
    var onChange: ((Snapshot) -> Void)?

    private let queue = DispatchQueue(label: "reader-monitor")
    private var managerObservation: NSKeyValueObservation?
    private var names: [String] = []
    private var slots: [String: TKSmartCardSlot] = [:]
    private var slotObservations: [String: NSKeyValueObservation] = [:]
    private var states: [String: TKSmartCardSlot.State] = [:]
    private var cards: [String: TKSmartCard] = [:]
    private var cardObservations: [String: NSKeyValueObservation] = [:]
    private var generations: [String: Int] = [:]

    func start() {
        guard let manager = TKSmartCardSlotManager.default else {
            publish(Snapshot(available: false))
            return
        }
        managerObservation = manager.observe(\.slotNames, options: [.initial, .new]) { [weak self] manager, _ in
            self?.queue.async { self?.sync(names: manager.slotNames, manager: manager) }
        }
    }

    func stop() {
        managerObservation = nil
        slotObservations.removeAll()
        cardObservations.removeAll()
    }

    private func sync(names: [String], manager: TKSmartCardSlotManager) {
        self.names = names
        for gone in slots.keys where !names.contains(gone) {
            slots[gone] = nil; slotObservations[gone] = nil; states[gone] = nil
            cards[gone] = nil; cardObservations[gone] = nil
        }
        for name in names where slots[name] == nil {
            guard let slot = manager.slotNamed(name) else { continue }
            slots[name] = slot
            slotObservations[name] = slot.observe(\.state, options: [.initial, .new]) { [weak self] slot, _ in
                self?.queue.async { self?.slotChanged(name, slot) }
            }
        }
        emit()
    }

    private func slotChanged(_ name: String, _ slot: TKSmartCardSlot) {
        states[name] = slot.state
        if slot.state == .validCard {
            trackCard(in: name, slot)
        } else {
            cards[name] = nil
            cardObservations[name] = nil
        }
        emit()
    }

    /// A new physical card in `name`, unless the one we hold is still valid (same card, no change).
    private func trackCard(in name: String, _ slot: TKSmartCardSlot) {
        if let card = cards[name], card.isValid { return }
        generations[name, default: 0] += 1
        guard let card = slot.makeSmartCard() else { return }
        cards[name] = card
        cardObservations[name] = card.observe(\.isValid, options: [.new]) { [weak self] card, _ in
            guard !card.isValid else { return }
            self?.queue.async {
                guard let self else { return }
                self.cards[name] = nil
                self.cardObservations[name] = nil
                // removed and (maybe) already replaced: a still-valid slot means a new card
                if let slot = self.slots[name], slot.state == .validCard { self.trackCard(in: name, slot) }
                self.emit()
            }
        }
    }

    private func emit() {
        let snapshot = Snapshot(slots: names.map { name in
            let state: Slot.State
            switch states[name] {
            case .validCard?: state = .card
            case .muteCard?: state = .mute
            case .probing?: state = .probing
            default: state = .empty
            }
            return Slot(name: name, state: state, generation: generations[name] ?? 0)
        })
        publish(snapshot)
    }

    private func publish(_ snapshot: Snapshot) {
        DispatchQueue.main.async { self.onChange?(snapshot) }
    }
}
