import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome

/// Debug-only preview fixtures: deterministic scenarios, fictional cards and unsigned demo documents.
final class PreviewTests: GnomeTestCase {
    override func setUp() {
        super.setUp()
        _ = DemoMode.current   // resolve the process-wide session (none) before any scenario variable is set
        L10n.language = "en"
    }

    override func tearDown() {
        for name in ["MSIGN_DEMO_SCENARIO", "MSIGN_DEMO_WINDOW", "MSIGN_DEMO_PAGE", "MSIGN_SCREENSHOT_CAPTURE",
                     "MSIGN_DEMO_SELECTED", "MSIGN_DEMO_LANGUAGE", "MSIGN_DEMO_DARK"] { unsetenv(name) }
        L10n.language = nil
    }

    func testScenarioStatesDescribeEachScreenWithoutSigning() throws {
        let files = try DemoDocuments()
        XCTAssertTrue(FileManager.default.fileExists(atPath: files.input.path))
        XCTAssertTrue(try Data(contentsOf: files.result).starts(with: Data("%PDF-1.4".utf8)))
        XCTAssertTrue(try String(contentsOf: files.text, encoding: .utf8).contains("DEMO ONLY"))
        for scenario in DemoScenario.allCases {
            let state = DemoScenarioState(scenario: scenario, files: files)
            switch scenario {
            case .documents, .pin:
                XCTAssertEqual(state.signItems.count, 2)
                XCTAssertNil(state.lastAttemptsLeft)
            case .pinError: XCTAssertEqual(state.lastAttemptsLeft, 2)
            case .signing:
                XCTAssertTrue(state.isSigning)
                XCTAssertEqual(state.currentStep, .timestamp)
            case .signingError:
                XCTAssertNotNil(state.signItems[0].error)
                XCTAssertNotNil(state.lastError)
            case .success: XCTAssertEqual(state.lastSigned, [files.result])
            case .verifyChecking:
                XCTAssertEqual(state.verifyFile, files.input)
                XCTAssertNil(state.verifyReports)
            case .verifyValid, .verifyInvalid, .verifyUnknown:
                XCTAssertEqual(state.verifyReports?.count, 1)
                XCTAssertEqual(scenario.page, "verify")
            case .verifyUnsigned: XCTAssertEqual(state.verifyReports?.count, 0)
            case .activity:
                XCTAssertEqual(state.activity.count, 3)
                XCTAssertEqual(state.signedDocuments.count, 1)
                XCTAssertEqual(scenario.page, "activity")
            case .settings: XCTAssertTrue(state.signItems.isEmpty)
            }
        }
        XCTAssertFalse(DemoScenario.verifyInvalid.report().contentIntact)
        XCTAssertFalse(DemoScenario.verifyUnknown.report().chainTrusted)
        XCTAssertTrue(DemoScenario.verifyValid.report().signer.contains("DEMO"), "Interactive previews label the signer")
        setenv("MSIGN_SCREENSHOT_CAPTURE", "1", 1)
        XCTAssertTrue(DemoMode.screenshotCapture)
        XCTAssertEqual(DemoScenario.verifyValid.report().signer, "POPESCU ION")
        XCTAssertFalse(DemoScenario.verifyValid.report().certificateDetails.isEmpty)
        var capture: DemoDocuments? = try DemoDocuments()
        XCTAssertEqual(capture?.input.lastPathComponent, "Contract.pdf")
        let directory = try XCTUnwrap(capture?.directory)
        capture = nil
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path), "Demo documents are removed with the session")
    }

    func testScenarioSignerOnlyCopiesTheUnsignedDemoResult() throws {
        let files = try DemoDocuments()
        let pdf = SignItem(url: files.input), text = SignItem(url: files.text)
        let signer = ScenarioDocumentSigner(.success)   // owns its scratch folder: keep it while reading the output
        let output = try signer.sign(pdf, pin: "", reader: "R", certificateSHA1: "x") { _ in }
        XCTAssertTrue(output.lastPathComponent.hasSuffix("-DEMO-NOT-SIGNED.pdf"))
        XCTAssertEqual(try Data(contentsOf: output), try Data(contentsOf: files.result))
        XCTAssertThrowsError(try ScenarioDocumentSigner(.mixed).sign(pdf, pin: "", reader: "R", certificateSHA1: "x") { _ in })
        XCTAssertNoThrow(try ScenarioDocumentSigner(.mixed).sign(text, pin: "", reader: "R", certificateSHA1: "x") { _ in })
        XCTAssertThrowsError(try ScenarioDocumentSigner(.fatal).sign(pdf, pin: "", reader: "R", certificateSHA1: "x") { _ in }) {
            guard case CardError.pinBlocked = $0 else { return XCTFail("Expected a blocked PIN") }
        }
        XCTAssertNil(ScenarioDocumentSigner.selected, "Only a demo session with a run id selects a scenario signer")
    }

    func testFictionalCardsAndWindowOptions() {
        let demo = DemoMode("2")
        var results: [CardReadResult] = []
        let provider = DemoCardDataProvider(demo: demo)
        provider.read(reader: demo.snapshot.readers[0]) { results.append($0) }
        provider.read(reader: "Unknown reader") { results.append($0) }
        XCTAssertTrue(GTKTest.pump(until: { results.count == 2 }, timeout: 3))
        XCTAssertEqual(results[0].certificate?.holder, "POPESCU ION")
        XCTAssertNil(results[1].certificate)
        XCTAssertEqual(results[1].problem, demo.failure)
        XCTAssertEqual(Set(DemoMode("4").certificates.values.map(\.holder)).count, 4)
        XCTAssertNil(DemoMode.windowSize)
        setenv("MSIGN_DEMO_WINDOW", "420X760", 1)
        XCTAssertEqual(DemoMode.windowSize?.width, 420)
        XCTAssertEqual(DemoMode.windowSize?.height, 760)
        setenv("MSIGN_DEMO_WINDOW", "wide", 1)
        XCTAssertNil(DemoMode.windowSize)
        setenv("MSIGN_DEMO_PAGE", "verify", 1)
        XCTAssertEqual(DemoMode.page, "verify")
        setenv("MSIGN_DEMO_SCENARIO", "activity", 1)
        XCTAssertEqual(DemoMode.page, "activity")
        XCTAssertFalse(DemoMode.screenshotCapture)
    }

    func testProtectionPreviewNamesTheFixtureForEachOperation() {
        XCTAssertNil(ProtectionPreview(scenario: "settings"))
        XCTAssertEqual(ProtectionPreview(scenario: "protect-encrypt")?.operation, 0)
        XCTAssertEqual(ProtectionPreview(scenario: "protect-remove")?.operation, 2)
        let decrypt = ProtectionPreview(scenario: "protect-decrypt-certificate")
        XCTAssertEqual(decrypt?.operation, 1)
        XCTAssertEqual(decrypt?.recipient, true)
        XCTAssertEqual(decrypt?.filename, "Contract.pdf.asymmetric.p7m")
        XCTAssertEqual(ProtectionPreview(scenario: "protect-decrypt")?.filename, "Contract.pdf.symmetric.p7m")
        XCTAssertNil(ProtectionPreview.selected)
    }

    func testDemoControllerPreparesTheRequestedScenario() throws {
        for (scenario, check) in [
            ("pin-error", { (c: AppController, pins: [PinRequest], pages: [String], preferences: Int) in
                XCTAssertEqual(pins.first?.attemptsLeft, 2)
                XCTAssertFalse(pins.first?.canRemember ?? true)
                XCTAssertEqual(pages, ["sign"])
            }),
            ("settings", { c, pins, pages, preferences in XCTAssertEqual(preferences, 1) }),
            ("verify-valid", { c, pins, pages, preferences in
                XCTAssertEqual(c.verifyReports?.count, 1)
                XCTAssertEqual(pages, ["verify"])
            }),
        ] {
            setenv("MSIGN_DEMO_SCENARIO", scenario, 1)
            setenv("MSIGN_DEMO_SELECTED", "0", 1)
            let controller = AppController(vault: FakeVault(), monitor: FakeMonitor(), settingsStore: TestSettings(), bridge: FakeBridge(),
                                           demo: DemoMode("1"))
            var pins: [PinRequest] = [], pages: [String] = [], preferences = 0
            controller.askPIN = { request, _ in pins.append(request) }
            controller.showDemoPage = { pages.append($0) }
            controller.showDemoPreferences = { preferences += 1 }
            controller.start()
            XCTAssertTrue(GTKTest.pump(until: { controller.demoPrepared }, timeout: 3), scenario)
            check(controller, pins, pages, preferences)
            controller.shutdown()
        }
    }
}
