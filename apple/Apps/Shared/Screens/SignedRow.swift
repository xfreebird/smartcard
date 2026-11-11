import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import QuickLook
#endif

struct SignedRow: View {
    let url: URL
    #if os(iOS)
    @State private var previewURL: URL?
    #endif
    @State private var hovered = false
    #if APP_STORE && os(macOS)
    @State private var exporting = false
    @State private var exportError: String?
    #endif

    var body: some View {
        Group {
            #if APP_STORE && os(macOS)
            HStack(spacing: 12) {
                Button { NSWorkspace.shared.activateFileViewerSelecting([url]) } label: { rowContents }
                SignedDocumentActions(url: url)
            }
                .contextMenu { Button(L10n.text(.ui_export)) { exporting = true } }
                .fileExporter(isPresented: $exporting, document: SignedExport(url: url),
                              contentType: UTType(filenameExtension: url.pathExtension) ?? .data,
                              defaultFilename: url.lastPathComponent) { result in
                    if case .failure(let error) = result { exportError = error.localizedDescription }
                }
                .alert(L10n.text(.ui_export_failed), isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
                    Button(L10n.text(.ui_done)) { exportError = nil }
                } message: { Text(exportError ?? L10n.text(.ui_)) }
            #elseif os(macOS)
            HStack(spacing: 12) {
                Button { NSWorkspace.shared.activateFileViewerSelecting([url]) } label: { rowContents }
                SignedDocumentActions(url: url)
            }
            #else
            HStack(spacing: 12) {
                Button { previewURL = url } label: {
                    HStack {
                        Label(url.lastPathComponent, systemImage: "doc.badge.checkmark")
                            .lineLimit(2).multilineTextAlignment(.leading)
                        Spacer()
                        Text(L10n.text(.ui_open)).font(.caption)
                    }.frame(minHeight: 44)
                }
                ShareLink(item: url) { Image(systemName: "square.and.arrow.up").frame(width: 44, height: 44) }
                    .accessibilityLabel(L10n.text(.ui_share))
            }
            .quickLookPreview($previewURL)
            #endif
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sign.result")
    }

    private var rowContents: some View {
        HStack(spacing: 12) {
            Label(url.lastPathComponent, systemImage: "checkmark.seal.fill")
                .labelStyle(SuccessLabelStyle())
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 12)
            #if os(macOS)
            Text(L10n.text(.ui_show_in_finder)).foregroundStyle(.secondary)
            #else
            Label(L10n.text(.ui_share), systemImage: "square.and.arrow.up").foregroundStyle(.secondary)
            #endif
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(hovered ? Color.accentColor.opacity(0.10) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct SuccessLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.foregroundStyle(.green)
            configuration.title
        }
    }
}

#if APP_STORE && os(macOS)
private struct SignedExport: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }
    let url: URL?
    private let contents: Data?
    init(url: URL) { self.url = url; contents = nil }
    init(configuration: ReadConfiguration) throws {
        url = nil
        contents = configuration.file.regularFileContents
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        if let url { return FileWrapper(regularFileWithContents: try Data(contentsOf: url)) }
        return FileWrapper(regularFileWithContents: contents ?? Data())
    }
}
#endif
