import SwiftUI
import UniformTypeIdentifiers
#if os(iOS)
import QuickLook
#endif

struct DocumentRow: View {
    // SwiftUI can keep a row alive during removal animations. Keep its display value
    // instead of a collection-index Binding that becomes invalid when signing dequeues it.
    let item: SignItem
    @State private var editingStamp = false
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

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    #endif

    var body: some View {
        #if os(iOS)
        if dynamicTypeSize.isAccessibilitySize { accessibilityRow }
        else if sizeClass == .compact { compactRow }
        else { standardRow }
        #else
        standardRow
        #endif
    }

    #if os(iOS)
    private var accessibilityRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.url.lastPathComponent)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .top, spacing: 12) {
                Text(item.sizeText).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                rowOptions
            }
            selectionTags
            if let error = item.signingError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .accessibilityIdentifier("sign.error." + item.url.lastPathComponent)
                    .font(.caption).foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var compactRow: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Image(systemName: item.format == .padesT ? "doc.richtext" : "doc.text")
                    .font(.body).foregroundStyle(.secondary).frame(width: 20)
                Text(item.url.lastPathComponent)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1).truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(item.sizeText).font(.caption2).foregroundStyle(.secondary).fixedSize()
                rowOptions
            }
            selectionTags.padding(.leading, 28).padding(.bottom, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let error = item.signingError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .accessibilityIdentifier("sign.error." + item.url.lastPathComponent)
                    .font(.caption).foregroundStyle(.red).padding(.leading, 28)
            }
        }
    }
    #endif

    private var standardRow: some View {
        HStack(spacing: Theme.Space.m) {
            Image(systemName: item.format == .padesT ? "doc.richtext" : "doc.text")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.url.lastPathComponent).fixedSize(horizontal: false, vertical: true)
                Text(item.sizeText).font(.caption).foregroundStyle(.secondary)
                selectionTags.padding(.top, 4).frame(maxWidth: .infinity, alignment: .leading)
                if let error = item.signingError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                    .accessibilityIdentifier("sign.error." + item.url.lastPathComponent)
                        .font(.callout).foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            rowOptions

        }
    }
    private var stampSummary: String {
        item.stamp.map { $0.allPages ? L10n.text(.file_stamp_all) : "\(L10n.text(.file_stamp_page)) \($0.page + 1)" } ?? L10n.text(.file_stamp_off)
    }
    @ViewBuilder private var selectionTags: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) { tags }
            VStack(alignment: .leading, spacing: 4) { tags }
        }
    }
    @ViewBuilder private var tags: some View {
        Label(item.format.label, systemImage: item.format == .padesT ? "doc.richtext" : "doc.badge.gearshape")
            .accessibilityIdentifier("sign.selectedFormat." + item.format.rawValue)
            .font(.caption2).foregroundStyle(Color.blue).padding(.horizontal, 6).padding(.vertical, 3).background(Color.blue.opacity(0.1), in: Capsule())
        if item.format == .padesT {
            Label(stampSummary, systemImage: "signature")
                .font(.caption2).foregroundStyle(item.stamp == nil ? Color.secondary : Color.green).padding(.horizontal, 6).padding(.vertical, 3).background((item.stamp == nil ? Color.secondary : Color.green).opacity(0.1), in: Capsule())
        }
    }
    private var rowOptions: some View {
        Menu {
            Section(L10n.text(.file_signing_type)) {
                ForEach(SignFormat.choices(for: item.url)) { choice in
                    Button { format.wrappedValue = choice } label: {
                        if choice == item.format { Label(choice.label, systemImage: "checkmark") }
                        else { Text(choice.label) }
                    }.accessibilityIdentifier("sign.format." + choice.rawValue)
                }
            }
            if item.format == .padesT {
                Button { editingStamp = true } label: {
                    Label(L10n.text(item.stamp == nil ? .stamp_add : .stamp_edit), systemImage: "signature")
                }.accessibilityIdentifier("sign.editStamp")
            }
            Divider()
            Button(L10n.text(.file_remove), role: .destructive) { model.remove(item) }
                .accessibilityIdentifier("sign.remove")
        } label: {
            #if os(iOS)
            Image(systemName: "ellipsis").nativeButtonIconFrame()
            #else
            Image(systemName: "ellipsis.circle").frame(minWidth: 44, minHeight: 44)
            #endif
        }
            #if os(macOS)
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            #else
            .nativeButtonStyle(.automatic)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            #endif
            .fixedSize()
            .accessibilityLabel(L10n.text(.file_options))
            .accessibilityIdentifier("sign.options." + item.url.lastPathComponent)
            .disabled(model.currentStep != nil)
                    #if DEBUG
                    .onAppear {
                        let env = ProcessInfo.processInfo.environment
                        if env["MSIGN_QA_STAMP_PREVIEW"] == "1", env["MSIGN_QA_NO_HARDWARE"] == "1",
                           env["MSIGN_DEMO_PREFERENCES_SUITE"]?.hasPrefix("md.esemnbun.qa.") == true,
                           model.signItems.first?.id == item.id { editingStamp = true }
                    }
                    #endif
                    .sheet(isPresented: $editingStamp) {
                        PDFStampEditor(url: item.url, initial: item.stamp, holder: model.certificate?.holder ?? "", save: { value in
                            guard let index = model.signItems.firstIndex(where: { $0.id == item.id }) else { return }
                            model.signItems[index].stamp = value
                        }, onBatch: { value in
                            for index in model.signItems.indices where model.signItems[index].format == .padesT {
                                var template = value
                                if model.signItems[index].id != item.id { template?.documentSHA256 = nil }
                                model.signItems[index].stamp = template
                            }
                        })
                    }
    }

}
