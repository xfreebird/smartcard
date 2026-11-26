import Foundation

extension Notification.Name {
    static let sharedDocumentsImported = Notification.Name("md.esemnbun.sharedDocumentsImported")
}

/// Moves complete share-extension deliveries into the app's own Documents folder.
/// A delivery is visible only after the extension has copied every file and written its marker.
enum SharedDocumentInbox {
    static func takeDocuments() -> [URL] {
        let fm = FileManager.default
        guard let group = fm.containerURL(forSecurityApplicationGroupIdentifier: "group.md.esemnbun.shared"),
              let documents = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return [] }
        return takeDocuments(from: group.appendingPathComponent("ShareInbox", isDirectory: true),
                             into: documents.appendingPathComponent("Shared Imports", isDirectory: true))
    }

    /// Moves every delivery folder that carries a `.ready` marker from `inbox` into `destination` and
    /// returns the files inside it. Incomplete deliveries stay where they are for a later launch.
    static func takeDocuments(from inbox: URL, into destination: URL, fileManager fm: FileManager = .default) -> [URL] {
        guard let deliveries = try? fm.contentsOfDirectory(at: inbox, includingPropertiesForKeys: nil) else { return [] }
        var result: [URL] = []
        for delivery in deliveries where fm.fileExists(atPath: delivery.appendingPathComponent(".ready").path) {
            let target = destination.appendingPathComponent(delivery.lastPathComponent, isDirectory: true)
            do {
                try fm.createDirectory(at: destination, withIntermediateDirectories: true)
                try fm.moveItem(at: delivery, to: target)
                let folders = try fm.contentsOfDirectory(at: target, includingPropertiesForKeys: [.isDirectoryKey])
                for folder in folders where folder.lastPathComponent != ".ready" {
                    result.append(contentsOf: (try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? [])
                }
                try? fm.removeItem(at: target.appendingPathComponent(".ready"))
            } catch { continue }
        }
        return result
    }
}
