#if DEBUG
import Foundation
import MoldSignKit

/// Scripted outcomes at the signing port; input bytes, PINs and card transports are never consumed.
struct ScenarioDocumentSigner: DocumentSigning {
    enum Scenario: String { case success = "sign-success", mixed = "sign-mixed", fatal = "sign-fatal" }
    let scenario: Scenario
    let files: any DemoDocumentProviding

    static var selected: Scenario? {
        let env = ProcessInfo.processInfo.environment
        guard env["MSIGN_QA_NO_HARDWARE"] == "1", env["MSIGN_DEMO_CARDS"] != nil,
              env["MSIGN_DEMO_PREFERENCES_SUITE"]?.hasPrefix("md.esemnbun.qa.") == true,
              let value = env["MSIGN_UI_TEST_SCENARIO"] else { return nil }
        guard let scenario = Scenario(rawValue: value) else { preconditionFailure("Unknown UI signing scenario") }
        return scenario
    }

    func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String,
              progress: @escaping @Sendable (SigningService.Step) -> Void) async throws -> URL {
        progress(.signing)
        try await Task.sleep(for: .milliseconds(150))
        if item.url.pathExtension == "pdf" {
            if scenario == .mixed { throw CardError.signFailed("Mock document failure") }
            if scenario == .fatal { throw CardError.pinBlocked }
        }
        return try files.output()
    }
}
#endif
