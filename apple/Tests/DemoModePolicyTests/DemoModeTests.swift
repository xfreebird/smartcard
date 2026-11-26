import XCTest
import PDFKit
@testable import DemoModePolicy

final class DemoModeTests: XCTestCase {
    func testDemoRejectsAllHardwareAccessUntilExplicitReturnToLive() {
        let gate = DemoHardwareGate(demo: true)
        XCTAssertFalse(gate.begin())
        XCTAssertTrue(gate.changeMode(demo: false))
        XCTAssertTrue(gate.begin())
        gate.end()
        XCTAssertFalse(gate.isBusy)
    }

    func testConnectedLiveOperationPreventsEnteringDemo() {
        let gate = DemoHardwareGate(demo: false)
        XCTAssertTrue(gate.begin())
        XCTAssertFalse(gate.changeMode(demo: true))
        gate.end()
        XCTAssertTrue(gate.changeMode(demo: true))
        XCTAssertFalse(gate.begin())
    }

    func testSampleOutputIsNewUnsignedWatermarkedPDFAndDoesNotUseInputs() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let files = DemoDocumentFiles(directory: root, notice: "DEMO - not a valid signature")
        let inputs = try files.inputs()
        let original = try inputs.map { try Data(contentsOf: $0) }
        let first = try files.output()
        let second = try files.output()
        XCTAssertNotEqual(first, second)
        XCTAssertFalse(inputs.contains(first))
        let pdf = String(decoding: try Data(contentsOf: first), as: UTF8.self)
        XCTAssertTrue(pdf.hasPrefix("%PDF-1.4"))
        XCTAssertTrue(pdf.contains("NOT A VALID ELECTRONIC SIGNATURE"))
        XCTAssertFalse(pdf.contains("/ByteRange"))
        XCTAssertFalse(pdf.contains("/Type /Sig"))
        let rendered = try XCTUnwrap(PDFDocument(url: first))
        XCTAssertEqual(rendered.pageCount, 1)
        XCTAssertTrue(rendered.string?.contains("NOT A VALID ELECTRONIC SIGNATURE") == true)
        XCTAssertEqual(try inputs.map { try Data(contentsOf: $0) }, original)
    }

    func testNoDemoWordingOutsideDemoMode() {
        // Real reader/NFC sessions: no banner, tray/status demo text, sample notice or simulated result.
        for capture in [false, true] {
            let live = DemoNotices(demoMode: false, screenshotCapture: capture)
            XCTAssertFalse(live.banner)
            XCTAssertFalse(live.simulatedResults)
            XCTAssertFalse(live.replacesBrowser)
        }
    }

    func testDemoModeLabelsEverySimulatedSurface() {
        let demo = DemoNotices(demoMode: true, screenshotCapture: false)
        XCTAssertEqual(demo, DemoNotices(demoMode: true, screenshotCapture: false))
        XCTAssertTrue(demo.banner)
        XCTAssertTrue(demo.simulatedResults)
        XCTAssertTrue(demo.replacesBrowser)
        // Store screenshots hide only the banner chrome; results still say they are samples.
        let capture = DemoNotices(demoMode: true, screenshotCapture: true)
        XCTAssertFalse(capture.banner)
        XCTAssertFalse(capture.replacesBrowser)
        XCTAssertTrue(capture.simulatedResults)
    }

    func testDemoSamplesStayOutsideTheUsersDocuments() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let files = DemoDocumentFiles(directory: root, notice: "Sample document")
        let produced = try files.inputs() + [try files.output()]
        for url in produced {
            XCTAssertEqual(url.deletingLastPathComponent().standardizedFileURL, root.standardizedFileURL)
        }
        XCTAssertTrue(produced.last?.lastPathComponent.hasPrefix("DEMO-result-") == true)
    }
}
