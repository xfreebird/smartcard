import SwiftUI
import MoldSignKit

/// Keep error meaning until presentation so switching language does not retain translated text.
enum PresentationText: Equatable {
    case localized(L10n.Key)
    case count(L10n.Key, Int)
    case verbatim(String)

    var text: String {
        switch self {
        case .localized(let key): return L10n.text(key)
        case .count(let key, let count): return L10n.text(key, count)
        case .verbatim(let value): return value
        }
    }
}
