import Foundation
import XCTest
@testable import MoldSignGnome

final class AgentSigningRequestTests: GnomeTestCase {
    private let id = UUID().uuidString
    private func packet(_ changes: [String: Any] = [:]) throws -> Data {
        var value: [String: Any] = ["schemaVersion": 1, "operation": "prepare", "jobId": id,
            "name": "contract.pdf", "pdf": Data("%PDF-1.7\nfixture".utf8).base64EncodedString()]
        value.merge(changes) { _, new in new }
        return try JSONSerialization.data(withJSONObject: value)
    }
    func testRequestFreezesExactBytesAndDisplayName() throws {
        let request = try AgentSigningRequest.decode(packet(), id: id)
        XCTAssertEqual(request.name, "contract.pdf")
        XCTAssertEqual(request.pdf, Data("%PDF-1.7\nfixture".utf8))
    }
    func testRejectsIdentityMismatchAndAuthorityFields() throws {
        for changes: [String: Any] in [["jobId": UUID().uuidString], ["pin": "fixture"],
                                       ["outputPath": "/outside"], ["schemaVersion": true], ["operation": "sign"]] {
            XCTAssertThrowsError(try AgentSigningRequest.decode(packet(changes), id: id))
        }
    }
    func testRejectsPathsControlNamesAndNonPdf() throws {
        for name in ["../contract.pdf", "folder/file.pdf", "folder\\file.pdf", "\ncontract.pdf", "", ".."] {
            XCTAssertThrowsError(try AgentSigningRequest.decode(packet(["name": name]), id: id))
        }
        XCTAssertThrowsError(try AgentSigningRequest.decode(packet(["pdf": Data("hello".utf8).base64EncodedString()]), id: id))
    }
    func testOldSettingsDefaultApprovalOff() throws {
        XCTAssertFalse(try JSONDecoder().decode(AppSettings.self, from: Data("{}".utf8)).agentApprovalEnabled)
        var settings = AppSettings(); settings.agentApprovalEnabled = true
        XCTAssertTrue(try JSONDecoder().decode(AppSettings.self, from: JSONEncoder().encode(settings)).agentApprovalEnabled)
    }
}
