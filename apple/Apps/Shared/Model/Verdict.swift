import SwiftUI
import MoldSignKit

enum Verdict {
    case valid(count: Int), invalid, unknown, incomplete, untrusted

    init(_ reports: [Validator.Report]) {
        if reports.isEmpty {
            self = .unknown
        } else if reports.contains(where: { !$0.signatureValid || (!$0.contentIntact && $0.missingDetachedReferences.isEmpty) }) {
            self = .invalid
        } else if reports.contains(where: { !$0.missingDetachedReferences.isEmpty }) {
            self = .incomplete
        } else if reports.allSatisfy({ $0.contentIntact && $0.signatureValid }) {
            self = reports.allSatisfy(\.chainTrusted) ? .valid(count: reports.count) : .untrusted
        } else {
            self = .invalid
        }
    }

    var title: String {
        switch self {
        case .valid: return L10n.text(.ui_valid_signature)
        case .invalid: return L10n.text(.ui_invalid_signature)
        case .unknown, .incomplete, .untrusted: return L10n.text(.ui_cannot_be_confirmed)
        }
    }

    var subtitle: String {
        switch self {
        case .valid(let count): return L10n.text(.ui_verified_signatures_count, count)
        case .invalid: return L10n.text(.ui_the_document_has_been_modified_or_the_signature_does_not_match)
        case .unknown: return L10n.text(.verify_no_recognized_signature)
        case .untrusted: return L10n.text(.verify_trust_unconfirmed)
        case .incomplete: return L10n.text(.verify_original_missing)
        }
    }

    var symbol: String {
        switch self {
        case .valid: return "checkmark.seal.fill"
        case .invalid: return "xmark.seal.fill"
        case .unknown, .incomplete, .untrusted: return "exclamationmark.triangle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .valid: return Theme.success
        case .invalid: return Theme.danger
        case .unknown, .incomplete, .untrusted: return Theme.warning
        }
    }
}
