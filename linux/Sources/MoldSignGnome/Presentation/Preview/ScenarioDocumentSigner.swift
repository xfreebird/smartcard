#if MOLDSIGN_DEMO
import Foundation
import MoldSignKit

/// Hardware-free outcomes for native UI interaction tests. Never loads a PIN or reads input bytes.
final class ScenarioDocumentSigner: DocumentSigning {
    enum Scenario: String { case success = "sign-success", mixed = "sign-mixed", fatal = "sign-fatal" }
    let scenario: Scenario
    private var files: DemoDocuments?

    static var selected: Scenario? {
        let env = ProcessInfo.processInfo.environment
        guard DemoMode.current != nil, env["MSIGN_DEMO_RUN_ID"] != nil,
              env["MSIGN_DEMO_READY_FILE"] != nil, let value = env["MSIGN_UI_TEST_SCENARIO"] else { return nil }
        guard let scenario = Scenario(rawValue: value) else { preconditionFailure("Unknown UI signing scenario") }
        return scenario
    }
    init(_ scenario: Scenario) { self.scenario = scenario }

    func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String,
              progress: @escaping (SigningService.Step) -> Void) throws -> URL {
        progress(.signing)
        if item.url.pathExtension == "pdf" {
            if scenario == .mixed { throw CardError.signFailed("Mock document failure") }
            if scenario == .fatal { throw CardError.pinBlocked }
        }
        if files == nil { files = try DemoDocuments() }
        guard let files else { throw CardError.signFailed("Mock files unavailable") }
        let output = files.directory.appendingPathComponent("result-\(UUID().uuidString)-DEMO-NOT-SIGNED.pdf")
        try FileManager.default.copyItem(at: files.result, to: output)
        return output
    }
}
#endif
