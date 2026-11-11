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
        if DemoMode.screenshotCapture {
            report.certificateDetails = [
                "Subject · Name": "POPESCU ION", "Issuer · Name": "Autoritate de test",
                "Serial number": "01", "Public key": "RSA 4096 bits",
                "Valid from": "01.01.2025", "Valid until": "01.01.2030",
            ]
        }
        return report
    }
}

#endif
