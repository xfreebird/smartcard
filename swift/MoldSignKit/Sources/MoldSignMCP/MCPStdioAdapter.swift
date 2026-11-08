import Foundation
import CoreFoundation

/// Explicit compatibility boundary: legacy connection initialization never supplies authority,
/// roots or credentials. Modern requests retain independent per-request metadata validation.
public final class MCPStdioAdapter {
    public static let legacyVersion = "2025-11-25"
    private let server: MCPServer
    private var legacyInitialized = false
    public init(server: MCPServer) { self.server = server }
    public func disconnect() { server.disconnect() }

    public func handle(_ line: Data) -> Data? {
        guard line.count <= MCPServer.maximumFrameBytes,
              let request = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any],
              request["jsonrpc"] as? String == "2.0",
              let method = request["method"] as? String else { return server.handle(line) }
        // No notification can initialize a connection or execute an application operation.
        guard let id = request["id"] else { return nil }
        func encode(_ value: [String: Any]) -> Data? {
            try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
        }
        func invalid(_ message: String) -> Data? {
            encode(["jsonrpc": "2.0", "id": id, "error": ["code": -32602, "message": message]])
        }
        var params = request["params"] as? [String: Any] ?? [:]
        if method == "initialize" {
            let validID: Bool
            if let value = id as? String { validID = value.utf8.count <= 128 }
            else if let value = id as? NSNumber {
                validID = CFGetTypeID(value) != CFBooleanGetTypeID() && value.doubleValue.isFinite && value.doubleValue.rounded() == value.doubleValue
            } else { validID = false }
            guard validID, Set(request.keys).isSubset(of: ["jsonrpc", "id", "method", "params"]) else { return server.handle(line) }
            guard !legacyInitialized,
                  Set(params.keys).isSubset(of: ["protocolVersion", "capabilities", "clientInfo", "_meta"]),
                  params["protocolVersion"] as? String == Self.legacyVersion,
                  params["capabilities"] is [String: Any],
                  let client = params["clientInfo"] as? [String: Any],
                  client["name"] is String, client["version"] is String else {
                return invalid("Expected a supported legacy initialization")
            }
            legacyInitialized = true
            return encode(["jsonrpc": "2.0", "id": id, "result": ["protocolVersion": Self.legacyVersion,
                "capabilities": ["tools": [:]], "serverInfo": ["name": "esemnbun-mcp", "version": "1"]]])
        }
        let metadata = params["_meta"] as? [String: Any]
        let legacyRequest = legacyInitialized && metadata?["io.modelcontextprotocol/protocolVersion"] == nil
        var translated = request
        if legacyRequest {
            guard request["params"] == nil || request["params"] is [String: Any],
                  params["_meta"] == nil || metadata != nil else { return invalid("Invalid params") }
            var meta = metadata ?? [:]
            meta["io.modelcontextprotocol/protocolVersion"] = MCPServer.protocolVersion
            meta["io.modelcontextprotocol/clientCapabilities"] = [String: Any]()
            params["_meta"] = meta
            translated["params"] = params
        }
        guard let data = encode(translated), let responseData = server.handle(data),
              var response = (try? JSONSerialization.jsonObject(with: responseData)) as? [String: Any] else { return nil }
        if var result = response["result"] as? [String: Any] {
            if method == "server/discover" { result["supportedVersions"] = [MCPServer.protocolVersion, Self.legacyVersion] }
            if legacyRequest { result.removeValue(forKey: "resultType"); result.removeValue(forKey: "_meta") }
            response["result"] = result
        }
        if var error = response["error"] as? [String: Any], error["code"] as? Int == -32022,
           var detail = error["data"] as? [String: Any] {
            detail["supported"] = [MCPServer.protocolVersion, Self.legacyVersion]
            error["data"] = detail; response["error"] = error
        }
        return encode(response)
    }
}
