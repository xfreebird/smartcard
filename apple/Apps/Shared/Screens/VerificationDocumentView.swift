import SwiftUI
import UniformTypeIdentifiers
import MoldSignKit

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
