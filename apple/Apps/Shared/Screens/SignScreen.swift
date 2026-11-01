import SwiftUI
import UniformTypeIdentifiers

/// Adaptive signing workspace. Wide mobile windows keep signing controls on the left and
/// document operations on the right; compact windows retain one scrollable column.
struct SignScreen: View {
    @Environment(AppModel.self) private var model
    @State private var importing = false
    @State private var dropTargeted = false

    var body: some View {
        Group {
            #if os(iOS)
            GeometryReader { geometry in
                if geometry.size.width >= 760 {
                    HStack(alignment: .top, spacing: 0) {
                        ScrollView {
                            VStack(spacing: 24) {
                                CardSelector(size: .phone)
                                if !model.signItems.isEmpty { signButton.frame(maxWidth: .infinity, alignment: .center) }
                                resultContent
                            }
                            .padding(24)
                        }
                        .frame(width: min(440, geometry.size.width * 0.382))
                        Divider()
                        ScrollView {
                            documentContent.padding(24)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .accessibilityIdentifier("signing.wideWorkspace")
                } else {
                    Form { cardSection; documentSection; resultSections }
                        .toolbar {
                            if !model.signItems.isEmpty {
                                ToolbarItem(placement: .primaryAction) { signButton }
                            }
                        }
                        .accessibilityIdentifier("signing.compactWorkspace")
                }
            }
            #else
            ScrollView {
                VStack(spacing: 24) {
                    CardSelector(size: .large)
                    documentContent
                    resultContent
                }
                .frame(maxWidth: 680)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .toolbar {
                if !model.signItems.isEmpty {
                    ToolbarItem(placement: .primaryAction) { signButton }
                }
            }
            #endif
        }
        .formStyle(.grouped)
        #if os(iOS)
        .listSectionSpacing(16)
        #endif
        #if os(iOS)
        .safeAreaInset(edge: .top, spacing: 0) { if model.showsDemoNotice { DemoModeBanner() } }
        #endif
        .navigationTitle(L10n.text(.ui_sign))
        .dropDestination(for: URL.self) { urls, _ in
            model.addFiles(urls)
            return !urls.isEmpty
        } isTargeted: { dropTargeted = $0 }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result { model.addFiles(urls) }
        }
    }

    /// Shared hierarchy for desktop and wide mobile: selected documents, then a standalone drop target.
    /// Explicit pane padding makes the divider gutter equal to the outer gutter on foldable displays.
    private var documentContent: some View {
        return VStack(alignment: .leading, spacing: 16) {
            if !model.signItems.isEmpty {
                Text(L10n.text(.ui_documents)).font(.headline).foregroundStyle(.secondary)
                VStack(spacing: 0) {
                    ForEach(model.signItems) { item in
                        DocumentRow(item: item).padding(16)
                        if item.id != model.signItems.last?.id { Divider().padding(.horizontal, 16) }
                    }
                }
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 16))
            }
            DropZone(compact: !model.signItems.isEmpty, targeted: dropTargeted) { importing = true }
            if !model.signItems.isEmpty {
                Text(L10n.text(.ui_pades_signs_inside_the_pdf_xades_creates_a_separate_xml_file_sha_256_algorithm))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var resultContent: some View {
        if let step = model.currentStep { StepProgressView(current: step).frame(maxWidth: .infinity) }
        if let error = model.lastError {
            Label {
                VStack(alignment: .leading) {
                    Text(error.message).fontWeight(.semibold)
                    if !error.recovery.isEmpty { Text(error.recovery).font(.callout).foregroundStyle(.secondary) }
                }
            } icon: { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red) }
        }
        if !model.lastSigned.isEmpty {
            if model.demoMode { Text(L10n.text(.demo_output_notice)).font(.callout).foregroundStyle(.secondary) }
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.text(model.demoMode ? .demo_simulation_complete : .ui_signed_successfully)).font(.headline)
                ForEach(model.lastSigned, id: \.self) { url in SignedRow(url: url) }
            }
        }
    }

    private var cardSection: some View {
        Section {
            CardSelector(size: cardSize)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
        }
    }

    @ViewBuilder private var documentSection: some View {
        let items = model.signItems
        if !model.signItems.isEmpty {
            Section {
                ForEach(items) { item in DocumentRow(item: item) }
                    .onDelete { offsets in
                        // Delete from the snapshot used to construct these rows, not a queue
                        // that may have changed while a signing operation completed.
                        let removed = offsets.compactMap { items.indices.contains($0) ? items[$0] : nil }
                        for item in removed { model.remove(item) }
                    }
            } header: { Text(L10n.text(.ui_documents)) }
        }
        // An independent section keeps the last document's native bottom corners rounded.
        // Its native section inset aligns the drop area with the document card above it.
        Section {
            DropZone(compact: !model.signItems.isEmpty, targeted: dropTargeted) { importing = true }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        } header: {
            if model.signItems.isEmpty { Text(L10n.text(.ui_documents)) }
        } footer: {
            if !model.signItems.isEmpty {
                Text(L10n.text(.ui_pades_signs_inside_the_pdf_xades_creates_a_separate_xml_file_sha_256_algorithm))
            }
        }
    }

    @ViewBuilder private var resultSections: some View {
        if let step = model.currentStep {
            Section { StepProgressView(current: step).frame(maxWidth: .infinity) }
        }
        if let error = model.lastError {
            Section {
                Label {
                    VStack(alignment: .leading) {
                        Text(error.message).fontWeight(.semibold)
                        if !error.recovery.isEmpty { Text(error.recovery).font(.callout).foregroundStyle(.secondary) }
                    }
                } icon: { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red) }
            }
        }
        if !model.lastSigned.isEmpty {
            Section(L10n.text(model.demoMode ? .demo_simulation_complete : .ui_signed_successfully)) {
                if model.demoMode { Text(L10n.text(.demo_output_notice)).foregroundStyle(.secondary) }
                ForEach(model.lastSigned, id: \.self) { url in SignedRow(url: url) }
            }
        }
    }

    private var cardSize: CardSelector.Size {
        #if os(macOS)
        return .large
        #else
        return .phone
        #endif
    }

    private var canSign: Bool { model.status.canSign && !model.signItems.isEmpty && model.currentStep == nil }

    @ViewBuilder private var signButton: some View {
        let button = Button { Task { await model.signAll() } } label: {
            Label(model.signItems.count > 1 ? L10n.text(.ui_sign_count_documents, model.signItems.count) : L10n.text(.ui_sign), systemImage: "signature")
                .labelStyle(.titleAndIcon)
                #if os(iOS)
                .frame(minHeight: 32)
                #endif
        }
        if canSign { styled(button.buttonStyle(.borderedProminent)) }
        else { styled(button.buttonStyle(.bordered)) }
    }

    private func styled(_ button: some View) -> some View {
        button.controlSize(.regular)
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(!canSign)
            .help(Text(model.status.canSign ? L10n.text(.ui_sign_the_documents_with_the_selected_card) : model.status.title))
    }
}

private struct DocumentRow: View {
    // SwiftUI can keep a row alive during removal animations. Keep its display value
    // instead of a collection-index Binding that becomes invalid when signing dequeues it.
    let item: SignItem
    @Environment(AppModel.self) private var model

    private var format: Binding<SignFormat> {
        Binding(
            get: { model.signItems.first { $0.id == item.id }?.format ?? item.format },
            set: { value in
                guard let index = model.signItems.firstIndex(where: { $0.id == item.id }) else { return }
                model.signItems[index].format = value
            }
        )
    }

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            Image(systemName: item.format == .padesT ? "doc.richtext" : "doc.text")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.url.lastPathComponent).fixedSize(horizontal: false, vertical: true)
                Text(item.sizeText).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Picker(L10n.text(.ui_format), selection: format) {
                ForEach(SignFormat.choices(for: item.url)) { Text($0.label).tag($0) }
            }
            .labelsHidden()
            .fixedSize()
            .help(L10n.text(.ui_pades_signs_within_the_pdf_xades_creates_a_separate_xml_file))
            Button { model.remove(item) } label: {
                Image(systemName: "xmark.circle.fill")
                    #if os(iOS)
                    .frame(minWidth: 44, minHeight: 44)
                    #endif
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .accessibilityLabel(L10n.text(.ui_remove_document, item.url.lastPathComponent))
        }
    }
}

private struct SignedRow: View {
    let url: URL
    #if APP_STORE && os(macOS)
    @State private var exporting = false
    @State private var exportError: String?
    #endif

    var body: some View {
        HStack {
            Label(url.lastPathComponent, systemImage: "checkmark.seal.fill")
                .labelStyle(SuccessLabelStyle())
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            #if APP_STORE && os(macOS)
            Button(L10n.text(.ui_export)) { exporting = true }
                .fileExporter(isPresented: $exporting, document: SignedExport(url: url),
                              contentType: UTType(filenameExtension: url.pathExtension) ?? .data,
                              defaultFilename: url.lastPathComponent) { result in
                    if case .failure(let error) = result { exportError = error.localizedDescription }
                }
                .alert(L10n.text(.ui_export_failed), isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
                    Button(L10n.text(.ui_done)) { exportError = nil }
                } message: { Text(exportError ?? L10n.text(.ui_)) }
            #elseif os(macOS)
            Button(L10n.text(.ui_show_in_finder)) { NSWorkspace.shared.activateFileViewerSelecting([url]) }
                .buttonStyle(.borderless)
            #else
            ShareLink(item: url) { Label(L10n.text(.ui_share), systemImage: "square.and.arrow.up") }
            #endif
        }
    }
}

private struct SuccessLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.foregroundStyle(.green)
            configuration.title
        }
    }
}

#if APP_STORE && os(macOS)
private struct SignedExport: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }
    let url: URL?
    private let contents: Data?
    init(url: URL) { self.url = url; contents = nil }
    init(configuration: ReadConfiguration) throws {
        url = nil
        contents = configuration.file.regularFileContents
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        if let url { return FileWrapper(regularFileWithContents: try Data(contentsOf: url)) }
        return FileWrapper(regularFileWithContents: contents ?? Data())
    }
}
#endif
