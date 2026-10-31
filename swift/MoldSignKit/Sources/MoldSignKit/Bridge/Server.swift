import Foundation
#if canImport(Network) && !MOLDSIGN_PORTABLE
import Network
#else
import CPCSC
#endif

/// What a bridge caller asks for: shown in the consent UI (SEC-02).
public struct BridgeRequest: Sendable {
    public enum Operation: String, Sendable { case signData, signPDF, signFile }
    public let origin: String?
    public let operation: Operation
    public let documentName: String?
    public let format: String?
    /// The caller already sent a PIN (typed into the web page); the host should not ask for one.
    public let pinIncluded: Bool
    /// Requested digest ("SHA-1" / "SHA-256"); honoured for XAdES (R-11).
    public internal(set) var algorithm: String? = nil
    /// `use_pin_session` of a multi-document portal batch: the first document's session id (MAC-19).
    public internal(set) var batchSession: String? = nil
    /// The certificate the page picked from `/certificates` (several cards may be connected): SHA-1 + holder.
    /// Consent and PIN must be for this card; the server signs with the reader that holds it.
    public internal(set) var certificateSHA1: String? = nil
    public internal(set) var certificateHolder: String? = nil
}

public enum BridgeDecision: Sendable {
    case deny
    /// `pin`: the PIN to use when the request carries none (nil → host fallback: env / dialog / tty).
    /// `certificateSHA1`: the card that PIN belongs to; the server refuses a different card before VERIFY.
    case allow(pin: String?, certificateSHA1: String? = nil)
}

public struct BridgeEvent: Sendable {
    public let origin: String?
    public let method: String
    public let path: String
    public let status: Int
}

/// Drop-in replica of the MoldSign Server (127.0.0.1:18480) protocol so the
/// msign.gov.md browser "Sign with MoldSign" flow works without the Java suite.
///
/// Embeddable (F-07): `start()`/`stop()` from an app, `run()` from the CLI. Hosts plug in
/// `authorize` (consent + PIN) and `onEvent` (activity log). Card work runs on its own queue; result polls
/// are long-polls held until the session finishes, exactly like the vendor's `Future.get()`.
public final class MoldSignServer {
    public enum TLSIdentityError: Error {
        case missing
        case invalid
    }

    struct Session {
        var ready = false
        var payload = ""       // JSON body for the poll response
        var contentType = "application/json"
        /// Failure → HTTP 400 + `error: <message>` header, as the vendor answers (the portal reads that header).
        var error: String?
    }

    public static let defaultHTTPPort: UInt16 = 18480
    public static let defaultHTTPSPort: UInt16 = 18443
    static let maxRequestBytes = 64 << 20

    /// Consent hook, called on a background queue (block until the user decides). nil = allow (CLI).
    public var authorize: ((BridgeRequest) -> BridgeDecision)?
    /// Every answered request, for the activity log.
    public var onEvent: ((BridgeEvent) -> Void)?
    /// Outcome of each signing request (nil = signed), on the work queue. Hosts use it to drop a stored PIN
    /// the card rejected (`CardError.wrongPIN` / `.pinBlocked`) and to show remaining attempts (MAC-05, LNX-11).
    public var onSignResult: ((BridgeRequest, Error?) -> Void)?
    /// A listener failed, typically EADDRINUSE because the vendor Java server holds the port (MAC-08).
    /// See `isAddressInUse(_:)`.
    public var onListenerError: ((_ port: UInt16, _ error: Error) -> Void)?
    public private(set) var isRunning = false

    private let policy: BridgeOriginPolicy
    private let tlsP12: Data?
    private let httpPort: UInt16
    private let httpsPort: UInt16
    private var sessions: [String: Session] = [:]
    /// Polls waiting for a pending session (long-poll), keyed by session id. Touched only on `queue`.
    private var waiters: [String: [(Session) -> Void]] = [:]
    private var stopListeners: [() -> Void] = []
    private let queue = DispatchQueue(label: "msign-server")
    private let workQueue = DispatchQueue(label: "msign-server-work")
    private static let p12Password = "u9mUvI9BNb1U9jSbpBKf36YWINVK5XX5KAzql3bILNnjscVfLn"

    public init(policy: BridgeOriginPolicy = .vendorDefault,
                tlsP12: Data? = MoldSignServer.defaultTLSP12(),
                httpPort: UInt16 = MoldSignServer.defaultHTTPPort,
                httpsPort: UInt16 = MoldSignServer.defaultHTTPSPort) {
        self.policy = policy
        self.tlsP12 = tlsP12
        self.httpPort = httpPort
        self.httpsPort = httpsPort
    }

    /// The localhost.cts.md identity (exported from the MoldSign suite keystore, docs/06).
    /// Order: `MSIGN_TLS_P12` env, installed vendor suite, app bundle, dev checkout (SEC-07, D-03).
    public static func defaultTLSP12() -> Data? {
        var paths: [String] = []
        if let env = ProcessInfo.processInfo.environment["MSIGN_TLS_P12"] { paths.append(env) }
        paths.append("/Applications/STISC/MoldSign/MoldSignData/Server/localhost.p12")
        if let bundled = Bundle.main.url(forResource: "localhost", withExtension: "p12") { paths.append(bundled.path) }
        #if os(Linux) || MOLDSIGN_PORTABLE
        // XDG data dir, Flatpak (/app), distro packages (LNX-13)
        let dataHome = ProcessInfo.processInfo.environment["XDG_DATA_HOME"] ?? NSHomeDirectory() + "/.local/share"
        // Relocatable distributions: executable + share/ or prefix/bin + prefix/share/.
        // Resolve symlinks so a launcher outside the installation still finds its identity.
        let executable = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        let directory = executable.deletingLastPathComponent()
        paths.append(dataHome + "/moldsign/localhost.p12")
        for base in [directory, directory.deletingLastPathComponent()] {
            paths.append(base.appendingPathComponent("share/moldsign/localhost.p12").path)
            paths.append(base.appendingPathComponent("share/moldsign-cli/localhost.p12").path)
        }
        paths += ["/app/share/moldsign/localhost.p12",
                  "/usr/local/share/moldsign/localhost.p12", "/usr/share/moldsign/localhost.p12",
                  "/usr/local/share/moldsign-cli/localhost.p12", "/usr/share/moldsign-cli/localhost.p12"]
        #endif
        paths.append(NSHomeDirectory() + "/Projects/smartcard/swift/MoldSignKit/Resources/localhost.p12")
        for path in paths {
            if let data = FileManager.default.contents(atPath: path) { return data }
        }
        return nil
    }

    /// True for "address already in use" from either listener implementation.
    public static func isAddressInUse(_ error: Error) -> Bool {
        #if canImport(Network) && !MOLDSIGN_PORTABLE
        if let nw = error as? NWError, case .posix(.EADDRINUSE) = nw { return true }
        #endif
        return (error as? POSIXError)?.code == .EADDRINUSE
    }

    #if canImport(Network) && !MOLDSIGN_PORTABLE
    private static func tlsIdentity(from data: Data) -> sec_identity_t? {
        var items: CFArray?
        var options: [CFString: Any] = [kSecImportExportPassphrase: Self.p12Password]
        // Otherwise macOS stores the key in the login keychain with an ACL for the importing binary: any other build
        // then blocks the TLS handshake on a "wants to sign using key" prompt and the portal hangs.
        if #available(macOS 15, iOS 18, *) { options[kSecImportToMemoryOnly] = true }
        let status = SecPKCS12Import(data as CFData, options as CFDictionary, &items)
        guard status == errSecSuccess,
              let arr = items as? [[String: Any]], let first = arr.first,
              let identity = first[kSecImportItemIdentity as String] else { return nil }
        return sec_identity_create(identity as! SecIdentity)
    }
    #endif

    /// Checks an imported vendor identity before replacing the installed copy.
    public static func validateTLSP12(_ data: Data) throws {
        #if canImport(Network) && !MOLDSIGN_PORTABLE
        guard tlsIdentity(from: data) != nil else { throw TLSIdentityError.invalid }
        #else
        let ctx = data.withUnsafeBytes {
            c_tls_server_new($0.bindMemory(to: UInt8.self).baseAddress, data.count, p12Password)
        }
        guard let ctx else { throw TLSIdentityError.invalid }
        c_tls_server_free(ctx)
        #endif
    }

    // MARK: - Lifecycle

    /// Starts the http (and, with a TLS identity, https) listeners bound to 127.0.0.1 only (SEC-03).
    public func start(requireHTTPS: Bool = false) throws {
        guard !isRunning else { return }
        if requireHTTPS {
            guard let tlsP12 else { throw TLSIdentityError.missing }
            try Self.validateTLSP12(tlsP12)
        }
        #if canImport(Network) && !MOLDSIGN_PORTABLE
        let plain = NWParameters.tcp
        try listen(plain, port: httpPort)
        MSLog.info("MoldSign server replica (http) on http://127.0.0.1:\(httpPort)")

        // HTTPS with the localhost.cts.md identity (same cert the Java suite uses)
        if let data = tlsP12, let identity = Self.tlsIdentity(from: data) {
            let tlsOpts = NWProtocolTLS.Options()
            sec_protocol_options_set_min_tls_protocol_version(tlsOpts.securityProtocolOptions, .TLSv12)
            sec_protocol_options_set_local_identity(tlsOpts.securityProtocolOptions, identity)
            do {
                try listen(NWParameters(tls: tlsOpts), port: httpsPort)
                MSLog.info("MoldSign server replica (https) on https://localhost.cts.md:\(httpsPort)")
            } catch {
                MSLog.info("WARNING: https listener failed: \(error)")
                if requireHTTPS { stop(); throw error }
            }
        } else {
            MSLog.info("WARNING: localhost.p12 not found — https listener disabled")
            if requireHTTPS { stop(); throw TLSIdentityError.invalid }
        }
        #else
        do {
            try startPOSIX(requireHTTPS: requireHTTPS)
        } catch {
            stop()
            throw error
        }
        #endif
        isRunning = true
    }

    public func stop() {
        stopListeners.forEach { $0() }
        stopListeners.removeAll()
        pinLock.lock(); pinSessions.removeAll(); pinLock.unlock()
        isRunning = false
    }

    /// CLI entry point: start and park the main thread.
    public func run() throws -> Never {
        try start()
        MSLog.info("Ctrl+C to stop. Card operations will be performed on demand.")
        dispatchMain()
    }

    #if canImport(Network) && !MOLDSIGN_PORTABLE
    private func listen(_ params: NWParameters, port: UInt16) throws {
        params.allowLocalEndpointReuse = true
        params.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: port)!)
        let listener = try NWListener(using: params)
        listener.newConnectionHandler = { [weak self] conn in self?.handle(conn) }
        listener.stateUpdateHandler = { [weak self] state in
            if case .failed(let error) = state {
                MSLog.info("[ERR] listener :\(port) failed: \(error)")
                self?.onListenerError?(port, error)
            }
        }
        listener.start(queue: queue)
        stopListeners.append { listener.cancel() }
    }

    // MARK: - Connection handling

    private func handle(_ conn: NWConnection) {
        conn.start(queue: queue)
        receiveFull(conn, into: Data()) { [weak self] (req: Data?) in
            guard let self = self, let req = req else { conn.cancel(); return }
            self.route(req) { resp in
                conn.send(content: resp, completion: .contentProcessed { _ in conn.cancel() })
            }
        }
    }

    private func receiveFull(_ conn: NWConnection, into acc: Data, done: @escaping (Data?) -> Void) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 1 << 22) { data, _, isComplete, err in
            var acc = acc
            if let data = data { acc.append(data) }
            if acc.count > Self.maxRequestBytes {
                done(nil)
            } else if Self.httpComplete(acc) || isComplete || err != nil {
                done(err == nil && !acc.isEmpty ? acc : nil)
            } else {
                self.receiveFull(conn, into: acc, done: done)
            }
        }
    }

    #endif

    #if !(canImport(Network) && !MOLDSIGN_PORTABLE)
    /// Linux / portable: POSIX sockets on 127.0.0.1, TLS via OpenSSL with the same p12 (LNX-05).
    private func startPOSIX(requireHTTPS: Bool) throws {
        let handler: (Data, @escaping (Data) -> Void) -> Void = { [weak self] raw, reply in
            guard let self else { return }
            self.queue.async { self.route(raw, reply: reply) }
        }
        do {
            let http = try POSIXHTTPListener(port: httpPort, tls: nil, maxRequestBytes: Self.maxRequestBytes, handler: handler)
            stopListeners.append { http.stop() }
            MSLog.info("MoldSign server replica (http) on http://127.0.0.1:\(httpPort)")
        } catch {
            MSLog.info("[ERR] listener :\(httpPort) failed: \(error)")
            onListenerError?(httpPort, error)
            throw error
        }
        guard let p12 = tlsP12 else {
            MSLog.info("WARNING: localhost.p12 not found — https listener disabled")
            return
        }
        let ctx = p12.withUnsafeBytes { c_tls_server_new($0.bindMemory(to: UInt8.self).baseAddress, p12.count, Self.p12Password) }
        guard let ctx else {
            MSLog.info("WARNING: could not load the TLS identity — https listener disabled")
            if requireHTTPS { throw TLSIdentityError.invalid }
            return
        }
        do {
            let https = try POSIXHTTPListener(port: httpsPort, tls: ctx, maxRequestBytes: Self.maxRequestBytes, handler: handler)
            stopListeners.append { https.stop() }
            MSLog.info("MoldSign server replica (https) on https://localhost.cts.md:\(httpsPort)")
        } catch {
            MSLog.info("[ERR] listener :\(httpsPort) failed: \(error)")
            onListenerError?(httpsPort, error)
            if requireHTTPS { throw error }
        }
    }
    #endif

    static func httpComplete(_ d: Data) -> Bool {
        guard let r = d.range(of: Data("\r\n\r\n".utf8)) else { return false }
        let head = String(decoding: d[d.startIndex..<r.lowerBound], as: UTF8.self)
        var len = 0
        for line in head.split(separator: "\r\n") {
            if line.lowercased().hasPrefix("content-length:") {
                len = Int(line.dropFirst(15).trimmingCharacters(in: .whitespaces)) ?? 0
            }
        }
        return d.count >= r.upperBound + len
    }

    // MARK: - Routing

    private func route(_ raw: Data, reply: @escaping (Data) -> Void) {
        guard let headEnd = raw.range(of: Data("\r\n\r\n".utf8)) else {
            reply(respond(400, "", contentType: "text/plain", origin: nil)); return
        }
        let head = String(decoding: raw[raw.startIndex..<headEnd.lowerBound], as: UTF8.self)
        let body = raw.subdata(in: headEnd.upperBound..<raw.endIndex)
        let lines = head.split(separator: "\r\n")
        let parts = lines.first?.split(separator: " ") ?? []
        guard parts.count >= 2 else { reply(respond(400, "", contentType: "text/plain", origin: nil)); return }
        let method = String(parts[0])
        let fullPath = String(parts[1])
        MSLog.info("[REQ] \(method) \(fullPath) body=\(body.count)B")
        if body.count > 0, body.count < 4000 {
            MSLog.debug("[BODY] " + String(decoding: body, as: UTF8.self).prefix(800))
        }
        let path = fullPath.split(separator: "?")[0].description
        let query = Self.queryItems(fullPath)
        let caller = headerValue(head, "Origin")
        let host = headerValue(head, "Host") ?? "localhost.cts.md:\(httpsPort)"
        let reply: (Data) -> Void = { [weak self] resp in
            let status = Int(String(decoding: resp.prefix(12).dropFirst(9), as: UTF8.self)) ?? 0
            self?.onEvent?(BridgeEvent(origin: caller, method: method, path: path, status: status))
            reply(resp)
        }

        // SEC-01: vendor allow-list on Origin; header-only auth for non-browser clients
        guard policy.allows(origin: caller, moldSignHeader: headerValue(head, "moldSign")) else {
            MSLog.info("[DENY] origin=\(caller ?? "-")")
            reply(respondJSON(403, #"{"error":"origin not allowed"}"#, origin: nil))
            return
        }
        let origin = caller ?? "*"

        if method == "OPTIONS" {
            reply(respond(200, "", contentType: "text/plain", origin: origin,
                          extra: ["Access-Control-Allow-Methods: GET, POST, OPTIONS",
                                  "Access-Control-Allow-Private-Network: true"]))
            return
        }

        switch (method, path) {
        case ("GET", "/certificates"), ("GET", "/certificates/"):
            workQueue.async { [weak self] in
                guard let self else { return }
                reply(self.respondJSON(200, self.certificatesJSON(), origin: origin))
            }
        case ("POST", "/sign/data"):
            let accept = headerValue(head, "Accept") ?? "application/json"
            reply(startSignData(body: body, accept: accept, caller: caller, origin: origin, host: host,
                                usePinSession: query["use_pin_session"]))
        case ("GET", _) where path.hasPrefix("/sign/data/PKCS11/"):
            poll(path: path, origin: origin, keepPinSession: query["keep_pin_session"] == "1", reply: reply)
        case ("POST", "/sign/pdf"):
            reply(startSignPDF(body: body, caller: caller, origin: origin, host: host))
        case ("GET", _) where path.hasPrefix("/sign/pdf/PKCS11/"):
            poll(path: path, origin: origin, keepPinSession: query["keep_pin_session"] == "1", reply: reply)
        case ("POST", "/sign/file"):
            reply(startSignFile(body: body, caller: caller, origin: origin, host: host))
        case ("GET", _) where path.hasPrefix("/sign/file/PKCS11/"):
            poll(path: path, origin: origin, keepPinSession: query["keep_pin_session"] == "1", reply: reply)
        case ("POST", "/sign/file/verify"):
            reply(startVerifyFile(body: body, origin: origin, host: host))
        case ("GET", _) where path.hasPrefix("/sign/file/verify/"):
            poll(path: path, origin: origin, keepPinSession: query["keep_pin_session"] == "1", reply: reply)
        case ("POST", "/verify/pdf"), ("POST", "/sign/pdf/verify"):
            reply(startVerifyPDF(body: body, origin: origin, host: host))
        case ("GET", _) where path.hasPrefix("/sign/pdf/verify/"):
            poll(path: path, origin: origin, keepPinSession: query["keep_pin_session"] == "1", reply: reply)
        default:
            reply(respondJSON(404, #"{"error":"not found"}"#, origin: origin))
        }
    }

    private func headerValue(_ head: String, _ name: String) -> String? {
        for line in head.split(separator: "\r\n") {
            if line.lowercased().hasPrefix(name.lowercased() + ":") {
                return line.dropFirst(name.count + 1).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    // MARK: - Responses

    /// `origin` nil → no CORS headers (denied callers get nothing a browser could read).
    private func respond(_ status: Int, _ body: String, contentType: String,
                         origin: String?, extra: [String] = []) -> Data {
        let statusText = [200: "OK", 201: "Created", 303: "See Other", 400: "Bad Request", 401: "Unauthorized",
                          403: "Forbidden", 404: "Not Found", 500: "Internal Server Error"][status] ?? "OK"
        var head = "HTTP/1.1 \(status) \(statusText)\r\n" +
            "Content-Type: \(contentType)\r\n" +
            "Content-Length: \(body.utf8.count)\r\n"
        if let origin {
            head += "Access-Control-Allow-Origin: \(origin)\r\n" +
                "Access-Control-Allow-Headers: Origin, x-requested-with, content-type, accept, error, Location\r\n" +
                "Access-Control-Expose-Headers: Origin, x-requested-with, content-type, accept, error, Location\r\n"
        }
        head += "Connection: close\r\n"
        for e in extra { head += e + "\r\n" }
        head += "\r\n"
        return Data(head.utf8) + Data(body.utf8)
    }

    /// `201 Created` exactly like the vendor's Jersey `Response.created(uri).header("sessionId", id)`: no body.
    /// mpass's jQuery login code continues only from `.fail`, i.e. when the empty body doesn't parse as JSON;
    /// a JSON body sends it to `.done`, where it does nothing (stuck on "Introduceți PIN-ul semnăturii").
    private func respondCreated(sessionId: String, origin: String?, location: String) -> Data {
        respond(201, "", contentType: "text/plain", origin: origin, extra: ["Location: \(location)", "sessionId: \(sessionId)"])
    }

    private func respondJSON(_ status: Int, _ json: String, origin: String?, extra: [String] = []) -> Data {
        respond(status, json, contentType: "application/json", origin: origin, extra: extra)
    }

    // MARK: - /certificates

    /// Every inserted card (several eID cards can be connected), like the vendor's GlobalCertificateProvider.
    /// Built with JSONSerialization: any holder name (diacritics, quotes, control bytes) stays valid JSON;
    /// the portal shows "no available signatures" for an empty list OR for a body it can't parse.
    private func certificatesJSON() -> String {
        let models: [[String: Any]] = SigningService.shared.listCards().enumerated().map { index, entry in
            let cert = entry.certificate.der
            let cn = entry.certificate.holder
            return [
                "certificateId": entry.certificate.sha1Hex,
                "label": cn + UUID().uuidString.prefix(4).lowercased(),
                "providerId": "libbit4xpki.dylib-\(index)",
                "policy": "1.2.498.3.32.1.1",
                "certificateName": "\(cn) (null) (1.2.498.3.32.1.1)",
                // decoded names (Java's X500Principal gives Unicode too), not the XAdES \XX escapes
                "subjectDN": entry.certificate.subjectDN,
                "issuerDN": entry.certificate.issuer,
                "authority": false, "trusted": true, "verified": 0, "privateKeyPresent": true,
                "certificateBase64": cert.base64EncodedString(),
            ]
        }
        let body = try? JSONSerialization.data(withJSONObject: ["certificateModel": models], options: [.withoutEscapingSlashes])
        return body.map { String(decoding: $0, as: UTF8.self) } ?? #"{"certificateModel":[]}"#
    }

    private func jsonEsc(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
    }

    // MARK: - Small helpers

    private func xmlField(_ body: Data, _ name: String) -> String? {
        let t = String(decoding: body, as: UTF8.self)
        guard let r = t.range(of: "<\(name)>"), let e = t.range(of: "</\(name)>", range: r.upperBound..<t.endIndex) else { return nil }
        return String(t[r.upperBound..<e.lowerBound])
    }

    private func xmlFields(_ body: Data, _ name: String) -> [String] {
        let t = String(decoding: body, as: UTF8.self)
        var out: [String] = []
        guard let re = try? NSRegularExpression(pattern: "<\(name)>([^<]*)</\(name)>") else { return out }
        let ns = t as NSString
        for m in re.matches(in: t, range: NSRange(location: 0, length: ns.length)) {
            out.append(ns.substring(with: m.range(at: 1)))
        }
        return out
    }

    // MARK: - Signing sessions

    /// Registers a pending session (called on `queue` from `route`) and runs `work` on the card queue.
    private func newSession(_ work: @escaping (_ id: String, _ session: inout Session) -> Void) -> String {
        let id = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24))
        sessions[id] = Session()
        workQueue.async { [weak self] in
            var s = Session()
            work(id, &s)
            s.ready = true
            self?.queue.async { self?.complete(id, s) }
        }
        return id
    }

    private func complete(_ id: String, _ session: Session) {
        if let pending = waiters.removeValue(forKey: id), !pending.isEmpty {
            sessions.removeValue(forKey: id)
            pending.forEach { $0(session) }
        } else {
            sessions[id] = session
        }
    }

    /// Long-poll, like the vendor (`Scheduler.getResult` → `Future.get()`): the GET is answered only when
    /// the session has finished. Never 303: browsers follow at most 20 redirects, and consent + PIN entry
    /// take longer than that (the 0.5 s/303 variant made browser signing fail).
    private func poll(path: String, origin: String, keepPinSession: Bool, reply: @escaping (Data) -> Void) {
        let id = path.split(separator: "/").dropFirst(3).first.map(String.init) ?? ""
        // vendor PinDistributor: the PIN session ends with the poll unless the batch asked to keep it
        if !keepPinSession { forgetPIN(session: id) }
        guard let session = sessions[id] else {
            reply(respondJSON(404, #"{"error":"unknown session"}"#, origin: origin, extra: ["error: unknown session"]))
            return
        }
        let answer: (Session) -> Void = { [weak self] s in
            guard let self else { return }
            reply(self.sessionResponse(s, origin: origin))
        }
        if session.ready {
            sessions.removeValue(forKey: id)
            answer(session)
        } else {
            waiters[id, default: []].append(answer)
        }
    }

    private func sessionResponse(_ s: Session, origin: String) -> Data {
        guard let error = s.error else { return respond(200, s.payload, contentType: s.contentType, origin: origin) }
        // header values must stay on one line and ASCII
        let headerSafe = String(error.unicodeScalars.map { $0.isASCII && $0.value >= 0x20 ? Character($0) : " " })
        return respond(400, s.payload, contentType: s.contentType, origin: origin, extra: ["error: \(headerSafe)"])
    }

    private func parseJSON(_ body: Data) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: body)) as? [String: Any] ?? [:]
    }

    private func certModel(fromJSON m: [String: Any]) -> Data? {
        guard let c = m["certificate"] as? [String: Any],
              let b64 = c["certificateBase64"] as? String, !b64.isEmpty else { return nil }
        return Data(base64Encoded: b64)
    }

    struct Denied: Error, CustomStringConvertible {
        var description: String { "user denied the signing request" }
    }

    // MARK: - PIN sessions (multi-document portal batches, MAC-19)

    /// The portal signs several contents in a row: the first request's session id comes back as
    /// `use_pin_session` on the next ones (and its poll carries `keep_pin_session=1`). Like the vendor's
    /// `PinDistributor`, the PIN that already signed is reused, so one consent + PIN covers the batch.
    /// Memory only, same origin only, dropped after `pinSessionTTL` idle seconds or when the server stops.
    private struct PinSession {
        let pin: String
        let certificateSHA1: String     // the card that accepted it: a swapped card must not get it
        let origin: String?
        var lastUse: Date
    }
    private var pinSessions: [String: PinSession] = [:]
    private let pinLock = NSLock()
    static let pinSessionTTL: TimeInterval = 300

    private func rememberPIN(_ auth: Authorization, session: String, origin: String?) {
        pinLock.lock(); defer { pinLock.unlock() }
        guard let cert = auth.certificateSHA1 else { return }
        pinSessions[session] = PinSession(pin: auth.pin, certificateSHA1: cert, origin: origin, lastUse: Date())
    }

    private func reusablePIN(session: String, origin: String?) -> Authorization? {
        pinLock.lock(); defer { pinLock.unlock() }
        let now = Date()
        pinSessions = pinSessions.filter { now.timeIntervalSince($0.value.lastUse) < Self.pinSessionTTL }
        guard var entry = pinSessions[session], entry.origin == origin else { return nil }
        entry.lastUse = now
        pinSessions[session] = entry
        return Authorization(pin: entry.pin, certificateSHA1: entry.certificateSHA1)
    }

    private func forgetPIN(session: String) {
        pinLock.lock(); defer { pinLock.unlock() }
        pinSessions[session] = nil
    }

    static func queryItems(_ fullPath: String) -> [String: String] {
        guard let q = fullPath.split(separator: "?", maxSplits: 1).dropFirst().first else { return [:] }
        var out: [String: String] = [:]
        for pair in q.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1).map(String.init)
            out[kv[0]] = kv.count > 1 ? (kv[1].removingPercentEncoding ?? kv[1]) : ""
        }
        return out
    }

    /// What the browser sees in the `error` header / body.
    static func message(for error: Error) -> String {
        if let denied = error as? Denied { return denied.description }
        return (error as? LocalizedError)?.errorDescription ?? String(describing: error)
    }

    /// Consent first (SEC-02), then the PIN: request JSON → host decision → env / native dialog / tty.
    struct Authorization {
        let pin: String
        /// Card the PIN belongs to (nil: typed into the web page / env / dialog, no expectation).
        let certificateSHA1: String?
    }

    private func authorizedPIN(_ request: BridgeRequest, requestPIN: String?) throws -> Authorization {
        var hostPIN: String?
        var hostCert: String?
        if let authorize {
            switch authorize(request) {
            case .deny: throw Denied()
            case .allow(let pin, let cert): hostPIN = pin; hostCert = cert
            }
        }
        if let pin = requestPIN, !pin.isEmpty { return Authorization(pin: pin, certificateSHA1: nil) }
        if let pin = hostPIN, !pin.isEmpty { return Authorization(pin: pin, certificateSHA1: hostCert) }
        return Authorization(pin: fallbackPIN() ?? "", certificateSHA1: nil)
    }

    private func fallbackPIN() -> String? {
        if let envPin = ProcessInfo.processInfo.environment["MSIGN_PIN"], !envPin.isEmpty { return envPin }
        #if os(macOS)
        return promptPINNative()
        #else
        return nil
        #endif
    }

    #if os(macOS)
    /// macOS password dialog via osascript; falls back to terminal readLine when a tty exists.
    private func promptPINNative() -> String? {
        let script = #"display dialog "Enter PIN QSCD for signing:" default answer "" with hidden answer buttons {"Cancel", "OK"} default button "OK" with title "MoldSign Mac""#
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", script, "-e", "text returned of result"]
        let out = Pipe()
        proc.standardOutput = out
        proc.standardError = FileHandle.nullDevice
        do {
            try proc.run()
            proc.waitUntilExit()
        } catch { return nil }
        guard proc.terminationStatus == 0 else { return nil }
        let text = String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty { return text }
        // detached (no GUI): last resort — tty prompt
        if isatty(STDIN_FILENO) == 1 {
            FileHandle.standardOutput.write(Data("PIN QSCD required for signing: ".utf8))
            return readLine(strippingNewline: true)
        }
        return nil
    }
    #endif

    private func startSignData(body: Data, accept: String, caller: String?, origin: String, host: String,
                               usePinSession: String? = nil) -> Data {
        let m = parseJSON(body)
        guard let dataB64 = m["data"] as? String, let raw = Data(base64Encoded: dataB64) else {
            return respondJSON(400, #"{"error":"missing data"}"#, origin: origin)
        }
        let contentType = (m["contentType"] as? String) ?? ""
        let signFormat = (m["signFormat"] as? String) ?? "XAdES-T"
        let algorithm = m["algorithm"] as? String
        let request = withCertificate(BridgeRequest(origin: caller, operation: .signData,
                                                    documentName: contentType.lowercased() == "pdf" ? "document.pdf" : nil,
                                                    format: contentType.lowercased() == "pdf" ? "PAdES-T" : signFormat,
                                                    pinIncluded: !((m["pin"] as? String) ?? "").isEmpty,
                                                    algorithm: algorithm, batchSession: usePinSession),
                                      certModel(fromJSON: m))
        let sessionId = newSession { [weak self] id, s in
            guard let self = self else { return }
            do {
                // later documents of a portal batch reuse the PIN the first one signed with (no new consent)
                let reused = usePinSession.flatMap { self.reusablePIN(session: $0, origin: caller) }
                var auth = try reused ?? self.authorizedPIN(request, requestPIN: m["pin"] as? String)
                if contentType.lowercased() == "pdf" {
                    let tmp = FileManager.default.temporaryDirectory
                    let inURL = tmp.appendingPathComponent("msa-in-\(UUID().uuidString).pdf")
                    let outURL = tmp.appendingPathComponent("msa-out-\(UUID().uuidString).pdf")
                    try raw.write(to: inURL)
                    defer { try? FileManager.default.removeItem(at: inURL); try? FileManager.default.removeItem(at: outURL) }
                    let out = try self.signPDFFile(inURL, outURL, certJSON: certModel(fromJSON: m), auth: auth,
                                                   reader: try self.reader(for: auth, request))
                    auth = Authorization(pin: auth.pin, certificateSHA1: out.certificateSHA1)
                    s.payload = #"{"base64File":""# + out.data.base64EncodedString() + "\"}"
                } else {
                    let format: XAdESSigner.Format
                    switch signFormat {
                    case "XAdES-BES": format = .bes
                    case "XAdES-C": format = .c
                    default: format = .t
                    }
                    let out = try self.signXAdESData(raw, format: format,
                                                     embedded: (m["signatureType"] as? String) != "Detached",
                                                     digest: XAdESSigner.DigestAlgorithm(requested: algorithm),
                                                     certJSON: certModel(fromJSON: m), auth: auth,
                                                     reader: try self.reader(for: auth, request))
                    auth = Authorization(pin: auth.pin, certificateSHA1: out.certificateSHA1)
                    s.payload = #"{"base64File":""# + out.data.base64EncodedString() + "\"}"
                }
                self.rememberPIN(auth, session: id, origin: caller)
                self.onSignResult?(request, nil)
            } catch {
                MSLog.info("[ERR] \(error)")
                s.error = Self.message(for: error)
                s.payload = #"{"error":""# + self.jsonEsc(s.error!) + "\"}"
                self.onSignResult?(request, error)
            }
        }
        return respondCreated(sessionId: sessionId, origin: origin,
                           location: "https://\(host)/sign/data/PKCS11/\(sessionId)/Any")
    }

    private func startSignPDF(body: Data, caller: String?, origin: String, host: String) -> Data {
        var m = parseJSON(body)
        if m.isEmpty, body.contains("originalFile".data(using: .utf8)!) {
            m = ["originalFile": xmlField(body, "originalFile") ?? "",
                 "signedFile": xmlField(body, "signedFile") ?? "",
                 "pin": xmlField(body, "pin") ?? "",
                 "certificate": ["certificateBase64": xmlField(body, "certificateBase64") ?? ""]]
        }
        guard let origPath = m["originalFile"] as? String, !origPath.isEmpty else {
            return respondJSON(400, #"{"error":"missing originalFile"}"#, origin: origin)
        }
        let outPath: String
        if let sp = m["signedFile"] as? String, !sp.isEmpty { outPath = sp }
        else { outPath = origPath.replacingOccurrences(of: ".pdf", with: "-signed.pdf") }
        let request = withCertificate(BridgeRequest(origin: caller, operation: .signPDF,
                                                    documentName: URL(fileURLWithPath: origPath).lastPathComponent,
                                                    format: "PAdES-T", pinIncluded: !((m["pin"] as? String) ?? "").isEmpty),
                                      certModel(fromJSON: m))
        let sessionId = newSession { [weak self] _, s in
            guard let self = self else { return }
            do {
                let auth = try self.authorizedPIN(request, requestPIN: m["pin"] as? String)
                _ = try self.signPDFFile(URL(fileURLWithPath: origPath), URL(fileURLWithPath: outPath),
                                         certJSON: certModel(fromJSON: m), auth: auth, reader: try self.reader(for: auth, request))
                s.payload = #"{"path":""# + self.jsonEsc(outPath) + "\"}"
                self.onSignResult?(request, nil)
            } catch {
                MSLog.info("[ERR] \(error)")
                s.error = Self.message(for: error)
                s.payload = #"{"error":""# + self.jsonEsc(s.error!) + "\"}"
                self.onSignResult?(request, error)
            }
        }
        return respondCreated(sessionId: sessionId, origin: origin,
                           location: "https://\(host)/sign/pdf/PKCS11/\(sessionId)")
    }

    private func startSignFile(body: Data, caller: String?, origin: String, host: String) -> Data {
        let files = xmlFields(body, "filesToSign")
        let signFormat = xmlField(body, "signFormat") ?? "XAdES-T"
        let sigType = (xmlField(body, "type") ?? "Detached").lowercased() == "embedded" ? XAdESSigner.SigType.enveloping : .detached
        let certB64 = xmlField(body, "certificateBase64")
        let pinField = xmlField(body, "pin") ?? ""
        let dest = xmlField(body, "destinationFile") ?? ""
        let signAlgorithm = xmlField(body, "signAlgorithm")
        let digest = XAdESSigner.DigestAlgorithm(requested: signAlgorithm)
        let request = withCertificate(BridgeRequest(origin: caller, operation: .signFile,
                                                    documentName: files.map { URL(fileURLWithPath: $0).lastPathComponent }.joined(separator: ", "),
                                                    format: signFormat, pinIncluded: !pinField.isEmpty, algorithm: signAlgorithm),
                                      certB64.flatMap { $0.isEmpty ? nil : Data(base64Encoded: $0) })
        let sessionId = newSession { [weak self] _, s in
            guard let self = self else { return }
            s.contentType = "application/xml"
            do {
                let format: XAdESSigner.Format
                switch signFormat {
                case "XAdES-BES": format = .bes
                case "XAdES-C": format = .c
                default: format = .t
                }
                let auth = try self.authorizedPIN(request, requestPIN: pinField)
                let outPath = dest.isEmpty ? ((files.first.map { $0 + ".xades" }) ?? dest) : dest
                let out = try SigningService.shared.withCard(reader: try self.reader(for: auth, request)) { card -> Data in
                    let cardCert = try card.prepareForSigning(pin: auth.pin,
                                                              expectedCertificateSHA1: auth.certificateSHA1 ?? request.certificateSHA1)
                    let cert: Data
                    if let b64 = certB64, !b64.isEmpty, let c = Data(base64Encoded: b64) { cert = c } else { cert = cardCert }
                    let signer = XAdESSigner()
                    return try signer.sign(files: files.map { URL(fileURLWithPath: $0) }, format: format,
                                           type: sigType, digest: digest, certDER: cert, chainDER: [ChainCerts.mdQSign],
                                           signBlock: { bytes in try card.sign(digestInfo: digest.digestInfo(of: bytes)) },
                                           tsaBlock: { data in try PAdESSigner.fetchTimestampToken(data: data) },
                                           ocspDerBlock: { issuer, c in try XAdESSigner.fetchOCSPResponse(issuerDER: issuer, certDER: c) })
                }
                try out.write(to: URL(fileURLWithPath: outPath))
                s.payload = "<XadesSignatureModelContainer><fileLocation>\(self.xmlEsc(outPath))</fileLocation><signatures/></XadesSignatureModelContainer>"
                self.onSignResult?(request, nil)
            } catch {
                MSLog.info("[ERR] \(error)")
                s.error = Self.message(for: error)
                s.payload = "<error>\(self.xmlEsc(s.error!))</error>"
                self.onSignResult?(request, error)
            }
        }
        return respondCreated(sessionId: sessionId, origin: origin,
                           location: "https://\(host)/sign/file/PKCS11/\(sessionId)")
    }

    private func startVerifyFile(body: Data, origin: String, host: String) -> Data {
        let files = xmlFields(body, "signedFiles")
        let sigPath = xmlField(body, "signature") ?? ""
        MSLog.debug("[VFY-REQ] signedFiles=\(files) sig=\(sigPath)")
        let sessionId = newSession { _, s in
            var filesMap: [String: Data] = [:]
            for f in files {
                filesMap[URL(fileURLWithPath: f).lastPathComponent] = try? Data(contentsOf: URL(fileURLWithPath: f))
            }
            var valid = false
            if let sigData = try? Data(contentsOf: URL(fileURLWithPath: sigPath)) {
                let rep = Validator.validateXAdES(sigData, referencedFiles: filesMap)
                for r0 in rep { MSLog.info("[VFY] \(r0.summary)") }
                if rep.isEmpty { MSLog.info("[VFY] no reports; sigPath=\(sigPath) filesMap=\(filesMap.keys)") }
                valid = !rep.isEmpty && rep.allSatisfy { $0.contentIntact && $0.signatureValid }
            } else { MSLog.info("[VFY] cannot read sig at \(sigPath)") }
            s.contentType = "application/xml"
            s.payload = "<verifySignedFileResponseModel><valid>\(valid)</valid></verifySignedFileResponseModel>"
        }
        return respondCreated(sessionId: sessionId, origin: origin,
                           location: "https://\(host)/sign/file/verify/\(sessionId)")
    }

    private func startVerifyPDF(body: Data, origin: String, host: String) -> Data {
        let pdfPath = xmlField(body, "signedFile") ?? xmlField(body, "originalFile") ?? ""
        let sessionId = newSession { _, s in
            var valid = false
            if let d = try? Data(contentsOf: URL(fileURLWithPath: pdfPath)) {
                let rep = Validator.validatePDF(d)
                valid = !rep.isEmpty && rep.allSatisfy { $0.contentIntact && $0.signatureValid }
            }
            s.contentType = "application/xml"
            s.payload = "<verifyPdfResponseModel><valid>\(valid)</valid></verifyPdfResponseModel>"
        }
        return respondCreated(sessionId: sessionId, origin: origin,
                           location: "https://\(host)/sign/pdf/verify/\(sessionId)")
    }

    private func xmlEsc(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }

    // MARK: - Signing drivers

    /// The page's chosen certificate (from the request JSON/XML) as request fields.
    private func withCertificate(_ request: BridgeRequest, _ certDER: Data?) -> BridgeRequest {
        guard let certDER else { return request }
        var r = request
        r.certificateSHA1 = certDER.sha1().hexString.lowercased()
        r.certificateHolder = Validator.subjectCN(certDER)
        return r
    }

    /// Reader holding the card the PIN/selection is for; nil → the host's default reader.
    /// A requested card that is in no reader fails here, before any PIN is sent.
    private func reader(for auth: Authorization, _ request: BridgeRequest) throws -> String? {
        guard let target = auth.certificateSHA1 ?? request.certificateSHA1 else { return nil }
        guard let reader = SigningService.shared.reader(forCertificateSHA1: target) else { throw CardError.noCard }
        return reader
    }

    struct SignedOutput {
        let data: Data
        /// SHA-1 of the certificate read from the card that produced the signature.
        let certificateSHA1: String
    }

    @discardableResult
    private func signPDFFile(_ inURL: URL, _ outURL: URL, certJSON: Data?, auth: Authorization,
                             reader: String?) throws -> SignedOutput {
        let pdf = try Data(contentsOf: inURL)
        let expected = auth.certificateSHA1 ?? certJSON.map { $0.sha1().hexString.lowercased() }
        let out = try SigningService.shared.withCard(reader: reader) { card -> SignedOutput in
            let cardCert = try card.prepareForSigning(pin: auth.pin, expectedCertificateSHA1: expected)
            let signed = try PAdESSigner().signPDF(pdf, certDER: certJSON ?? cardCert) { di in
                try card.sign(digestInfo: di)
            }
            return SignedOutput(data: signed, certificateSHA1: cardCert.sha1().hexString.lowercased())
        }
        try out.data.write(to: outURL)
        return out
    }

    private func signXAdESData(_ raw: Data, format: XAdESSigner.Format, embedded: Bool,
                               digest: XAdESSigner.DigestAlgorithm, certJSON: Data?, auth: Authorization,
                               reader: String?) throws -> SignedOutput {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("msa-xades-\(UUID().uuidString).xml")
        try raw.write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }
        let expected = auth.certificateSHA1 ?? certJSON.map { $0.sha1().hexString.lowercased() }
        return try SigningService.shared.withCard(reader: reader) { card -> SignedOutput in
            let cardCert = try card.prepareForSigning(pin: auth.pin, expectedCertificateSHA1: expected)
            // the portal asks for signatureType "Embedded" (enveloping): a detached signature carries no content
            let xml = try XAdESSigner().sign(files: [tmp], format: format, type: embedded ? .enveloping : .detached,
                                             digest: digest, certDER: certJSON ?? cardCert, chainDER: [ChainCerts.mdQSign],
                                             signBlock: { bytes in try card.sign(digestInfo: digest.digestInfo(of: bytes)) },
                                             tsaBlock: { data in try PAdESSigner.fetchTimestampToken(data: data) },
                                             ocspDerBlock: { issuer, c in try XAdESSigner.fetchOCSPResponse(issuerDER: issuer, certDER: c) })
            return SignedOutput(data: xml, certificateSHA1: cardCert.sha1().hexString.lowercased())
        }
    }
}
