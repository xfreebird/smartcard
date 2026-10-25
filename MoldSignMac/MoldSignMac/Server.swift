import Foundation
import Network

/// Drop-in replica of the MoldSign Server (127.0.0.1:18480) protocol so the
/// msign.gov.md browser "Sign with MoldSign" flow works without the Java suite.
final class MoldSignServer {
    struct Session {
        var ready = false
        var payload = ""       // JSON body for the poll response
        var contentType = "application/json"
    }

    private var sessions: [String: Session] = [:]
    private let queue = DispatchQueue(label: "msign-server")
    private static let p12Password = "u9mUvI9BNb1U9jSbpBKf36YWINVK5XX5KAzql3bILNnjscVfLn"

    /// Load the localhost.cts.md identity (exported from the MoldSign suite keystore).
    private static func tlsIdentity() -> sec_identity_t? {
        let paths = [
            "/Applications/STISC/MoldSign/MoldSignData/Server/localhost.p12",
            NSHomeDirectory() + "/Projects/smartcard/MoldSignMac/Resources/localhost.p12",
        ]
        for path in paths {
            guard let data = FileManager.default.contents(atPath: path) else { continue }
            var items: CFArray?
            let status = SecPKCS12Import(data as CFData, [kSecImportExportPassphrase: p12Password] as CFDictionary, &items)
            guard status == errSecSuccess,
                  let arr = items as? [[String: Any]], let first = arr.first,
                  let identity = first[kSecImportItemIdentity as String] else { continue }
            return sec_identity_create(identity as! SecIdentity)
        }
        return nil
    }

    func run() throws {
        // plain HTTP on 18480
        let plain = NWParameters.tcp
        plain.allowLocalEndpointReuse = true
        let l1 = try NWListener(using: plain, on: 18480)
        l1.newConnectionHandler = { [weak self] conn in self?.handle(conn) }
        l1.start(queue: queue)
        print("MoldSign server replica (http) on http://127.0.0.1:18480")

        // HTTPS on 18443 with the localhost.cts.md identity (same cert the Java suite uses)
        if let identity = Self.tlsIdentity() {
            let tlsOpts = NWProtocolTLS.Options()
            sec_protocol_options_set_min_tls_protocol_version(tlsOpts.securityProtocolOptions, .TLSv12)
            sec_protocol_options_set_local_identity(tlsOpts.securityProtocolOptions, identity)
            let secure = NWParameters(tls: tlsOpts)
            secure.allowLocalEndpointReuse = true
            if let l2 = try? NWListener(using: secure, on: 18443) {
                l2.newConnectionHandler = { [weak self] conn in self?.handle(conn) }
                l2.start(queue: queue)
                print("MoldSign server replica (https) on https://localhost.cts.md:18443")
            }
        } else {
            print("WARNING: localhost.p12 not found — https listener disabled")
        }
        print("Ctrl+C to stop. Card operations will be performed on demand.")
        dispatchMain()
    }

    // MARK: - Connection handling

    private func handle(_ conn: NWConnection) {
        conn.start(queue: queue)
        receiveFull(conn, into: Data()) { [weak self] (req: Data?) in
            guard let self = self, let req = req else { conn.cancel(); return }
            let resp = self.route(req)
            conn.send(content: resp, completion: .contentProcessed { _ in conn.cancel() })
        }
    }

    private func receiveFull(_ conn: NWConnection, into acc: Data, done: @escaping (Data?) -> Void) {
        conn.receive(minimumIncompleteLength: 1, maximumLength: 1 << 22) { data, _, isComplete, err in
            var acc = acc
            if let data = data { acc.append(data) }
            if Self.httpComplete(acc) || isComplete || err != nil {
                done(err == nil && !acc.isEmpty ? acc : nil)
            } else {
                self.receiveFull(conn, into: acc, done: done)
            }
        }
    }

    private static func httpComplete(_ d: Data) -> Bool {
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

    private func route(_ raw: Data) -> Data {
        let headEnd = raw.range(of: Data("\r\n\r\n".utf8))!
        let head = String(decoding: raw[raw.startIndex..<headEnd.lowerBound], as: UTF8.self)
        let body = raw.subdata(in: headEnd.upperBound..<raw.endIndex)
        let lines = head.split(separator: "\r\n")
        let parts = lines[0].split(separator: " ")
        let method = String(parts[0])
        let fullPath = String(parts[1])
        print("[REQ] \(method) \(fullPath) body=\(body.count)B")
        if body.count > 0, body.count < 4000 {
            FileHandle.standardOutput.write(Data(("[BODY] " + String(decoding: body, as: UTF8.self).prefix(800) + "\n").utf8))
        }
        let path = fullPath.split(separator: "?")[0].description
        let origin = headerValue(head, "Origin") ?? "*"
        let host = headerValue(head, "Host") ?? "localhost.cts.md:18443"

        if method == "OPTIONS" {
            return respond(200, "", contentType: "text/plain", origin: origin,
                           extra: ["Access-Control-Allow-Methods: GET, POST, OPTIONS"])
        }

        switch (method, path) {
        case ("GET", "/certificates"), ("GET", "/certificates/"):
            return respondJSON(200, certificatesJSON(), origin: origin)
        case ("POST", "/sign/data"):
            let accept = headerValue(head, "Accept") ?? "application/json"
            return startSignData(body: body, accept: accept, origin: origin, host: host)
        case ("GET", _) where path.hasPrefix("/sign/data/PKCS11/"):
            return poll(path: path, origin: origin, host: host)
        case ("POST", "/sign/pdf"):
            return startSignPDF(body: body, origin: origin, host: host)
        case ("GET", _) where path.hasPrefix("/sign/pdf/PKCS11/"):
            return poll(path: path, origin: origin, host: host)
        case ("POST", "/sign/file"):
            return startSignFile(body: body, origin: origin, host: host)
        case ("GET", _) where path.hasPrefix("/sign/file/PKCS11/"):
            return poll(path: path, origin: origin, host: host)
        case ("POST", "/sign/file/verify"):
            return startVerifyFile(body: body, origin: origin, host: host)
        case ("GET", _) where path.hasPrefix("/sign/file/verify/"):
            return poll(path: path, origin: origin, host: host)
        case ("POST", "/verify/pdf"), ("POST", "/sign/pdf/verify"):
            return startVerifyPDF(body: body, origin: origin, host: host)
        case ("GET", _) where path.hasPrefix("/sign/pdf/verify/"):
            return poll(path: path, origin: origin, host: host)
        default:
            return respondJSON(404, #"{"error":"not found"}"#, origin: origin)
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

    private func respond(_ status: Int, _ body: String, contentType: String,
                         origin: String, extra: [String] = []) -> Data {
        let statusText = [200: "OK", 201: "Created", 303: "See Other", 400: "Bad Request",
                          401: "Unauthorized", 404: "Not Found", 500: "Internal Server Error"][status] ?? "OK"
        var head = "HTTP/1.1 \(status) \(statusText)\r\n" +
            "Content-Type: \(contentType)\r\n" +
            "Content-Length: \(body.utf8.count)\r\n" +
            "Access-Control-Allow-Origin: \(origin)\r\n" +
            "Access-Control-Allow-Headers: Origin, x-requested-with, content-type, accept, error, Location\r\n" +
            "Access-Control-Expose-Headers: Origin, x-requested-with, content-type, accept, error, Location\r\n" +
            "Connection: close\r\n"
        for e in extra { head += e + "\r\n" }
        head += "\r\n"
        return Data(head.utf8) + Data(body.utf8)
    }

    private func respondJSON(_ status: Int, _ json: String, origin: String, extra: [String] = []) -> Data {
        respond(status, json, contentType: "application/json", origin: origin, extra: extra)
    }

    // MARK: - /certificates

    private func certificatesJSON() -> String {
        let card = CosmoXCard()
        do {
            try card.connect()
            try card.authenticate()
            try card.selectMF()
            try card.selectGenericADF()
            let cert = try card.readCertificate()
            card.disconnect()
            let subj = (try? XAdESSigner.parseSubject(cert)) ?? ""
            let issuer = (try? XAdESSigner.parseIssuer(cert).issuerDNRFC2253Named) ?? ""
            let sha1 = cert.sha1().hexString.lowercased()
            let cn = Validator.subjectCN(cert) ?? "Certificate"
            let label = cn + UUID().uuidString.prefix(4).lowercased()
            let b64 = cert.base64EncodedString()
            return """
            {"certificateModel":[{"certificateId":"\(sha1)","label":"\(label)","providerId":"libbit4xpki.dylib-0","policy":"1.2.498.3.32.1.1","certificateName":"\(jsonEsc(cn)) (null) (1.2.498.3.32.1.1)","subjectDN":"\(jsonEsc(subj))","issuerDN":"\(jsonEsc(issuer))","authority":false,"trusted":true,"verified":0,"privateKeyPresent":true,"certificateBase64":"\(b64)"}]}
            """
        } catch {
            return #"{"certificateModel":[]}"#
        }
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

    private func xmlCertBase64(_ body: Data) -> Data? {
        xmlField(body, "certificateBase64").flatMap { Data(base64Encoded: $0) }
    }

    // MARK: - Signing sessions

    private func newSession(_ work: @escaping (inout Session) -> Void) -> String {
        let id = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24))
        queue.async { [weak self] in
            var s = Session()
            work(&s)
            s.ready = true
            self?.sessions[id] = s
        }
        return id
    }

    private func poll(path: String, origin: String, host: String = "") -> Data {
        let id = path.split(separator: "/").dropFirst(3).first.map(String.init) ?? ""
        if let s = sessions[id], s.ready {
            sessions.removeValue(forKey: id)
            return respond(200, s.payload, contentType: s.contentType, origin: origin)
        }
        return respond(303, "", contentType: "text/plain", origin: origin,
                       extra: ["Location: https://\(host.isEmpty ? "localhost.cts.md:18443" : host)\(path)"])
    }

    private func parseJSON(_ body: Data) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: body)) as? [String: Any] ?? [:]
    }

    private func certModel(fromJSON m: [String: Any]) -> Data? {
        guard let c = m["certificate"] as? [String: Any],
              let b64 = c["certificateBase64"] as? String, !b64.isEmpty else { return nil }
        return Data(base64Encoded: b64)
    }

    /// Read the PIN from JSON or show a native PIN dialog (like the Java suite does).
    private func obtainPIN(json: [String: Any]) -> String {
        if let pin = json["pin"] as? String, !pin.isEmpty { return pin }
        if let envPin = ProcessInfo.processInfo.environment["MSIGN_PIN"], !envPin.isEmpty { return envPin }
        return promptPINNative() ?? ""
    }

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

    private func startSignData(body: Data, accept: String, origin: String, host: String) -> Data {
        let m = parseJSON(body)
        guard let dataB64 = m["data"] as? String, let raw = Data(base64Encoded: dataB64) else {
            return respondJSON(400, #"{"error":"missing data"}"#, origin: origin)
        }
        let contentType = (m["contentType"] as? String) ?? ""
        let signFormat = (m["signFormat"] as? String) ?? "XAdES-T"
        let sessionId = newSession { [weak self] s in
            guard let self = self else { return }
            do {
                let pin = self.obtainPIN(json: m)
                if contentType.lowercased() == "pdf" {
                    let tmp = FileManager.default.temporaryDirectory
                    let inURL = tmp.appendingPathComponent("msa-in-\(UUID().uuidString).pdf")
                    let outURL = tmp.appendingPathComponent("msa-out-\(UUID().uuidString).pdf")
                    try raw.write(to: inURL)
                    let outData = try self.signPDFFile(inURL, outURL, certJSON: certModel(fromJSON: m), pin: pin)
                    s.payload = #"{"base64File":""# + outData.base64EncodedString() + "\"}"
                } else {
                    let format: XAdESSigner.Format
                    switch signFormat {
                    case "XAdES-BES": format = .bes
                    case "XAdES-C": format = .c
                    default: format = .t
                    }
                    let outData = try self.signXAdESData(raw, format: format,
                                                         embedded: (m["signatureType"] as? String) != "Detached",
                                                         certJSON: certModel(fromJSON: m), pin: pin)
                    s.payload = #"{"base64File":""# + outData.base64EncodedString() + "\"}"
                }
            } catch {
                print("[ERR] \(error)")
                s.payload = #"{"error":""# + self.jsonEsc(String(describing: error)) + "\"}"
            }
        }
        return respondJSON(201, #"{"sessionId":""# + sessionId + "\"}", origin: origin,
                           extra: ["Location: https://\(host)/sign/data/PKCS11/\(sessionId)/Any"])
    }

    private func startSignPDF(body: Data, origin: String, host: String) -> Data {
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
        let sessionId = newSession { [weak self] s in
            guard let self = self else { return }
            do {
                let pin = self.obtainPIN(json: m)
                _ = try self.signPDFFile(URL(fileURLWithPath: origPath), URL(fileURLWithPath: outPath),
                                         certJSON: certModel(fromJSON: m), pin: pin)
                s.payload = #"{"path":""# + self.jsonEsc(outPath) + "\"}"
            } catch {
                print("[ERR] \(error)")
                s.payload = #"{"error":""# + self.jsonEsc(String(describing: error)) + "\"}"
            }
        }
        return respondJSON(201, #"{"sessionId":""# + sessionId + "\"}", origin: origin,
                           extra: ["Location: https://\(host)/sign/pdf/PKCS11/\(sessionId)"])
    }

    private func startSignFile(body: Data, origin: String, host: String) -> Data {
        let files = xmlFields(body, "filesToSign")
        let signFormat = xmlField(body, "signFormat") ?? "XAdES-T"
        let sigType = (xmlField(body, "type") ?? "Detached").lowercased() == "embedded" ? XAdESSigner.SigType.enveloping : .detached
        let certB64 = xmlField(body, "certificateBase64")
        let pinField = xmlField(body, "pin") ?? ""
        let dest = xmlField(body, "destinationFile") ?? ""
        let sessionId = newSession { [weak self] s in
            guard let self = self else { return }
            s.contentType = "application/xml"
            do {
                let format: XAdESSigner.Format
                switch signFormat {
                case "XAdES-BES": format = .bes
                case "XAdES-C": format = .c
                default: format = .t
                }
                var m: [String: Any] = ["pin": pinField]
                if let b = certB64 { m["certificate"] = ["certificateBase64": b] }
                let pin = pinField.isEmpty ? self.obtainPIN(json: m) : pinField
                let outPath = dest.isEmpty ? ((files.first.map { $0 + ".xades" }) ?? dest) : dest
                let cert: Data
                if let b64 = certB64, let c = Data(base64Encoded: b64) { cert = c }
                else { cert = try self.cardCert(pin: pin) }
                let card = CosmoXCard()
                try card.connect()
                try card.authenticate()
                try card.selectMF()
                try card.selectGenericADF()
                try card.verifyPIN(pin)
                let signer = XAdESSigner()
                let out = try signer.sign(files: files.map { URL(fileURLWithPath: $0) }, format: format,
                                          type: sigType, certDER: cert, chainDER: [ChainCerts.mdQSign],
                                          signBlock: { bytes in
                                              try card.sign(digestInfo: XAdESSigner.digestInfoForSHA256(bytes.sha256()))
                                          },
                                          tsaBlock: { data in try PAdESSigner.fetchTimestampToken(data: data) },
                                          ocspDerBlock: { issuer, c in try XAdESSigner.fetchOCSPResponse(issuerDER: issuer, certDER: c) })
                card.disconnect()
                try out.write(to: URL(fileURLWithPath: outPath))
                s.payload = "<XadesSignatureModelContainer><fileLocation>\(self.xmlEsc(outPath))</fileLocation><signatures/></XadesSignatureModelContainer>"
            } catch {
                print("[ERR] \(error)")
                s.payload = "<error>\(self.xmlEsc(String(describing: error)))</error>"
            }
        }
        return respondJSON(201, #"{"sessionId":""# + sessionId + "\"}", origin: origin,
                           extra: ["Location: https://\(host)/sign/file/PKCS11/\(sessionId)"])
    }

    private func startVerifyFile(body: Data, origin: String, host: String) -> Data {
        let files = xmlFields(body, "signedFiles")
        let sigPath = xmlField(body, "signature") ?? ""
        print("[VFY-REQ] signedFiles=\(files) sig=\(sigPath)")
        let sessionId = newSession { [weak self] s in
            guard let self = self else { return }
            var filesMap: [String: Data] = [:]
            for f in files {
                filesMap[URL(fileURLWithPath: f).lastPathComponent] = try? Data(contentsOf: URL(fileURLWithPath: f))
            }
            var valid = false
            if let sigData = try? Data(contentsOf: URL(fileURLWithPath: sigPath)) {
                let rep = Validator.validateXAdES(sigData, referencedFiles: filesMap)
                for r0 in rep { print("[VFY] \(r0.summary)") }
                if rep.isEmpty { print("[VFY] no reports; sigPath=\(sigPath) filesMap=\(filesMap.keys)") }
                valid = !rep.isEmpty && rep.allSatisfy { $0.contentIntact && $0.signatureValid }
            } else { print("[VFY] cannot read sig at \(sigPath)") }
            s.contentType = "application/xml"
            s.payload = "<verifySignedFileResponseModel><valid>\(valid)</valid></verifySignedFileResponseModel>"
        }
        return respondJSON(201, #"{"sessionId":""# + sessionId + "\"}", origin: origin,
                           extra: ["Location: https://\(host)/sign/file/verify/\(sessionId)"])
    }

    private func startVerifyPDF(body: Data, origin: String, host: String) -> Data {
        let pdfPath = xmlField(body, "signedFile") ?? xmlField(body, "originalFile") ?? ""
        let sessionId = newSession { s in
            var valid = false
            if let d = try? Data(contentsOf: URL(fileURLWithPath: pdfPath)) {
                let rep = Validator.validatePDF(d)
                valid = !rep.isEmpty && rep.allSatisfy { $0.contentIntact && $0.signatureValid }
            }
            s.contentType = "application/xml"
            s.payload = "<verifyPdfResponseModel><valid>\(valid)</valid></verifyPdfResponseModel>"
        }
        return respondJSON(201, #"{"sessionId":""# + sessionId + "\"}", origin: origin,
                           extra: ["Location: https://\(host)/sign/pdf/verify/\(sessionId)"])
    }

    private func cardCert(pin: String) throws -> Data {
        let card = CosmoXCard()
        try card.connect()
        try card.authenticate()
        try card.selectMF()
        try card.selectGenericADF()
        let cert = try card.readCertificate()
        card.disconnect()
        return cert
    }

    private func xmlEsc(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }

    // MARK: - Signing drivers

    @discardableResult
    private func signPDFFile(_ inURL: URL, _ outURL: URL, certJSON: Data?, pin: String) throws -> Data {
        let card = CosmoXCard()
        try card.connect()
        try card.authenticate()
        try card.selectMF()
        try card.selectGenericADF()
        try card.verifyPIN(pin)
        let cert: Data
        if let cj = certJSON { cert = cj } else { cert = try card.readCertificate() }
        let pdf = try Data(contentsOf: inURL)
        let signer = PAdESSigner()
        let signed = try signer.signPDF(pdf, certDER: cert) { di in
            try card.sign(digestInfo: di)
        }
        try signed.write(to: outURL)
        card.disconnect()
        return signed
    }

    private func signXAdESData(_ raw: Data, format: XAdESSigner.Format, embedded: Bool,
                               certJSON: Data?, pin: String) throws -> Data {
        let card = CosmoXCard()
        try card.connect()
        try card.authenticate()
        try card.selectMF()
        try card.selectGenericADF()
        try card.verifyPIN(pin)
        let cert: Data
        if let cj = certJSON { cert = cj } else { cert = try card.readCertificate() }
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("msa-xades-\(UUID().uuidString).xml")
        try raw.write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }
        let signer = XAdESSigner()
        let out = try signer.sign(files: [tmp], format: format, certDER: cert,
                                  chainDER: [ChainCerts.mdQSign],
                                  signBlock: { bytes in
                                      try card.sign(digestInfo: XAdESSigner.digestInfoForSHA256(bytes.sha256()))
                                  },
                                  tsaBlock: { data in try PAdESSigner.fetchTimestampToken(data: data) },
                                  ocspDerBlock: { issuer, c in try XAdESSigner.fetchOCSPResponse(issuerDER: issuer, certDER: c) })
        card.disconnect()
        return out
    }
}
