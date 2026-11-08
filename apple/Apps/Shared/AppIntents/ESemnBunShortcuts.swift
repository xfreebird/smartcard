import AppIntents
import Foundation
import MoldSignKit
import Observation

/// Retained navigation survives an intent running before the first SwiftUI view appears.
@MainActor @Observable
final class ShortcutNavigation {
    static let shared = ShortcutNavigation()
    struct Request {
        let id = UUID()
        var preparedURL: URL? = nil
        let reports: [Validator.Report]?
        let filename: String?
    }
    var documentSearch = ""
    var documentSearchGeneration = UUID()
    var selectedDocumentID: UUID?
    var request: Request?
    private var generation = UUID()

    func openDocuments() {
        generation = UUID()
        request = Request(reports: nil, filename: nil)
        activate()
    }
    func prepare(_ url: URL) {
        generation = UUID()
        request = Request(preparedURL: url, reports: nil, filename: nil)
        activate()
    }
    private func activate() {
        #if os(macOS)
        NotificationCenter.default.post(name: .showInsertedCard, object: nil)
        #endif
    }
    func beginVerification() -> UUID {
        generation = UUID()
        return generation
    }
    func showVerification(_ reports: [Validator.Report], filename: String, generation: UUID) {
        guard self.generation == generation else { return }
        request = Request(reports: reports, filename: filename)
        activate()
    }
}

struct OpenDocumentsIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("shortcut_open_documents", defaultValue: "Open Documents")
    static var description = IntentDescription(LocalizedStringResource("shortcut_open_documents_description", defaultValue: "Open your documents in eSemnBun."))
    @available(iOS 26.0, macOS 26.0, *)
    static var supportedModes: IntentModes { .foreground }
    static var openAppWhenRun: Bool = true
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @MainActor
    func perform() async throws -> some IntentResult {
        ShortcutNavigation.shared.openDocuments()
        return .result()
    }
}

enum PDFVerificationOutcome: String, AppEnum {
    case signaturesVerified, invalidSignature, unconfirmed, noRecognizedSignature

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("shortcut_verification_result", defaultValue: "Offline verification result"))
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .signaturesVerified: DisplayRepresentation(title: LocalizedStringResource("shortcut_verified_offline", defaultValue: "Signatures verified offline")),
        .invalidSignature: DisplayRepresentation(title: LocalizedStringResource("shortcut_invalid_signature", defaultValue: "Invalid signature")),
        .unconfirmed: DisplayRepresentation(title: LocalizedStringResource("shortcut_unconfirmed_trust", defaultValue: "Trust could not be confirmed")),
        .noRecognizedSignature: DisplayRepresentation(title: LocalizedStringResource("shortcut_no_signature", defaultValue: "No recognized signature"))
    ]
}

struct VerifyPDFIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("shortcut_verify_pdf", defaultValue: "Verify PDF")
    static var description = IntentDescription(LocalizedStringResource("shortcut_verify_pdf_description", defaultValue: "Check PDF signatures offline and open the full results. PDFs up to 32 MiB are supported. This does not check current certificate revocation status."))
    @available(iOS 26.0, macOS 26.0, *)
    static var supportedModes: IntentModes { .foreground }
    static var openAppWhenRun: Bool = true
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: LocalizedStringResource("shortcut_pdf_document", defaultValue: "PDF document"), supportedTypeIdentifiers: ["com.adobe.pdf"])
    var document: IntentFile

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<PDFVerificationOutcome> {
        try Task.checkCancellation()
        let generation = ShortcutNavigation.shared.beginVerification()
        let file = document
        // Stream file-backed input off the main actor; never copy an unbounded provider file.
        let copying = Task.detached { try ShortcutPDFCopy(file) }
        let copy = try await withTaskCancellationHandler {
            try await copying.value
        } onCancel: {
            copying.cancel()
        }
        defer { try? FileManager.default.removeItem(at: copy.directory) }
        try Task.checkCancellation()
        let reports = try await CoreDocumentVerifier(service: SigningService()).inspect(copy.url)
        try Task.checkCancellation()
        let outcome: PDFVerificationOutcome
        if reports.isEmpty { outcome = .noRecognizedSignature }
        else if reports.contains(where: { !$0.contentIntact || !$0.signatureValid }) { outcome = .invalidSignature }
        else if reports.contains(where: { !$0.chainTrusted }) { outcome = .unconfirmed }
        else { outcome = .signaturesVerified }
        ShortcutNavigation.shared.showVerification(reports, filename: copy.url.lastPathComponent, generation: generation)
        return .result(value: outcome)
    }
}

struct ESemnBunShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: OpenDocumentsIntent(), phrases: ["Open documents in \(.applicationName)"],
                    shortTitle: LocalizedStringResource("shortcut_open_documents", defaultValue: "Open Documents"), systemImageName: "folder")
        AppShortcut(intent: PreparePDFSigningIntent(), phrases: ["Prepare PDF for signing in \(.applicationName)"],
                    shortTitle: LocalizedStringResource("shortcut_prepare_short", defaultValue: "Prepare Signing"), systemImageName: "signature")
        AppShortcut(intent: VerifyPDFIntent(), phrases: ["Verify PDF with \(.applicationName)"],
                    shortTitle: LocalizedStringResource("shortcut_verify_pdf", defaultValue: "Verify PDF"), systemImageName: "checkmark.seal")
    }
}

struct ShortcutPDFCopy: Sendable {
    let directory: URL
    let url: URL
    private static let maximumBytes = 32 * 1_024 * 1_024

    init(_ file: IntentFile, forSigning: Bool = false) throws {
        let base = forSigning
            ? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("eSemnBun Imports", isDirectory: true)
            : FileManager.default.temporaryDirectory
        directory = base.appendingPathComponent("shortcut-" + UUID().uuidString, isDirectory: true)
        let name = URL(fileURLWithPath: file.filename).lastPathComponent
        guard !name.isEmpty, name.lowercased().hasSuffix(".pdf") else { throw InputError.pdfRequired }
        url = directory.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                               attributes: nil)
        do {
            var data = Data()
            if let source = file.fileURL {
                guard source.isFileURL else { throw InputError.unreadable }
                let scoped = source.startAccessingSecurityScopedResource()
                defer { if scoped { source.stopAccessingSecurityScopedResource() } }
                let handle = try FileHandle(forReadingFrom: source)
                defer { try? handle.close() }
                while let chunk = try handle.read(upToCount: 64 * 1_024), !chunk.isEmpty {
                    try Task.checkCancellation()
                    guard chunk.count <= Self.maximumBytes - data.count else { throw InputError.tooLarge }
                    data.append(chunk)
                }
            } else {
                // IntentFile already owns this in-memory payload; cap the app-owned copy.
                let supplied = file.data
                guard supplied.count <= Self.maximumBytes else { throw InputError.tooLarge }
                data = supplied
            }
            guard data.starts(with: Data("%PDF-".utf8)) else { throw InputError.pdfRequired }
            #if os(iOS)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            #else
            try data.write(to: url, options: .atomic)
            #endif
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    enum InputError: LocalizedError {
        case pdfRequired, tooLarge, unreadable
        var errorDescription: String? {
            switch self {
            case .pdfRequired: L10n.text(.shortcut_error_pdf_required)
            case .tooLarge: L10n.text(.shortcut_error_too_large)
            case .unreadable: L10n.text(.shortcut_error_unreadable)
            }
        }
    }
}

/// Preparation never invokes signing or requests a PIN. The existing foreground review owns both.
struct PreparePDFSigningIntent: AppIntent {
    static var title: LocalizedStringResource = LocalizedStringResource("shortcut_prepare_pdf", defaultValue: "Prepare PDF for Signing")
    static var description = IntentDescription(LocalizedStringResource("shortcut_prepare_description", defaultValue: "Add a PDF up to 32 MiB to the signing queue. Review the document and explicitly sign in the app."))
    @available(iOS 26.0, macOS 26.0, *)
    static var supportedModes: IntentModes { .foreground }
    static var openAppWhenRun = true
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Parameter(title: LocalizedStringResource("shortcut_pdf_document", defaultValue: "PDF document"), supportedTypeIdentifiers: ["com.adobe.pdf"])
    var document: IntentFile

    @MainActor
    func perform() async throws -> some IntentResult {
        let file = document
        let task = Task.detached { try ShortcutPDFCopy(file, forSigning: true) }
        let copy = try await withTaskCancellationHandler { try await task.value } onCancel: { task.cancel() }
        do {
            try Task.checkCancellation()
            ShortcutNavigation.shared.prepare(copy.url)
        } catch {
            try? FileManager.default.removeItem(at: copy.directory)
            throw error
        }
        return .result()
    }
}
