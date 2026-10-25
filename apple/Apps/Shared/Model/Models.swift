import SwiftUI
import MoldSignKit

/// StatusCard states (docs/10 §3).
enum ReaderStatus: Equatable {
    case unavailable                       // no smart-card access (entitlement missing)
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
        case .unavailable: return String(localized: "Acces la cititor indisponibil")
        case .noReader: return String(localized: "Conectează cititorul")
        case .empty: return String(localized: "Introdu cardul în cititor")
        case .reading: return String(localized: "Se citește cardul…")
        case .ready(_, let holder, _), .busy(_, let holder): return holder
        case .error(let message, _): return message
        }
    }

    var subtitle: String {
        switch self {
        case .unavailable: return String(localized: "Verifică permisiunile aplicației")
        case .noReader: return String(localized: "USB-A, USB-C sau adaptor Lightning")
        case .empty(let reader), .reading(let reader): return reader
        case .ready(let reader, _, _): return String(localized: "Card pregătit · \(reader)")
        case .busy: return String(localized: "Se semnează…")
        case .error(_, let recovery): return recovery
        }
    }

    var detail: String? {
        guard case .ready(_, _, let until?) = self else { return nil }
        return String(localized: "Certificat valabil până la \(until.formatted(.dateTime.month(.twoDigits).year()))")
    }

    var tint: Color {
        switch self {
        case .ready: return Theme.success
        case .busy, .reading: return Theme.brand
        case .error, .unavailable: return Theme.danger
        case .noReader, .empty: return .secondary
        }
    }

    var menuBarSymbol: String {
        switch self {
        case .error, .unavailable: return "exclamationmark.triangle"
        case .busy: return "ellipsis.circle"
        default: return "signature"
        }
    }
}

/// One inserted card. `generation` comes from the reader monitor: a new value means a (re)inserted card.
struct CardSlot: Identifiable, Equatable {
    let reader: String
    let generation: Int
    var certificate: SigningService.CertificateSummary?
    var problem: String?
    var id: String { reader }
}

enum SignFormat: String, CaseIterable, Identifiable {
    case padesT, xadesBES, xadesT, xadesC
    var id: String { rawValue }

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

    /// PDF → PAdES-T, anything else → XAdES-T detached (docs/10 principle 2).
    static func automatic(for url: URL) -> SignFormat {
        url.pathExtension.lowercased() == "pdf" ? .padesT : .xadesT
    }
}

struct SignItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var format: SignFormat

    init(url: URL) {
        self.url = url
        format = .automatic(for: url)
    }

    var sizeText: String {
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
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

    var title: LocalizedStringKey {
        switch self {
        case .valid: return "Semnătură validă"
        case .invalid: return "Semnătură invalidă"
        case .unknown: return "Nu poate fi confirmată"
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .valid(let count): return "Semnături verificate: \(count)"
        case .invalid: return "Documentul a fost modificat sau semnătura nu corespunde"
        case .unknown: return "Nicio semnătură găsită sau lanț de încredere necunoscut"
        }
    }

    var symbol: String {
        switch self {
        case .valid: return "checkmark.seal.fill"
        case .invalid: return "xmark.seal.fill"
        case .unknown: return "exclamationmark.triangle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .valid: return Theme.success
        case .invalid: return Theme.danger
        case .unknown: return Theme.warning
        }
    }
}

struct ActivityItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var subtitle: String
    var ok: Bool
    var date = Date()
    var fileURL: URL?
}

/// What the PIN sheet shows. `attemptsLeft` comes from the last 63Cx.
struct PinRequest: Identifiable {
    let id = UUID()
    let holder: String
    let attemptsLeft: Int?
    let canRemember: Bool
}

/// A browser asking for a signature (SEC-02).
struct ConsentRequest: Identifiable {
    let id = UUID()
    let request: BridgeRequest
    let holder: String
    let hasStoredPIN: Bool

    var originHost: String {
        request.origin.flatMap { URL(string: $0)?.host } ?? String(localized: "Aplicație locală")
    }
}

enum BridgeState: Equatable {
    case stopped
    case running
    case portBusy   // the vendor Java server holds 18480/18443 (MAC-08)
    case failed(String)
}
