import Foundation

/// HTTP/XML/JSON wire encoding, independent of listeners, card operations and consent state.
enum BridgeWireFormat {
    static func httpComplete(_ d: Data) -> Bool {
        guard let r = d.range(of: Data("\r\n\r\n".utf8)) else { return false }
        let head = String(decoding: d[d.startIndex..<r.lowerBound], as: UTF8.self)
        // Invalid framing is complete enough to reject; do not wait forever for an impossible length.
        guard let length = contentLength(head) else { return true }
        return d.distance(from: r.upperBound, to: d.endIndex) >= length
    }

    /// This bridge accepts one fixed-length request per connection, never chunked/pipelined requests.
    static func contentLength(_ head: String) -> Int? {
        var length: Int?
        for line in head.split(separator: "\r\n").dropFirst() {
            let pair = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard pair.count == 2 else { return nil }
            let name = pair[0].trimmingCharacters(in: .whitespaces).lowercased()
            if name == "transfer-encoding" { return nil }
            guard name == "content-length" else { continue }
            let value = pair[1].trimmingCharacters(in: .whitespaces)
            guard length == nil, !value.isEmpty, value.utf8.allSatisfy({ (48...57).contains($0) }),
                  let parsed = Int(value) else { return nil }
            length = parsed
        }
        return length ?? 0
    }

    static func headerValue(_ head: String, _ name: String) -> String? {
        for line in head.split(separator: "\r\n") {
            if line.lowercased().hasPrefix(name.lowercased() + ":") {
                return line.dropFirst(name.count + 1).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    static func respond(_ status: Int, _ body: String, contentType: String,
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

    static func respondCreated(sessionId: String, origin: String?, location: String) -> Data {
        respond(201, "", contentType: "text/plain", origin: origin, extra: ["Location: \(location)", "sessionId: \(sessionId)"])
    }

    static func respondJSON(_ status: Int, _ json: String, origin: String?, extra: [String] = []) -> Data {
        respond(status, json, contentType: "application/json", origin: origin, extra: extra)
    }

    static func jsonEsc(_ value: String) -> String {
        // JSON escaping must include control characters, not only quotes and backslashes.
        guard let encoded = try? JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed]),
              let quoted = String(data: encoded, encoding: .utf8) else { return "" }
        return String(quoted.dropFirst().dropLast())
    }

    static func xmlField(_ body: Data, _ name: String) -> String? {
        let t = String(decoding: body, as: UTF8.self)
        guard let r = t.range(of: "<\(name)>"), let e = t.range(of: "</\(name)>", range: r.upperBound..<t.endIndex) else { return nil }
        return String(t[r.upperBound..<e.lowerBound])
    }

    static func xmlFields(_ body: Data, _ name: String) -> [String] {
        let t = String(decoding: body, as: UTF8.self)
        var out: [String] = []
        guard let re = try? NSRegularExpression(pattern: "<\(name)>([^<]*)</\(name)>") else { return out }
        let ns = t as NSString
        for m in re.matches(in: t, range: NSRange(location: 0, length: ns.length)) {
            out.append(ns.substring(with: m.range(at: 1)))
        }
        return out
    }

    static func parseJSON(_ body: Data) -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: body)) as? [String: Any] ?? [:]
    }

    static func certModel(fromJSON m: [String: Any]) -> Data? {
        guard let c = m["certificate"] as? [String: Any],
              let b64 = c["certificateBase64"] as? String, !b64.isEmpty else { return nil }
        return Data(base64Encoded: b64)
    }

    static func queryItems(_ fullPath: String) -> [String: String] {
        guard let q = fullPath.split(separator: "?", maxSplits: 1).dropFirst().first else { return [:] }
        var out: [String: String] = [:]
        for pair in q.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
            guard let key = kv.first, !key.isEmpty else { continue }
            out[key] = kv.count > 1 ? (kv[1].removingPercentEncoding ?? kv[1]) : ""
        }
        return out
    }

    static func xmlEsc(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }
}
