import Foundation
import MoldSignKit

// Toolkit-free app state types. Mirrors apple/Apps/Shared/Model/Models.swift (same states, same copy).

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

/// The status light (docs/10 §0.1, UX-01): green = a card is ready, amber = reader only / card being read,
/// blue = signing, red = error, none = nothing connected. Never the only signal: `text` always says the same.
/// GNOME has no tray: it goes to the Background portal (Quick Settings → Background Apps) and to the
/// Sign page's action bar.
struct StatusLight: Equatable {
    enum Light: String { case ready, reader, busy, error, idle }

    let light: Light
    let text: String

    static func from(status: ReaderStatus, cardCount: Int, busy: Bool) -> StatusLight {
        if busy { return StatusLight(light: .busy, text: L10n.text(.ui_signing)) }
        switch status {
        case .ready(_, let holder, _):
            return StatusLight(light: .ready, text: localized(.ui_card_ready_value, holder) + (cardCount > 1 ? " · " + localized(.ui_cards_value, String(cardCount)) : ""))
        case .reading:
            return StatusLight(light: .reader, text: L10n.text(.ui_reader_connected_reading_the_card))
        case .empty:
            return StatusLight(light: .reader, text: L10n.text(.ui_reader_connected_insert_your_card))
        case .busy:
            return StatusLight(light: .busy, text: L10n.text(.ui_signing))
        case .error(let message, let recovery):
            return StatusLight(light: .error, text: recovery.isEmpty ? message : "\(message). \(recovery)")
        case .noReader:
            return StatusLight(light: .idle, text: L10n.text(.ui_connect_the_reader))
        }
    }
}

/// The tray-style status (docs/10 §0.2b, UX-11): two states only. GNOME has no tray, so this is the Background
/// portal's status text (Quick Settings → Background Apps); the five-state light stays in the window.
struct TrayStatus: Equatable {
    /// At least one card is inserted (reading, ready or signing).
    let connected: Bool
    let text: String

    static func from(cards: [CardSlot], selected: CardSlot?, status: ReaderStatus) -> TrayStatus {
        // cards that are only "in error" count as not connected
        let usable = cards.filter { $0.certificate != nil || $0.problem == nil }
        if !usable.isEmpty {
            let shown = selected.flatMap { card in usable.contains(card) ? card : nil } ?? usable[0]
            let holder = shown.certificate?.holder ?? usable.lazy.compactMap(\.certificate?.holder).first
            return TrayStatus(connected: true, text: holder.map { localized(.ui_card_connected_value, $0) } ?? L10n.text(.ui_card_connected))
        }
        if case .error(let message, let recovery) = status {
            return TrayStatus(connected: false, text: recovery.isEmpty ? message : "\(message). \(recovery)")
        }
        return TrayStatus(connected: false, text: L10n.text(.ui_no_card_connected))
    }
}

enum SignFormat: String, CaseIterable, Codable {
    case padesT, xadesBES, xadesT, xadesC

    var label: String {
        switch self {
        case .padesT: return "PAdES-T"
        case .xadesBES: return "XAdES-BES"
        case .xadesT: return "XAdES-T"
        case .xadesC: return "XAdES-C"
        }
    }

    var xades: XAdESSigner.Format? {
        switch self {
        case .padesT: return nil
        case .xadesBES: return .bes
        case .xadesT: return .t
        case .xadesC: return .c
        }
    }

    var outputExtension: String { self == .padesT ? "pdf" : "xml" }

    /// PDF → PAdES-T, anything else → XAdES-T detached (docs/10 principle 2).
    static func automatic(for url: URL) -> SignFormat {
        url.pathExtension.lowercased() == "pdf" ? .padesT : .xadesT
    }

    /// Choices offered for a file. A PDF can also get a detached XAdES over its bytes (`<name>-semnat.xml`);
    /// other files pick an XAdES level.
    static func choices(for url: URL) -> [SignFormat] {
        url.pathExtension.lowercased() == "pdf" ? [.padesT, .xadesBES, .xadesT, .xadesC] : [.xadesBES, .xadesT, .xadesC]
    }
}

struct SignItem: Equatable {
    let id = UUID()
    let url: URL
    var format: SignFormat
    var error: String?

    init(url: URL) {
        self.url = url
        format = .automatic(for: url)
    }

    var sizeText: String {
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value ?? 0
        return Format.bytes(size)
    }
}

enum Verdict {
    case valid(count: Int), invalid, unknown

    init(_ reports: [SignatureReport]) {
        if reports.isEmpty {
            self = .unknown
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
        case .unknown: return L10n.text(.ui_cannot_be_confirmed)
        }
    }

    var subtitle: String {
        switch self {
        case .valid(let count): return localized(.ui_signatures_verified_value, String(count))
        case .invalid: return L10n.text(.ui_the_document_has_been_modified_or_the_signature_does_not_match)
        case .unknown: return L10n.text(.ui_no_signature_found_or_unknown_trust_chain)
        }
    }

    var icon: String {
        switch self {
        case .valid: return "security-high-symbolic"
        case .invalid: return "dialog-error-symbolic"
        case .unknown: return "dialog-warning-symbolic"
        }
    }

    /// libadwaita semantic style class (colors follow the theme, light and dark).
    var styleClass: String {
        switch self {
        case .valid: return "success"
        case .invalid: return "error"
        case .unknown: return "warning"
        }
    }
}

struct ActivityItem: Codable, Equatable {
    enum Kind: String, Codable { case signed, verified, bridge, failed }
    var id = UUID()
    var kind: Kind
    var title: String
    var subtitle: String
    var ok: Bool
    var date = Date()
    var filePath: String?

    /// File entries are shown only while the file still exists; browser requests (no file) always are.
    var isShowable: Bool {
        filePath.map { FileManager.default.fileExists(atPath: $0) } ?? true
    }
}

/// What the PIN dialog shows. `attemptsLeft` comes from the last 63Cx.
struct PinRequest {
    let holder: String
    /// One line about what is being signed ("2 documente", "msign.gov.md · cerere.pdf").
    let purpose: String
    let attemptsLeft: Int?
    let canRemember: Bool
    /// nil when the vault works; otherwise why "remember" is unavailable.
    let vaultProblem: String?
}

struct PinEntry {
    let pin: String
    let remember: Bool
}

/// One inserted card. `generation` comes from the reader monitor: a new value means a (re)inserted card.
struct CardSlot: Equatable {
    let reader: String
    let generation: Int
    var certificate: SigningService.CertificateSummary?
    var problem: String?
    var hasStoredPIN = false

    /// Identity of this insertion (the wallet rebuilds its pages when the set of keys changes).
    var key: String { "\(reader)#\(generation)" }
}

/// A browser asking for a signature (SEC-02).
struct ConsentRequest {
    let request: BridgeRequest
    let holder: String
    let hasStoredPIN: Bool

    var originHost: String {
        request.origin.flatMap { URL(string: $0)?.host } ?? L10n.text(.ui_a_local_application)
    }
}

enum BridgeState: Equatable {
    case stopped
    case running
    case identityRequired
    case portBusy   // the vendor Java server holds 18480/18443 (MAC-08)
    case failed(String)

    var description: String {
        switch self {
        case .stopped: return L10n.text(.ui_off)
        case .running: return localized(.linux_bridge_active, String(MoldSignServer.defaultHTTPPort), String(MoldSignServer.defaultHTTPSPort))
        case .identityRequired: return L10n.text(.ui_the_moldsign_https_identity_is_missing_or_cannot_be_read_import_the_localhost_p12_file_f)
        case .portBusy: return localized(.linux_bridge_ports_busy, String(MoldSignServer.defaultHTTPPort), String(MoldSignServer.defaultHTTPSPort))
        case .failed(let message): return localized(.linux_bridge_failed, message)
        }
    }
}

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
