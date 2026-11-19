import Foundation

struct ProtectionPreview {
    let operation: Int
    let filename: String
    let recipient: Bool

    init?(scenario: String) {
        guard scenario.hasPrefix("protect-") else { return nil }
        operation = scenario.contains("remove") ? 2 : scenario.contains("decrypt") ? 1 : 0
        recipient = scenario.contains("certificate")
        filename = operation == 1 ? (recipient ? "Contract.pdf.asymmetric.p7m" : "Contract.pdf.symmetric.p7m") : "Contract.pdf"
    }

    static var selected: ProtectionPreview? {
        #if MOLDSIGN_DEMO
        guard DemoMode.screenshotCapture,
              let scenario = ProcessInfo.processInfo.environment["MSIGN_CAPTURE_DIALOG"] else { return nil }
        return ProtectionPreview(scenario: scenario)
        #else
        return nil
        #endif
    }
}
