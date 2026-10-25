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
        case .noReader: return "Conectează cititorul"
        case .empty: return "Introdu cardul în cititor"
        case .reading: return "Se citește cardul…"
        case .ready(_, let holder, _), .busy(_, let holder): return holder
        case .error(let message, _): return message
        }
    }

    var subtitle: String {
        switch self {
        // Linux: no reader is also what an absent pcscd / a sandbox without --socket=pcsc looks like.
        case .noReader: return "Cititor USB (de ex. bit4id miniLector). Serviciul pcscd trebuie să ruleze."
        case .empty(let reader), .reading(let reader): return reader
        case .ready(let reader, _, _): return "Card pregătit · \(reader)"
        case .busy: return "Se semnează…"
        case .error(_, let recovery): return recovery
        }
    }

    var validityText: String? {
        guard case .ready(_, _, let until?) = self else { return nil }
        return "Certificat valabil până la \(Format.monthYear(until))"
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

    /// Choices offered for a file (PDF is always PAdES; others pick an XAdES level).
    static func choices(for url: URL) -> [SignFormat] {
        url.pathExtension.lowercased() == "pdf" ? [.padesT] : [.xadesBES, .xadesT, .xadesC]
    }
}

struct SignItem: Equatable {
    let id = UUID()
    let url: URL
    var format: SignFormat

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

    init(_ reports: [Validator.Report]) {
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
        case .valid: return "Semnătură validă"
        case .invalid: return "Semnătură invalidă"
        case .unknown: return "Nu poate fi confirmată"
        }
    }

    var subtitle: String {
        switch self {
        case .valid(let count): return "Semnături verificate: \(count)"
        case .invalid: return "Documentul a fost modificat sau semnătura nu corespunde"
        case .unknown: return "Nicio semnătură găsită sau lanț de încredere necunoscut"
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

/// A browser asking for a signature (SEC-02).
/// One inserted card. `generation` comes from the reader monitor: a new value means a (re)inserted card.
struct CardSlot: Equatable {
    let reader: String
    let generation: Int
    var certificate: SigningService.CertificateSummary?
    var problem: String?
    var hasStoredPIN = false
}

struct ConsentRequest {
    let request: BridgeRequest
    let holder: String
    let hasStoredPIN: Bool

    var originHost: String {
        request.origin.flatMap { URL(string: $0)?.host } ?? "O aplicație locală"
    }
}

enum BridgeState: Equatable {
    case stopped
    case running
    case portBusy   // the vendor Java server holds 18480/18443 (MAC-08)
    case failed(String)

    var description: String {
        switch self {
        case .stopped: return "Oprită"
        case .running: return "Activă pe 127.0.0.1:\(MoldSignServer.defaultHTTPPort) și localhost.cts.md:\(MoldSignServer.defaultHTTPSPort)"
        case .portBusy: return "Porturile \(MoldSignServer.defaultHTTPPort)/\(MoldSignServer.defaultHTTPSPort) sunt ocupate (probabil de MoldSign Desktop). Închide-l și repornește conexiunea."
        case .failed(let message): return "Nu a pornit: \(message)"
        }
    }
}

/// Signing progress shown to the user: Card → PIN → Semnătură → Marcă temporală → Salvare (docs/10 §3).
enum UIStep: Int, CaseIterable {
    case card, pin, signature, timestamp, save

    var label: String {
        switch self {
        case .card: return "Card"
        case .pin: return "PIN"
        case .signature: return "Semnătură"
        case .timestamp: return "Marcă temporală"
        case .save: return "Salvare"
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

    static func longDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ro_MD")
        f.dateStyle = .long
        f.timeStyle = .none
        return f.string(from: date)
    }

    /// "acum 2 min", "10:12", "24.10.2026".
    static func relative(_ date: Date, now: Date = Date()) -> String {
        let seconds = now.timeIntervalSince(date)
        if seconds < 60 { return "acum" }
        if seconds < 3600 { return "acum \(Int(seconds / 60)) min" }
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
