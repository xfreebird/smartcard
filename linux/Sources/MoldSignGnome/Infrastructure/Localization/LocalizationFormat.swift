import Foundation

/// A typed catalog key keeps translated sentence order separate from user/card data.
func localized(_ key: L10n.Key, _ arguments: String...) -> String {
    let format = L10n.text(key).replacingOccurrences(of: #"%(\d+)\$s"#, with: "%$1$@", options: .regularExpression)
    return String(format: format, arguments: arguments)
}
