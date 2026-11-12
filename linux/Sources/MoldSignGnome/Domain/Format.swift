import Foundation

enum Format {
    static func monthYear(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ro_MD")
        f.dateFormat = "MM.yyyy"
        return f.string(from: date)
    }

    /// ID-card face: "Valabil până la/Valid until" as `dd MM yyyy` (docs/10 §0.2b; the certificate's notAfter).
    static func cardDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ro_MD")
        f.dateFormat = "dd MM yyyy"
        return f.string(from: date)
    }

    static func longDate(_ date: Date) -> String {
        let code = L10n.language ?? Locale.current.language.languageCode?.identifier ?? "ro"
        let f = DateFormatter()
        f.locale = Locale(identifier: ["ro", "en", "ru"].contains(code) ? code : "ro")
        f.dateStyle = .long
        f.timeStyle = .none
        return f.string(from: date)
    }

    /// "acum 2 min", "10:12", "24.10.2026".
    static func relative(_ date: Date, now: Date = Date()) -> String {
        let seconds = now.timeIntervalSince(date)
        if seconds < 60 { return L10n.text(.ui_now) }
        if seconds < 3600 { return localized(.ui_value_min_ago, String(Int(seconds / 60))) }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ro_MD")
        f.dateFormat = Calendar.current.isDate(date, inSameDayAs: now) ? "HH:mm" : "dd.MM.yyyy HH:mm"
        return f.string(from: date)
    }

    static func bytes(_ count: Int64) -> String {
        if count < 1024 { return "\(count) B" }
        if count < 1024 * 1024 { return String(format: "%.0f KB", Double(count) / 1024) }
        return String(format: "%.1f MB", Double(count) / 1024 / 1024)
    }
}
