import Foundation
import UniformTypeIdentifiers

/// Files may vend either file URLs or concrete document representations on iPad.
/// Copy inside the provider callback: its temporary URL expires when the callback returns.
enum DroppedDocumentLoader {
    static func load(_ providers: [NSItemProvider]) async -> [URL] {
        var urls: [URL] = []
        for provider in providers {
            if let url = await load(provider) { urls.append(url) }
        }
        return urls
    }

    private static func copy(_ source: URL, name: String?) -> URL? {
        guard source.isFileURL else { return nil }
        let access = source.startAccessingSecurityScopedResource()
        defer { if access { source.stopAccessingSecurityScopedResource() } }
        do {
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("DroppedDocuments", isDirectory: true)
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let filename = name.map { URL(fileURLWithPath: $0).lastPathComponent } ?? source.lastPathComponent
            var destination = folder.appendingPathComponent(filename)
            if destination.pathExtension.isEmpty && !source.pathExtension.isEmpty { destination.appendPathExtension(source.pathExtension) }
            try FileManager.default.copyItem(at: source, to: destination)
            return destination
        } catch { return nil }
    }

    private static func load(_ provider: NSItemProvider) async -> URL? {
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            let url: URL? = await withCheckedContinuation { continuation in
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    let source = (item as? URL) ?? (item as? Data).flatMap { URL(dataRepresentation: $0, relativeTo: nil) }
                    continuation.resume(returning: source.flatMap { copy($0, name: provider.suggestedName) })
                }
            }
            if let url { return url }
        }
        guard let type = provider.registeredTypeIdentifiers.first(where: { identifier in
            guard let type = UTType(identifier) else { return false }
            return type.conforms(to: .data) && type != .fileURL
        }) else { return nil }
        return await withCheckedContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: type) { url, _ in
                continuation.resume(returning: url.flatMap { copy($0, name: provider.suggestedName) })
            }
        }
    }
}
