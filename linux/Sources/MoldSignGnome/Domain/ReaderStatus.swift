import Foundation
import MoldSignKit

// Toolkit-free app state types. Mirrors apple/Apps/Shared/Model/ReaderStatus.swift (same states, same copy).

/// StatusCard states (docs/10 §3).
enum ReaderStatus: Equatable {
    case noReader
    case empty(reader: String)
    case reading(reader: String)
    case ready(reader: String, holder: String, validUntil: Date?)
    case busy(reader: String, holder: String)
    case error(message: String, recovery: String)

    var cardPresent: Bool {
        switch self {
        case .reading, .ready, .busy: return true
        default: return false
        }
    }

    var canSign: Bool {
        if case .ready = self { return true }
        return false
    }

    var title: String {
        switch self {
        case .noReader: return L10n.text(.ui_connect_the_reader)
        case .empty: return L10n.text(.ui_insert_the_card)
        case .reading: return L10n.text(.ui_reading_the_card)
        case .ready(_, let holder, _), .busy(_, let holder): return holder
        case .error(let message, _): return message
        }
    }

    var subtitle: String {
        switch self {
        // Linux: no reader is also what an absent pcscd / a sandbox without --socket=pcsc looks like.
        case .noReader: return L10n.text(.ui_usb_reader_e_g_bit4id_minilector_the_pcscd_service_must_be_running)
        case .empty(let reader), .reading(let reader): return reader
        case .ready(let reader, _, _): return localized(.ui_card_ready_value, reader)
        case .busy: return L10n.text(.ui_signing)
        case .error(_, let recovery): return recovery
        }
    }

    var validityText: String? {
        guard case .ready(_, _, let until?) = self else { return nil }
        return localized(.ui_certificate_valid_until_value, Format.monthYear(until))
    }
}
