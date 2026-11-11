#if DEBUG
import Foundation
import MoldSignKit

/// Presentation-only, fictional results. Used exclusively by the isolated screenshot gate;
/// these are not evidence of cryptographic verification and never enter live preferences.
enum ScreenshotFixtures {
    static func reports(_ scenario: String) -> [Validator.Report] {
        guard !scenario.contains("unsigned") else { return [] }
        let skeleton = Data("<ds:Signature Id=\"Signature1\"><ds:SignedInfo></ds:SignedInfo></ds:Signature>".utf8)
        guard var report = Validator.validateXAdES(skeleton, referencedFiles: [:]).first else { return [] }
        report.kind = scenario.contains("incomplete") ? "XAdES" : "PAdES"
        report.name = "Signature1"
        report.signer = "Popescu Ion"
        report.contentIntact = !scenario.contains("invalid") && !scenario.contains("incomplete")
        report.signatureValid = true
        report.chainTrusted = !scenario.contains("untrusted")
        report.signingTime = "2026-11-07T10:15:00+02:00"
        report.timestampTime = "2026-11-07T10:15:03+02:00"
        report.level = report.kind == "PAdES" ? "PAdES-B-T" : "XAdES-T"
        report.missingDetachedReferences = scenario.contains("incomplete") ? ["Contract.pdf"] : []
        report.certificateDetails = ["Subject · Name": "Popescu Ion", "Subject · Country": "MD",
            "Issuer · Name": "MDQSign", "Serial number": "1298074214877499210738125554536943",
            "Public key": "RSA 4096 bits", "SHA-256 fingerprint": String(repeating: "AB", count: 32),
            "Valid from": "7 Nov 2026", "Valid until": "7 Nov 2030"]
        if scenario.contains("multiple") {
            var second = report
            second.name = "Signature2"
            second.signer = "Rusu Ana"
            second.certificateDetails["Subject · Name"] = "Rusu Ana"
            return [report, second]
        }
        return [report]
    }

    @MainActor
    static func activityRecords(_ scenario: String, in directory: URL) -> [ActivityItem] {
        let urls = ScreenshotFixtures.documents(in: directory, unavailable: scenario.contains("unavailable"), xml: scenario.contains("incomplete"))
        var records = urls.map { ActivityItem(title: $0.lastPathComponent, subtitle: L10n.text(.ui_verified), ok: true,
            fileURL: $0, signedOutput: true) }
        if scenario == "documents-protection" {
            records += ["encrypt", "decrypt"].map { operation in
                let name = operation == "encrypt" ? "Contract.pdf.symmetric.p7m" : "decrypted-Contract.pdf"
                return ActivityItem(title: name, subtitle: L10n.text(operation == "encrypt" ? .protect_encrypted : .protect_decrypted), ok: true,
                            fileURL: directory.appendingPathComponent(name), signedOutput: false, protectionOperation: operation)
            }
        }
        return records
    }

    static func documents(in directory: URL, unavailable: Bool = false, xml: Bool = false) -> [URL] {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let names = unavailable ? ["Document-indisponibil.pdf"] : xml ? ["Contract-semnat.xml"] :
            ["Contract-semnat.pdf", "Cerere-semnat.pdf", "Declaratie-cu-un-nume-lung-pentru-verificarea-aspectului-semnat.pdf"]
        return names.map { name in
            let url = directory.appendingPathComponent(name)
            if !unavailable { try? DemoDocumentFiles.pdf().write(to: url) }
            return url
        }
    }
}
#endif
