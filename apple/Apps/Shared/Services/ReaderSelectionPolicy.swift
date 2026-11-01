/// Keep the user's chosen reader while the operating system temporarily reports no card in it.
/// The UI can use the first available card as a fallback until the preferred reader returns.
enum ReaderSelectionPolicy {
    static func preferredReader(previous: String?, available: [String]) -> String? {
        previous ?? available.first
    }

    static func activeReader(preferred: String?, available: [String]) -> String? {
        if let preferred, available.contains(preferred) { return preferred }
        return available.first
    }
}
