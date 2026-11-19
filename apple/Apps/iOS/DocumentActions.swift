import SwiftUI
import QuickLook

/// The filename retains its normal action. Adjacent controls have independent touch targets.
struct IOSDocumentEntry: View {
    let url: URL
    var date: Date? = nil
    var protectionOperation: String? = nil
    var openDetails: (() -> Void)? = nil
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var previewURL: URL?
    @State private var showingPDF = false
    @State private var decrypting = false

    var body: some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                                                 : AnyLayout(HStackLayout(spacing: 8))
        layout {
            Button {
                if let openDetails { openDetails() } else { preview() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: protectionOperation == "encrypt" ? "lock.doc.fill" : "doc.text.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.brand)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(url.lastPathComponent)
                            .font(.subheadline.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 5) {
                            if let operation = protectionOperation {
                                Text(L10n.text(operation == "encrypt" ? .protect_encrypted : .protect_decrypted))
                            }
                            if let date { Text(date, style: .date) }
                            else { Text(L10n.text(.document_preview)) }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(L10n.text(openDetails == nil ? .document_preview : .saved_details))
            .accessibilityIdentifier(openDetails == nil ? "sign.previewResult" : "documents.openDetails")

            HStack(spacing: 0) {
                if openDetails != nil {
                    let encrypted = protectionOperation == "encrypt"
                    Button {
                        if encrypted { decrypting = true } else { preview() }
                    } label: {
                        actionIcon(encrypted ? "lock.open" : "eye")
                    }
                    .accessibilityLabel(L10n.text(encrypted ? .protect_decrypt : .document_preview))
                    Divider().frame(height: 17).accessibilityHidden(true)
                }
                ShareLink(item: url) { actionIcon("square.and.arrow.up") }
                    .accessibilityLabel(L10n.text(.ui_share))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.brand)
            .background(Theme.brandSoft, in: Capsule())
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingPDF) { PDFDocumentPreview(url: url) }
        .quickLookPreview($previewURL)
        .sheet(isPresented: $decrypting) { FileProtectionScreen(initialURL: url, operation: 1).appPreferences() }
    }

    private func actionIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.body.weight(.medium))
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }

    private func preview() {
        if url.pathExtension.lowercased() == "pdf" { showingPDF = true }
        else { previewURL = url }
    }
}

struct IOSDocumentDetailActions: View {
    let url: URL
    let protectionOperation: String?
    let preview: () -> Void
    let decrypt: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(spacing: 10) { actions(singleLine: false) }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { actions(singleLine: true) }
                    VStack(spacing: 10) { actions(singleLine: false) }
                }
            }
        }
        .font(.body.weight(.semibold))
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .tint(Theme.brand)
    }

    @ViewBuilder
    private func actions(singleLine: Bool) -> some View {
        let encrypted = protectionOperation == "encrypt"
        Button(action: encrypted ? decrypt : preview) {
            Label(L10n.text(encrypted ? .protect_decrypt : .document_preview),
                  systemImage: encrypted ? "lock.open" : "eye")
                // Measure the complete label before choosing the horizontal row.
                .fixedSize(horizontal: singleLine, vertical: true)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 24)
        }
        .accessibilityIdentifier("documents.details.primaryAction")
        .nativeButtonStyle(.prominent)
        ShareLink(item: url) {
            Label(L10n.text(.ui_share), systemImage: "square.and.arrow.up")
                .fixedSize(horizontal: singleLine, vertical: true)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 24)
        }
        .accessibilityIdentifier("documents.details.share")
        .nativeButtonStyle()
    }
}
