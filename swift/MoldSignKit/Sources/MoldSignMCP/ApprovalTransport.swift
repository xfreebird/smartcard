import Foundation

public protocol MCPUnattendedTransport: AnyObject {
    func sign(pdf: Data, name: String) throws -> [String: Any]
}

public protocol MCPApprovalTransport: AnyObject {
    var available: Bool { get }
    func prepare(pdf: Data, name: String) throws -> [String: Any]
    func job(id: String, cancel: Bool) throws -> [String: Any]
    func disconnect()
}

/// The app owns this private spool and all signing decisions. Caller names in MCP metadata
/// never grant authority. Only jobs created by this process are accessible through it.
public final class SpoolApprovalTransport: MCPApprovalTransport {
    private let requests: TrustedRoot
    private let responses: TrustedRoot
    private var jobs = Set<String>()
    private var cancellationRequests = Set<String>()
    public var available: Bool { true }
    public init(directory: String) throws {
        _ = try TrustedRoot(path: directory, privateDirectory: true)
        requests = try TrustedRoot(path: directory + "/requests", privateDirectory: true)
        responses = try TrustedRoot(path: directory + "/responses", privateDirectory: true)
        _ = try TrustedRoot(path: directory + "/outputs", privateDirectory: true)
    }
    public func prepare(pdf: Data, name: String) throws -> [String: Any] {
        guard jobs.count < 16 else { throw MCPFailure.limitExceeded }
        let id = UUID().uuidString
        let request: [String: Any] = ["schemaVersion": 1, "operation": "prepare", "jobId": id,
                                      "name": name, "pdf": pdf.base64EncodedString()]
        try requests.writeExclusive(id + ".json", data: JSONSerialization.data(withJSONObject: request))
        jobs.insert(id)
        return ["jobId": id, "state": "awaiting_user"]
    }
    public func job(id: String, cancel: Bool) throws -> [String: Any] {
        guard jobs.contains(id) else { throw MCPFailure.unknownJob }
        if cancel {
            let request: [String: Any] = ["schemaVersion": 1, "operation": "cancel", "jobId": id]
            // An existing cancel request is idempotent.
            if (try? requests.read(id + "-cancel.json", limit: 1024, privateFile: true)) == nil {
                try requests.writeExclusive(id + "-cancel.json", data: JSONSerialization.data(withJSONObject: request))
            }
            cancellationRequests.insert(id)
        }
        guard let bytes = try? responses.read(id + ".json", limit: 8192, privateFile: true) else {
            return ["jobId": id, "state": "awaiting_user", "cancellationRequested": cancellationRequests.contains(id)]
        }
        guard let value = try JSONSerialization.jsonObject(with: bytes) as? [String: Any],
              value["jobId"] as? String == id,
              let state = value["state"] as? String,
              ["awaiting_user", "signing", "completed", "failed", "cancelled", "expired"].contains(state) else {
            throw MCPFailure.brokerUnavailable
        }
        var result: [String: Any] = ["jobId": id, "state": state, "cancellationRequested": cancellationRequests.contains(id)]
        for key in ["inputSHA256", "outputSHA256"] {
            if let hash = value[key] as? String, hash.count == 64,
               hash.allSatisfy({ "0123456789abcdef".contains($0) }) { result[key] = hash }
        }
        let errorCodes = ["BUSY", "NO_CARD", "CARD_CHANGED", "USER_CANCELLED", "EXPIRED", "PIN_INCORRECT", "PIN_BLOCKED", "NETWORK_FAILED", "OUTCOME_UNKNOWN", "SIGNING_FAILED"]
        if let code = value["errorCode"] as? String, errorCodes.contains(code) { result["errorCode"] = code }
        if state == "completed" { result["output"] = ["rootId": "broker-output", "relativePath": id + ".pdf"] }
        return result
    }
    public func disconnect() { for id in jobs { _ = try? job(id: id, cancel: true) } }
}
