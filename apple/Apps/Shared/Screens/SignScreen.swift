import SwiftUI
import UniformTypeIdentifiers

/// docs/10 §0.2b + §4.2 "Semnează" (UX-03/UX-04/UX-10): the card selector picks the card, the list holds the documents,
/// one prominent action. Grouped form on macOS, inset-grouped list with a bottom action on iOS.
struct SignScreen: View {
    @Environment(AppModel.self) private var model
    @State private var importing = false
    @State private var dropTargeted = false

    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                CardSelector(size: cardSize)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
            } header: {
                Text("Semnezi cu")
            }

            Section {
                ForEach($model.signItems) { $item in
                    DocumentRow(item: $item)
                }
                .onDelete { offsets in
                    for index in offsets { model.remove(model.signItems[index]) }
                }
                DropZone(compact: !model.signItems.isEmpty, targeted: dropTargeted) { importing = true }
                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    .listRowBackground(Color.clear)
            } header: {
                Text("Documente")
            } footer: {
                if !model.signItems.isEmpty {
                    Text("Se salvează lângă original, ca „nume-semnat”, fără a suprascrie. PAdES semnează în PDF; XAdES creează un fișier .xml separat. Algoritm SHA-256.")
                }
            }

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
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                    }
                }
            }
            if !model.lastSigned.isEmpty {
                Section("Semnat cu succes") {
                    ForEach(model.lastSigned, id: \.self) { url in SignedRow(url: url) }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Semnează")
        .dropDestination(for: URL.self) { urls, _ in
            model.addFiles(urls)
            return !urls.isEmpty
        } isTargeted: { dropTargeted = $0 }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.item], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result { model.addFiles(urls) }
        }
        #if os(macOS)
        .toolbar {
            // only once there is something to sign: a disabled prominent button reads as broken
            if !model.signItems.isEmpty {
                ToolbarItem(placement: .primaryAction) { signButton }
            }
        }
        #else
        .safeAreaInset(edge: .bottom) {
            signButton
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
        }
        #endif
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
        let button = Button {
            Task { await model.signAll() }
        } label: {
            Label(model.signItems.count > 1 ? "Semnează \(model.signItems.count) documente" : "Semnează",
                  systemImage: "signature")
                .labelStyle(.titleAndIcon)
                #if os(iOS)
                .frame(maxWidth: .infinity)
                #endif
        }
        // prominent (accent fill) only while it can act; disabled it's a plain bordered button
        if canSign {
            styled(button.buttonStyle(.borderedProminent))
        } else {
            styled(button.buttonStyle(.bordered))
        }
    }

    private func styled(_ button: some View) -> some View {
        button
            .controlSize(.large)
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(!canSign)
            .help(Text(model.status.canSign ? "Semnează documentele cu cardul selectat (⌘↩)" : model.status.title))
    }
}

private struct DocumentRow: View {
    @Binding var item: SignItem
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            Image(systemName: item.format == .padesT ? "doc.richtext" : "doc.text")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.url.lastPathComponent).lineLimit(1).truncationMode(.middle)
                Text(item.sizeText).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Picker("Format", selection: $item.format) {
                ForEach(SignFormat.choices(for: item.url)) { Text($0.label).tag($0) }
            }
            .labelsHidden()
            .fixedSize()
            .help("PAdES semnează în PDF; XAdES creează un fișier .xml separat")
            #if os(macOS)
            Button { model.remove(item) } label: { Image(systemName: "xmark.circle.fill") }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Elimină \(item.url.lastPathComponent)")
            #endif
        }
    }
}

private struct SignedRow: View {
    let url: URL

    var body: some View {
        HStack {
            Label(url.lastPathComponent, systemImage: "checkmark.seal.fill")
                .labelStyle(SuccessLabelStyle())
                .lineLimit(1).truncationMode(.middle)
            Spacer()
            #if os(macOS)
            Button("Arată în Finder") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
                .buttonStyle(.borderless)
            #else
            ShareLink(item: url) { Label("Partajează", systemImage: "square.and.arrow.up") }
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
