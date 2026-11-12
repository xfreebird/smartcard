import Foundation

/// Filesystem policy for confirmed library entries; independent of GTK and persistence.
struct DeleteSavedDocuments {
    struct Result {
        var documents: [ActivityItem]
        var failed = false
    }

    func execute(_ selected: [ActivityItem], saved: [ActivityItem]) -> Result {
        var result = Result(documents: saved)
        for item in selected {
            guard let stored = result.documents.first(where: { $0.id == item.id }) else { continue }
            guard let path = stored.filePath, path == item.filePath else { result.failed = true; continue }
            do {
                let url = URL(fileURLWithPath: path)
                let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
                guard values.isRegularFile == true, values.isSymbolicLink != true else {
                    result.failed = true; continue
                }
                try FileManager.default.removeItem(at: url)
                result.documents.removeAll { $0.id == item.id }
            } catch let error as NSError where error.domain == NSCocoaErrorDomain &&
                (error.code == NSFileNoSuchFileError || error.code == NSFileReadNoSuchFileError) {
                result.documents.removeAll { $0.id == item.id }
            } catch { result.failed = true }
        }
        return result
    }
}
