import SwiftUI
import UniformTypeIdentifiers
import MoldSignKit

struct ActivityScreen: View {
    @Environment(AppModel.self) private var model
    @State private var protecting = false
    @State private var protectionSource: URL?
    @State private var confirmClear = false
    @State private var confirmDelete = false
    @State private var deletionFailed = false
    @State private var deleting: [ActivityItem] = []
    @State private var history = false
    @State private var selectedDocument: ActivityItem?
    @State private var documentNavigation = ShortcutNavigation.shared
    private var entries: [ActivityItem] {
        let items = history ? model.activity : model.savedDocuments
        let query = documentNavigation.documentSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty ? items : items.filter { ($0.fileURL?.lastPathComponent ?? $0.title).localizedCaseInsensitiveContains(query) }
    }

    private var protectButton: some View {
        Button { protectionSource = nil; protecting = true } label: {
            Label(L10n.text(.protect_title), systemImage: "shield")
        }.accessibilityIdentifier("documents.protectFiles")
    }

    private var clearButton: some View {
        Button(role: .destructive) {
            if history { confirmClear = true }
            else { deleting = model.savedDocuments; confirmDelete = true }
        } label: { Label(L10n.text(history ? .ui_clear_list : .saved_delete_all), systemImage: "trash") }
            .accessibilityIdentifier("documents.clear")
            .disabled(history ? model.activity.isEmpty : model.savedDocuments.isEmpty)
            .help(L10n.text(history ? .ui_clear_history_documents_remain_on_disk : .saved_delete_all))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
            Picker(L10n.text(.saved_title), selection: $history) {
                Text(L10n.text(.saved_signed)).tag(false)
                Text(L10n.text(.saved_history)).tag(true)
            }.pickerStyle(.segmented).labelsHidden()
            #if os(macOS)
            .frame(maxWidth: 260)
            #endif
            #if os(macOS)
            Spacer()
            protectButton
                .labelStyle(.titleAndIcon)
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help(L10n.text(.protect_title))
            clearButton
                .labelStyle(.iconOnly)
                .buttonStyle(.bordered)
                .controlSize(.small)
            #endif
            }.padding()
            List {
            ForEach(entries) { item in
                if !history, let url = item.fileURL {
                    Group {
                        #if os(macOS)
                        MacDocumentEntry(url: url, date: item.date, protectionOperation: item.protectionOperation) {
                            selectedDocument = item
                        }
                        #else
                        IOSDocumentEntry(url: url, date: item.date, protectionOperation: item.protectionOperation) {
                            selectedDocument = item
                        }
                        #endif
                    }
                    #if os(macOS)
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
                    #endif
                    .modifier(SignedDocumentAnnotation(item: item))
                    .swipeActions(allowsFullSwipe: false) {
                        Button(role: .destructive) { deleting = [item]; confirmDelete = true } label: {
                            Label(L10n.text(.saved_delete), systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button { protectionSource = url; protecting = true } label: {
                            Label(L10n.text(.protect_title), systemImage: "shield")
                        }
                        Button(L10n.text(.saved_delete), role: .destructive) { deleting = [item]; confirmDelete = true }
                    }
                }
                else { ActivityRowView(item: item)
                    .contextMenu {
                        #if os(macOS)
                        if let url = item.fileURL {
                            Button(L10n.text(.ui_show_in_finder)) { NSWorkspace.shared.activateFileViewerSelecting([url]) }
                        }
                        #endif
                    }
                }
            }
        }
        .accessibilityHidden(selectedDocument != nil)
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView(L10n.text(history ? .ui_no_activity_yet : .saved_empty), systemImage: "folder",
                                       description: Text(L10n.text(history ? .ui_signed_and_verified_documents_appear_here : .saved_hint)))
            }
        }
        }
        .navigationTitle(L10n.text(.saved_title))
        #if !os(macOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                protectButton
            }
        }
        #endif
        .searchable(text: Binding(get: { documentNavigation.documentSearch }, set: { documentNavigation.documentSearch = $0 }),
                    prompt: L10n.text(.discovery_search))
        #if os(macOS)
        .background(DocumentSearchWidth())
        #endif
        .onChange(of: documentNavigation.documentSearch) { _, _ in history = false }
        .onChange(of: documentNavigation.documentSearchGeneration) { _, _ in history = false }
        .sheet(isPresented: $protecting, onDismiss: { protectionSource = nil }) { FileProtectionScreen(initialURL: protectionSource).environment(model).appPreferences() }
        .sheet(item: $selectedDocument) { item in
            if let url = item.fileURL {
                SavedDocumentDetails(url: url, protectionOperation: item.protectionOperation).environment(model).appPreferences()
            }
        }
        .onAppear {
            model.pruneMissingFiles()
            DocumentDiscovery.refresh()
            if !documentNavigation.documentSearch.isEmpty { history = false }
            if let id = DocumentDiscovery.selectedID {
                selectedDocument = model.savedDocuments.first { $0.id == id }
                DocumentDiscovery.selectedID = nil
            }
            #if DEBUG
            if model.isScreenshotCapture {
                let scenario = ProcessInfo.processInfo.environment["MSIGN_DEMO_SCENARIO"] ?? ""
                protecting = scenario.hasPrefix("protect-")
                history = scenario.hasPrefix("history-")
                if scenario.hasPrefix("documents-details-") { selectedDocument = model.savedDocuments.first }
            }
            #endif
        }      // moved/deleted documents drop out of the list
        .onChange(of: documentNavigation.selectedDocumentID) { _, id in
            if let id {
                history = false
                selectedDocument = model.savedDocuments.first { $0.id == id }
                documentNavigation.selectedDocumentID = nil
            }
        }
        .onChange(of: model.savedDocuments.count) { _, _ in
            #if DEBUG
            if model.isScreenshotCapture,
               ProcessInfo.processInfo.environment["MSIGN_DEMO_SCENARIO"]?.hasPrefix("documents-details-") == true {
                selectedDocument = model.savedDocuments.first
            }
            #endif
        }
        #if !os(macOS)
        .toolbar { ToolbarItem(placement: .primaryAction) { clearButton } }
        #endif
        .confirmationDialog(L10n.text(deleting.count == 1 ? .saved_delete : .saved_delete_all), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(L10n.text(deleting.count == 1 ? .saved_delete : .saved_delete_all), role: .destructive) {
                deletionFailed = !model.deleteSavedDocuments(deleting)
                deleting = []
            }
        } message: {
            Text((deleting.count == 1 ? (deleting.first?.fileURL?.lastPathComponent ?? "") + "\n\n" : "") + L10n.text(.saved_delete_warning))
        }
        .alert(L10n.text(.saved_delete_failed), isPresented: $deletionFailed) {
            Button(L10n.text(.ui_done), role: .cancel) {}
        }
        .confirmationDialog(L10n.text(.ui_clear_the_activity_list), isPresented: $confirmClear, titleVisibility: .visible) {
            Button(L10n.text(.ui_clear_list), role: .destructive) { model.clearActivity() }
                .accessibilityIdentifier("documents.confirmClear")
            Button(L10n.text(.ui_cancel), role: .cancel) {}
                .accessibilityIdentifier("documents.cancelClear")
        } message: {
            Text(L10n.text(.ui_signed_documents_remain_on_disk_only_the_history_is_cleared))
        }
    }
}
