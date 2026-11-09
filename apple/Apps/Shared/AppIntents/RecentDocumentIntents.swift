import AppIntents
import Foundation

/// Discovery is opt-in; resolve again at invocation instead of trusting cached widget metadata.
struct OpenLatestSignedDocumentIntent: AppIntent {
    static var title: LocalizedStringResource = "shortcut_open_latest"
    static var description = IntentDescription("shortcut_open_latest_description")
    static var openAppWhenRun = true
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication
    @available(iOS 26.0, macOS 26.0, *)
    static var supportedModes: IntentModes { .foreground }

    @MainActor
    func perform() async throws -> some IntentResult {
        try Task.checkCancellation()
        ShortcutNavigation.shared.documentSearch = ""
        if let id = DocumentDiscovery.documents().max(by: { $0.date < $1.date })?.id {
            ShortcutNavigation.shared.openDocument(id)
        } else {
            ShortcutNavigation.shared.selectedDocumentID = nil
            ShortcutNavigation.shared.openDocuments()
        }
        return .result()
    }
}

struct VerifyLatestSignedPDFIntent: AppIntent {
    static var title: LocalizedStringResource = "shortcut_verify_latest"
    static var description = IntentDescription("shortcut_verify_latest_description")
    static var openAppWhenRun = true
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication
    @available(iOS 26.0, macOS 26.0, *)
    static var supportedModes: IntentModes { .foreground }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<PDFVerificationOutcome> {
        try Task.checkCancellation()
        var intent = VerifyPDFIntent()
        if let url = DocumentDiscovery.documents().filter({ $0.fileURL?.pathExtension.lowercased() == "pdf" })
            .max(by: { $0.date < $1.date })?.fileURL {
            intent.document = IntentFile(fileURL: url, filename: url.lastPathComponent)
        }
        // No eligible recent PDF (or discovery disabled): ask the user through the existing picker.
        return try await intent.perform()
    }
}
