import Foundation

/// Stable input identity for picker and drop batches, independent of presentation and storage.
public enum DocumentImportPolicy {
    public static func newFiles(_ incoming: [URL], excluding existing: [URL]) -> [URL] {
        var seen = Set(existing.map(\.standardizedFileURL))
        return incoming.filter { url in
            url.isFileURL && !url.hasDirectoryPath && seen.insert(url.standardizedFileURL).inserted
        }
    }
}
