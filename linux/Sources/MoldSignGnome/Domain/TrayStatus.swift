import Foundation
import MoldSignKit

/// The tray-style status (docs/10 §0.2b, UX-11): two states only. GNOME has no tray, so this is the Background
/// portal's status text (Quick Settings → Background Apps); the five-state light stays in the window.
struct TrayStatus: Equatable {
    /// At least one card is inserted (reading, ready or signing).
    let connected: Bool
    let text: String

    static func from(cards: [CardSlot], selected: CardSlot?, status: ReaderStatus) -> TrayStatus {
        // cards that are only "in error" count as not connected
        let usable = cards.filter { $0.certificate != nil || $0.problem == nil }
        if !usable.isEmpty {
            let shown = selected.flatMap { card in usable.contains(card) ? card : nil } ?? usable[0]
            let holder = shown.certificate?.holder ?? usable.lazy.compactMap(\.certificate?.holder).first
            return TrayStatus(connected: true, text: holder.map { localized(.ui_card_connected_value, $0) } ?? L10n.text(.ui_card_connected))
        }
        if case .error(let message, let recovery) = status {
            return TrayStatus(connected: false, text: recovery.isEmpty ? message : "\(message). \(recovery)")
        }
        return TrayStatus(connected: false, text: L10n.text(.ui_no_card_connected))
    }
}
