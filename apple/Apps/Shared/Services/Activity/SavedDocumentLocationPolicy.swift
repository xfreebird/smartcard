import Foundation

/// App-owned iOS Documents locations survive container UUID changes. This policy only
/// constructs locations inside the current Documents root; it never grants file access.
enum SavedDocumentLocationPolicy {
    static func stored(_ item: ActivityItem, documents: URL) -> ActivityItem {
        var result = item
        if let relative = relativePath(for: item.fileURL, documents: documents) {
            result.documentRelativePath = relative
            result.fileURL = nil
        }
        return result
    }

    static func restored(_ item: ActivityItem, documents: URL) -> ActivityItem {
        var result = item
        if let relative = item.documentRelativePath {
            result.fileURL = safeComponents(relative).map { parts in
                parts.reduce(documents) { $0.appendingPathComponent($1) }
            }
        } else if let relative = relativePath(for: item.fileURL, documents: documents) {
            result.documentRelativePath = relative
            result.fileURL = safeComponents(relative)!.reduce(documents) { $0.appendingPathComponent($1) }
        }
        return result
    }

    private static func safeComponents(_ path: String) -> [String]? {
        let parts = path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard !path.isEmpty, !path.contains("\0"), !path.contains("\\"), !path.contains(":"),
              parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }) else { return nil }
        return parts
    }

    private static func relativePath(for url: URL?, documents: URL) -> String? {
        guard let url, url.isFileURL, url.host == nil || url.host == "" || url.host == "localhost" else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard !parts.contains(".."), !parts.contains(".") else { return nil }
        let current = documents.pathComponents.filter { $0 != "/" }
        var prefixCount: Int?
        if parts.starts(with: current) { prefixCount = current.count }
        else {
            // Physical iOS app data containers, including the /private spelling.
            let devicePrefixes = [["var", "mobile", "Containers", "Data", "Application"],
                                  ["private", "var", "mobile", "Containers", "Data", "Application"]]
            for prefix in devicePrefixes where parts.starts(with: prefix) {
                let index = prefix.count
                if parts.count > index + 1, UUID(uuidString: parts[index]) != nil, parts[index + 1] == "Documents" {
                    prefixCount = index + 2
                }
            }
            // Simulator data containers have both a device UUID and an application UUID.
            if parts.count > 12, parts[0] == "Users",
               Array(parts[2...5]) == ["Library", "Developer", "CoreSimulator", "Devices"],
               UUID(uuidString: parts[6]) != nil,
               Array(parts[7...10]) == ["data", "Containers", "Data", "Application"],
               UUID(uuidString: parts[11]) != nil, parts[12] == "Documents" {
                prefixCount = 13
            }
        }
        guard let count = prefixCount, parts.count > count else { return nil }
        let relative = parts.dropFirst(count).joined(separator: "/")
        return safeComponents(relative) == nil ? nil : relative
    }
}
