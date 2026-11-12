import Foundation
import Observation

/// Owns document history and deletion policy. Mode changes replace its persistence adapter.
@MainActor @Observable
final class DocumentLibraryModel {
    var activity: [ActivityItem] = []
    var savedDocuments: [ActivityItem] = []
    private(set) var recentsClearedAt = Date.distantPast
    @ObservationIgnored private var store: any ActivityStoring
    @ObservationIgnored private var onDocumentsChanged: () -> Void

    init(store: any ActivityStoring, onDocumentsChanged: @escaping () -> Void) {
        self.store = store
        self.onDocumentsChanged = onDocumentsChanged
        reload(store: store, onDocumentsChanged: onDocumentsChanged)
    }

    func reload(store: any ActivityStoring, onDocumentsChanged: @escaping () -> Void) {
        self.store = store
        self.onDocumentsChanged = onDocumentsChanged
        activity = store.load()
        savedDocuments = store.loadOrMigrateDocuments()
        recentsClearedAt = store.recentsClearedAt
    }

    func log(_ item: ActivityItem) {
        if item.isSavedDocument, let url = item.fileURL {
            savedDocuments.removeAll { $0.fileURL?.standardizedFileURL == url.standardizedFileURL }
            savedDocuments.insert(item, at: 0)
            store.saveDocuments(savedDocuments)
            onDocumentsChanged()
        }
        activity.insert(item, at: 0)
        if activity.count > 100 { activity.removeLast(activity.count - 100) }
        saveActivity()
    }

    /// Recent documents: signed/verified files that are still on disk (browser requests have no file), newer than the
    /// last "Golește" in the popover. Clearing recents keeps the Activity history; that one has its own clear.
    var recentDocuments: [ActivityItem] {
        activity.filter { item in
            item.date > recentsClearedAt && (item.fileURL.map(Self.fileExists) ?? false)
        }
    }

    func clearRecents() {
        recentsClearedAt = Date()
        store.recentsClearedAt = recentsClearedAt
    }

    /// Forget entries whose file was moved or deleted (called when a list of them is shown).
    func pruneMissingFiles() {
        let kept = activity.filter { $0.fileURL.map(Self.fileExists) ?? true }
        guard kept.count != activity.count else { return }
        activity = kept
        saveActivity()
    }

    /// Called only after the user confirms the selected saved outputs.
    func deleteSavedDocuments(_ items: [ActivityItem]) -> Bool {
        var failed = false
        for item in items {
            guard let saved = savedDocuments.first(where: { $0.id == item.id }) else { continue }
            // A confirmation belongs to the stored file, not merely an entry identifier.
            guard let url = saved.fileURL, url == item.fileURL else { failed = true; continue }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
                guard values.isRegularFile == true, values.isSymbolicLink != true else { failed = true; continue }
                try FileManager.default.removeItem(at: url)
                savedDocuments.removeAll { $0.id == item.id }
            } catch let error as NSError where error.domain == NSCocoaErrorDomain &&
                (error.code == NSFileNoSuchFileError || error.code == NSFileReadNoSuchFileError) {
                savedDocuments.removeAll { $0.id == item.id }
            } catch { failed = true }
        }
        store.saveDocuments(savedDocuments)
        onDocumentsChanged()
        return !failed
    }

    func clearActivity() {
        activity.removeAll()
        saveActivity()
    }

    private func saveActivity() {
        store.save(activity)
    }

    private static func fileExists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
    }

}
