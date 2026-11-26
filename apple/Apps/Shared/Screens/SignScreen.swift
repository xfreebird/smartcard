import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import QuickLook
#endif

/// Mobile signing progresses from document choice to review and PIN, with one primary action.
struct SignScreen: View {
    var onOpenDocuments: () -> Void = {}
    @Environment(AppModel.self) private var model
    @State private var importing = false
    @State private var shortcutPDFOnly = false
    @State private var activeShortcutSelection: ShortcutNavigation.PDFSelection?
    @State private var shortcutNavigation = ShortcutNavigation.shared
    @State private var dropTargeted = false
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stackExpanded = false
    @State private var batchStamp: SignItem?
    @State private var presentedSetting: MobileSettingsDestination?
    private var groupedFiles: Bool { sizeClass == .compact && model.signItems.count > 1 }
    #else
    private var groupedFiles: Bool { false }
    #endif

    var body: some View {
        Group {
            #if os(iOS)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    resultContent
                    if model.signItems.isEmpty {
                        if model.lastSigned.isEmpty { SigningCardChoice(signing: true).frame(maxWidth: .infinity) }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(L10n.text(.guided_ready)).font(.largeTitle.bold())
                            Text(L10n.text(.guided_ready_body)).font(.body).foregroundStyle(.secondary)
                        }.accessibilityIdentifier("signing.nextStep")
                        documentContent
                        SigningCardChoice(compact: true, signing: true).frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: 560).padding(24).frame(maxWidth: .infinity)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .accessibilityIdentifier("signing.compactWorkspace")
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: model.signItems.isEmpty)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 10) {
                    if model.signItems.isEmpty {
                        Button { shortcutPDFOnly = false; importing = true } label: {
                            Text(L10n.text(.guided_choose)).font(.headline).frame(maxWidth: .infinity, minHeight: 32)
                        }.buttonStyle(.borderedProminent).accessibilityIdentifier("sign.pickFiles")
                    } else {
                        Text(model.signingMethod == .reader && !model.status.canSign
                             ? model.status.title
                             : L10n.text(model.signingMethod == .nfc ? .guided_next_nfc : .guided_next_reader))
                            .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        signButton
                    }
                }.controlSize(.large).buttonBorderShape(.capsule).tint(Theme.brand)
                    .frame(maxWidth: 560).padding(.horizontal, 24).padding(.vertical, 12)
                    .frame(maxWidth: .infinity).background(Color(uiColor: .systemGroupedBackground))
            }
            #else
            ScrollView {
                VStack(spacing: 24) {
                    CardSelector(size: .large)
                    resultContent
                    documentContent
                }
                .frame(maxWidth: 680)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("signing.workspace")
            .safeAreaInset(edge: .bottom, alignment: .trailing, spacing: 0) {
                if !model.signItems.isEmpty {
                    signButton
                        .controlSize(.large)
                        .buttonBorderShape(.capsule)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                }
            }
            #endif
        }
        #if os(iOS)
        .safeAreaInset(edge: .top, spacing: 0) { if model.showsDemoNotice { DemoModeBanner() } }
        // Keep the workspace height stable on short and landscape displays.
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { presentedSetting = .details } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel(L10n.text(.card_details_title))
                .accessibilityIdentifier("sign.cardDetails")
                .disabled(model.signingCertificate == nil)
            }
        }
        .sheet(item: $presentedSetting) { MobileSettingsSheet(destination: $0) }
        #else
        .navigationTitle(L10n.text(.ui_sign))
        #endif
        .onDrop(of: [.fileURL, .pdf, .xml, .data, .item], isTargeted: $dropTargeted) { providers in
            Task { model.addFiles(await DroppedDocumentLoader.load(providers)) }
            return !providers.isEmpty
        }
        .task(id: "\(shortcutNavigation.pendingPDFSelection?.id.uuidString ?? "none")-\(importing)") {
            guard !importing else { return }
            guard shortcutNavigation.pendingPDFSelection?.purpose == .prepareSigning else { return }
            // Present after the destination is mounted, including a cold Siri launch.
            await Task.yield()
            guard !Task.isCancelled, !importing,
                  shortcutNavigation.pendingPDFSelection?.purpose == .prepareSigning else { return }
            activeShortcutSelection = shortcutNavigation.pendingPDFSelection
            shortcutPDFOnly = true
            importing = true
            shortcutNavigation.pendingPDFSelection = nil
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: shortcutPDFOnly ? [.pdf] : [.item], allowsMultipleSelection: !shortcutPDFOnly, onCompletion: { result in
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
            if case .success(let urls) = result { model.addFiles(urls) }
        }, onCancellation: {
            if let selection = activeShortcutSelection, selection.waitsForIntent {
                shortcutNavigation.finishPDFSelection(id: selection.id, result: .failure(CancellationError()))
            }
            activeShortcutSelection = nil
        })
    }

    private var shortViewport: Bool {
        #if os(iOS)
        verticalSizeClass == .compact
        #else
        false
        #endif
    }

    private var visibleFiles: [SignItem] {
        #if os(iOS)
        if groupedFiles && !stackExpanded && !model.signItems.contains(where: { $0.signingError != nil }) { return [] }
        #endif
        return model.signItems
    }

    #if os(iOS)
    private func removeFileGroup() {
        guard model.currentStep == nil else { return }
        batchStamp = nil
        model.signItems.removeAll()
        stackExpanded = false
    }

    private var fileStackHeader: some View {
        SwipeFileRow(onRemove: removeFileGroup, removeLabel: L10n.text(.batch_remove), enabled: model.currentStep == nil) {
            fileStackContent
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .background {
            RoundedRectangle(cornerRadius: 12).fill(.quaternary).padding(.horizontal, 6).offset(y: 6)
        }
        .padding(.bottom, 6)
    }

    private var fileStackContent: some View {
        HStack(spacing: 12) {
            Button { withAnimation { stackExpanded.toggle() } } label: {
                HStack(spacing: 12) {
                    Image(systemName: "doc.on.doc").font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(model.signItems.count) \(L10n.text(.batch_files))").font(.headline)
                        Text(Set(model.signItems.map(\.format)).count == 1 ? model.signItems[0].format.label : L10n.text(.batch_mixed))
                            .font(.caption).foregroundStyle(.secondary)
                        Text(L10n.text(stackExpanded ? .batch_collapse : .batch_expand)).font(.caption)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: stackExpanded ? "chevron.up" : "chevron.down").font(.caption)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text(stackExpanded ? .batch_collapse : .batch_expand))
            .accessibilityIdentifier("sign.expandBatch")
            Menu {
                Button { shortcutPDFOnly = false; importing = true } label: {
                    Label(L10n.text(.guided_add), systemImage: "plus")
                }.accessibilityIdentifier("sign.addFiles")
                Divider()
                Section(L10n.text(.batch_options)) {
                    Button(L10n.text(.batch_automatic)) {
                        for i in model.signItems.indices { model.signItems[i].format = .automatic(for: model.signItems[i].url) }
                    }
                    ForEach(SignFormat.allCases.filter { format in model.signItems.allSatisfy { SignFormat.choices(for: $0.url).contains(format) } }) { format in
                        Button(format.label) {
                            for i in model.signItems.indices { model.signItems[i].format = format }
                        }.accessibilityIdentifier("sign.format." + format.rawValue)
                    }
                }
                if let source = model.signItems.first(where: { $0.format == .padesT }) {
                    Button { batchStamp = source } label: { Label(L10n.text(.batch_stamp), systemImage: "signature") }
                }
                Divider()
                Button(L10n.text(.batch_remove), role: .destructive, action: removeFileGroup)
            } label: {
                #if os(iOS)
                Image(systemName: "ellipsis").nativeButtonIconFrame()
                #else
                Image(systemName: "ellipsis.circle").frame(width: 44, height: 44)
                #endif
            }
                #if os(iOS)
                .nativeButtonStyle(.automatic)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                #endif
                .accessibilityLabel(L10n.text(.batch_options))
                .accessibilityIdentifier("sign.batchOptions")
                .disabled(model.currentStep != nil)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.secondary.opacity(0.22)))
        .sheet(item: $batchStamp) { source in
            PDFStampEditor(url: source.url, initial: source.stamp, holder: model.signingCertificate?.holder ?? "", save: { value in
                guard model.currentStep == nil else { return }
                for index in model.signItems.indices where model.signItems[index].format == .padesT {
                    var template = value
                    if model.signItems[index].id != source.id { template?.documentSHA256 = nil }
                    model.signItems[index].stamp = template
                }
            }, requester: L10n.text(.batch_stamp))
        }
    }
    #endif

    /// Shared hierarchy for desktop and wide mobile: selected documents, then a standalone drop target.
    /// Explicit pane padding makes the divider gutter equal to the outer gutter on foldable displays.
    private var documentContent: some View {
        return VStack(alignment: .leading, spacing: shortViewport ? 8 : 16) {
            if !model.signItems.isEmpty {
                #if os(macOS)
                if !shortViewport { Text(L10n.text(.ui_documents)).font(.headline).foregroundStyle(.secondary) }
                #endif
                #if os(iOS)
                if groupedFiles { fileStackHeader }
                #endif
                VStack(spacing: 8) {
                    ForEach(visibleFiles) { item in
                        #if os(iOS)
                        SwipeFileRow(onRemove: { if model.currentStep == nil { model.remove(item) } }) {
                            DocumentRow(item: item, onAddDocument: { shortcutPDFOnly = false; importing = true }).padding(12)
                        }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary.opacity(0.22), lineWidth: 1))
                        #else
                        DocumentRow(item: item).padding(12)
                            .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.secondary.opacity(0.22), lineWidth: 1))
                        #endif
                    }
                }
            }
            #if os(macOS)
            DropZone(compact: !model.signItems.isEmpty || shortViewport, short: shortViewport, targeted: dropTargeted) { shortcutPDFOnly = false; importing = true }
            #endif
            #if os(macOS)
            if !model.signItems.isEmpty {
                Text(L10n.text(.ui_pades_signs_inside_the_pdf_xades_creates_a_separate_xml_file_sha_256_algorithm))
                    .font(.caption).foregroundStyle(.secondary)
            }
            #endif
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var resultContent: some View {
        if let step = model.currentStep { StepProgressView(current: step).frame(maxWidth: .infinity) }
        if let error = model.lastError, !model.signItems.contains(where: { $0.signingError == error.message }) {
            Label {
                VStack(alignment: .leading) {
                    Text(error.message).fontWeight(.semibold)
                    if !error.recovery.isEmpty { Text(error.recovery).font(.callout).foregroundStyle(.secondary) }
                }
            } icon: { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red) }
        }
        if !model.lastSigned.isEmpty {
            #if os(iOS)
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label(L10n.text(model.demoNotices.simulatedResults ? .demo_simulation_complete : .saved_signed), systemImage: "checkmark.circle.fill")
                        .font(.headline).foregroundStyle(.green)
                    Spacer(minLength: 8)
                    Button { model.lastSigned = [] } label: {
                        #if os(iOS)
                        Image(systemName: "xmark").nativeButtonIconFrame()
                        #else
                        Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(.secondary).frame(width: 44, height: 44)
                        #endif
                    }
                        #if os(iOS)
                        .nativeButtonStyle()
                        .buttonBorderShape(.circle)
                        .controlSize(.large)
                        #endif
                        .accessibilityLabel(L10n.text(.results_clear))
                        .accessibilityIdentifier("sign.clearResults")
                        .disabled(model.currentStep != nil)
                }
                ForEach(model.lastSigned, id: \.self) { url in
                    SignedRow(url: url)
                        .padding(12)
                        .background(.background, in: RoundedRectangle(cornerRadius: 12))
                }
                if model.demoNotices.simulatedResults { Text(L10n.text(.demo_output_notice)).font(.caption).foregroundStyle(.secondary) }
                Text(L10n.text(.results_hint)).font(.footnote).foregroundStyle(.secondary)
                Button(action: onOpenDocuments) {
                    Label(L10n.text(.results_documents), systemImage: "folder")
                        .frame(maxWidth: .infinity, minHeight: 32)
                }.nativeButtonStyle()
            }
            .padding(16)
            .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.green.opacity(0.18)))
            #else
            if model.demoNotices.simulatedResults { Text(L10n.text(.demo_output_notice)).font(.callout).foregroundStyle(.secondary) }
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text(model.demoNotices.simulatedResults ? .demo_simulation_complete : .saved_signed)).font(.headline)
                ForEach(model.lastSigned, id: \.self) { url in SignedRow(url: url) }
            }
            #endif
        }
    }

    private var canSign: Bool { model.canSignDocuments }

    private var signActionTitle: String {
        model.signItems.count > 1 ? L10n.text(.ui_sign_count_documents, model.signItems.count) : L10n.text(.ui_sign)
    }

    @ViewBuilder private var signButton: some View {
        let button = Button { Task { await model.signAll() } } label: {
            #if os(iOS)
            Label(L10n.text(.guided_continue), systemImage: "arrow.right")
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, minHeight: 32)
            #else
            Label(signActionTitle, systemImage: "signature")
                .labelStyle(.titleAndIcon)
                .frame(minWidth: 120, minHeight: 32)
            #endif
        }
        // One native style owns enabled, pressed and disabled rendering on each platform.
        styled(button.nativeButtonStyle(.prominent))
    }

    private func styled(_ button: some View) -> some View {
        button.accessibilityIdentifier("sign.submit")
            #if os(iOS)
            .accessibilityLabel(L10n.text(.guided_continue))
            .accessibilityValue(signActionTitle)
            #else
            .accessibilityLabel(signActionTitle)
            #endif
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(!canSign)
            .help(Text(L10n.text(.ui_sign_the_documents_with_the_selected_card)))
    }
}
