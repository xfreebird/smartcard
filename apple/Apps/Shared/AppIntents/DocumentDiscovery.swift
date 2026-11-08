import AppIntents
import CoreSpotlight
import UniformTypeIdentifiers
import SwiftUI

/// Only app-owned, readable signed outputs participate. A history URL never grants access.
@MainActor
enum DocumentDiscovery {
    static let domain = "md.esemnbun.signed-documents"
    static let activityType = "md.esemnbun.documents"
    static var selectedID: UUID? {
        get { ShortcutNavigation.shared.selectedDocumentID }
        set { ShortcutNavigation.shared.selectedDocumentID = newValue }
    }
    static var enabled: Bool { AppPreferencesStore.defaults.bool(forKey: "documentDiscoveryEnabled") }

    static func documents() -> [ActivityItem] {
        guard enabled, let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return [] }
        #if os(macOS) && !APP_STORE
        // Standalone macOS Documents is the user's folder, not the app container.
        let ownedRoot = root.appendingPathComponent("eSemnBun Imports", isDirectory: true)
        #else
        let ownedRoot = root
        #endif
        let prefix = ownedRoot.resolvingSymlinksInPath().path + "/"
        return PreferencesActivityStore(defaults: AppPreferencesStore.defaults).loadOrMigrateDocuments().filter {
            guard let url = $0.fileURL, $0.isSignedDocument, url.isFileURL,
                  url.resolvingSymlinksInPath().path.hasPrefix(prefix),
                  ["pdf", "xml"].contains(url.pathExtension.lowercased()),
                  (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { return false }
            return FileManager.default.isReadableFile(atPath: url.path)
        }
    }

    /// Serialize delete/reindex so disabling wins over an in-flight refresh.
    private static var indexing: Task<Void, Never>?
    static func refresh() {
        let previous = indexing
        indexing = Task { @MainActor in
            await previous?.value
            let index = CSSearchableIndex.default()
            do {
                try await index.deleteSearchableItems(withDomainIdentifiers: [domain])
                let items = documents().map { item in
                    let attributes = CSSearchableItemAttributeSet(contentType: UTType(filenameExtension: item.fileURL!.pathExtension) ?? .data)
                    attributes.title = item.fileURL!.lastPathComponent
                    attributes.contentCreationDate = item.date
                    if #available(iOS 18.0, macOS 15.0, *), let id = try? FileEntityIdentifier.file(url: item.fileURL!) {
                        attributes.associateAppEntity(SignedDocumentEntity(id: id, creationDate: item.date,
                            fileModificationDate: nil, filename: item.fileURL!.lastPathComponent))
                    }
                    // No contents, URLs, certificate fields, IDNP or PIN are indexed.
                    return CSSearchableItem(uniqueIdentifier: item.id.uuidString, domainIdentifier: domain, attributeSet: attributes)
                }
                if !items.isEmpty { try await index.indexSearchableItems(items) }
            } catch { /* A later activation retries; discovery is not a signing dependency. */ }
        }
    }
    static func resume(_ activity: NSUserActivity) {
        if activity.activityType == CSSearchableItemActionType,
           let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
           let uuid = UUID(uuidString: id), documents().contains(where: { $0.id == uuid }) {
            selectedID = uuid
            ShortcutNavigation.shared.openDocuments()
        } else if activity.activityType == activityType {
            // Navigation only: never restore a document, certificate, PIN or pending signature.
            ShortcutNavigation.shared.openDocuments()
        }
    }
}

struct DocumentDiscoverySettings: View {
    @AppStorage("documentDiscoveryEnabled", store: AppPreferencesStore.defaults) private var enabled = false
    var body: some View {
        Toggle(L10n.text(.discovery_enable), isOn: $enabled)
        Text(L10n.text(.discovery_explanation))
            .font(.caption).foregroundStyle(.secondary)
            .onChange(of: enabled) { _, _ in DocumentDiscovery.refresh() }
    }
}

@available(iOS 18.0, macOS 15.0, *)
@AppEntity(schema: .files.file)
struct SignedDocumentEntity: FileEntity, IndexedEntity {
    static let defaultQuery = SignedDocumentQuery()
    static var supportedContentTypes: [UTType] { [.pdf, .xml] }
    let id: FileEntityIdentifier
    var creationDate: Date?
    var fileModificationDate: Date?
    var filename: String
    init(id: FileEntityIdentifier, creationDate: Date?, fileModificationDate: Date?, filename: String) {
        self.id = id
        self.filename = filename
        self.creationDate = creationDate
        self.fileModificationDate = fileModificationDate
    }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(filename)") }
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(contentType: UTType(filenameExtension: URL(fileURLWithPath: filename).pathExtension) ?? .data)
        attributes.title = filename
        attributes.contentCreationDate = creationDate
        return attributes
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct SignedDocumentQuery: EntityStringQuery {
    @MainActor private func available() -> [SignedDocumentEntity] {
        DocumentDiscovery.documents().compactMap { item -> SignedDocumentEntity? in
            guard let url = item.fileURL, let id = try? FileEntityIdentifier.file(url: url) else { return nil }
            return SignedDocumentEntity(id: id, creationDate: item.date,
                fileModificationDate: try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                filename: url.lastPathComponent)
        }
    }
    func entities(for identifiers: [FileEntityIdentifier]) async throws -> [SignedDocumentEntity] {
        await available().filter { identifiers.contains($0.id) }
    }
    func entities(matching string: String) async throws -> [SignedDocumentEntity] {
        await available().filter { $0.filename.localizedCaseInsensitiveContains(string) }
    }
    func suggestedEntities() async throws -> [SignedDocumentEntity] { await available() }
}

#if compiler(>=6.4)
@available(iOS 27.0, macOS 27.0, *)
@AppIntent(schema: .system.open)
#else
@available(iOS 18.0, macOS 15.0, *)
@AppIntent(schema: .files.openFile)
#endif
struct OpenSignedDocumentIntent: OpenIntent {
    #if compiler(<6.4)
    @available(iOS 26.0, macOS 26.0, *)
    #endif
    static var supportedModes: IntentModes { .foreground }
    static var openAppWhenRun = true
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication
    @Parameter(title: LocalizedStringResource("shortcut_document", defaultValue: "Document")) var target: SignedDocumentEntity
    @MainActor
    func perform() async throws -> some IntentResult {
        guard let item = DocumentDiscovery.documents().first(where: { item in
            guard let url = item.fileURL else { return false }
            return (try? FileEntityIdentifier.file(url: url)) == target.id
        }) else { throw CocoaError(.fileReadNoSuchFile) }
        ShortcutNavigation.shared.documentSearch = ""
        DocumentDiscovery.selectedID = item.id
        ShortcutNavigation.shared.openDocuments()
        return .result()
    }
}

/// Row-level context identifies the document only; no document content is transferred.
struct SignedDocumentAnnotation: ViewModifier {
    let item: ActivityItem
    @AppStorage("documentDiscoveryEnabled", store: AppPreferencesStore.defaults) private var enabled = false
    func body(content: Content) -> some View {
        if #available(iOS 18.4, macOS 15.4, *), enabled,
           DocumentDiscovery.documents().contains(where: { $0.id == item.id }),
           let url = item.fileURL, let id = try? FileEntityIdentifier.file(url: url) {
            content.appEntityIdentifier(EntityIdentifier(for: SignedDocumentEntity.self, identifier: id))
        } else { content }
    }
}

// Xcode 27 SDK adds these schema names; earlier toolchains keep the custom/file intents.
#if compiler(>=6.4)
@available(iOS 27.0, macOS 27.0, *)
@AppIntent(schema: .system.searchInApp)
struct SearchSignedDocumentsIntent: ShowInAppSearchResultsIntent {
    static var searchScopes: [StringSearchScope] = [.general]
    static var supportedModes: IntentModes { .foreground }
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresLocalDeviceAuthentication
    @Parameter(title: LocalizedStringResource("discovery_search", defaultValue: "Search documents"))
    var criteria: StringSearchCriteria

    @MainActor
    func perform() async throws -> some IntentResult {
        guard DocumentDiscovery.enabled else { throw CocoaError(.userCancelled) }
        ShortcutNavigation.shared.documentSearch = criteria.term
        ShortcutNavigation.shared.documentSearchGeneration = UUID()
        ShortcutNavigation.shared.selectedDocumentID = nil
        ShortcutNavigation.shared.openDocuments()
        return .result()
    }
}

#endif
