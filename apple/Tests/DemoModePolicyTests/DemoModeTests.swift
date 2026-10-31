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
}
