import Foundation
import CoreFoundation
import MoldSignKit

public final class MCPServer {
    public static let protocolVersion = "2026-07-28"
    public static let maximumFrameBytes = 65536
    public static let maximumDocumentBytes = 8 * 1024 * 1024
    private let roots: [String: TrustedRoot]
    private let broker: MCPApprovalTransport?
    private let unattended: MCPUnattendedTransport?
    public init(roots: [String: TrustedRoot], broker: MCPApprovalTransport? = nil, unattended: MCPUnattendedTransport? = nil) {
        self.roots = roots; self.broker = broker; self.unattended = unattended
    }
    public func disconnect() { broker?.disconnect() }
    public static func validIdentifier(_ value: String) -> Bool {
        !value.isEmpty && value.utf8.count <= 64 && value.unicodeScalars.allSatisfy {
            CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-").contains($0)
        }
    }
    private static func object(_ properties: [String: Any], _ required: [String]) -> [String: Any] {
        ["type": "object", "properties": properties, "required": required, "additionalProperties": false]
    }
    private static func string(_ max: Int = 1024) -> [String: Any] { ["type": "string", "minLength": 1, "maxLength": max] }
    private static var referenceSchema: [String: Any] {
        object(["rootId": string(64), "relativePath": string()], ["rootId", "relativePath"])
    }
    private static var jobSchema: [String: Any] {
        object(["jobId": string(64), "state": ["enum": ["awaiting_user", "signing", "completed", "failed", "cancelled", "expired"]],
                "cancellationRequested": ["type": "boolean"], "inputSHA256": string(64), "outputSHA256": string(64),
                "errorCode": string(64), "output": referenceSchema], ["jobId", "state"])
    }
    public static var tools: [[String: Any]] {
        let signature = object(["index": ["type": "integer"], "kind": string(32), "level": string(64),
            "contentIntact": ["type": "boolean"], "signatureValid": ["type": "boolean"],
            "chainTrusted": ["type": "boolean"], "missingDocumentCount": ["type": "integer"]],
            ["index", "kind", "level", "contentIntact", "signatureValid", "chainTrusted", "missingDocumentCount"])
        let verification = object(["status": ["enum": ["valid", "unconfirmed", "incomplete", "invalid", "no_recognized_signature"]],
            "mode": ["const": "offline"], "revocationChecked": ["const": false], "signatureCount": ["type": "integer"],
            "signatures": ["type": "array", "maxItems": 64, "items": signature]],
            ["status", "mode", "revocationChecked", "signatureCount", "signatures"])
        let capability = object(["product": ["const": "eSemnBun"], "protocolVersion": ["const": protocolVersion],
            "rootIds": ["type": "array", "maxItems": 32, "items": string(64)], "verificationFormats": ["type": "array", "items": string(16)],
            "desktopApprovalBrokerAvailable": ["type": "boolean"], "signingFormat": ["const": "PAdES-T"], "unattendedSigningAvailable": ["type": "boolean"]],
            ["product", "protocolVersion", "rootIds", "verificationFormats", "desktopApprovalBrokerAvailable", "signingFormat", "unattendedSigningAvailable"])
        let definitions: [(String, String, [String: Any], [String: Any], Bool)] = [
            ("capabilities", "Discover configured root IDs and broker availability without accessing a card.", object([:], []), capability, true),
            ("verify_document", "Offline PDF or XAdES verification. No revocation check; no document text is returned.",
             object(["input": referenceSchema, "detachedRootId": string(64)], ["input"]), verification, true),
            ("prepare_signing", "Stage one PDF for native user approval. The user selects and reviews the signing card in the app. Never supply a PIN.",
             object(["input": referenceSchema, "format": ["const": "PAdES-T"]], ["input", "format"]), jobSchema, false),
            ("sign_document", "Sign a PDF using the locally configured unattended policy and secret provider. Available only with explicit launch opt-in.",
             object(["input": referenceSchema, "format": ["const": "PAdES-T"]], ["input", "format"]),
             object(["state": ["const": "completed"], "inputSHA256": string(64), "outputSHA256": string(64), "output": referenceSchema], ["state", "inputSHA256", "outputSHA256", "output"]), false),
            ("get_job", "Read a job created by this helper. A pending job does not imply user approval.", object(["jobId": string(64)], ["jobId"]), jobSchema, true),
            ("cancel_job", "Request cancellation; an in-progress card operation cannot be undone.", object(["jobId": string(64)], ["jobId"]), jobSchema, false)
        ]
        return definitions.map { name, description, input, output, readOnly in
            let error = object(["code": string(64), "retryable": ["type": "boolean"], "message": string(128)], ["code", "retryable", "message"])
            let envelope: [String: Any] = ["type": "object", "oneOf": [
                object(["schemaVersion": ["const": 1], "ok": ["const": true], "data": output], ["schemaVersion", "ok", "data"]),
                object(["schemaVersion": ["const": 1], "ok": ["const": false], "error": error], ["schemaVersion", "ok", "error"])]]
            return ["name": name, "description": description, "inputSchema": input, "outputSchema": envelope,
                    "annotations": ["readOnlyHint": readOnly, "destructiveHint": false, "openWorldHint": !readOnly]]
        }
    }
    /// One request is independent of prior discovery or caller identity metadata.
    public func handle(_ line: Data) -> Data? {
        func encoded(_ object: [String: Any]) -> Data? { try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) }
        func error(_ id: Any?, _ code: Int, _ message: String, _ data: [String: Any]? = nil) -> Data? {
            var body: [String: Any] = ["code": code, "message": message]
            if let data { body["data"] = data }
            var response: [String: Any] = ["jsonrpc": "2.0", "error": body]
            if let id { response["id"] = id }
            return encoded(response)
        }
        guard line.count <= Self.maximumFrameBytes else { return error(nil, -32600, "Request exceeds limit") }
        guard let parsed = try? JSONSerialization.jsonObject(with: line) else { return error(nil, -32700, "Parse error") }
        guard let request = parsed as? [String: Any], request["jsonrpc"] as? String == "2.0",
              let method = request["method"] as? String else { return error(nil, -32600, "Invalid request") }
        // Notifications never receive responses or invoke tools.
        guard let id = request["id"] else { return nil }
        let validID: Bool
        if let text = id as? String { validID = text.utf8.count <= 128 }
        else if let number = id as? NSNumber { validID = CFGetTypeID(number) != CFBooleanGetTypeID() && number.doubleValue.isFinite && number.doubleValue.rounded() == number.doubleValue }
        else { validID = false }
        guard validID, Set(request.keys).isSubset(of: ["jsonrpc", "id", "method", "params"]) else { return error(nil, -32600, "Invalid request") }
        guard let params = request["params"] as? [String: Any], let meta = params["_meta"] as? [String: Any],
              let version = meta["io.modelcontextprotocol/protocolVersion"] as? String,
              meta["io.modelcontextprotocol/clientCapabilities"] is [String: Any] else { return error(id, -32602, "Required request metadata is missing") }
        guard version == Self.protocolVersion else { return error(id, -32022, "Unsupported protocol version", ["supported": [Self.protocolVersion], "requested": String(version.prefix(64))]) }
        func result(_ body: [String: Any]) -> Data? {
            var value = body; value["resultType"] = "complete"
            value["_meta"] = ["io.modelcontextprotocol/serverInfo": ["name": "esemnbun-mcp", "version": "1"]]
            return encoded(["jsonrpc": "2.0", "id": id, "result": value])
        }
        switch method {
        case "server/discover":
            guard Set(params.keys) == ["_meta"] else { return error(id, -32602, "Invalid params") }
            return result(["supportedVersions": [Self.protocolVersion], "capabilities": ["tools": [:]]])
        case "ping": return result([:])
        case "tools/list":
            guard Set(params.keys) == ["_meta"] else { return error(id, -32602, "Invalid params") }
            return result(["tools": Self.tools.filter { unattended != nil || $0["name"] as? String != "sign_document" }])
        case "tools/call":
            guard Set(params.keys).isSubset(of: ["_meta", "name", "arguments"]), let name = params["name"] as? String,
                  Self.tools.contains(where: { $0["name"] as? String == name }),
                  name != "sign_document" || unattended != nil,
                  let arguments = params["arguments"] as? [String: Any] else { return error(id, -32602, "Invalid tool call") }
            let envelope: [String: Any]
            do { envelope = ["schemaVersion": 1, "ok": true, "data": try call(name, arguments)] }
            catch { let failure = error as? MCPFailure ?? .brokerUnavailable
                envelope = ["schemaVersion": 1, "ok": false, "error": ["code": failure.rawValue, "retryable": false, "message": "The operation could not be completed."]]
            }
            let text = String(data: (try? JSONSerialization.data(withJSONObject: envelope, options: [.sortedKeys])) ?? Data(), encoding: .utf8) ?? "{}"
            return result(["content": [["type": "text", "text": text]], "structuredContent": envelope, "isError": envelope["ok"] as? Bool != true])
        default: return error(id, -32601, "Method not found")
        }
    }
    private func call(_ name: String, _ arguments: [String: Any]) throws -> [String: Any] {
        func keys(_ required: Set<String>, _ optional: Set<String> = []) throws {
            guard required.isSubset(of: Set(arguments.keys)), Set(arguments.keys).isSubset(of: required.union(optional)) else { throw MCPFailure.invalidArgument }
        }
        if name == "capabilities" {
            try keys([])
            return ["product": "eSemnBun", "protocolVersion": Self.protocolVersion, "rootIds": roots.keys.sorted(),
                    "verificationFormats": ["PDF", "XAdES"], "desktopApprovalBrokerAvailable": broker?.available ?? false, "signingFormat": "PAdES-T", "unattendedSigningAvailable": unattended != nil]
        }
        if name == "get_job" || name == "cancel_job" {
            try keys(["jobId"])
            guard let id = arguments["jobId"] as? String, Self.validIdentifier(id) else { throw MCPFailure.invalidArgument }
            guard let broker else { throw MCPFailure.brokerUnavailable }
            return try broker.job(id: id, cancel: name == "cancel_job")
        }
        if name == "verify_document" { try keys(["input"], ["detachedRootId"]) }
        else { try keys(["input", "format"]); guard arguments["format"] as? String == "PAdES-T" else { throw MCPFailure.invalidArgument } }
        guard let input = arguments["input"] as? [String: Any], Set(input.keys) == ["rootId", "relativePath"],
              let rootID = input["rootId"] as? String, Self.validIdentifier(rootID), let root = roots[rootID],
              let path = input["relativePath"] as? String else { throw MCPFailure.invalidArgument }
        let suffix = (path as NSString).pathExtension.lowercased()
        guard suffix == "pdf" || (name == "verify_document" && suffix == "xml") else { throw MCPFailure.unsupported }
        var detached: TrustedRoot?
        if let detachedID = arguments["detachedRootId"] {
            guard suffix == "xml", let id = detachedID as? String, let selected = roots[id] else { throw MCPFailure.invalidArgument }
            detached = selected
        }
        let data = try root.read(path, limit: Self.maximumDocumentBytes)
        if name == "prepare_signing" || name == "sign_document" {
            guard data.starts(with: Data("%PDF-".utf8)) else { throw MCPFailure.unsupported }
            if name == "sign_document" {
                guard let unattended else { throw MCPFailure.signingDisabled }
                return try unattended.sign(pdf: data, name: (path as NSString).lastPathComponent)
            }
            guard let broker else { throw MCPFailure.brokerUnavailable }
            return try broker.prepare(pdf: data, name: (path as NSString).lastPathComponent)
        }
        let reports: [Validator.Report]
        if suffix == "pdf" { reports = Validator.validatePDF(data) }
        else {
            guard let xml = String(data: data, encoding: .utf8), !xml.uppercased().contains("<!DOCTYPE"), !xml.uppercased().contains("<!ENTITY") else { throw MCPFailure.unsupported }
            let initial = Validator.validateXAdES(data, referencedFiles: [:])
            let references = Set(initial.flatMap(\.missingDetachedReferences))
            guard references.count <= 32 else { throw MCPFailure.limitExceeded }
            var files: [String: Data] = [:], total = data.count
            if let detached {
                for reference in references.sorted() {
                    if let bytes = try? detached.read(reference, limit: Self.maximumDocumentBytes - total) {
                        total += bytes.count; files[reference] = bytes
                    }
                }
            }
            reports = files.isEmpty ? initial : Validator.validateXAdES(data, referencedFiles: files)
        }
        guard reports.count <= 64 else { throw MCPFailure.limitExceeded }
        let incomplete = reports.contains { !$0.missingDetachedReferences.isEmpty }
        let invalid = reports.contains { !$0.signatureValid || (!$0.contentIntact && $0.missingDetachedReferences.isEmpty) }
        let status = invalid ? "invalid" : incomplete ? "incomplete" : reports.isEmpty ? "no_recognized_signature" : reports.allSatisfy(\.chainTrusted) ? "valid" : "unconfirmed"
        let signatures: [[String: Any]] = reports.enumerated().map { index, report in
            ["index": index + 1, "kind": report.kind, "level": report.level, "contentIntact": report.contentIntact,
             "signatureValid": report.signatureValid, "chainTrusted": report.chainTrusted, "missingDocumentCount": report.missingDetachedReferences.count]
        }
        return ["status": status, "mode": "offline", "revocationChecked": false, "signatureCount": reports.count, "signatures": signatures]
    }
}
