import SwiftUI
import UniformTypeIdentifiers
import MoldSignKit

struct SignatureSection: View {
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
            FullWidthDisclosure(captureKey: "certificate", symbol: "person.text.rectangle") { Text(L10n.text(.ui_certificate_details)).fontWeight(.medium) } content: {
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
            FullWidthDisclosure(captureKey: "technical", symbol: "slider.horizontal.3") { Text(L10n.text(.ui_technical_details)).fontWeight(.medium) } content: {
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
