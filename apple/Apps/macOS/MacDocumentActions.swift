import SwiftUI

/// Shared action strip for the document list, signing results, and document inspector.
struct MacDocumentActions: View {
    let url: URL
    var expanded = false
    var protectionOperation: String?
    var saveAs: (() -> Void)?
    var decrypt: (() -> Void)?
    @State private var previewing = false

    var body: some View {
        HStack(spacing: expanded ? 12 : 6) {
            if protectionOperation == "encrypt" {
                if let decrypt {
                    Button(action: decrypt) { Label(L10n.text(.protect_decrypt), systemImage: "lock.open") }
                        .buttonStyle(DocumentActionStyle(prominent: true))
                }
            } else {
                Button { previewing = true } label: {
                    Label(L10n.text(.document_preview), systemImage: "eye")
                }
                .buttonStyle(DocumentActionStyle(prominent: true))
                .help(L10n.text(.document_preview))
            }
            if let saveAs {
                Button(action: saveAs) { Label(L10n.text(.store_save_as), systemImage: "square.and.arrow.down") }
                    .buttonStyle(DocumentActionStyle())
            }
            if expanded { Spacer(minLength: 4) }
            Group {
                if expanded || url.pathExtension.lowercased() != "xml" {
                    ShareLink(item: url) { Label(L10n.text(.ui_share), systemImage: "square.and.arrow.up") }
                        .help(L10n.text(.ui_share))
                }
                Button { NSWorkspace.shared.activateFileViewerSelecting([url]) } label: {
                    Label(L10n.text(.ui_show_in_finder), systemImage: "folder")
                }
                .help(L10n.text(.ui_show_in_finder))
            }
            .labelStyle(DocumentActionLabelStyle(showsTitle: expanded))
            .buttonStyle(DocumentActionStyle())
        }
        .sheet(isPresented: $previewing) { NativeDocumentPreview(url: url) }
    }
}

private struct DocumentActionLabelStyle: LabelStyle {
    let showsTitle: Bool
    func makeBody(configuration: Configuration) -> some View {
        if showsTitle { Label(configuration).labelStyle(.titleAndIcon) }
        else { Label(configuration).labelStyle(.iconOnly) }
    }
}

private struct DocumentActionStyle: ButtonStyle {
    var prominent = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.medium))
            .foregroundStyle(prominent ? Color.accentColor : .primary)
            .padding(.horizontal, 9)
            .frame(minWidth: 30, minHeight: 29)
            .background((prominent ? Color.accentColor : .secondary)
                .opacity(configuration.isPressed ? 0.22 : prominent ? 0.12 : 0.08), in: Capsule())
            .contentShape(Capsule())
    }
}

struct MacDocumentEntry: View {
    let url: URL
    var date: Date?
    var protectionOperation: String?
    var saveAs: (() -> Void)?
    let open: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: open) {
                HStack(spacing: 10) {
                    Image(systemName: protectionOperation == "encrypt" ? "lock.doc" : "doc.text")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 34, height: 38)
                        .background(Color.accentColor.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(url.lastPathComponent).font(.body.weight(.semibold))
                            .lineLimit(2).truncationMode(.middle)
                        HStack(spacing: 6) {
                            if let operation = protectionOperation {
                                Text(L10n.text(operation == "encrypt" ? .protect_encrypted : .protect_decrypted))
                            } else {
                                Text(verbatim: url.pathExtension.uppercased())
                            }
                            if let date { Text(verbatim: "·"); Text(date, style: .date) }
                            else { Image(systemName: "checkmark.seal.fill").foregroundStyle(.green) }
                        }.font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(L10n.text(date == nil ? .ui_show_in_finder : .saved_details))
            .accessibilityIdentifier(date == nil ? "sign.revealResult" : "documents.openDetails")
            MacDocumentActions(url: url, protectionOperation: protectionOperation, saveAs: saveAs)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
    }
}
