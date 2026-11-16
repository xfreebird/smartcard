import XCTest
@testable import AppBatch

final class NFCSessionDiagnosticsTests: XCTestCase {
    func testDiagnosticsRetainStatusButExcludeErrorPayloadAndDescription() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let log = NFCSessionDiagnostics(purpose: "identify", directory: folder)
        let error = NSError(domain: "NFCError", code: 102, userInfo: [NSLocalizedDescriptionKey: "PRIVATE-CARD-CONTENT",
            "payload": "PRIVATE-PIN", NSUnderlyingErrorKey: NSError(domain: "nfcd", code: 29)])
        log.record("commandResponse", instruction: 0xB0, responseBytes: 0, error: error)
        let file = try XCTUnwrap(FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil).first)
        let text = try String(contentsOf: file, encoding: .utf8)
        XCTAssertFalse(text.contains("PRIVATE"))
        XCTAssertTrue(text.contains("102"))
        XCTAssertTrue(text.contains("29"))
        XCTAssertTrue(text.contains("B0"))
    }
}
