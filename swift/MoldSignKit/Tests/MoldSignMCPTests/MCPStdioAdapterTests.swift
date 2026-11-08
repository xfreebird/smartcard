import XCTest
import Foundation
@testable import MoldSignMCP

final class MCPStdioAdapterTests: XCTestCase {
    private func call(_ adapter: MCPStdioAdapter, method: String, params: [String: Any]? = nil) throws -> [String: Any] {
        var request: [String: Any] = ["jsonrpc": "2.0", "id": 1, "method": method]
        request["params"] = params
        return try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(adapter.handle(JSONSerialization.data(withJSONObject: request)))) as? [String: Any])
    }
    private var initialization: [String: Any] {
        ["protocolVersion": "2025-11-25", "capabilities": ["roots": [:]], "clientInfo": ["name": "test", "version": "1"]]
    }
    func testLegacyHandshakeAndReadOnlyCall() throws {
        let adapter = MCPStdioAdapter(server: MCPServer(roots: [:]))
        XCTAssertNotNil(try call(adapter, method: "tools/list")["error"])
        let initialized = try call(adapter, method: "initialize", params: initialization)["result"] as? [String: Any]
        XCTAssertEqual(initialized?["protocolVersion"] as? String, "2025-11-25")
        XCTAssertNil(initialized?["resultType"])
        XCTAssertNil(adapter.handle(Data(#"{"jsonrpc":"2.0","method":"notifications/initialized"}"#.utf8)))
        let listing = try call(adapter, method: "tools/list")["result"] as? [String: Any]
        XCTAssertNotNil(listing?["tools"]); XCTAssertNil(listing?["resultType"]); XCTAssertNil(listing?["_meta"])
        let response = try call(adapter, method: "tools/call", params: ["name": "capabilities", "arguments": [:]])["result"] as? [String: Any]
        let content = response?["structuredContent"] as? [String: Any]
        XCTAssertEqual(content?["ok"] as? Bool, true)
        XCTAssertEqual((content?["data"] as? [String: Any])?["rootIds"] as? [String], [])
        XCTAssertNotNil(try call(adapter, method: "initialize", params: initialization)["error"])
    }
    func testUnknownLegacyVersionDoesNotEnableAdapter() throws {
        let adapter = MCPStdioAdapter(server: MCPServer(roots: [:]))
        var params = initialization; params["protocolVersion"] = "1900-01-01"
        XCTAssertNotNil(try call(adapter, method: "initialize", params: params)["error"])
        XCTAssertNotNil(try call(adapter, method: "tools/list")["error"])
    }
    func testModernMetadataRemainsAuthoritativeAfterLegacyHandshake() throws {
        let adapter = MCPStdioAdapter(server: MCPServer(roots: [:]))
        _ = try call(adapter, method: "initialize", params: initialization)
        let modern: [String: Any] = ["_meta": ["io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": [:]]]
        let response = try call(adapter, method: "server/discover", params: modern)["result"] as? [String: Any]
        XCTAssertEqual(response?["resultType"] as? String, "complete")
        XCTAssertEqual(response?["supportedVersions"] as? [String], ["2026-07-28", "2025-11-25"])
        let invalid: [String: Any] = ["_meta": ["io.modelcontextprotocol/protocolVersion": "2026-07-28"]]
        XCTAssertNotNil(try call(adapter, method: "tools/list", params: invalid)["error"])
    }
}
