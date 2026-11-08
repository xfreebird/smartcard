import Foundation
import MoldSignKit
import MoldSignMCP
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

/// Opt-in, same-user spool shared with esemnbun-mcp. A file is a request, never consent.
/// All callbacks and lifecycle state are confined to the GTK main loop.
final class AgentApprovalBroker {
    static var directory: URL {
        let base = ProcessInfo.processInfo.environment["XDG_DATA_HOME"].flatMap {
            $0.hasPrefix("/") ? URL(fileURLWithPath: $0) : nil
        } ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/share")
        return base.appendingPathComponent("eSemnBun/AgentBroker", isDirectory: true)
    }
    private weak var controller: AppController?
    private var running = false
    private var active: String?
    private var deadline = Date.distantPast
    private var cancelled = false
    private var signingStarted = false
    private var cursor = ""
    private var nextCleanup = Date.distantPast
    private var cleanupCursor = ""
    init(controller: AppController) { self.controller = controller }
    func prepare() throws { _ = try directories(create: true) }
    func start() { guard !running else { return }; running = true; tick() }
    func stop() { running = false; cancelled = true }
    private func tick() {
        guard running else { return }
        poll()
        after(milliseconds: 1000) { [weak self] in self?.tick() }
    }
    private func directories(create: Bool) throws -> [String: TrustedRoot] {
        let manager = FileManager.default
        var roots: [String: TrustedRoot] = [:]
        for name in ["", "requests", "responses", "outputs", "staging"] {
            let url = name.isEmpty ? Self.directory : Self.directory.appendingPathComponent(name)
            if create && !manager.fileExists(atPath: url.path) {
                try manager.createDirectory(at: url, withIntermediateDirectories: true,
                                            attributes: [.posixPermissions: 0o700])
            }
            roots[name] = try TrustedRoot(path: url.path, privateDirectory: true)
        }
        return roots
    }
    private func respond(_ id: String, state: String, roots: [String: TrustedRoot],
                         hash: String? = nil, output: Data? = nil, code: String? = nil) {
        do {
            var value: [String: Any] = ["schemaVersion": 1, "jobId": id, "state": state]
            if let hash { value["inputSHA256"] = hash }
            if let code { value["errorCode"] = code }
            if let output {
                try roots["outputs"]!.writeExclusive(id + ".pdf", data: output)
                value["outputSHA256"] = output.sha256().hexString
            }
            // A missing response is pending/unknown, never permission to retry signing.
            try? roots["responses"]!.remove(id + ".json")
            try roots["responses"]!.writeExclusive(id + ".json", data: JSONSerialization.data(withJSONObject: value))
        } catch { /* Preserve uncertainty rather than invent a successful outcome. */ }
    }
    private func poll() {
        guard let controller else { return }
        let enabled = controller.settings.agentApprovalEnabled && !controller.isDemo
        if active != nil && (!enabled || Date() >= deadline) {
            cancelled = true
            if !signingStarted { controller.cancelAgentPreview() }
        }
        do {
            let roots = try directories(create: enabled)
            cleanup(roots)
            if let id = active {
                if let bytes = try? roots["requests"]!.read(id + "-cancel.json", limit: 1024, privateFile: true),
                   let value = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any],
                   value["operation"] as? String == "cancel", value["jobId"] as? String == id {
                    cancelled = true
                    if !signingStarted { controller.cancelAgentPreview() }
                }
                return
            }
            guard enabled else { return }
            let names = try FileManager.default.contentsOfDirectory(atPath: Self.directory.appendingPathComponent("requests").path).sorted()
            let rest = names.filter { $0 > cursor }
            for name in (rest.isEmpty ? names : rest).prefix(64) {
                cursor = name
                guard name.hasSuffix(".json"), let uuid = UUID(uuidString: String(name.dropLast(5))),
                      name == uuid.uuidString + ".json" else { continue }
                let id = uuid.uuidString
                do {
                    // Existing terminal/pending responses prevent replay across app restarts.
                    if (try? roots["responses"]!.read(name, limit: 8192, privateFile: true)) != nil {
                        try? roots["requests"]!.remove(name); continue
                    }
                    let bytes = try roots["requests"]!.read(name, limit: MCPServer.maximumDocumentBytes * 4 / 3 + 8192, privateFile: true)
                    let request = try AgentSigningRequest.decode(bytes, id: id)
                    let label = request.name, pdf = request.pdf
                    let attrs = try FileManager.default.attributesOfItem(atPath: Self.directory.appendingPathComponent("requests/" + name).path)
                    let created = attrs[.modificationDate] as? Date ?? .distantPast
                    try roots["requests"]!.remove(name)
                    guard created <= Date(), Date().timeIntervalSince(created) < 300 else {
                        respond(id, state: "expired", roots: roots, code: "EXPIRED"); continue
                    }
                    if (try? roots["requests"]!.read(id + "-cancel.json", limit: 1024, privateFile: true)) != nil {
                        respond(id, state: "cancelled", roots: roots, code: "USER_CANCELLED"); continue
                    }
                    active = id; deadline = created.addingTimeInterval(300); cancelled = false; signingStarted = false
                    let hash = pdf.sha256().hexString
                    let staging = id + ".pdf"
                    try roots["staging"]!.writeExclusive(staging, data: pdf)
                    respond(id, state: "awaiting_user", roots: roots, hash: hash)
                    controller.signAgentPDF(pdf, name: label, stagingURL: Self.directory.appendingPathComponent("staging/" + staging),
                        authorized: { [weak self, weak controller] in
                            guard let self, let controller else { return false }
                            return self.running && controller.settings.agentApprovalEnabled && !self.cancelled && Date() < self.deadline
                        }, willSign: { [weak self] in
                            self?.signingStarted = true
                            self?.respond(id, state: "signing", roots: roots, hash: hash)
                        }, completion: { [weak self] result in
                            guard let self else { return }
                            defer { self.active = nil; try? roots["staging"]!.remove(staging) }
                            switch result {
                            case .success(let output): self.respond(id, state: "completed", roots: roots, hash: hash, output: output)
                            case .failure(let error):
                                let code: String
                                switch error {
                                case AppController.AgentSigningError.cancelled: code = Date() >= self.deadline ? "EXPIRED" : "USER_CANCELLED"
                                case AppController.AgentSigningError.unavailable: code = "BUSY"
                                case AppController.AgentSigningError.noCard: code = "NO_CARD"
                                case CardError.wrongPIN: code = "PIN_INCORRECT"
                                case CardError.pinBlocked: code = "PIN_BLOCKED"
                                case CardError.cardChanged: code = "CARD_CHANGED"
                                default: code = self.signingStarted ? "OUTCOME_UNKNOWN" : "SIGNING_FAILED"
                                }
                                self.respond(id, state: code == "EXPIRED" ? "expired" : code == "USER_CANCELLED" ? "cancelled" : "failed", roots: roots, hash: hash, code: code)
                            }
                        })
                    return
                } catch {
                    try? roots["requests"]!.remove(name)
                    if active == id { active = nil }
                    respond(id, state: "failed", roots: roots, code: "SIGNING_FAILED")
                }
            }
        } catch { /* No prompt/card access when the spool cannot be secured. */ }
    }
    private func cleanup(_ roots: [String: TrustedRoot]) {
        guard Date() >= nextCleanup else { return }
        nextCleanup = Date().addingTimeInterval(60)
        var paths: [(String, String)] = []
        for folder in ["requests", "responses", "outputs", "staging"] {
            let directory = Self.directory.appendingPathComponent(folder).path
            let names = (try? FileManager.default.contentsOfDirectory(atPath: directory)) ?? []
            paths.append(contentsOf: names.map { (folder, $0) })
        }
        paths.sort { $0.0 + "/" + $0.1 < $1.0 + "/" + $1.1 }
        let rest = paths.filter { $0.0 + "/" + $0.1 > cleanupCursor }
        for (folder, name) in (rest.isEmpty ? paths : rest).prefix(256) {
            cleanupCursor = folder + "/" + name
            if let active, name.hasPrefix(active) { continue }
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: Self.directory.appendingPathComponent(cleanupCursor).path),
                  let modified = attrs[.modificationDate] as? Date, Date().timeIntervalSince(modified) > 86400 else { continue }
            try? roots[folder]!.remove(name)
        }
    }
}

/// Bounded untrusted IPC decoding, kept separate from UI/card operations.
struct AgentSigningRequest {
    let name: String
    let pdf: Data
    static func decode(_ bytes: Data, id: String) throws -> Self {
        struct Payload: Decodable {
            let schemaVersion: Int
            let operation: String
            let jobId: String
            let name: String
            let pdf: String
        }
        guard bytes.count <= MCPServer.maximumDocumentBytes * 4 / 3 + 8192,
              let object = try JSONSerialization.jsonObject(with: bytes) as? [String: Any],
              Set(object.keys) == ["schemaVersion", "operation", "jobId", "name", "pdf"] else { throw MCPFailure.invalidArgument }
        let value = try JSONDecoder().decode(Payload.self, from: bytes)
        guard value.schemaVersion == 1, value.operation == "prepare", value.jobId == id,
              !value.name.isEmpty, value.name.utf8.count <= 255, value.name != ".", value.name != "..",
              !value.name.contains("/"), !value.name.contains("\\"),
              !value.name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
              let pdf = Data(base64Encoded: value.pdf), pdf.count <= MCPServer.maximumDocumentBytes,
              pdf.starts(with: Data("%PDF-".utf8)) else { throw MCPFailure.invalidArgument }
        return Self(name: value.name, pdf: pdf)
    }
}
