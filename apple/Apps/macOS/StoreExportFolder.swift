#if APP_STORE
import MoldSignKit
import SwiftUI

@MainActor
enum StoreExportFolder {
    static let bookmarkKey = "signedDocumentExportFolder"

    static func resolve(_ data: Data, stale: inout Bool) throws -> URL {
        try URL(resolvingBookmarkData: data, options: [.withSecurityScope, .withoutUI, .withoutMounting],
                relativeTo: nil, bookmarkDataIsStale: &stale)
    }

    static func exportCopy(of signed: URL, original: URL) async throws {
        let defaults = AppPreferencesStore.defaults
        guard let bookmark = defaults.data(forKey: bookmarkKey) else { return }
        var stale = false
        let folder = try resolve(bookmark, stale: &stale)
        guard folder.startAccessingSecurityScopedResource() else { throw CocoaError(.fileWriteNoPermission) }
        defer { folder.stopAccessingSecurityScopedResource() }
        if stale {
            let refreshed = try folder.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            defaults.set(refreshed, forKey: bookmarkKey)
        }
        if folder.standardizedFileURL == signed.deletingLastPathComponent().standardizedFileURL { return }

        try await Task.detached {
            let manager = FileManager.default
            // Publish a complete copy, including on removable drives. Never overwrite another document.
            let temporary = folder.appendingPathComponent(".esemnbun-\(UUID().uuidString).tmp")
            defer { try? manager.removeItem(at: temporary) }
            try manager.copyItem(at: signed, to: temporary)
            let input = folder.appendingPathComponent(original.lastPathComponent)
            let destination = SigningService.outputURL(for: input, pathExtension: signed.pathExtension)
            try manager.moveItem(at: temporary, to: destination)
        }.value
    }
}

struct StoreExportFolderSettings: View {
    @AppStorage(StoreExportFolder.bookmarkKey, store: AppPreferencesStore.defaults) private var bookmark: Data?
    @State private var errorMessage: String?

    private var folderName: String {
        var stale = false
        guard let bookmark else { return L10n.text(.store_no_folder) }
        return (try? StoreExportFolder.resolve(bookmark, stale: &stale).path(percentEncoded: false))
            ?? L10n.text(.store_folder_unavailable)
    }

    var body: some View {
        LabeledContent(L10n.text(.store_copy_folder), value: folderName)
        HStack {
            Button(L10n.text(.store_choose_folder)) {
                let panel = NSOpenPanel()
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                panel.canCreateDirectories = true
                guard panel.runModal() == .OK, let folder = panel.url else { return }
                let accessed = folder.startAccessingSecurityScopedResource()
                defer { if accessed { folder.stopAccessingSecurityScopedResource() } }
                do {
                    bookmark = try folder.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                    errorMessage = nil
                } catch { errorMessage = error.localizedDescription }
            }
            if bookmark != nil {
                Button(L10n.text(.store_stop_copies)) { bookmark = nil; errorMessage = nil }
            }
        }
        if let errorMessage { Text(errorMessage).font(.caption).foregroundStyle(Theme.danger) }
    }
}
#endif
