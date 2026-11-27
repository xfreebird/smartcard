import SwiftUI
import MoldSignKit

/// Keep error meaning until presentation so switching language does not retain translated text.
enum PresentationText: Equatable {
    case localized(L10n.Key)
    case count(L10n.Key, Int)
    /// A template with one `%@` value that is not translated (a product name).
    case formatted(L10n.Key, String)
    case verbatim(String)

    var text: String {
        switch self {
        case .localized(let key): return L10n.text(key)
        case .count(let key, let count): return L10n.text(key, count)
        case .formatted(let key, let value): return L10n.text(key, value)
        case .verbatim(let value): return value
        }
    }
}
