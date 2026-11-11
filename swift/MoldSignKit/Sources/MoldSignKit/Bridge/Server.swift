import Foundation
#if canImport(Network) && !MOLDSIGN_PORTABLE
import Network
#else
import CPCSC
#endif

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
        let origin: String
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
    /// Optional host preview, before PIN authorization. Reused only within the same origin/card/batch for five minutes.
    public var previewPDFEnabled: (() -> Bool)?
    public var previewPDF: ((BridgeRequest, Data) -> PDFStampDecision)?
    private let stampStateLock = NSLock()
    private var stampEpoch = 0
    private var stampSessions: [String: (String?, String?, PDFStampPlacement?, Date)] = [:]
    func stampPlacement(_ request: BridgeRequest, _ data: Data, batch: String) throws -> PDFStampPlacement? {
        guard let previewPDF else { return nil }
        stampStateLock.lock(); let epoch = stampEpoch; stampStateLock.unlock()
        guard previewPDFEnabled?() ?? true else { stampSessions[batch] = nil; return nil }
        let now = Date()
        stampSessions = stampSessions.filter { now.timeIntervalSince($0.value.3) < 300 }
        if let cached = stampSessions[batch], cached.0 == request.origin, cached.1 == request.certificateSHA1,
           cached.2 == nil || StampPDF.canApply(cached.2!, to: data) {
            stampSessions[batch] = (cached.0, cached.1, cached.2, now)
            return cached.2?.bound(to: data)
        }
        let decision = previewPDF(request, data)
        stampStateLock.lock(); let current = stampEpoch; stampStateLock.unlock()
        guard current == epoch else { throw Denied() }
        switch decision {
        case .cancel: throw Denied()
        case .proceed(let placement):
            stampSessions[batch] = (request.origin, request.certificateSHA1, placement, now)
            return placement?.bound(to: data)
        }
    }
    /// Every answered request, for the activity log.
    public var onEvent: ((BridgeEvent) -> Void)?
    /// Outcome of each signing request (nil = signed), on the work queue. Hosts use it to drop a stored PIN
    /// the card rejected (`CardError.wrongPIN` / `.pinBlocked`) and to show remaining attempts (MAC-05, LNX-11).
    public var onSignResult: ((BridgeRequest, Error?) -> Void)?
    /// A listener failed, typically EADDRINUSE because the vendor Java server holds the port (MAC-08).
    /// See `isAddressInUse(_:)`.
    public var onListenerError: ((_ port: UInt16, _ error: Error) -> Void)?
    public private(set) var isRunning = false

    private let previewCertificates: [SigningService.CertificateSummary]?
    private let policy: BridgeOriginPolicy
    private let allowsFileSystemRoutes: Bool
    private let allowsLegacyDesktopClient: Bool
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
                httpsPort: UInt16 = MoldSignServer.defaultHTTPSPort,
                allowsFileSystemRoutes: Bool = true,
                allowsLegacyDesktopClient: Bool = false,
                previewCertificates: [SigningService.CertificateSummary]? = nil) {
        self.previewCertificates = previewCertificates
        self.allowsFileSystemRoutes = allowsFileSystemRoutes
        self.allowsLegacyDesktopClient = allowsLegacyDesktopClient
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
        try listen(plain, port: httpPort, isTLS: false)
        MSLog.info("MoldSign server replica (http) on http://127.0.0.1:\(httpPort)")

        // HTTPS with the localhost.cts.md identity (same cert the Java suite uses)
        if let data = tlsP12, let identity = Self.tlsIdentity(from: data) {
            let tlsOpts = NWProtocolTLS.Options()
            sec_protocol_options_set_min_tls_protocol_version(tlsOpts.securityProtocolOptions, .TLSv12)
            sec_protocol_options_set_local_identity(tlsOpts.securityProtocolOptions, identity)
            do {
                try listen(NWParameters(tls: tlsOpts), port: httpsPort, isTLS: true)
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
        stampStateLock.lock(); stampEpoch += 1; stampStateLock.unlock()
        workQueue.async { [weak self] in self?.stampSessions.removeAll() }
        isRunning = false
    }

    /// CLI entry point: start and park the main thread.
    public func run() throws -> Never {
        try start()
        MSLog.info("Ctrl+C to stop. Card operations will be performed on demand.")
        dispatchMain()
    }

    #if canImport(Network) && !MOLDSIGN_PORTABLE
    private func listen(_ params: NWParameters, port: UInt16, isTLS: Bool) throws {
        params.allowLocalEndpointReuse = true
        params.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: port)!)
        let listener = try NWListener(using: params)
        listener.newConnectionHandler = { [weak self] conn in self?.handle(conn, isTLS: isTLS) }
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

    private func handle(_ conn: NWConnection, isTLS: Bool) {
        conn.start(queue: queue)
        receiveFull(conn, into: Data()) { [weak self] (req: Data?) in
            guard let self = self, let req = req else { conn.cancel(); return }
            self.route(req, isTLS: isTLS) { resp in
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
        func handler(isTLS: Bool) -> (Data, @escaping (Data) -> Void) -> Void {
            { [weak self] raw, reply in
                guard let self else { return }
                self.queue.async { self.route(raw, isTLS: isTLS, reply: reply) }
            }
        }
        do {
            let http = try POSIXHTTPListener(port: httpPort, tls: nil, maxRequestBytes: Self.maxRequestBytes, handler: handler(isTLS: false))
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
            let https = try POSIXHTTPListener(port: httpsPort, tls: ctx, maxRequestBytes: Self.maxRequestBytes, handler: handler(isTLS: true))
            stopListeners.append { https.stop() }
            MSLog.info("MoldSign server replica (https) on https://localhost.cts.md:\(httpsPort)")
        } catch {
            MSLog.info("[ERR] listener :\(httpsPort) failed: \(error)")
            onListenerError?(httpsPort, error)
            if requireHTTPS { throw error }
        }
    }
    #endif

    static func httpComplete(_ data: Data) -> Bool { BridgeWireFormat.httpComplete(data) }
    static func queryItems(_ path: String) -> [String: String] { BridgeWireFormat.queryItems(path) }

    // MARK: - Routing

    private func route(_ raw: Data, isTLS: Bool, reply: @escaping (Data) -> Void) {
        guard let headEnd = raw.range(of: Data("\r\n\r\n".utf8)) else {
            reply(BridgeWireFormat.respond(400, "", contentType: "text/plain", origin: nil)); return
        }
        let head = String(decoding: raw[raw.startIndex..<headEnd.lowerBound], as: UTF8.self)
        let body = raw.subdata(in: headEnd.upperBound..<raw.endIndex)
        guard BridgeWireFormat.contentLength(head) == body.count else {
            reply(BridgeWireFormat.respond(400, "", contentType: "text/plain", origin: nil)); return
        }
        let lines = head.split(separator: "\r\n")
        let parts = lines.first?.split(separator: " ") ?? []
        guard parts.count >= 2 else { reply(BridgeWireFormat.respond(400, "", contentType: "text/plain", origin: nil)); return }
        let method = String(parts[0])
        let fullPath = String(parts[1])
        MSLog.info("[REQ] \(method) \(fullPath) body=\(body.count)B")
        // Request bodies may carry PINs or document content; never emit them to diagnostics.
        let path = fullPath.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)[0].description
        guard path.hasPrefix("/") else {
            reply(BridgeWireFormat.respond(400, "", contentType: "text/plain", origin: nil)); return
        }
        let query = Self.queryItems(fullPath)
        let caller = BridgeWireFormat.headerValue(head, "Origin")
        // Never reflect a caller-controlled authority into the async result Location.
        let host = isTLS ? "https://localhost.cts.md:\(httpsPort)" : "http://localhost.cts.md:\(httpPort)"
        let reply: (Data) -> Void = { [weak self] resp in
            let status = Int(String(decoding: resp.prefix(12).dropFirst(9), as: UTF8.self)) ?? 0
            self?.onEvent?(BridgeEvent(origin: caller, method: method, path: path, status: status))
            reply(resp)
        }

        // SEC-01: vendor allow-list on Origin; header-only auth for non-browser clients
        let legacyDesktop = allowsLegacyDesktopClient && allowsFileSystemRoutes && authorize != nil
            && caller == nil && BridgeWireFormat.headerValue(head, "Sec-Fetch-Site") == nil
            && Self.isLegacyDesktopRoute(method: method, path: path)
        guard policy.allows(origin: caller, moldSignHeader: BridgeWireFormat.headerValue(head, "moldSign")) || legacyDesktop else {
            MSLog.info("[DENY] origin=\(caller ?? "-")")
            reply(BridgeWireFormat.respondJSON(403, #"{"error":"origin not allowed"}"#, origin: nil))
            return
        }
        let origin = caller ?? "*"

        if method == "OPTIONS" {
            reply(BridgeWireFormat.respond(200, "", contentType: "text/plain", origin: origin,
                          extra: ["Access-Control-Allow-Methods: GET, POST, OPTIONS",
                                  "Access-Control-Allow-Private-Network: true"]))
            return
        }

        // Explicit certificate previews are enumeration-only and never touch a card or sign data.
        if previewCertificates != nil && !((method == "GET" && ["/hello", "/certificates", "/certificates/"].contains(path))
            || (method == "POST" && path == "/certificates/refresh")) {
            reply(BridgeWireFormat.respondJSON(403, #"{"error":"Demo identities: signing is disabled"}"#, origin: origin))
            return
        }

        // Sandboxed hosts accept document bytes, never filesystem paths supplied by a website.
        // Check before parsing payloads, creating sessions, or reaching consent/card operations.
        if previewCertificates == nil && !allowsFileSystemRoutes && !(path == "/certificates" || path == "/certificates/"
            || path == "/sign/data" || path.hasPrefix("/sign/data/PKCS11/")) {
            reply(BridgeWireFormat.respondJSON(403, #"{"error":"filesystem routes disabled"}"#, origin: origin))
            return
        }

        // Path-based document access is native-only, even for allowlisted browser origins.
        // Sec-Fetch-Site also rejects browser requests that omit Origin (e.g. same-origin GET).
        let isFileSystemRoute = path == "/sign/pdf" || path.hasPrefix("/sign/pdf/")
            || path == "/sign/file" || path.hasPrefix("/sign/file/")
            || path == "/verify/pdf" || path.hasPrefix("/verify/pdf/")
        if isFileSystemRoute && (caller != nil || BridgeWireFormat.headerValue(head, "Sec-Fetch-Site") != nil) {
            reply(BridgeWireFormat.respondJSON(403, #"{"error":"filesystem routes require a native client"}"#, origin: origin))
            return
        }

        switch (method, path) {
        case ("GET", "/hello"):
            reply(BridgeWireFormat.respond(200, "Hello world", contentType: "text/plain", origin: origin))
        case ("POST", "/certificates/refresh"):
            // listCards reads inserted certificates on every request; there is no stale provider cache.
            reply(BridgeWireFormat.respond(200, "", contentType: "application/json", origin: origin))
        case ("GET", "/certificates"), ("GET", "/certificates/"):
            workQueue.async { [weak self] in
                guard let self else { return }
                reply(BridgeWireFormat.respondJSON(200, self.certificatesJSON(), origin: origin))
            }
        case ("POST", "/sign/data"):
            let accept = BridgeWireFormat.headerValue(head, "Accept") ?? "application/json"
            reply(startSignData(body: body, accept: accept, caller: caller, origin: origin, host: host,
                                usePinSession: query["use_pin_session"]))
        case ("GET", _) where path.hasPrefix("/sign/data/PKCS11/"):
            poll(path: path, origin: origin, keepPinSession: query["keep_pin_session"] == "1", reply: reply)
        case ("POST", "/sign/pdf"):
            reply(startSignPDF(body: body, caller: caller, origin: origin, host: host, usePinSession: query["use_pin_session"]))
        case ("GET", _) where path.hasPrefix("/sign/pdf/PKCS11/"):
            poll(path: path, origin: origin, keepPinSession: query["keep_pin_session"] == "1", reply: reply)
        case ("POST", "/sign/file"):
            reply(startSignFile(body: body, caller: caller, origin: origin, host: host, usePinSession: query["use_pin_session"]))
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
            reply(BridgeWireFormat.respondJSON(404, #"{"error":"not found"}"#, origin: origin))
        }
    }

    /// The legacy Java desktop client omits the bridge header for these routes. Support is
    /// opt-in, unavailable to sandboxed hosts and CLI servers without a consent callback.
    /// Browser Origins (including null) still use the original allow-list without exceptions.
    static func isLegacyDesktopRoute(method: String, path: String) -> Bool {
        if method == "GET" {
            if path == "/hello" { return true }
            let components = path.split(separator: "/", omittingEmptySubsequences: false)
            return components.count == 5 && components[0].isEmpty && components[1] == "sign"
                && ["pdf", "file"].contains(components[2]) && components[3] == "PKCS11"
                && components[4].count == 24 && components[4].allSatisfy { $0.isHexDigit }
        }
        return method == "POST" && ["/certificates/refresh", "/sign/pdf", "/sign/file"].contains(path)
    }

    // MARK: - Responses

    /// `origin` nil → no CORS headers (denied callers get nothing a browser could read).

    /// `201 Created` exactly like the vendor's Jersey `Response.created(uri).header("sessionId", id)`: no body.
    /// mpass's jQuery login code continues only from `.fail`, i.e. when the empty body doesn't parse as JSON;
    /// a JSON body sends it to `.done`, where it does nothing (stuck on "Introduceți PIN-ul semnăturii").

    // MARK: - /certificates

    /// Every inserted card (several eID cards can be connected), like the vendor's GlobalCertificateProvider.
    /// Built with JSONSerialization: any holder name (diacritics, quotes, control bytes) stays valid JSON;
    /// the portal shows "no available signatures" for an empty list OR for a body it can't parse.
    private func certificatesJSON() -> String {
        let certificates = previewCertificates ?? SigningService.shared.listCards().map(\.certificate)
        let models: [[String: Any]] = certificates.enumerated().map { index, entry in
            let cert = entry.der
            let cn = entry.holder
            return [
                "certificateId": entry.sha1Hex,
                "label": cn + UUID().uuidString.prefix(4).lowercased(),
                "providerId": "libbit4xpki.dylib-\(index)",
                "policy": "1.2.498.3.32.1.1",
                "certificateName": "\(cn) (null) (1.2.498.3.32.1.1)",
                // decoded names (Java's X500Principal gives Unicode too), not the XAdES \XX escapes
                "subjectDN": entry.subjectDN,
                "issuerDN": entry.issuer,
                "authority": false, "trusted": true, "verified": 0, "privateKeyPresent": true,
                "certificateBase64": cert.base64EncodedString(),
            ]
        }
        let body = try? JSONSerialization.data(withJSONObject: ["certificateModel": models], options: [.withoutEscapingSlashes])
        return body.map { String(decoding: $0, as: UTF8.self) } ?? #"{"certificateModel":[]}"#
    }

    // MARK: - Small helpers

    // MARK: - Signing sessions

    /// Registers a pending session (called on `queue` from `route`) and runs `work` on the card queue.
    private func newSession(origin: String, _ work: @escaping (_ id: String, _ session: inout Session) -> Void) -> String {
        let id = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24))
        sessions[id] = Session(origin: origin)
        workQueue.async { [weak self] in
            var s = Session(origin: origin)
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
        guard let session = sessions[id], session.origin == origin else {
            reply(BridgeWireFormat.respondJSON(404, #"{"error":"unknown session"}"#, origin: origin, extra: ["error: unknown session"]))
            return
        }
        let answer: (Session) -> Void = { [weak self] s in
            guard let self else { return }
            // Clear after completion: an early long-poll must not leave a newly remembered PIN behind.
            if !keepPinSession { self.forgetPIN(session: id) }
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
        guard let error = s.error else { return BridgeWireFormat.respond(200, s.payload, contentType: s.contentType, origin: origin) }
        // header values must stay on one line and ASCII
        let headerSafe = String(error.unicodeScalars.map { $0.isASCII && $0.value >= 0x20 ? Character($0) : " " })
        return BridgeWireFormat.respond(400, s.payload, contentType: s.contentType, origin: origin, extra: ["error: \(headerSafe)"])
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
        let m = BridgeWireFormat.parseJSON(body)
        guard let dataB64 = m["data"] as? String, let raw = Data(base64Encoded: dataB64) else {
            return BridgeWireFormat.respondJSON(400, #"{"error":"missing data"}"#, origin: origin)
        }
        let contentType = (m["contentType"] as? String) ?? ""
        let signFormat = (m["signFormat"] as? String) ?? "XAdES-T"
        let algorithm = m["algorithm"] as? String
        let documentName = contentType.lowercased() == "pdf" ? "document.pdf" : nil
        let request = withCertificate(BridgeRequest(origin: caller, operation: .signData,
                                                    documentName: documentName, documentNames: documentName.map { [$0] } ?? [], contentBytes: raw.count,
                                                    format: contentType.lowercased() == "pdf" ? "PAdES-T" : signFormat,
                                                    pinIncluded: !((m["pin"] as? String) ?? "").isEmpty,
                                                    algorithm: algorithm, batchSession: usePinSession),
                                      BridgeWireFormat.certModel(fromJSON: m))
        let sessionId = newSession(origin: origin) { [weak self] id, s in
            guard let self = self else { return }
            do {
                let placement = contentType.lowercased() == "pdf" ? try self.stampPlacement(request, raw, batch: usePinSession ?? id) : nil
                // later documents of a portal batch reuse the PIN the first one signed with (no new consent)
                let reused = usePinSession.flatMap { self.reusablePIN(session: $0, origin: caller) }
                var auth = try reused ?? self.authorizedPIN(request, requestPIN: m["pin"] as? String)
                if contentType.lowercased() == "pdf" {
                    let tmp = FileManager.default.temporaryDirectory
                    let inURL = tmp.appendingPathComponent("msa-in-\(UUID().uuidString).pdf")
                    let outURL = tmp.appendingPathComponent("msa-out-\(UUID().uuidString).pdf")
                    try raw.write(to: inURL)
                    defer { try? FileManager.default.removeItem(at: inURL); try? FileManager.default.removeItem(at: outURL) }
                    let out = try self.signPDFFile(inURL, outURL, certJSON: BridgeWireFormat.certModel(fromJSON: m), auth: auth,
                                                   reader: try self.reader(for: auth, request), appearance: placement)
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
                                                     certJSON: BridgeWireFormat.certModel(fromJSON: m), auth: auth,
                                                     reader: try self.reader(for: auth, request))
                    auth = Authorization(pin: auth.pin, certificateSHA1: out.certificateSHA1)
                    s.payload = #"{"base64File":""# + out.data.base64EncodedString() + "\"}"
                }
                self.rememberPIN(auth, session: id, origin: caller)
                self.onSignResult?(request, nil)
            } catch {
                MSLog.info("[ERR] \(error)")
                s.error = Self.message(for: error)
                s.payload = #"{"error":""# + BridgeWireFormat.jsonEsc(s.error!) + "\"}"
                self.onSignResult?(request, error)
            }
        }
        return BridgeWireFormat.respondCreated(sessionId: sessionId, origin: origin,
                           location: "\(host)/sign/data/PKCS11/\(sessionId)/Any")
    }

    private func startSignPDF(body: Data, caller: String?, origin: String, host: String, usePinSession: String?) -> Data {
        var m = BridgeWireFormat.parseJSON(body)
        if m.isEmpty, body.contains("originalFile".data(using: .utf8)!) {
            m = ["originalFile": BridgeWireFormat.xmlField(body, "originalFile") ?? "",
                 "signedFile": BridgeWireFormat.xmlField(body, "signedFile") ?? "",
                 "pin": BridgeWireFormat.xmlField(body, "pin") ?? "",
                 "certificate": ["certificateBase64": BridgeWireFormat.xmlField(body, "certificateBase64") ?? ""]]
        }
        guard let origPath = m["originalFile"] as? String, !origPath.isEmpty else {
            return BridgeWireFormat.respondJSON(400, #"{"error":"missing originalFile"}"#, origin: origin)
        }
        let outPath: String
        if let sp = m["signedFile"] as? String, !sp.isEmpty { outPath = sp }
        else { outPath = origPath.replacingOccurrences(of: ".pdf", with: "-signed.pdf") }
        let documentName = URL(fileURLWithPath: origPath).lastPathComponent
        let contentBytes = (try? FileManager.default.attributesOfItem(atPath: origPath)[.size] as? NSNumber)?.intValue
        let request = withCertificate(BridgeRequest(origin: caller, operation: .signPDF,
                                                    documentName: documentName, documentNames: [documentName], contentBytes: contentBytes,
                                                    format: "PAdES-T", pinIncluded: !((m["pin"] as? String) ?? "").isEmpty),
                                      BridgeWireFormat.certModel(fromJSON: m))
        let sessionId = newSession(origin: origin) { [weak self] id, s in
            guard let self = self else { return }
            do {
                var auth = try usePinSession.flatMap { self.reusablePIN(session: $0, origin: caller) }
                    ?? self.authorizedPIN(request, requestPIN: m["pin"] as? String)
                let bytes = try Data(contentsOf: URL(fileURLWithPath: origPath))
                let placement = try self.stampPlacement(request, bytes, batch: usePinSession ?? id)
                let output = try self.signPDFFile(URL(fileURLWithPath: origPath), URL(fileURLWithPath: outPath),
                                         certJSON: BridgeWireFormat.certModel(fromJSON: m), auth: auth, reader: try self.reader(for: auth, request), appearance: placement)
                auth = Authorization(pin: auth.pin, certificateSHA1: output.certificateSHA1)
                self.rememberPIN(auth, session: id, origin: caller)
                s.payload = #"{"path":""# + BridgeWireFormat.jsonEsc(outPath) + "\"}"
                self.onSignResult?(request, nil)
            } catch {
                MSLog.info("[ERR] \(error)")
                s.error = Self.message(for: error)
                s.payload = #"{"error":""# + BridgeWireFormat.jsonEsc(s.error!) + "\"}"
                self.onSignResult?(request, error)
            }
        }
        return BridgeWireFormat.respondCreated(sessionId: sessionId, origin: origin,
                           location: "\(host)/sign/pdf/PKCS11/\(sessionId)")
    }

    private func startSignFile(body: Data, caller: String?, origin: String, host: String, usePinSession: String?) -> Data {
        let json = BridgeWireFormat.parseJSON(body)
        let wantsJSON = !json.isEmpty
        let files = json["filesToSign"] as? [String] ?? BridgeWireFormat.xmlFields(body, "filesToSign")
        guard !files.isEmpty else { return BridgeWireFormat.respondJSON(400, #"{"error":"missing filesToSign"}"#, origin: origin) }
        let signFormat = json["signFormat"] as? String ?? BridgeWireFormat.xmlField(body, "signFormat") ?? "XAdES-T"
        let sigType = (json["type"] as? String ?? BridgeWireFormat.xmlField(body, "type") ?? "Detached").lowercased() == "embedded" ? XAdESSigner.SigType.enveloping : .detached
        let certB64 = (json["certificate"] as? [String: Any])?["certificateBase64"] as? String ?? BridgeWireFormat.xmlField(body, "certificateBase64")
        let pinField = json["pin"] as? String ?? BridgeWireFormat.xmlField(body, "pin") ?? ""
        let dest = json["destinationFile"] as? String ?? BridgeWireFormat.xmlField(body, "destinationFile") ?? ""
        let signAlgorithm = json["signAlgorithm"] as? String ?? BridgeWireFormat.xmlField(body, "signAlgorithm")
        let digest = XAdESSigner.DigestAlgorithm(requested: signAlgorithm)
        let documentNames = files.map { URL(fileURLWithPath: $0).lastPathComponent }
        let sizes: [Int?] = files.map { path in
            (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? NSNumber)?.intValue
        }
        // Do not display a misleading partial total in the consent sheet.  The
        // app shows an explicit unavailable size if one caller-supplied path is
        // not inspectable by this process.
        let contentBytes = sizes.contains(where: { $0 == nil }) ? nil : sizes.compactMap { $0 }.reduce(0, +)
        let request = withCertificate(BridgeRequest(origin: caller, operation: .signFile,
                                                    documentName: documentNames.joined(separator: ", "), documentNames: documentNames, contentBytes: contentBytes,
                                                    format: signFormat, pinIncluded: !pinField.isEmpty, algorithm: signAlgorithm),
                                      certB64.flatMap { $0.isEmpty ? nil : Data(base64Encoded: $0) })
        let sessionId = newSession(origin: origin) { [weak self] id, s in
            guard let self = self else { return }
            s.contentType = wantsJSON ? "application/json" : "application/xml"
            do {
                let format: XAdESSigner.Format
                switch signFormat {
                case "XAdES-BES": format = .bes
                case "XAdES-C": format = .c
                default: format = .t
                }
                var auth = try usePinSession.flatMap { self.reusablePIN(session: $0, origin: caller) }
                    ?? self.authorizedPIN(request, requestPIN: pinField)
                let outPath = dest.isEmpty ? ((files.first.map { $0 + ".xades" }) ?? dest) : dest
                let signed = try SigningService.shared.withCard(reader: try self.reader(for: auth, request)) { card -> SignedOutput in
                    let cardCert = try card.prepareForSigning(pin: auth.pin,
                                                              expectedCertificateSHA1: auth.certificateSHA1 ?? request.certificateSHA1)
                    let cert: Data
                    if let b64 = certB64, !b64.isEmpty, let c = Data(base64Encoded: b64) { cert = c } else { cert = cardCert }
                    let signer = XAdESSigner()
                    let output = try signer.sign(files: files.map { URL(fileURLWithPath: $0) }, format: format,
                                           type: sigType, digest: digest, certDER: cert, chainDER: [ChainCerts.mdQSign],
                                           signBlock: { bytes in try card.sign(digestInfo: digest.digestInfo(of: bytes)) },
                                           tsaBlock: { data in try PAdESSigner.fetchTimestampToken(data: data) },
                                           ocspDerBlock: { issuer, c in try XAdESSigner.fetchOCSPResponse(issuerDER: issuer, certDER: c) })
                    return SignedOutput(data: output, certificateSHA1: cardCert.sha1().hexString.lowercased())
                }
                try signed.data.write(to: URL(fileURLWithPath: outPath))
                auth = Authorization(pin: auth.pin, certificateSHA1: signed.certificateSHA1)
                self.rememberPIN(auth, session: id, origin: caller)
                if wantsJSON {
                    s.payload = "{\"fileLocation\":\"\(BridgeWireFormat.jsonEsc(outPath))\",\"signatures\":[]}"
                } else {
                    s.payload = "<XadesSignatureModelContainer><fileLocation>\(BridgeWireFormat.xmlEsc(outPath))</fileLocation><signatures/></XadesSignatureModelContainer>"
                }
                self.onSignResult?(request, nil)
            } catch {
                MSLog.info("[ERR] \(error)")
                s.error = Self.message(for: error)
                s.payload = wantsJSON ? "{\"error\":\"\(BridgeWireFormat.jsonEsc(s.error!))\"}" : "<error>\(BridgeWireFormat.xmlEsc(s.error!))</error>"
                self.onSignResult?(request, error)
            }
        }
        return BridgeWireFormat.respondCreated(sessionId: sessionId, origin: origin,
                           location: "\(host)/sign/file/PKCS11/\(sessionId)")
    }

    private func startVerifyFile(body: Data, origin: String, host: String) -> Data {
        let files = BridgeWireFormat.xmlFields(body, "signedFiles")
        let sigPath = BridgeWireFormat.xmlField(body, "signature") ?? ""
        MSLog.debug("[VFY-REQ] signedFiles=\(files) sig=\(sigPath)")
        let sessionId = newSession(origin: origin) { _, s in
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
        return BridgeWireFormat.respondCreated(sessionId: sessionId, origin: origin,
                           location: "\(host)/sign/file/verify/\(sessionId)")
    }

    private func startVerifyPDF(body: Data, origin: String, host: String) -> Data {
        let pdfPath = BridgeWireFormat.xmlField(body, "signedFile") ?? BridgeWireFormat.xmlField(body, "originalFile") ?? ""
        let sessionId = newSession(origin: origin) { _, s in
            var valid = false
            if let d = try? Data(contentsOf: URL(fileURLWithPath: pdfPath)) {
                let rep = Validator.validatePDF(d)
                valid = !rep.isEmpty && rep.allSatisfy { $0.contentIntact && $0.signatureValid }
            }
            s.contentType = "application/xml"
            s.payload = "<verifyPdfResponseModel><valid>\(valid)</valid></verifyPdfResponseModel>"
        }
        return BridgeWireFormat.respondCreated(sessionId: sessionId, origin: origin,
                           location: "\(host)/sign/pdf/verify/\(sessionId)")
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
        if let credentialCard = auth.certificateSHA1, let requestedCard = request.certificateSHA1,
           credentialCard.caseInsensitiveCompare(requestedCard) != .orderedSame {
            throw CardError.cardChanged
        }
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
                             reader: String?, appearance: PDFStampPlacement? = nil) throws -> SignedOutput {
        let pdf = try Data(contentsOf: inURL)
        try appearance?.validate(document: pdf)
        if let appearance, !StampPDF.canApply(appearance, to: pdf) { throw StampPDF.fail() }
        let expected = auth.certificateSHA1 ?? certJSON.map { $0.sha1().hexString.lowercased() }
        let out = try SigningService.shared.withCard(reader: reader) { card -> SignedOutput in
            let cardCert = try card.prepareForSigning(pin: auth.pin, expectedCertificateSHA1: expected)
            let signed = try PAdESSigner().signPDF(pdf, certDER: certJSON ?? cardCert, appearance: appearance) { di in
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
