import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome

/// The automation spool shared with esemnbun-mcp: a request file is never consent, every outcome is written once.
final class AgentBrokerTests: GnomeTestCase {
    private var harness: ControllerHarness!
    private var spool: URL { AgentApprovalBroker.directory }

    override func setUp() {
        super.setUp()
        L10n.language = "en"
        try? FileManager.default.removeItem(at: spool)
        var settings = TestSettings.defaults
        settings.agentApprovalEnabled = true
        harness = ControllerHarness(cards: 1, settings: settings, transport: { _ in throw CardError.wrongPIN(remaining: 1) })
    }

    override func tearDown() {
        harness.controller.shutdown()
        harness = nil
        L10n.language = nil
        try? FileManager.default.removeItem(at: spool)
    }

    private func write(_ name: String, _ object: [String: Any], folder: String = "requests", modified: Date? = nil) throws {
        let url = spool.appendingPathComponent(folder).appendingPathComponent(name)
        XCTAssertTrue(FileManager.default.createFile(atPath: url.path, contents: try JSONSerialization.data(withJSONObject: object),
                                                     attributes: [.posixPermissions: 0o600]))
        if let modified { try FileManager.default.setAttributes([.modificationDate: modified], ofItemAtPath: url.path) }
    }

    private func request(_ id: String, name: String = "agent.pdf", modified: Date? = nil) throws {
        try write(id + ".json", ["schemaVersion": 1, "operation": "prepare", "jobId": id, "name": name,
                                 "pdf": Data("%PDF-1.7\nfixture".utf8).base64EncodedString()], modified: modified)
    }

    private func response(_ id: String) -> [String: Any]? {
        guard let data = try? Data(contentsOf: spool.appendingPathComponent("responses/\(id).json")) else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    private func waitFor(_ id: String, state: String, timeout: Double = 5) -> [String: Any]? {
        GTKTest.pump(until: { self.response(id)?["state"] as? String == state }, timeout: timeout)
        return response(id)
    }

    func testApprovedRequestGoesThroughPreviewApprovalPINAndReportsTheCardOutcome() throws {
        let id = UUID().uuidString
        try request(id)
        XCTAssertNotNil(waitFor(id, state: "awaiting_user"))
        XCTAssertTrue(GTKTest.pump(until: { self.harness.stamps.count == 1 }))
        XCTAssertTrue(FileManager.default.fileExists(atPath: spool.appendingPathComponent("staging/\(id).pdf").path))
        harness.stamps[0].answer(.proceed(nil))
        XCTAssertEqual(harness.approvals.count, 1)
        harness.approvals[0].answer(true)
        XCTAssertTrue(GTKTest.pump(until: { self.harness.pinRequests.count == 1 }))
        harness.pinRequests[0].answer(PinEntry(pin: "1234", remember: false))
        let result = try XCTUnwrap(waitFor(id, state: "failed"))
        XCTAssertEqual(result["errorCode"] as? String, "PIN_INCORRECT")
        XCTAssertNotNil(result["inputSHA256"])
        XCTAssertFalse(FileManager.default.fileExists(atPath: spool.appendingPathComponent("staging/\(id).pdf").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: spool.appendingPathComponent("requests/\(id).json").path))
    }

    func testDeclinedPreviewIsReportedAsUserCancelled() throws {
        let id = UUID().uuidString
        try request(id)
        XCTAssertTrue(GTKTest.pump(until: { self.harness.stamps.count == 1 }))
        harness.stamps[0].answer(.cancel)
        XCTAssertEqual(waitFor(id, state: "cancelled")?["errorCode"] as? String, "USER_CANCELLED")
    }

    func testCancelFileStopsAPendingRequest() throws {
        let id = UUID().uuidString
        try request(id)
        XCTAssertTrue(GTKTest.pump(until: { self.harness.stamps.count == 1 }))
        try write(id + "-cancel.json", ["operation": "cancel", "jobId": id])
        XCTAssertTrue(GTKTest.pump(until: { self.harness.stampCancelled == 1 }, timeout: 4), "The preview closes on cancel")
        harness.stamps[0].answer(.cancel)
        XCTAssertEqual(waitFor(id, state: "cancelled")?["state"] as? String, "cancelled")
    }

    func testExpiredInvalidReplayedAndForeignFilesNeverPrompt() throws {
        let expired = UUID().uuidString, invalid = UUID().uuidString, replay = UUID().uuidString, cancelled = UUID().uuidString
        harness.controller.setAgentApprovalEnabled(false)
        try request(expired, modified: Date().addingTimeInterval(-600))
        try write(invalid + ".json", ["schemaVersion": 1, "operation": "sign", "jobId": invalid])
        try request(replay)
        try write(replay + ".json", ["state": "completed"], folder: "responses")
        try request(cancelled)
        try write(cancelled + "-cancel.json", ["operation": "cancel", "jobId": cancelled])
        try write("notes.txt", ["x": 1])
        try write("stale.json", ["x": 1], folder: "outputs", modified: Date().addingTimeInterval(-3 * 86_400))
        harness.controller.setAgentApprovalEnabled(true)
        XCTAssertEqual(waitFor(expired, state: "expired")?["errorCode"] as? String, "EXPIRED")
        XCTAssertEqual(waitFor(invalid, state: "failed")?["errorCode"] as? String, "SIGNING_FAILED")
        XCTAssertEqual(waitFor(cancelled, state: "cancelled")?["errorCode"] as? String, "USER_CANCELLED")
        XCTAssertEqual(response(replay)?["state"] as? String, "completed", "An existing outcome is never replaced")
        XCTAssertTrue(GTKTest.pump(until: { !FileManager.default.fileExists(atPath: self.spool.appendingPathComponent("requests/\(replay).json").path) }))
        XCTAssertTrue(harness.stamps.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: spool.appendingPathComponent("requests/notes.txt").path))
    }

    func testDisablingApprovalCancelsTheOpenPreview() throws {
        let id = UUID().uuidString
        try request(id)
        XCTAssertTrue(GTKTest.pump(until: { self.harness.stamps.count == 1 }))
        harness.controller.setAgentApprovalEnabled(false)
        XCTAssertTrue(GTKTest.pump(until: { self.harness.stampCancelled == 1 }, timeout: 4))
        harness.stamps[0].answer(.proceed(nil))
        XCTAssertEqual(waitFor(id, state: "cancelled")?["errorCode"] as? String, "USER_CANCELLED")
    }
}
