import SwiftUI
import UniformTypeIdentifiers
import MoldSignKit

/// "Verifică": choose or drop a signed file → verdict + one section per signature (UX-03/UX-04).
struct VerifyScreen: View {
    @Environment(AppModel.self) private var model
    @State private var importing = false
    @State private var shortcutPDFOnly = false
    @State private var activeShortcutSelection: ShortcutNavigation.PDFSelection?
    @State private var shortcutNavigation = ShortcutNavigation.shared
    @State private var dropTargeted = false
    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif
    private var shortViewport: Bool {
        #if os(iOS)
        verticalSizeClass == .compact
        #else
        false
        #endif
    }
    private var compactChooser: Bool {
        #if os(iOS)
        verticalSizeClass == .compact || !model.verifiedDocuments.isEmpty
        #else
        !model.verifiedDocuments.isEmpty
        #endif
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: shortViewport ? 12 : 24) {
                #if os(iOS)
                if model.verifiedDocuments.isEmpty && model.verifyFile == nil {
                    VStack(spacing: 24) {
                        Image(systemName: "checkmark.seal")
                            .font(.system(size: 72, weight: .light)).foregroundStyle(Theme.brand)
                            .frame(height: 175).accessibilityHidden(true)
                        Text(L10n.text(.ui_choose_the_signed_document)).font(.largeTitle.bold())
                        Text(L10n.text(.ui_or_drop_it_here_signed_pdf_or_xades_signature_xml))
                            .font(.body).foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center).frame(maxWidth: .infinity)
                    .accessibilityIdentifier("verify.dropZone")
                }
                #else
                DropZone(verification: true, compact: compactChooser, short: compactChooser, targeted: dropTargeted) { shortcutPDFOnly = false; importing = true }
                    .accessibilityIdentifier("verify.dropZone")
                #endif
                if let file = model.verifyFile, model.verifyReports == nil {
                    ProgressView(L10n.text(.ui_verifying) + " · " + file.lastPathComponent)
                }
                #if os(macOS)
                if !model.verifiedDocuments.isEmpty || model.verifyFile != nil {
                    Button(L10n.text(.ui_clear_results), role: .destructive) { model.clearVerification() }
                        .accessibilityIdentifier("verify.clearResults")
                }
                #endif
                ForEach(model.verifiedDocuments, id: \.url) { document in
                    VerificationDocumentView(url: document.url, reports: document.reports)
                        .id(model.verificationGeneration)
                }
            }
            #if os(iOS)
            .frame(maxWidth: 560)
            #else
            .frame(maxWidth: 680)
            #endif
            .padding(shortViewport ? 12 : 24)
            .frame(maxWidth: .infinity)
        }
        .accessibilityIdentifier("verify.workspace")
        #if os(iOS)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button { shortcutPDFOnly = false; importing = true } label: {
                Text(L10n.text(model.verifiedDocuments.isEmpty ? .guided_choose : .ui_choose_another_document))
                    .font(.headline).frame(maxWidth: .infinity, minHeight: 32)
            }
            .buttonStyle(.borderedProminent).controlSize(.large).buttonBorderShape(.capsule).tint(Theme.brand)
            .accessibilityIdentifier("verify.pickFiles")
            .frame(maxWidth: 560).padding(.horizontal, 24).padding(.vertical, 12)
            .frame(maxWidth: .infinity).background(Color(uiColor: .systemGroupedBackground))
        }
        .safeAreaInset(edge: .top, spacing: 0) { if model.showsDemoNotice { DemoModeBanner() } }
        #endif
        .navigationTitle(L10n.text(.ui_verify))
        #if os(iOS)
        .toolbar {
            if !model.verifiedDocuments.isEmpty || model.verifyFile != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) { model.clearVerification() } label: {
                        Label(L10n.text(.ui_clear_results), systemImage: "trash")
                    }
                    .accessibilityIdentifier("verify.clearResults")
                }
            }
        }
        #endif
        .overlay {
            if dropTargeted {
                RoundedRectangle(cornerRadius: 12).strokeBorder(Color.accentColor, lineWidth: 2).padding(4).allowsHitTesting(false)
            }
        }
        .onDrop(of: [.fileURL, .pdf, .xml, .data, .item], isTargeted: $dropTargeted) { providers in
            Task {
                let urls = await DroppedDocumentLoader.load(providers)
                if !urls.isEmpty { await model.verifyFiles(urls) }
            }
            return !providers.isEmpty
        }
        .task(id: "\(shortcutNavigation.pendingPDFSelection?.id.uuidString ?? "none")-\(importing)") {
            guard !importing else { return }
            guard shortcutNavigation.pendingPDFSelection?.purpose == .verify else { return }
            // Present after the destination is mounted, including a cold Siri launch.
            await Task.yield()
            guard !Task.isCancelled, !importing,
                  shortcutNavigation.pendingPDFSelection?.purpose == .verify else { return }
            activeShortcutSelection = shortcutNavigation.pendingPDFSelection
            shortcutPDFOnly = true
            importing = true
            shortcutNavigation.pendingPDFSelection = nil
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: shortcutPDFOnly ? [.pdf] : [.pdf, .xml, .item], allowsMultipleSelection: !shortcutPDFOnly, onCompletion: { result in
            let selection = activeShortcutSelection
            activeShortcutSelection = nil
            if let selection, selection.waitsForIntent {
                let selectedURL = result.flatMap { urls -> Result<URL, Error> in
                    guard let url = urls.first else { return .failure(CancellationError()) }
                    return .success(url)
                }
                shortcutNavigation.finishPDFSelection(id: selection.id, result: selectedURL)
                return
            }
            if let selection, !shortcutNavigation.isCurrentSelection(selection.id) { return }
            if case .success(let urls) = result { Task { await model.verifyFiles(urls) } }
        }, onCancellation: {
            if let selection = activeShortcutSelection, selection.waitsForIntent {
                shortcutNavigation.finishPDFSelection(id: selection.id, result: .failure(CancellationError()))
            }
            activeShortcutSelection = nil
        })
    }
}
