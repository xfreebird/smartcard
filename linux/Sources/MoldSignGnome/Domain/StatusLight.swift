import Foundation
import MoldSignKit

/// The status light (docs/10 §0.1, UX-01): green = a card is ready, amber = reader only / card being read,
/// blue = signing, red = error, none = nothing connected. Never the only signal: `text` always says the same.
/// GNOME has no tray: it goes to the Background portal (Quick Settings → Background Apps) and to the
/// Sign page's action bar.
struct StatusLight: Equatable {
    enum Light: String { case ready, reader, busy, error, idle }

    let light: Light
    let text: String

    static func from(status: ReaderStatus, cardCount: Int, busy: Bool) -> StatusLight {
        if busy { return StatusLight(light: .busy, text: L10n.text(.ui_signing)) }
        switch status {
        case .ready(_, let holder, _):
            return StatusLight(light: .ready, text: localized(.ui_card_ready_value, holder) + (cardCount > 1 ? " · " + localized(.ui_cards_value, String(cardCount)) : ""))
        case .reading:
            return StatusLight(light: .reader, text: L10n.text(.ui_reader_connected_reading_the_card))
        case .empty:
            return StatusLight(light: .reader, text: L10n.text(.ui_reader_connected_insert_your_card))
        case .busy:
            return StatusLight(light: .busy, text: L10n.text(.ui_signing))
        case .error(let message, let recovery):
            return StatusLight(light: .error, text: recovery.isEmpty ? message : "\(message). \(recovery)")
        case .noReader:
            return StatusLight(light: .idle, text: L10n.text(.ui_connect_the_reader))
        }
    }
}
