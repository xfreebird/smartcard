import SwiftUI
import UniformTypeIdentifiers
import MoldSignKit

/// "Verifică": choose or drop a signed file → verdict + one section per signature (UX-03/UX-04).
struct VerifyScreen: View {
    @Environment(AppModel.self) private var model
    @State private var importing = false
    @State private var shortcutPDFOnly = false
    @State private var activeShortcutSelection: ShortcutNavigation.PDFSelection?
    @State private var shortcutNavigation = ShortcutNavigation.shared
    @State private var dropTargeted = false
    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif
    private var shortViewport: Bool {
        #if os(iOS)
        verticalSizeClass == .compact
        #else
        false
        #endif
    }
    private var compactChooser: Bool {
        #if os(iOS)
        verticalSizeClass == .compact || !model.verifiedDocuments.isEmpty
        #else
        !model.verifiedDocuments.isEmpty
        #endif
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: shortViewport ? 12 : 24) {
                DropZone(verification: true, compact: compactChooser, short: compactChooser, targeted: dropTargeted) { shortcutPDFOnly = false; importing = true }
                    .accessibilityIdentifier("verify.dropZone")
                if let file = model.verifyFile, model.verifyReports == nil {
                    ProgressView(L10n.text(.ui_verifying) + " · " + file.lastPathComponent)
                }
                if !shortViewport && (!model.verifiedDocuments.isEmpty || model.verifyFile != nil) {
                    Button(L10n.text(.ui_clear_results), role: .destructive) { model.clearVerification() }
                        .accessibilityIdentifier("verify.clearResults")
                }
                ForEach(model.verifiedDocuments, id: \.url) { document in
                    VerificationDocumentView(url: document.url, reports: document.reports)
                        .id(model.verificationGeneration)
                }
            }
            .frame(maxWidth: 680)
            .padding(shortViewport ? 12 : 24)
            .frame(maxWidth: .infinity)
        }
        #if os(iOS)
        .safeAreaInset(edge: .top, spacing: 0) { if model.showsDemoNotice { DemoModeBanner() } }
        #endif
        .navigationTitle(L10n.text(.ui_verify))
        .toolbar {
            if shortViewport && (!model.verifiedDocuments.isEmpty || model.verifyFile != nil) {
                ToolbarItem(placement: .primaryAction) {
                    Button(L10n.text(.ui_clear_results), role: .destructive) { model.clearVerification() }
                }
            }
        }
        .overlay {
            if dropTargeted {
                RoundedRectangle(cornerRadius: 12).strokeBorder(Color.accentColor, lineWidth: 2).padding(4).allowsHitTesting(false)
            }
        }
        .onDrop(of: [.fileURL, .pdf, .xml, .data, .item], isTargeted: $dropTargeted) { providers in
            Task {
                let urls = await DroppedDocumentLoader.load(providers)
                if !urls.isEmpty { await model.verifyFiles(urls) }
            }
            return !providers.isEmpty
        }
        .task(id: "\(shortcutNavigation.pendingPDFSelection?.id.uuidString ?? "none")-\(importing)") {
            guard !importing else { return }
            guard shortcutNavigation.pendingPDFSelection?.purpose == .verify else { return }
            // Present after the destination is mounted, including a cold Siri launch.
            await Task.yield()
            guard !Task.isCancelled, !importing,
                  shortcutNavigation.pendingPDFSelection?.purpose == .verify else { return }
            activeShortcutSelection = shortcutNavigation.pendingPDFSelection
            shortcutPDFOnly = true
            importing = true
            shortcutNavigation.pendingPDFSelection = nil
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: shortcutPDFOnly ? [.pdf] : [.pdf, .xml, .item], allowsMultipleSelection: !shortcutPDFOnly, onCompletion: { result in
            let selection = activeShortcutSelection
            activeShortcutSelection = nil
            if let selection, selection.waitsForIntent {
                let selectedURL = result.flatMap { urls -> Result<URL, Error> in
                    guard let url = urls.first else { return .failure(CancellationError()) }
                    return .success(url)
                }
                shortcutNavigation.finishPDFSelection(id: selection.id, result: selectedURL)
                return
            }
            if let selection, !shortcutNavigation.isCurrentSelection(selection.id) { return }
            if case .success(let urls) = result { Task { await model.verifyFiles(urls) } }
        }, onCancellation: {
            if let selection = activeShortcutSelection, selection.waitsForIntent {
                shortcutNavigation.finishPDFSelection(id: selection.id, result: .failure(CancellationError()))
            }
            activeShortcutSelection = nil
        })
    }
}

/// Shared current-file verification presentation for Verify and saved-document details.
struct VerificationDocumentView: View {
    let url: URL
    let reports: [Validator.Report]
    @Environment(AppModel.self) private var model
    @State private var importingOriginals = false
    @State private var companions: [URL] = []
    @State private var checkedReports: [Validator.Report]?
    @State private var checking = false
    @State private var unavailable = false
    private var displayedReports: [Validator.Report] { checking || unavailable ? [] : (checkedReports ?? reports) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            let verdict = Verdict(displayedReports)
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: verdict.symbol)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(verdict.tint)
                    .accessibilityLabel(verdict.title)
                VStack(alignment: .leading, spacing: 4) {
                    Text(url.lastPathComponent)
                        .font(.headline).textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(verdict.title).font(.subheadline.weight(.medium))
                    Text(verdict.subtitle).font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if url.pathExtension.lowercased() == "xml" {
                if !displayedReports.flatMap(\.missingDetachedReferences).isEmpty {
                    Text(displayedReports.flatMap(\.missingDetachedReferences).joined(separator: "\n"))
                        .font(.caption).textSelection(.enabled)
                }
                Button { importingOriginals = true } label: {
                    Label(L10n.text(.verify_choose_originals), systemImage: "doc.badge.plus")
                }
                .accessibilityIdentifier("verify.chooseOriginals")
                if checking { ProgressView(L10n.text(.ui_verifying)).accessibilityIdentifier("verify.originalsLoading") }
                if unavailable { Text(L10n.text(.saved_unavailable)).foregroundStyle(.secondary) }
            }
            ForEach(Array(displayedReports.enumerated()), id: \.offset) { index, report in
                FullWidthDisclosure(captureKey: "signature") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.text(.ui_author_value, report.signer)).font(.headline)
                        Text(L10n.text(.ui_signature_count, index + 1)).font(.subheadline)
                        if let idnp = report.signerIDNP { Text(L10n.text(.ui_idnp_value, idnp)) }
                        Text(Validator.readableDate(report.signingTime)).foregroundStyle(.secondary)
                    }
                } content: {
                    SignatureSection(report: report, index: index + 1)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 16))
        .fileImporter(isPresented: $importingOriginals, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result, !urls.isEmpty {
                // Start a fresh task identity even if the same originals are selected again.
                companions = urls
                selectionGeneration = UUID()
                checking = true
                unavailable = false
                checkedReports = nil
            }
        }
        .task(id: selectionGeneration) {
            guard !companions.isEmpty else { return }
            let generation = selectionGeneration
            do {
                let result = try await model.inspectDocument(url, companions: companions)
                guard !Task.isCancelled, selectionGeneration == generation else { return }
                checkedReports = result
                checking = false
            } catch {
                guard !Task.isCancelled, selectionGeneration == generation else { return }
                unavailable = true
                checking = false
            }
        }
    }
    @State private var selectionGeneration = UUID()
}

private struct FullWidthDisclosure<Title: View, Content: View>: View {
    @State private var expanded = false
    var captureKey: String? = nil
    @ViewBuilder var title: () -> Title
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { expanded.toggle() } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right").frame(width: 14).padding(.top, 3)
                    title().frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(expanded ? "Expanded" : "Collapsed")
            .accessibilityIdentifier("verify.disclosure." + (captureKey ?? "section"))
            if expanded { content().padding(.leading, 24) }
        }
        .onAppear {
            #if DEBUG
            let env = ProcessInfo.processInfo.environment
            if env["MSIGN_SCREENSHOT_CAPTURE"] == "1", env["MSIGN_QA_NO_HARDWARE"] == "1",
               env["MSIGN_DEMO_CARDS"] != nil, env["MSIGN_DEMO_PREFERENCES_SUITE"]?.hasPrefix("md.esemnbun.qa.") == true,
               let target = env["MSIGN_CAPTURE_EXPAND"], let captureKey {
                expanded = target == "all" || target == captureKey || captureKey == "signature"
            }
            #endif
        }
    }
}

private struct SignatureSection: View {
    let report: Validator.Report
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabeledContent(L10n.text(.ui_signer), value: report.signer)
            LabeledContent(L10n.text(.ui_signed_at), value: Validator.readableDate(report.signingTime))
            if let tst = report.timestampTime { LabeledContent(L10n.text(.ui_timestamp), value: Validator.readableDate(tst)) }
            LabeledContent(L10n.text(.ui_level), value: signatureLabels(report.level))
            if report.missingDetachedReferences.isEmpty {
                check(L10n.text(.ui_document_integrity), report.contentIntact)
            } else {
                Label(L10n.text(.verify_original_missing), systemImage: "questionmark.circle")
                    .foregroundStyle(Theme.warning)
                    .accessibilityIdentifier("verify.missingOriginal")
            }
            check(L10n.text(.ui_cryptographic_signature), report.signatureValid)
            check(L10n.text(.ui_trust_chain_mdqsign_mdtrustca), report.chainTrusted)
            FullWidthDisclosure(captureKey: "certificate") { Text(L10n.text(.ui_certificate_details)).fontWeight(.medium) } content: {
                ForEach(["Subject", "Issuer", "Certificate"], id: \.self) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(CertificateLabels.label(group)).font(.headline)
                        ForEach(report.certificateDetails.keys.sorted().filter { key in
                            group == "Certificate" ? !key.contains(" · ") : key.hasPrefix(group + " · ")
                        }, id: \.self) { key in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(CertificateLabels.label(key.components(separatedBy: " · ").last ?? key)).font(.caption).foregroundStyle(.secondary)
                                Text(report.certificateDetails[key] ?? "—").textSelection(.enabled)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            FullWidthDisclosure(captureKey: "technical") { Text(L10n.text(.ui_technical_details)).fontWeight(.medium) } content: {
                Text(signatureLabels(report.summary)).font(.caption.monospaced()).textSelection(.enabled)
            }
        }
    }

    private func check(_ title: String, _ ok: Bool) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .foregroundStyle(ok ? .green : .red)
        }
    }
}

struct ActivityScreen: View {
    @Environment(AppModel.self) private var model
    @State private var protecting = false
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

    var body: some View {
        VStack(spacing: 0) {
            HStack {
            Picker(L10n.text(.saved_title), selection: $history) {
                Text(L10n.text(.saved_signed)).tag(false)
                Text(L10n.text(.saved_history)).tag(true)
            }.pickerStyle(.segmented).labelsHidden()
            #if os(macOS)
            Button(role: .destructive) {
                if history { confirmClear = true }
                else { deleting = model.savedDocuments; confirmDelete = true }
            } label: {
                Label(L10n.text(history ? .ui_clear_list : .saved_delete_all), systemImage: "trash")
            }
            .labelStyle(.iconOnly)
            .accessibilityIdentifier("documents.clear")
            .disabled(history ? model.activity.isEmpty : model.savedDocuments.isEmpty)
            .help(L10n.text(history ? .ui_clear_history_documents_remain_on_disk : .saved_delete_all))
            #endif
            }.padding()
            List {
            ForEach(entries) { item in
                if !history, let url = item.fileURL {
                    Button { selectedDocument = item } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.protectionOperation == "encrypt" ? "lock.doc" : "doc.text").foregroundStyle(Color.accentColor)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(url.lastPathComponent).font(.headline)
                                    .fixedSize(horizontal: false, vertical: true)
                                HStack {
                                    if let operation = item.protectionOperation { Text(L10n.text(operation == "encrypt" ? .protect_encrypted : .protect_decrypted)) }
                                    Text(item.date, style: .date)
                                }.font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(L10n.text(.saved_details))
                    .accessibilityIdentifier("documents.openDetails")
                    .modifier(SignedDocumentAnnotation(item: item))
                    .swipeActions(allowsFullSwipe: false) {
                        Button(role: .destructive) { deleting = [item]; confirmDelete = true } label: {
                            Label(L10n.text(.saved_delete), systemImage: "trash")
                        }
                    }
                    .contextMenu {
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
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView(L10n.text(history ? .ui_no_activity_yet : .saved_empty), systemImage: "folder",
                                       description: Text(L10n.text(history ? .ui_signed_and_verified_documents_appear_here : .saved_hint)))
            }
        }
        }
        .navigationTitle(L10n.text(.saved_title))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { protecting = true } label: {
                        Label(L10n.text(.protect_title), systemImage: "lock.doc")
                    }.accessibilityIdentifier("documents.protectFiles")
                } label: { Label(L10n.text(.protect_title), systemImage: "ellipsis.circle") }
                .accessibilityIdentifier("documents.menu")
            }
        }
        .searchable(text: Binding(get: { documentNavigation.documentSearch }, set: { documentNavigation.documentSearch = $0 }),
                    prompt: L10n.text(.discovery_search))
        .onChange(of: documentNavigation.documentSearch) { _, _ in history = false }
        .onChange(of: documentNavigation.documentSearchGeneration) { _, _ in history = false }
        .sheet(isPresented: $protecting) { FileProtectionScreen().environment(model).appPreferences() }
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                if history { confirmClear = true }
                else { deleting = model.savedDocuments; confirmDelete = true }
            } label: { Label(L10n.text(history ? .ui_clear_list : .saved_delete_all), systemImage: "trash") }
                    .accessibilityIdentifier("documents.clear")
                    .disabled(history ? model.activity.isEmpty : model.savedDocuments.isEmpty)
            }
        }
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

/// "Card": the card selector + the selected card's certificate and PIN.
struct CardScreen: View {
    @Environment(AppModel.self) private var model
    @State private var copied = false
    #if os(iOS)
    @State private var settingsPresented = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    var body: some View {
        Form {
            Section {
                Group {
                    #if os(iOS)
                    if verticalSizeClass == .compact {
                        DisclosureGroup(L10n.text(.ui_card)) { CardSelector(size: .compact) }
                    } else { CardSelector(size: cardSize) }
                    #else
                    CardSelector(size: cardSize)
                    #endif
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            } footer: {
                if model.cards.count > 1 {
                    #if os(macOS)
                    Text(L10n.text(.ui_swipe_horizontally_or_use_the_arrows_to_choose_a_card_right_click_to_read_it_again))
                    #else
                    Text(L10n.text(.ui_swipe_horizontally_or_use_the_arrows_to_choose_a_card_touch_and_hold_to_read_it_again))
                    #endif
                }
            }

            if let cert = model.certificate {
                Section(L10n.text(.ui_signing_certificate)) {
                    LabeledContent(L10n.text(.ui_holder), value: cert.holder)
                    LabeledContent(L10n.text(.ui_issuer), value: cert.issuerName)
                    if let until = cert.notAfter {
                        LabeledContent(L10n.text(.ui_valid_until), value: until.formatted(date: .long, time: .omitted))
                    }
                    LabeledContent(L10n.text(.ui_serial_number), value: cert.serialDecimal)
                    LabeledContent(L10n.text(.ui_sha_1)) {
                        HStack {
                            Text(cert.sha1Hex).font(.caption.monospaced()).textSelection(.enabled)
                            Button {
                                copy(cert.sha1Hex)
                            } label: { Image(systemName: copied ? "checkmark" : "doc.on.doc") }
                                .buttonStyle(.borderless)
                                .accessibilityLabel(L10n.text(.ui_copy_sha_1))
                        }
                    }
                    if let reader = model.selectedCard?.reader { LabeledContent(L10n.text(.ui_reader), value: reader) }
                }
                Section {
                    Label(model.hasStoredPIN ? L10n.text(.ui_pin_is_saved) : L10n.text(.ui_pin_is_not_saved),
                          systemImage: model.hasStoredPIN ? "key.fill" : "key")
                    if model.hasStoredPIN {
                        Button(L10n.text(.ui_delete_the_saved_pin), role: .destructive) { model.forgetPIN() }
                    }
                } header: {
                    Text(L10n.text(.ui_pin))
                } footer: {
                    Text(L10n.text(.ui_the_saved_pin_is_unlocked_using_touch_id_face_id_or_the_device_password_and_is_linked_to))
                }
            }

            Section(L10n.text(.ui_card_problems)) {
                Label(L10n.text(.ui_if_signing_fails_repeatedly_remove_and_reinsert_the_card), systemImage: "arrow.triangle.2.circlepath")
                Label(L10n.text(.ui_the_pin_is_not_retried_automatically_after_3_incorrect_attempts_the_card_is_blocked), systemImage: "lock.shield")
                Label(L10n.text(.ui_the_pin_can_be_unblocked_at_cev), systemImage: "building.columns")
            }
            .font(.callout)
        }
        .formStyle(.grouped)
        #if os(iOS)
        .safeAreaInset(edge: .top, spacing: 0) { if model.showsDemoNotice { DemoModeBanner() } }
        #endif
        .navigationTitle(L10n.text(.ui_card))
        #if os(iOS)
        .sheet(isPresented: $settingsPresented) { MobileSettingsView().environment(model).appPreferences() }
        .onAppear {
            #if DEBUG
            if model.isScreenshotCapture, ProcessInfo.processInfo.environment["MSIGN_CAPTURE_SHEET"] == "settings" {
                settingsPresented = true
            }
            #endif
        }
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .primaryAction) {
                Button { settingsPresented = true } label: { Label(L10n.text(.ui_settings), systemImage: "gearshape") }
                    .accessibilityIdentifier("card.settings")
            }
            #endif
            ToolbarItem(placement: .primaryAction) {
                Button { model.rereadCards() } label: { Label(L10n.text(.ui_read_the_card_again), systemImage: "arrow.clockwise") }
                    .disabled(model.cards.isEmpty)
                    .help(L10n.text(.ui_read_the_cards_again_after_removing_or_changing_a_card))
            }
        }
    }

    private var cardSize: CardSelector.Size {
        #if os(macOS)
        return .large
        #else
        return verticalSizeClass == .compact ? .compact : .phone
        #endif
    }

    private func copy(_ text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
        copied = true
    }
}
