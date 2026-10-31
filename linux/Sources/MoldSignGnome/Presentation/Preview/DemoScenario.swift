#if MOLDSIGN_DEMO
import Foundation

/// Explicit debug-only UI states. No scenario performs signing, network requests or PIN verification.
enum DemoScenario: String, CaseIterable {
    case documents
    case signing
    case pin
    case pinError = "pin-error"
    case success
    case signingError = "signing-error"
    case verifyChecking = "verify-checking"
    case verifyValid = "verify-valid"
    case verifyInvalid = "verify-invalid"
    case verifyUnknown = "verify-unknown"
    case verifyUnsigned = "verify-unsigned"
    case activity
    case settings

    static var current: DemoScenario? {
        guard let value = ProcessInfo.processInfo.environment["MSIGN_DEMO_SCENARIO"] else { return nil }
        guard let scenario = Self(rawValue: value) else {
            fatalError("Unknown debug scenario; refusing to fall back to hardware mode")
        }
        return scenario
    }

    var page: String {
        if rawValue.hasPrefix("verify-") { return "verify" }
        return self == .activity ? "activity" : "sign"
    }

    func report() -> SignatureReport {
        var report = SignatureReport()
        report.kind = "PAdES"
        report.name = DemoMode.screenshotCapture ? "Signature1" : "DemoSignature1"
        report.signer = DemoMode.screenshotCapture ? "POPESCU ION" : "POPESCU ION · DEMO"
        report.contentIntact = self != .verifyInvalid
        report.signatureValid = true
        report.chainTrusted = self != .verifyUnknown
        report.signingTime = "2026-10-30T12:00:00Z"
        report.timestampTime = "2026-10-30T12:00:02Z"
        report.level = "PAdES-B-T"
        report.summary = DemoMode.screenshotCapture ? "" : L10n.text(.ui_demo_data_cryptographic_verification_was_not_performed)
        return report
    }
}

/// Scratch documents are valid, unsigned PDFs, visibly marked DEMO. They never leave the temp folder
/// unless the user explicitly opens/copies one. The mock result must never be presented as a real signature.
final class DemoDocuments {
    let directory: URL
    let input: URL
    let result: URL
    let text: URL

    init() throws {
        let root = ProcessInfo.processInfo.environment["MSIGN_DEMO_WORK_DIR"].map { URL(fileURLWithPath: $0) }
            ?? FileManager.default.temporaryDirectory
        directory = root.appendingPathComponent("esemnbun-demo-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                                                attributes: [.posixPermissions: 0o700])
        input = directory.appendingPathComponent(DemoMode.screenshotCapture ? "Contract.pdf" : "demo-document.pdf")
        result = directory.appendingPathComponent(DemoMode.screenshotCapture ? "Contract-result.pdf" : "demo-result-UNSIGNED.pdf")
        text = directory.appendingPathComponent(DemoMode.screenshotCapture ? "Declaration.txt" : "demo-document.txt")
        let pdf = Self.pdf()
        try pdf.write(to: input)
        try pdf.write(to: result)
        try "DEMO ONLY — no real signature.\n".write(to: text, atomically: true, encoding: .utf8)
    }

    deinit { try? FileManager.default.removeItem(at: directory) }

    private static func pdf() -> Data {
        let stream = "BT /F1 18 Tf 50 760 Td (DEMO ONLY - UNSIGNED DOCUMENT) Tj ET"
        let objects = [
            "<< /Type /Catalog /Pages 2 0 R >>",
            "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
            "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
            "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
            "<< /Length \(stream.utf8.count) >>\nstream\n\(stream)\nendstream",
        ]
        var bytes = Data("%PDF-1.4\n".utf8)
        var offsets = [0]
        for (index, object) in objects.enumerated() {
            offsets.append(bytes.count)
            bytes.append(Data("\(index + 1) 0 obj\n\(object)\nendobj\n".utf8))
        }
        let xref = bytes.count
        bytes.append(Data("xref\n0 \(objects.count + 1)\n0000000000 65535 f \n".utf8))
        for offset in offsets.dropFirst() { bytes.append(Data(String(format: "%010d 00000 n \n", offset).utf8)) }
        bytes.append(Data("trailer\n<< /Size \(objects.count + 1) /Root 1 0 R >>\nstartxref\n\(xref)\n%%EOF\n".utf8))
        return bytes
    }
}
#endif
