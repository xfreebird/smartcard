import Foundation
import MoldSignKit

/// Signing progress shown to the user: Card → PIN → Semnătură → Marcă temporală → Salvare (docs/10 §3).
enum UIStep: Int, CaseIterable {
    case card, pin, signature, timestamp, save

    var label: String {
        switch self {
        case .card: return L10n.text(.ui_card)
        case .pin: return L10n.text(.ui_pin)
        case .signature: return L10n.text(.ui_signature)
        case .timestamp: return L10n.text(.ui_timestamp)
        case .save: return L10n.text(.linux_saving)
        }
    }

    init(_ step: SigningService.Step) {
        switch step {
        case .connecting, .authenticating, .readingCertificate: self = .card
        case .verifyingPIN: self = .pin
        case .signing: self = .signature
        case .timestamping: self = .timestamp
        case .writing, .done: self = .save
        }
    }
}
