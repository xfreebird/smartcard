import SwiftUI
import MoldSignKit
#if os(iOS)
import QuickLook
import PDFKit
#else
import QuickLookUI
#endif

/// Read-only inspection: it neither changes the Verify workspace nor creates another history event.
struct SavedDocumentDetails: View {
    let url: URL
    var protectionOperation: String? = nil
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var reports: [Validator.Report]?
    @State private var decrypting = false
    @State private var unavailable = false
    @State private var scoped = false
    @State private var inspectedURL: URL?
    @State private var contentHeight: CGFloat = 240
    #if os(iOS)
    @State private var previewURL: URL?
    @State private var pdfPreviewing = false
    #else
    @State private var previewing = false
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if unavailable {
                        ContentUnavailableView(L10n.text(.saved_unavailable), systemImage: "doc.badge.ellipsis",
                                               description: Text(L10n.text(.saved_unavailable_hint)))
                    } else if let operation = protectionOperation {
                        Label(url.lastPathComponent, systemImage: operation == "encrypt" ? "lock.doc" : "doc.text")
                            .font(.headline).textSelection(.enabled)
                        Text(L10n.text(operation == "encrypt" ? .protect_encrypted : .protect_decrypted))
                            .foregroundStyle(.secondary)
                        if operation == "encrypt" { Text(L10n.text(.protect_encrypted_hint)) }
                    } else if let reports {
                        VerificationDocumentView(url: url, reports: reports)
                    } else {
                        ProgressView(L10n.text(.ui_verifying)).frame(maxWidth: .infinity, minHeight: 120)
                    }
                    if !unavailable, reports != nil || protectionOperation != nil {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 16) { fileActions }
                            VStack(alignment: .leading, spacing: 16) { fileActions }
                        }
                        if url.pathExtension.lowercased() == "xml" {
                            Text(L10n.text(.saved_xml_hint)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(24).frame(maxWidth: 680).frame(maxWidth: .infinity)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .navigationTitle(L10n.text(protectionOperation == nil ? .saved_details : .saved_title))
            .accessibilityIdentifier("documents.details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text(.ui_done)) { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, idealWidth: 640, maxWidth: 760)
        .frame(height: min(740, max(240, contentHeight + 56)))
        .sheet(isPresented: $previewing) { NativeDocumentPreview(url: url) }
        #else
        .quickLookPreview($previewURL)
        .sheet(isPresented: $pdfPreviewing) { PDFDocumentPreview(url: url) }
        #endif
        .sheet(isPresented: $decrypting) { FileProtectionScreen(initialURL: url, operation: 1).environment(model).appPreferences() }
        .onAppear { scoped = url.startAccessingSecurityScopedResource() }
        .onDisappear {
            if scoped { url.stopAccessingSecurityScopedResource(); scoped = false }
        }
        .task(id: url) {
            // A nested Files picker may make this task appear again. Do not destroy the
            // verification card and its selected-original state when that picker dismisses.
            guard inspectedURL != url else { return }
            reports = nil
            // An inaccessible file must not be presented as an unsigned or invalid document.
            unavailable = !FileManager.default.isReadableFile(atPath: url.path)
            guard !unavailable, protectionOperation == nil else { return }
            do {
                let checked = try await model.inspectDocument(url)
                guard !Task.isCancelled else { return }
                unavailable = !FileManager.default.isReadableFile(atPath: url.path)
                reports = checked
                inspectedURL = url
            } catch {
                guard !Task.isCancelled else { return }
                unavailable = true
            }
        }
    }

    @ViewBuilder private var fileActions: some View {
        if protectionOperation == "encrypt" {
            Button { decrypting = true } label: { Label(L10n.text(.protect_decrypt), systemImage: "lock.open") }
        }
        if protectionOperation != "encrypt" {
        Button {
            #if os(iOS)
            if url.pathExtension.lowercased() == "pdf" { pdfPreviewing = true }
            else { previewURL = url }
            #else
            previewing = true
            #endif
        } label: { Label(L10n.text(.document_preview), systemImage: "doc.text.magnifyingglass") }
        }
        ShareLink(item: url) { Label(L10n.text(.ui_share), systemImage: "square.and.arrow.up") }
        #if os(macOS)
        Button { NSWorkspace.shared.activateFileViewerSelecting([url]) } label: {
            Label(L10n.text(.ui_show_in_finder), systemImage: "folder")
        }
        #endif
    }
}

#if os(macOS)
/// Adjacent actions preserve the existing whole-row Finder reveal behavior after signing.
struct SignedDocumentActions: View {
    let url: URL
    @State private var previewing = false
    var body: some View {
        HStack(spacing: 12) {
            Button { previewing = true } label: {
                Label(L10n.text(.document_preview), systemImage: "doc.text.magnifyingglass")
            }.help(L10n.text(.document_preview))
            // Detached XML needs its original file; avoid implying that XML alone is a complete handoff.
            if url.pathExtension.lowercased() == "pdf" {
                ShareLink(item: url) { Label(L10n.text(.ui_share), systemImage: "square.and.arrow.up") }
                    .help(L10n.text(.ui_share))
            }
        }
        .labelStyle(.iconOnly)
        .sheet(isPresented: $previewing) { NativeDocumentPreview(url: url) }
    }
}

/// Quick Look remains a preview; verification is always performed by the document verifier.
struct NativeDocumentPreview: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var scoped = false
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(url.lastPathComponent).font(.headline).lineLimit(2)
                Spacer()
                Button(L10n.text(.ui_done)) { dismiss() }.keyboardShortcut(.cancelAction)
            }.padding()
            QuickLookDocumentView(url: url)
        }
        .frame(minWidth: 520, idealWidth: 720, maxWidth: 900, minHeight: 440, idealHeight: 700, maxHeight: 780)
        .onAppear { scoped = url.startAccessingSecurityScopedResource() }
        .onDisappear { if scoped { url.stopAccessingSecurityScopedResource(); scoped = false } }
    }
}

private struct QuickLookDocumentView: NSViewRepresentable {
    let url: URL
    func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView(frame: .zero, style: .normal)!
        view.autostarts = true
        view.previewItem = url as NSURL
        return view
    }
    func updateNSView(_ view: QLPreviewView, context: Context) { view.previewItem = url as NSURL }
    static func dismantleNSView(_ view: QLPreviewView, coordinator: ()) { view.close() }
}
#endif

#if os(iOS)
/// PDFKit keeps PDF rendering in the app; other document types retain Quick Look.
private struct PDFDocumentPreview: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var document: PDFDocument?
    @State private var loaded = false
    @State private var scoped = false
    var body: some View {
        NavigationStack {
            Group {
                if let document {
                    PDFPreviewSurface(document: document)
                } else if loaded {
                    ContentUnavailableView(L10n.text(.saved_unavailable), systemImage: "doc.badge.ellipsis",
                                           description: Text(L10n.text(.saved_unavailable_hint)))
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(url.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.text(.ui_done)) { dismiss() }
                }
            }
        }
        .onAppear {
            // Own access for the complete preview lifetime, independently of the details sheet.
            scoped = url.startAccessingSecurityScopedResource()
            guard !loaded else { return }
            if let candidate = PDFDocument(url: url), !candidate.isLocked, candidate.pageCount > 0 {
                document = candidate
            }
            loaded = true
        }
        .onDisappear { if scoped { url.stopAccessingSecurityScopedResource(); scoped = false } }
    }
}

private struct PDFPreviewSurface: UIViewRepresentable {
    let document: PDFDocument
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.document = document
        view.accessibilityIdentifier = "documents.pdfPreview"
        return view
    }
    func updateUIView(_ view: PDFView, context: Context) {
        if view.document !== document { view.document = document }
    }
}
#endif
