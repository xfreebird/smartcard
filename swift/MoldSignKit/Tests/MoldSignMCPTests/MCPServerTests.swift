import XCTest
import Foundation
@testable import MoldSignMCP

final class MCPServerTests: XCTestCase {
    private var directory: URL!
    override func setUpWithError() throws {
        let temporary = FileManager.default.temporaryDirectory.path
        let canonical = try XCTUnwrap(realpath(temporary, nil))
        defer { free(canonical) }
        directory = URL(fileURLWithPath: String(cString: canonical)).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: directory) }
    private func request(_ server: MCPServer, method: String = "tools/call", name: String = "capabilities", arguments: [String: Any] = [:], version: String = MCPServer.protocolVersion) throws -> [String: Any] {
        var params: [String: Any] = ["_meta": ["io.modelcontextprotocol/protocolVersion": version, "io.modelcontextprotocol/clientCapabilities": [:]]]
        if method == "tools/call" { params["name"] = name; params["arguments"] = arguments }
        let bytes = try JSONSerialization.data(withJSONObject: ["jsonrpc": "2.0", "id": 7, "method": method, "params": params])
        return try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(server.handle(bytes))) as? [String: Any])
    }
    private func content(_ response: [String: Any]) throws -> [String: Any] {
        let result = try XCTUnwrap(response["result"] as? [String: Any])
        return try XCTUnwrap(result["structuredContent"] as? [String: Any])
    }
    func testModernDiscoveryAndNoUnattendedToolByDefault() throws {
        let server = MCPServer(roots: [:])
        let discovery = try request(server, method: "server/discover")
        XCTAssertEqual((discovery["result"] as? [String: Any])?["supportedVersions"] as? [String], ["2026-07-28"])
        let listing = try request(server, method: "tools/list")
        let tools = (listing["result"] as? [String: Any])?["tools"] as? [[String: Any]]
        XCTAssertFalse(try XCTUnwrap(tools).contains { $0["name"] as? String == "sign_document" })
        XCTAssertEqual((try request(server, version: "2025-11-25")["error"] as? [String: Any])?["code"] as? Int, -32022)
    }
    func testNoMetadataAndNotificationCannotExecuteTools() throws {
        let server = MCPServer(roots: [:])
        XCTAssertNil(server.handle(Data(#"{"jsonrpc":"2.0","method":"tools/call","params":{"name":"prepare_signing"}}"#.utf8)))
        let response = try XCTUnwrap(server.handle(Data(#"{"jsonrpc":"2.0","id":1,"method":"tools/list"}"#.utf8)))
        let object = try JSONSerialization.jsonObject(with: response) as! [String: Any]
        XCTAssertEqual((object["error"] as? [String: Any])?["code"] as? Int, -32602)
    }
    func testUnknownArgumentsIncludingPINRejected() throws {
        let server = MCPServer(roots: [:])
        let value = try content(request(server, arguments: ["pin": "not-a-real-secret"]))
        XCTAssertEqual(value["ok"] as? Bool, false)
        XCTAssertEqual((value["error"] as? [String: Any])?["code"] as? String, "INVALID_ARGUMENT")
        XCTAssertFalse(String(data: try JSONSerialization.data(withJSONObject: value), encoding: .utf8)!.contains("not-a-real-secret"))
    }
    func testOfflineUnsignedPDFAndTraversal() throws {
        try Data("%PDF-1.7\n%%EOF".utf8).write(to: directory.appendingPathComponent("test.pdf"))
        let root = try TrustedRoot(path: directory.path)
        let server = MCPServer(roots: ["documents": root])
        let report = try content(request(server, name: "verify_document", arguments: ["input": ["rootId": "documents", "relativePath": "test.pdf"]]))
        XCTAssertEqual((report["data"] as? [String: Any])?["status"] as? String, "no_recognized_signature")
        for path in ["../test.pdf", "/test.pdf", "folder/../test.pdf", "file:///test.pdf"] {
            XCTAssertThrowsError(try root.read(path, limit: 100))
        }
        try FileManager.default.createSymbolicLink(at: directory.appendingPathComponent("link.pdf"), withDestinationURL: directory.appendingPathComponent("test.pdf"))
        XCTAssertThrowsError(try root.read("link.pdf", limit: 100))
        XCTAssertThrowsError(try root.read("test.pdf", limit: 2))
    }
    func testDirectoryInodeRemainsPinnedAfterRename() throws {
        let nested = directory.appendingPathComponent("trusted")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: false)
        try Data("original".utf8).write(to: nested.appendingPathComponent("a.pdf"))
        let root = try TrustedRoot(path: nested.path)
        try FileManager.default.moveItem(at: nested, to: directory.appendingPathComponent("moved"))
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: false)
        try Data("replacement".utf8).write(to: nested.appendingPathComponent("a.pdf"))
        XCTAssertEqual(try root.read("a.pdf", limit: 100), Data("original".utf8))
    }
    func testXMLDTDRejectedBeforeValidation() throws {
        try Data("<!DOCTYPE a SYSTEM 'http://localhost/private'><a/>".utf8).write(to: directory.appendingPathComponent("test.xml"))
        let server = MCPServer(roots: ["docs": try TrustedRoot(path: directory.path)])
        let response = try content(request(server, name: "verify_document", arguments: ["input": ["rootId": "docs", "relativePath": "test.xml"]]))
        XCTAssertEqual((response["error"] as? [String: Any])?["code"] as? String, "UNSUPPORTED")
    }
    func testExclusiveWriteNeverReplacesExistingOutput() throws {
        let root = try TrustedRoot(path: directory.path)
        try root.writeExclusive("result.pdf", data: Data("first".utf8))
        XCTAssertThrowsError(try root.writeExclusive("result.pdf", data: Data("second".utf8)))
        XCTAssertEqual(try root.read("result.pdf", limit: 100), Data("first".utf8))
    }
    func testExplicitUnattendedTransportReceivesOnlyBoundedPDF() throws {
        final class FakeSigner: MCPUnattendedTransport {
            var calls = 0
            func sign(pdf: Data, name: String) throws -> [String: Any] {
                calls += 1
                XCTAssertEqual(pdf, Data("%PDF-1.7".utf8))
                XCTAssertEqual(name, "test.pdf")
                return ["state": "completed", "inputSHA256": String(repeating: "a", count: 64),
                        "outputSHA256": String(repeating: "b", count: 64),
                        "output": ["rootId": "unattended-output", "relativePath": "test.pdf"]]
            }
        }
        try Data("%PDF-1.7".utf8).write(to: directory.appendingPathComponent("test.pdf"))
        let signer = FakeSigner()
        let server = MCPServer(roots: ["docs": try TrustedRoot(path: directory.path)], unattended: signer)
        let arguments: [String: Any] = ["input": ["rootId": "docs", "relativePath": "test.pdf"], "format": "PAdES-T"]
        let response = try content(request(server, name: "sign_document", arguments: arguments))
        XCTAssertEqual(response["ok"] as? Bool, true)
        XCTAssertEqual(signer.calls, 1)
        var forbidden = arguments; forbidden["pin"] = "sentinel"
        _ = try request(server, name: "sign_document", arguments: forbidden)
        XCTAssertEqual(signer.calls, 1)
    }
    func testSpoolOwnershipAndForeignJobs() throws {
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
        for name in ["requests", "responses", "outputs"] {
            try FileManager.default.createDirectory(at: directory.appendingPathComponent(name), withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        }
        let transport = try SpoolApprovalTransport(directory: directory.path)
        XCTAssertThrowsError(try transport.job(id: UUID().uuidString, cancel: true))
        let prepared = try transport.prepare(pdf: Data("%PDF-1.7".utf8), name: "test.pdf")
        let id = try XCTUnwrap(prepared["jobId"] as? String)
        transport.disconnect()
        XCTAssertEqual(try transport.job(id: id, cancel: false)["cancellationRequested"] as? Bool, true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("requests/\(id)-cancel.json").path))
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: directory.path)
        XCTAssertThrowsError(try SpoolApprovalTransport(directory: directory.path))
    }
}
