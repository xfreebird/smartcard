import Foundation
import MoldSignKit

enum Verdict {
    case valid(count: Int), invalid, unknown, incomplete

    init(_ reports: [SignatureReport]) {
        if reports.isEmpty {
            self = .unknown
        } else if reports.contains(where: { !$0.signatureValid || (!$0.contentIntact && $0.missingDetachedReferences.isEmpty) }) {
            self = .invalid
        } else if reports.contains(where: { !$0.missingDetachedReferences.isEmpty }) {
            self = .incomplete
        } else if reports.allSatisfy({ $0.contentIntact && $0.signatureValid }) {
            self = reports.allSatisfy(\.chainTrusted) ? .valid(count: reports.count) : .unknown
        } else {
            self = .invalid
        }
    }

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var title: String {
        switch self {
        case .valid: return L10n.text(.ui_valid_signature)
        case .invalid: return L10n.text(.ui_invalid_signature)
        case .unknown, .incomplete: return L10n.text(.ui_cannot_be_confirmed)
        }
    }

    var subtitle: String {
        switch self {
        case .valid(let count): return localized(.ui_signatures_verified_value, String(count))
        case .invalid: return L10n.text(.ui_the_document_has_been_modified_or_the_signature_does_not_match)
        case .unknown: return L10n.text(.ui_no_signature_found_or_unknown_trust_chain)
        case .incomplete: return L10n.text(.ui_signed_files_must_be_in_the_same_folder_as_the_xml_signature)
        }
    }

    var icon: String {
        switch self {
        case .valid: return "security-high-symbolic"
        case .invalid: return "dialog-error-symbolic"
        case .unknown, .incomplete: return "dialog-warning-symbolic"
        }
    }

    /// libadwaita semantic style class (colors follow the theme, light and dark).
    var styleClass: String {
        switch self {
        case .valid: return "success"
        case .invalid: return "error"
        case .unknown, .incomplete: return "warning"
        }
    }
}
