import SwiftUI
import UniformTypeIdentifiers

/// docs/10 §4.2 "Semnează": drop → auto format chips → one primary button.
struct SignScreen: View {
    @Environment(AppModel.self) private var model
    @State private var importing = false
    @State private var showAdvanced = false

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                Text("Semnează documente").font(.title2.weight(.semibold))

                DropZoneView(minHeight: model.signItems.isEmpty ? 160 : 72,
                             onFiles: { model.addFiles($0) },
                             onBrowse: { importing = true })

                if !model.signItems.isEmpty {
                    CardSurface(padding: Theme.Space.m) {
                        VStack(spacing: 0) {
                            ForEach($model.signItems) { $item in
                                FileRowView(item: item) { model.remove(item) }
                                    .contextMenu { formatMenu($item) }
                                if item.id != model.signItems.last?.id { Divider() }
                            }
                        }
                    }
                    DisclosureGroup("Opțiuni avansate", isExpanded: $showAdvanced) {
                        VStack(alignment: .leading, spacing: Theme.Space.s) {
                            ForEach($model.signItems) { $item in
                                Picker(item.url.lastPathComponent, selection: $item.format) {
                                    ForEach(item.url.pathExtension.lowercased() == "pdf" ? [SignFormat.padesT] : [.xadesBES, .xadesT, .xadesC]) {
                                        Text($0.label).tag($0)
                                    }
                                }
                            }
                            LabeledContent("Algoritm", value: "SHA-256")
                            LabeledContent("Salvare", value: String(localized: "Lângă original, fără suprascriere"))
                        }
                        .padding(.top, Theme.Space.s)
                    }
                }

                if let step = model.currentStep {
                    StepProgressView(current: step)
                }
                if let error = model.lastError {
                    Label("\(error.message). \(error.recovery)", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.danger)
                }
                if !model.lastSigned.isEmpty {
                    SignedResultView(urls: model.lastSigned)
                }
            }
            .padding(Theme.Space.xl)
        }
        .safeAreaInset(edge: .bottom) { footer }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result { model.addFiles(urls) }
        }
    }

    private var footer: some View {
        HStack(spacing: Theme.Space.l) {
            StatusCardView(status: model.status, compact: true)
                .frame(maxWidth: 320)
            CardPicker().fixedSize()
            Spacer()
            Button {
                Task { await model.signAll() }
            } label: {
                Text(model.signItems.count > 1 ? "Semnează \(model.signItems.count) documente" : "Semnează")
            }
            .buttonStyle(.primary)
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(!model.status.canSign || model.signItems.isEmpty || model.currentStep != nil)
        }
        .padding(.horizontal, Theme.Space.xl)
        .padding(.vertical, Theme.Space.m)
        .background(.bar)
    }

    @ViewBuilder
    private func formatMenu(_ item: Binding<SignItem>) -> some View {
        if item.wrappedValue.url.pathExtension.lowercased() != "pdf" {
            ForEach([SignFormat.xadesBES, .xadesT, .xadesC]) { format in
                Button(format.label) { item.wrappedValue.format = format }
            }
        }
    }
}

struct SignedResultView: View {
    let urls: [URL]

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                Label("Semnat cu succes", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.success)
                ForEach(urls, id: \.self) { url in
                    HStack {
                        Text(url.lastPathComponent).lineLimit(1).truncationMode(.middle)
                        Spacer()
                        #if os(macOS)
                        Button("Arată în Finder") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
                        #else
                        ShareLink(item: url) { Label("Partajează", systemImage: "square.and.arrow.up") }
                        #endif
                    }
                    .font(.subheadline)
                }
            }
        }
    }
}
