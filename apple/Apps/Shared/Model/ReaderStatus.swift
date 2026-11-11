import SwiftUI
import MoldSignKit

/// StatusCard states (docs/10 §3).
enum ReaderStatus: Equatable {
    case unavailable                       // no smart-card access (entitlement missing)
    case noReader
    case empty(reader: String)
    case reading(reader: String)
    case ready(reader: String, holder: String, validUntil: Date?)
    case busy(reader: String, holder: String)
    case error(message: PresentationText, recovery: PresentationText)

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
        case .unavailable: return L10n.text(.ui_reader_access_unavailable)
        case .noReader: return L10n.text(.ui_connect_the_reader)
        case .empty: return L10n.text(.ui_insert_the_card)
        case .reading: return L10n.text(.ui_reading_the_card)
        case .ready(_, let holder, _), .busy(_, let holder): return holder
        case .error(let message, _): return message.text
        }
    }

    var subtitle: String {
        switch self {
        case .unavailable: return L10n.text(.ui_check_the_app_permissions)
        case .noReader:
            #if os(iOS)
            return L10n.text(.ui_usb_c_or_lightning_adapter_for_iphone_and_ipad)
            #else
            return L10n.text(.ui_usb_a_or_usb_c_adapter)
            #endif
        case .empty(let reader), .reading(let reader): return reader
        case .ready(let reader, _, _): return L10n.text(.ui_card_ready_value, reader)
        case .busy: return L10n.text(.ui_signing)
        case .error(_, let recovery): return recovery.text
        }
    }

    var detail: String? {
        guard case .ready(_, _, let until?) = self else { return nil }
        return L10n.text(.ui_certificate_valid_until_value, until.formatted(.dateTime.month(.twoDigits).year()))
    }

    var tint: Color {
        switch self {
        case .ready: return Theme.success
        case .busy, .reading: return Theme.brand
        case .error, .unavailable: return Theme.danger
        case .noReader, .empty: return .secondary
        }
    }

    var menuBarSymbol: String {
        switch self {
        case .error, .unavailable: return "exclamationmark.triangle"
        case .busy: return "ellipsis.circle"
        default: return "signature"
        }
    }
}
