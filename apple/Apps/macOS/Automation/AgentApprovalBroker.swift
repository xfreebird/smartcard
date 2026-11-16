#if !APP_STORE
import AppKit
import SwiftUI
import PDFKit
import MoldSignKit
import Darwin

/// Local, opt-in spool. Files are never authority to sign: each request needs a fresh
/// foreground decision. No network listener, compatibility bridge credentials or PIN IPC.
@MainActor
final class AgentApprovalBroker {
    static let enabledKey = "agentApprovalEnabled"
    static var directory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/eSemnBun/AgentBroker", isDirectory: true)
    }
    private let model: AppModel
    private var timer: Timer?
    private var activeID: UUID?
    private var deadline = Date.distantPast
    private var cancelled = false
    private var signingStarted = false
    private var approvalWindow: NSWindow?
    private var approvalAlert: NSAlert?
    private var seen = Set<UUID>()
    private var requestCursor = ""
    private var cleanupCursor = ""
    private var nextCleanup = Date.distantPast
    private let retention: TimeInterval = 24 * 60 * 60
    private let maximumBytes = 32 * 1024 * 1024
    init(model: AppModel) { self.model = model }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
    }

    private var enabled: Bool { AppPreferencesStore.defaults.bool(forKey: Self.enabledKey) }

    private func secureDirectory(_ url: URL, create: Bool = true) throws {
        if create && !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true,
                                                   attributes: [.posixPermissions: 0o700])
        }
        var info = stat()
        guard lstat(url.path, &info) == 0, info.st_uid == getuid(),
              info.st_mode & S_IFMT == S_IFDIR, info.st_mode & 0o777 == 0o700,
              url.resolvingSymlinksInPath().path == url.standardizedFileURL.path else { throw BrokerError.pathDenied }
    }

    private func read(_ url: URL, limit: Int) throws -> Data {
        let fd = open(url.path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK)
        guard fd >= 0 else { throw BrokerError.pathDenied }
        defer { close(fd) }
        var info = stat()
        guard fstat(fd, &info) == 0, info.st_uid == getuid(), info.st_mode & S_IFMT == S_IFREG,
              info.st_mode & 0o777 == 0o600, info.st_nlink == 1,
              info.st_size >= 0, info.st_size <= limit else { throw BrokerError.pathDenied }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: false)
        let data = try handle.read(upToCount: limit + 1) ?? Data()
        guard data.count <= limit else { throw BrokerError.invalid }
        return data
    }

    private func write(_ data: Data, to url: URL) throws {
        let temporary = url.deletingLastPathComponent().appendingPathComponent(".\(UUID().uuidString)")
        let fd = open(temporary.path, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0o600)
        guard fd >= 0 else { throw BrokerError.pathDenied }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        defer { try? handle.close(); try? FileManager.default.removeItem(at: temporary) }
        try handle.write(contentsOf: data)
        try handle.synchronize()
        guard rename(temporary.path, url.path) == 0 else { throw BrokerError.pathDenied }
    }

    private func respond(_ id: UUID, state: String, hash: String? = nil, output: Data? = nil, error: String? = nil) {
        do {
            try secureDirectory(Self.directory, create: false)
            let responses = Self.directory.appendingPathComponent("responses")
            try secureDirectory(responses, create: false)
            var result: [String: Any] = ["schemaVersion": 1, "jobId": id.uuidString, "state": state]
            if let hash { result["inputSHA256"] = hash }
            if let error { result["errorCode"] = error }
            if let output {
                let outputs = Self.directory.appendingPathComponent("outputs")
                try secureDirectory(outputs, create: false)
                try write(output, to: outputs.appendingPathComponent(id.uuidString + ".pdf"))
                result["outputSHA256"] = output.sha256().hexString
            }
            try write(JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]),
                      to: responses.appendingPathComponent(id.uuidString + ".json"))
        } catch { /* Fail closed: a missing terminal response is an unknown outcome, never a retry instruction. */ }
    }

    private func poll() {
        if activeID != nil && (!enabled || Date() > deadline) {
            cancelPendingApproval()
        }
        do {
            // Retention also applies after opt-out, but disabled installations create no spool.
            try secureDirectory(Self.directory, create: enabled)
            for name in ["requests", "responses", "outputs"] {
                try secureDirectory(Self.directory.appendingPathComponent(name), create: enabled)
            }
            cleanupExpiredFiles()
            guard enabled else { return }
            let requests = Self.directory.appendingPathComponent("requests")
            if let id = activeID {
                let cancel = requests.appendingPathComponent(id.uuidString + "-cancel.json")
                if let data = try? read(cancel, limit: 1024),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   json["operation"] as? String == "cancel", json["jobId"] as? String == id.uuidString {
                    cancelPendingApproval()
                    try? FileManager.default.removeItem(at: cancel)
                }
                return
            }
            // Rotate bounded batches so malformed or irrelevant files cannot starve later jobs.
            let files = try FileManager.default.contentsOfDirectory(at: requests, includingPropertiesForKeys: [.creationDateKey])
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
            let remaining = files.filter { $0.lastPathComponent > requestCursor }
            let batch = Array((remaining.isEmpty ? files : remaining).prefix(64))
            for file in batch {
                requestCursor = file.lastPathComponent
                guard file.pathExtension == "json", let id = UUID(uuidString: file.deletingPathExtension().lastPathComponent),
                      !seen.contains(id) else { continue }
                do {
                    let data = try read(file, limit: maximumBytes * 4 / 3 + 8192)
                    let request = try JSONDecoder().decode(Request.self, from: data)
                    guard request.schemaVersion == 1, request.operation == "prepare", request.jobId == id,
                          request.name.count <= 255, !request.name.isEmpty,
                          request.name == URL(fileURLWithPath: request.name).lastPathComponent,
                          !request.name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
                          let pdf = Data(base64Encoded: request.pdf), pdf.count <= maximumBytes,
                          pdf.starts(with: Data("%PDF-".utf8)) else { throw BrokerError.invalid }
                    let created = try file.resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast
                    seen.insert(id)
                    if seen.count > 4096 { seen.removeAll(); seen.insert(id) }
                    _ = unlink(file.path)
                    guard created <= Date(), Date().timeIntervalSince(created) < 300 else { respond(id, state: "expired", error: "EXPIRED"); continue }
                    activeID = id; deadline = created.addingTimeInterval(300); cancelled = false; signingStarted = false
                    let hash = pdf.sha256().hexString
                    respond(id, state: "awaiting_user", hash: hash)
                    Task { await process(id, pdf: pdf, name: request.name, hash: hash) }
                    return
                } catch {
                    // Consume only this job. A broken request must not prevent unrelated jobs.
                    seen.insert(id)
                    if seen.count > 4096 { seen.removeAll(); seen.insert(id) }
                    _ = unlink(file.path)
                    respond(id, state: "failed", error: "INVALID_ARGUMENT")
                }
            }
        } catch { /* Untrusted or inaccessible spool: do not open a prompt or touch the card. */ }
    }

    /// Completed artifacts remain available for one day. Cleanup is incremental and also
    /// removes abandoned cancel markers/temp files; it never removes an active job's files.
    private func cleanupExpiredFiles() {
        guard Date() >= nextCleanup else { return }
        nextCleanup = Date().addingTimeInterval(60)
        let manager = FileManager.default
        let files = ["requests", "responses", "outputs"].flatMap { name in
            (try? manager.contentsOfDirectory(at: Self.directory.appendingPathComponent(name),
                includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey, .isSymbolicLinkKey])) ?? []
        }.sorted { $0.path < $1.path }
        let remaining = files.filter { $0.path > cleanupCursor }
        for file in (remaining.isEmpty ? files : remaining).prefix(256) {
            cleanupCursor = file.path
            if let activeID, file.lastPathComponent.hasPrefix(activeID.uuidString) { continue }
            guard let values = try? file.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey, .isSymbolicLinkKey]),
                  values.isRegularFile == true, values.isSymbolicLink != true,
                  let modified = values.contentModificationDate,
                  Date().timeIntervalSince(modified) > retention else { continue }
            _ = unlink(file.path)
        }
    }

    private func cancelPendingApproval() {
        cancelled = true
        guard !signingStarted else { return } // A card operation cannot be undone; preserve its actual outcome.
        if let sheet = approvalAlert?.window, sheet.sheetParent != nil { NSApp.endSheet(sheet, returnCode: NSApplication.ModalResponse.alertSecondButtonReturn.rawValue) }
        model.cancelPIN()
    }

    private func process(_ id: UUID, pdf: Data, name: String, hash: String) async {
        defer { activeID = nil; approvalWindow?.close(); approvalWindow = nil; approvalAlert = nil }
        do {
            let output = try await model.signAgentPDF(pdf, name: name, approve: { certificate in
                await self.approve(pdf: pdf, name: name, hash: hash, certificate: certificate)
            }, stillAuthorized: {
                guard self.enabled, !self.cancelled, Date() < self.deadline else { return false }
                return true
            }, willSign: {
                self.signingStarted = true
                self.respond(id, state: "signing", hash: hash)
            })
            respond(id, state: "completed", hash: hash, output: output)
        } catch {
            let code: String
            switch error {
            case AppModel.AgentSigningError.cancelled: code = Date() > deadline ? "EXPIRED" : "USER_CANCELLED"
            case AppModel.AgentSigningError.busy: code = "BUSY"
            case AppModel.AgentSigningError.noCard: code = "NO_CARD"
            case CardError.cardChanged: code = "CARD_CHANGED"
            case CardError.wrongPIN: code = "PIN_INCORRECT"
            case CardError.pinBlocked: code = "PIN_BLOCKED"
            default: code = signingStarted ? "OUTCOME_UNKNOWN" : "INVALID_ARGUMENT"
            }
            respond(id, state: code == "EXPIRED" ? "expired" : code == "USER_CANCELLED" ? "cancelled" : "failed", hash: hash, error: code)
        }
    }

    private func approve(pdf: Data, name: String, hash: String, certificate: SigningService.CertificateSummary) async -> Bool {
        guard !cancelled, enabled, Date() < deadline, let document = PDFDocument(data: pdf) else { return false }
        let preview = PDFView(frame: NSRect(x: 0, y: 0, width: 560, height: 340))
        preview.document = document; preview.autoScales = true
        let window = NSWindow(contentRect: preview.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.title = name; window.center()
        window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
        approvalWindow = window
        let alert = NSAlert()
        // Preview belongs inside the sheet so its scrolling remains interactive during review.
        alert.accessoryView = preview
        alert.messageText = L10n.text(.automation_approve_title)
        alert.informativeText = L10n.text(.automation_approve_details, name, certificate.holder, hash, certificate.der.sha256().hexString)
        alert.addButton(withTitle: L10n.text(.automation_approve)); alert.addButton(withTitle: L10n.text(.automation_reject))
        // Reject is the safe default; pressing Return must not authorize an unsolicited job.
        alert.buttons[0].keyEquivalent = ""; alert.buttons[1].keyEquivalent = "\r"
        approvalAlert = alert
        let result = await alert.beginSheetModal(for: window)
        window.close(); approvalWindow = nil; approvalAlert = nil
        return result == .alertFirstButtonReturn && !cancelled && enabled && Date() < deadline
    }

    private struct Request: Decodable { let schemaVersion: Int; let operation: String; let jobId: UUID; let name: String; let pdf: String }
    private enum BrokerError: Error { case pathDenied, invalid }
}

struct AgentBrokerSettingsView: View {
    @AppStorage(AgentApprovalBroker.enabledKey, store: AppPreferencesStore.defaults) private var enabled = false
    var body: some View {
        Group {
            Toggle(L10n.text(.automation_enable), isOn: $enabled)
            Text(L10n.text(.automation_hint))
                .font(.caption).foregroundStyle(.secondary)
            if enabled {
                Text(AgentApprovalBroker.directory.path).font(.caption).textSelection(.enabled)
            }
        }
    }
}
#endif
