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

struct PresentedError: Equatable {
    let messageText: PresentationText
    let recoveryText: PresentationText
    var message: String { messageText.text }
    var recovery: String { recoveryText.text }
}

/// StatusCard states (docs/10 §3).
enum ReaderStatus: Equatable {
    case unavailable                       // no smart-card access (entitlement missing)
    case noReader
    case empty(reader: String)
    case reading(reader: String)
    case ready(reader: String, holder: String, validUntil: Date?)
    case busy(reader: String, holder: String)
    case error(message: PresentationText, recovery: PresentationText)

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
        case .unavailable: return L10n.text(.ui_reader_access_unavailable)
        case .noReader: return L10n.text(.ui_connect_the_reader)
        case .empty: return L10n.text(.ui_insert_the_card)
        case .reading: return L10n.text(.ui_reading_the_card)
        case .ready(_, let holder, _), .busy(_, let holder): return holder
        case .error(let message, _): return message.text
        }
    }

    var subtitle: String {
        switch self {
        case .unavailable: return L10n.text(.ui_check_the_app_permissions)
        case .noReader:
            #if os(iOS)
            return L10n.text(.ui_usb_c_or_lightning_adapter_for_iphone_and_ipad)
            #else
            return L10n.text(.ui_usb_a_or_usb_c_adapter)
            #endif
        case .empty(let reader), .reading(let reader): return reader
        case .ready(let reader, _, _): return L10n.text(.ui_card_ready_value, reader)
        case .busy: return L10n.text(.ui_signing)
        case .error(_, let recovery): return recovery.text
        }
    }

    var detail: String? {
        guard case .ready(_, _, let until?) = self else { return nil }
        return L10n.text(.ui_certificate_valid_until_value, until.formatted(.dateTime.month(.twoDigits).year()))
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

/// The one-glance "can I sign?" light (docs/10 §0.1, UX-01). Color is never the only signal: `label` says it too.
enum StatusLight: Equatable {
    case idle, reader, ready, busy, error

    var color: Color? {
        switch self {
        case .idle: return nil
        case .reader: return .orange
        case .ready: return .green
        case .busy: return .blue
        case .error: return .red
        }
    }
}

/// One inserted card. `generation` comes from the reader monitor: a new value means a (re)inserted card.
struct CardSlot: Identifiable, Equatable {
    let reader: String
    let generation: Int
    var certificate: SigningService.CertificateSummary?
    var problemText: PresentationText?
    var problem: String? { problemText?.text }
    var id: String { reader }
}

enum SignFormat: String, CaseIterable, Identifiable {
    case padesT, xadesBES, xadesT, xadesC
    var id: String { rawValue }

    var label: String {
        switch self {
        case .padesT: return L10n.text(.format_pdf)
        case .xadesBES: return L10n.text(.format_xml)
        case .xadesT: return L10n.text(.format_xml_time)
        case .xadesC: return L10n.text(.format_xml_data)
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

    /// PDFs: PAdES-T inside the PDF (default) or a detached XAdES next to it; other files: XAdES only.
    static func choices(for url: URL) -> [SignFormat] {
        url.pathExtension.lowercased() == "pdf" ? [.padesT, .xadesBES, .xadesT, .xadesC] : [.xadesBES, .xadesT, .xadesC]
    }
}

struct SignItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var format: SignFormat
    var stamp: PDFStampPlacement?
    var signingError: String?

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
    case valid(count: Int), invalid, unknown, incomplete, untrusted

    init(_ reports: [Validator.Report]) {
        if reports.isEmpty {
            self = .unknown
        } else if reports.contains(where: { !$0.signatureValid || (!$0.contentIntact && $0.missingDetachedReferences.isEmpty) }) {
            self = .invalid
        } else if reports.contains(where: { !$0.missingDetachedReferences.isEmpty }) {
            self = .incomplete
        } else if reports.allSatisfy({ $0.contentIntact && $0.signatureValid }) {
            self = reports.allSatisfy(\.chainTrusted) ? .valid(count: reports.count) : .untrusted
        } else {
            self = .invalid
        }
    }

    var title: String {
        switch self {
        case .valid: return L10n.text(.ui_valid_signature)
        case .invalid: return L10n.text(.ui_invalid_signature)
        case .unknown, .incomplete, .untrusted: return L10n.text(.ui_cannot_be_confirmed)
        }
    }

    var subtitle: String {
        switch self {
        case .valid(let count): return L10n.text(.ui_verified_signatures_count, count)
        case .invalid: return L10n.text(.ui_the_document_has_been_modified_or_the_signature_does_not_match)
        case .unknown: return L10n.text(.verify_no_recognized_signature)
        case .untrusted: return L10n.text(.verify_trust_unconfirmed)
        case .incomplete: return L10n.text(.verify_original_missing)
        }
    }

    var symbol: String {
        switch self {
        case .valid: return "checkmark.seal.fill"
        case .invalid: return "xmark.seal.fill"
        case .unknown, .incomplete, .untrusted: return "exclamationmark.triangle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .valid: return Theme.success
        case .invalid: return Theme.danger
        case .unknown, .incomplete, .untrusted: return Theme.warning
        }
    }
}


/// What the PIN sheet shows. `attemptsLeft` comes from the last 63Cx.
struct PinRequest: Identifiable {
    let id = UUID()
    let holder: String
    let attemptsLeft: Int?
    let canRemember: Bool
    let documentNames: [String]

    init(holder: String, attemptsLeft: Int?, canRemember: Bool, documentNames: [String] = []) {
        self.holder = holder
        self.attemptsLeft = attemptsLeft
        self.canRemember = canRemember
        self.documentNames = documentNames
    }
}

/// A browser asking for a signature (SEC-02).
struct ConsentRequest: Identifiable {
    let id = UUID()
    let request: BridgeRequest
    let holder: String
    let hasStoredPIN: Bool

    var originHost: String {
        request.origin.flatMap { URL(string: $0)?.host } ?? L10n.text(.ui_local_application)
    }

    /// The request payload identifies every document where the bridge knows it.
    /// Keep the fallback in the presentation model so older portals that only send
    /// opaque data still get an accurate, non-empty consent summary.
    var documentNames: [String] {
        request.documentNames.isEmpty
            ? [request.documentName ?? L10n.text(.ui_data_to_sign)]
            : request.documentNames
    }

    var contentSummary: String {
        let bytes = request.contentBytes.map { ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file) }
            ?? L10n.text(.ui_content_size_unknown)
        return L10n.text(.ui_consent_content_count_size, request.documentCount, bytes)
    }
}

enum BridgeState: Equatable {
    case stopped
    case running
    case portBusy   // the vendor Java server holds 18480/18443 (MAC-08)
    case failed(String)
}
