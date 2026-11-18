import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import QuickLook
#endif

struct SignedRow: View {
    let url: URL
    #if APP_STORE && os(macOS)
    @Environment(AppModel.self) private var model
    @State private var exporting = false
    @State private var exportError: String?
    #endif

    var body: some View {
        Group {
            #if APP_STORE && os(macOS)
            MacDocumentEntry(url: url, saveAs: { exporting = true }) {
                NSWorkspace.shared.activateFileViewerSelecting([url])
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
            if let error = model.exportErrors[url] {
                Text(L10n.text(.store_copy_failed, error)).font(.caption).foregroundStyle(Theme.warning)
            }
            #elseif os(macOS)
            MacDocumentEntry(url: url) { NSWorkspace.shared.activateFileViewerSelecting([url]) }
            #else
            IOSDocumentEntry(url: url)
            #endif
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sign.result")
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
