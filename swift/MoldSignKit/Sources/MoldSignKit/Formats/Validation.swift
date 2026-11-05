import Foundation

/// Offline signature validation for PAdES PDFs and XAdES documents produced by
/// this app or the MoldSign middleware. No card required.
public enum Validator {

    public struct Report {
        public var certificateDetails: [String: String] = [:]
        public var signerIDNP: String? {
            guard let value = certificateDetails["Subject · Personal identifier"], value.count == 13, value.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
            return value
        }
        public var kind: String              // "PAdES" / "XAdES"
        public var name: String              // signature field name or Signature Id
        public var signer: String            // CN from signing cert
        public var contentIntact: Bool       // referenced content digest matches
        public var signatureValid: Bool      // RSA signature over attrs/SignedInfo valid
        public var chainTrusted: Bool        // chain builds to embedded mdtrustca root
        public var signingTime: String
        public var timestampTime: String?    // RFC3161 genTime if present
        public var level: String             // "PAdES-B-T" / "XAdES-C" etc.

        public var summary: String {
            let ok = contentIntact && signatureValid
            return "\(name): \(ok ? "VALID" : "INVALID") — \(signer), \(level)" +
                   ", signed \(signingTime)" + (timestampTime.map { ", tst \($0)" } ?? "") +
                   ", chain \(chainTrusted ? "trusted" : "untrusted")" +
                   (contentIntact ? "" : ", content modified!") +
                   (signatureValid ? "" : ", bad signature!")
        }
    }

    public static func readableDate(_ value: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        for format in ["yyMMddHHmmss'Z'", "yyyyMMddHHmmss'Z'", "yyyy-MM-dd'T'HH:mm:ssXXXXX"] {
            parser.dateFormat = format
            if let date = parser.date(from: value) {
                return date.formatted(date: .abbreviated, time: .standard)
            }
        }
        return value
    }

    static func certificateDetails(_ rawDER: Data) -> [String: String] {
        guard let (header, length) = try? DER.header(rawDER, at: 0), header + length <= rawDER.count else { return [:] }
        let der = Data(rawDER.prefix(header + length))
        let cert = SigningService.CertificateSummary(der: der)
        var details = ["Serial number": cert.serialDecimal, "SHA-256 fingerprint": der.sha256().hexString]
        let labels = ["CN": "Name", "SN": "Surname", "GN": "Given names", "serialNumber": "Personal identifier",
                      "C": "Country", "L": "City", "ST": "Region", "O": "Organization", "OU": "Department",
                      "organizationIdentifier": "Organization identifier", "2.5.4.20": "Telephone", "T": "Title"]
        for (group, subject) in [("Subject", true), ("Issuer", false)] {
            if let name = try? XAdESSigner.nameDER(der, subject: subject) {
                for attribute in X509Name.attributes(name) {
                    let key = group + " · " + (labels[attribute.type] ?? attribute.type)
                    details[key] = details[key].map { $0 + "; " + attribute.value } ?? attribute.value
                }
            }
        }
        if let date = (try? X509Validity(der))?.notBefore { details["Valid from"] = date.formatted(date: .abbreviated, time: .standard) }
        if let date = cert.notAfter { details["Valid until"] = date.formatted(date: .abbreviated, time: .standard) }
        func children(_ data: Data) -> [(UInt8, Data)] {
            guard let (header, length) = try? DER.header(data, at: 0), header + length <= data.count else { return [] }
            var result: [(UInt8, Data)] = [], position = header
            while position < header + length {
                guard let (h, n) = try? DER.header(data, at: position), position + h + n <= data.count else { break }
                result.append((data[position], Data(data[(position + h)..<(position + h + n)])))
                position += h + n
            }
            return result
        }
        // Inspect SubjectPublicKeyInfo without relying on a platform trust service.
        let outerHeader = (try? DER.header(der, at: 0))?.0 ?? 0
        if outerHeader < der.count, let (h, n) = try? DER.header(der, at: outerHeader), outerHeader + h + n <= der.count {
            let tbs = Data(der[outerHeader..<(outerHeader + h + n)])
            let fields = children(tbs)
            let keyIndex = fields.first?.0 == 0xA0 ? 6 : 5
            if fields.indices.contains(keyIndex) {
                let spki = children(Data([0x30]) + lengthBytes(fields[keyIndex].1.count) + fields[keyIndex].1)
                if spki.count > 1, spki[1].1.count > 1 {
                    let rsa = children(Data(spki[1].1.dropFirst()))
                    if let modulus = rsa.first, modulus.0 == 0x02 {
                        let bytes = modulus.1.drop(while: { $0 == 0 })
                        details["Public key"] = "RSA \(bytes.count * 8) bits"
                    }
                }
            }
        }
        func sequence(_ content: Data) -> Data { Data([0x30]) + lengthBytes(content.count) + content }
        func dotted(_ bytes: Data) -> String {
            guard let first = bytes.first else { return "" }
            var parts = [Int(first) / 40, Int(first) % 40], value = 0
            for byte in bytes.dropFirst() {
                value = (value << 7) | Int(byte & 0x7f)
                if byte & 0x80 == 0 { parts.append(value); value = 0 }
            }
            return parts.map(String.init).joined(separator: ".")
        }
        func strings(_ data: Data, depth: Int = 0) -> [String] {
            guard depth < 20, let tag = data.first, let (h, n) = try? DER.header(data, at: 0), h + n <= data.count else { return [] }
            let content = Data(data[h..<(h + n)])
            if tag == 0x86 || tag == 0x81 || tag == 0x82 || tag == 0x16 { return [String(decoding: content, as: UTF8.self)] }
            if tag & 0x20 != 0 { return children(data).flatMap { strings(Data([$0.0]) + lengthBytes($0.1.count) + $0.1, depth: depth + 1) } }
            return []
        }
        let certificate = children(der)
        if let tbs = certificate.first {
            let fields = children(sequence(tbs.1))
            if let extensions = fields.first(where: { $0.0 == 0xA3 }) {
                for entry in children(extensions.1) {
                    let fields = children(sequence(entry.1))
                    guard let oid = fields.first, let value = fields.last, value.0 == 0x04 else { continue }
                    let id = dotted(oid.1)
                    let names = ["2.5.29.31": "Revocation lists", "1.3.6.1.5.5.7.1.1": "Authority information",
                                 "2.5.29.17": "Alternative names", "2.5.29.32": "Certificate policies"]
                    if id == "1.3.6.1.5.5.7.1.1" {
                        for access in children(value.1) {
                            let fields = children(sequence(access.1))
                            guard fields.count > 1, fields[1].0 == 0x86 else { continue }
                            let method = dotted(fields[0].1)
                            let name = method == "1.3.6.1.5.5.7.48.1" ? "OCSP responder" : method == "1.3.6.1.5.5.7.48.2" ? "Issuer certificate URL" : "Authority " + method
                            details[name] = String(decoding: fields[1].1, as: UTF8.self)
                        }
                        continue
                    }
                    if id == "2.5.29.32" {
                        for policy in children(value.1) {
                            let fields = children(sequence(policy.1))
                            guard let oid = fields.first else { continue }
                            let policyID = dotted(oid.1)
                            let qualifiers = strings(sequence(policy.1))
                            details["Certificate policy " + policyID] = qualifiers.isEmpty ? policyID : qualifiers.joined(separator: "\n")
                        }
                        continue
                    }
                    if id == "1.3.6.1.5.5.7.1.3" {
                        details["Qualified certificate statements"] = children(value.1).compactMap { statement in
                            guard let oid = children(sequence(statement.1)).first else { return nil }
                            let statementID = dotted(oid.1)
                            return statementID == "0.4.0.1862.1.1" ? "QC compliance declaration (" + statementID + ")" : statementID
                        }.joined(separator: "\n")
                        continue
                    }
                    let decoded = strings(value.1)
                    if !decoded.isEmpty { details[names[id] ?? "Extension " + id] = decoded.joined(separator: "\n") }
                    else if id == "2.5.29.14", let (h, n) = try? DER.header(value.1, at: 0), h + n <= value.1.count {
                        details["Subject key identifier"] = Data(value.1[h..<(h+n)]).hexString
                    } else if id == "2.5.29.35", let key = children(value.1).first(where: { $0.0 == 0x80 }) {
                        details["Authority key identifier"] = key.1.hexString
                    } else if id == "2.5.29.15", let (h, n) = try? DER.header(value.1, at: 0), n > 1, h + n <= value.1.count {
                        let bits = Array(value.1[(h+1)..<(h+n)])
                        let names = ["Digital signature", "Content commitment", "Key encipherment", "Data encipherment", "Key agreement", "Certificate signing", "CRL signing", "Encipher only", "Decipher only"]
                        details["Key usage"] = names.enumerated().compactMap { index, name in
                            index / 8 < bits.count && bits[index / 8] & (0x80 >> (index % 8)) != 0 ? name : nil
                        }.joined(separator: ", ")
                    } else { details["Extension " + id] = value.1.hexString }
                }
            }
            if certificate.count > 1 {
                let algorithm = children(sequence(certificate[1].1)).first.map { dotted($0.1) } ?? ""
                details["Certificate signature algorithm"] = algorithm == "1.2.840.113549.1.1.11" ? "SHA-256 with RSA" : algorithm
            }
        }
        return details
    }

    // MARK: - PAdES

    public static func validatePDF(_ pdf: Data) -> [Report] {
        let text = String(decoding: pdf, as: UTF8.self)
        var reports: [Report] = []
        // every SigDict: "/Contents<hex>" followed/followed-by "/ByteRange [a b c d]"
        guard let re = try? NSRegularExpression(pattern: #"/ByteRange\s*\[\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*\]"#) else { return [] }
        let matches = re.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for (idx, m) in matches.enumerated() {
            guard let r0 = Range(m.range, in: text) else { continue }
            let brText = String(text[r0])
            let nums = (1...4).compactMap { g -> Int? in
                Range(m.range(at: g), in: text).flatMap { Int(text[$0]) }
            }
            guard nums.count == 4 else { continue }
            // find the /Contents hex belonging to this ByteRange — within the SAME object
            // (object text spans from the enclosing "N 0 obj" up to "endobj")
            let name: String
            var hexText: String? = nil
            if let objEnd = text.range(of: "endobj", range: r0.upperBound..<text.endIndex) {
                // a String, not a Substring: Linux Foundation has no NSRange ↔ Range conversion for Substring
                let objRegion = String(text[r0.lowerBound..<objEnd.lowerBound])
                if let cre = try? NSRegularExpression(pattern: #"/Contents\s*<([0-9A-Fa-f\s]+)>"#),
                   let cm = cre.firstMatch(in: objRegion, range: NSRange(objRegion.startIndex..., in: objRegion)),
                   let cr = Range(cm.range(at: 1), in: objRegion) {
                    hexText = String(objRegion[cr]).replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
                }
            }
            if let fname = fieldNameForSigObject(text: text, byteRangePos: r0.lowerBound) {
                name = fname
            } else {
                name = "Signature\(idx + 1)"
            }
            guard let hex = hexText, let cms = Data(hexString: hex) else { continue }
            // ByteRange content digest
            var content = Data()
            content += pdf.subdata(in: nums[0]..<(nums[0] + nums[1]))
            content += pdf.subdata(in: nums[2]..<(nums[2] + nums[3]))
            reports.append(validateCMS(cms, content: content, name: name, kind: "PAdES"))
        }
        return reports
    }

    // MARK: - XAdES

    public static func validateXAdES(_ xml: Data, referencedFiles: [String: Data]) -> [Report] {
        guard let doc = String(data: xml, encoding: .utf8) else { return [] }
        var reports: [Report] = []
        // for each root-level ds:Signature
        let signer = XMLSig(doc: doc, files: referencedFiles)
        for sig in signer.signatures() {
            reports.append(sig)
        }
        return reports
    }

    // MARK: - CMS validation (shared by PAdES)

    static func validateCMS(_ cmsFull: Data, content: Data, name: String, kind: String) -> Report {
        var r = Report(kind: kind, name: name, signer: "?", contentIntact: false,
                       signatureValid: false, chainTrusted: false,
                       signingTime: "-", timestampTime: nil, level: kind + "-B-B")
        // DER total length -> strip zero padding
        guard cmsFull.count > 4 else { return r }
        let cms = stripDERPadding(cmsFull)
        guard let parts = parseSignedData(cms) else { return r }

        // signer identity
        if let c = parts.cert {
            let subj = subjectCN(c)
            r.signer = subj ?? "?"
            r.certificateDetails = certificateDetails(c)
        }
        r.signingTime = readableDate(parts.signingTime ?? "-")
        r.contentIntact = (parts.messageDigest == content.sha256())
        if parts.hasTimestamp {
            r.level = kind + "-B-T"
            r.timestampTime = parts.tstGenTime.map(readableDate)
        }

        // RSA verify: signature over sha256(SET(attrs)) with signer cert key
        if let certDER = parts.cert {
            let attrsHash = "31".hexByte + lengthBytes(parts.attrsContent.count) + parts.attrsContent
            r.signatureValid = RSAVerifier.verify(certDER: certDER, digest: attrsHash.sha256(), signature: parts.signature)
        }

        // chain: manual offline check (no SecTrust — it can hang fetching intermediates):
        // leaf signed by MDQSign CA (issuer match + RSA verify), CA is child of embedded root.
        if let certDER = parts.cert {
            r.chainTrusted = Self.verifiesOfflineChain(leafDER: certDER)
        }
        return r
    }

    /// Resolve a display name for the signature near the given position (object-local scan).
    private static func fieldNameForSigObject(text: String, byteRangePos: String.Index) -> String? {
        let lo = text.index(byteRangePos, offsetBy: -6000, limitedBy: text.startIndex) ?? text.startIndex
        let hi = text.index(byteRangePos, offsetBy: 6000, limitedBy: text.endIndex) ?? text.endIndex
        let window = text[lo..<hi]
        if let r = window.range(of: "/T(", options: .backwards),
           let e = window[r.upperBound...].firstIndex(of: ")") {
            let candidate = String(window[r.upperBound..<e])
            if candidate.contains("Signature") { return candidate }
        }
        if let r = window.range(of: "/T("),
           let e = window[r.upperBound...].firstIndex(of: ")") {
            let candidate = String(window[r.upperBound..<e])
            if candidate.contains("Signature") { return candidate }
        }
        return nil
    }

    /// Offline chain verification (no SecTrust — it hangs fetching missing intermediates):
    /// issuer DN match + TBS RSA-verify against embedded MDQSign CA and mdtrustca root.
    static func verifiesOfflineChain(leafDER: Data) -> Bool {
        guard let (leafTBS, leafIss, leafSig) = certBits(leafDER),
              let (caTBS, caIss, caSig) = certBits(ChainCerts.mdQSign) else { return false }
        let caSubj = subjectDNData(ChainCerts.mdQSign)
        let rootSubj = subjectDNData(ChainCerts.mdTrustCA)
        guard leafIss == caSubj, caIss == rootSubj else { return false }
        let ok1 = RSAVerifier.verify(certDER: ChainCerts.mdQSign, digest: leafTBS.sha256(), signature: leafSig)
        let ok2 = RSAVerifier.verify(certDER: ChainCerts.mdTrustCA, digest: caTBS.sha256(), signature: caSig)
        return ok1 && ok2
    }

    private static func tlvPair(_ d: Data, _ off: Int) -> (Int, Int) {
        let l1 = Int(d[off + 1])
        if l1 < 0x80 { return (2, 2 + l1) }
        if l1 == 0x81 { return (3, 3 + Int(d[off + 2])) }
        if l1 == 0x82 { return (4, 4 + Int(d[off + 2]) * 256 + Int(d[off + 3])) }
        return (5, 5 + Int(d[off + 2]) * 65536 + Int(d[off + 3]) * 256 + Int(d[off + 4]))
    }

    private static func tbsNames(_ tbs: Data) -> (Data, Data)? {
        var pos = tlvPair(tbs, 0).0
        guard pos < tbs.count else { return nil }
        if tbs[pos] == 0xA0 { pos += tlvPair(tbs, pos).1 }
        pos += tlvPair(tbs, pos).1
        pos += tlvPair(tbs, pos).1
        let (hi, li) = tlvPair(tbs, pos)
        guard pos + li <= tbs.count else { return nil }
        let issuer = tbs.subdata(in: pos..<(pos + li))
        pos += li
        pos += tlvPair(tbs, pos).1
        let (hs, ls) = tlvPair(tbs, pos)
        guard pos + ls <= tbs.count else { return nil }
        return (issuer, tbs.subdata(in: pos..<(pos + ls)))
    }

    private static func certBits(_ der: Data) -> (tbs: Data, issuerRaw: Data, sig: Data)? {
        guard der.count > 8 else { return nil }
        var pos = tlvPair(der, 0).0
        guard pos < der.count else { return nil }
        let (_, lt) = tlvPair(der, pos)
        guard pos + lt <= der.count else { return nil }
        let tbs = der.subdata(in: pos..<(pos + lt))
        pos += lt
        pos += tlvPair(der, pos).1
        guard pos + 2 < der.count else { return nil }
        let (hb, lb) = tlvPair(der, pos)
        guard pos + lb <= der.count, lb - hb > 1 else { return nil }
        let sig = der.subdata(in: (pos + hb + 1)..<(pos + lb))
        guard let names = tbsNames(tbs) else { return nil }
        return (tbs, names.0, sig)
    }

    private static func subjectDNData(_ der: Data) -> Data {
        guard let (tbs, _, _) = certBits(der), let names = tbsNames(tbs) else { return Data() }
        return names.1
    }

    struct CMSParts {
        var messageDigest: Data
        var signingTime: String?
        var attrsContent: Data      // inside the [0] signedAttrs (for re-hashing as SET)
        var signature: Data
        var cert: Data?
        var hasTimestamp: Bool
        var tstGenTime: String?
    }

    static func parseSignedData(_ d: Data) -> CMSParts? {
        func tlv(_ off: Int) -> (Int, Int, Int) { // (tag, headerLen, contentLen)
            let l1 = Int(d[off + 1])
            if l1 < 0x80 { return (Int(d[off]), 2, l1) }
            if l1 == 0x81 { return (Int(d[off]), 3, Int(d[off + 2])) }
            if l1 == 0x82 { return (Int(d[off]), 4, Int(d[off + 2]) * 256 + Int(d[off + 3])) }
            return (Int(d[off]), 5, Int(d[off + 2]) * 65536 + Int(d[off + 3]) * 256 + Int(d[off + 4]))
        }
        guard d.count > 8 else { return nil }
        var pos = tlv(0).1                       // into ContentInfo SEQ
        var (_, h, l) = tlv(pos); pos += h + l   // skip OID
        _ = l; (_, h, _) = tlv(pos); pos += h    // into [0]
        (_, h, l) = tlv(pos); pos += h           // into SignedData SEQ
        var certDER: Data? = nil
        var signerInfoRange: Range<Int>? = nil
        let end = pos + l
        pos += tlv(pos).1 + tlv(pos).2           // version
        pos += tlv(pos).1 + tlv(pos).2           // digestAlgs
        pos += tlv(pos).1 + tlv(pos).2           // encapContent
        while pos < end {
            let (tag, hh, ll) = tlv(pos)
            if tag == 0xA0 && certDER == nil {   // certificates
                certDER = d.subdata(in: (pos + hh)..<(pos + hh + Swift.min(ll, d.count - pos - hh)))
            } else if tag == 0x31 {              // signerInfos
                signerInfoRange = (pos + hh)..<(pos + hh + ll)
            }
            pos += hh + ll
        }
        guard let siRange = signerInfoRange else { return nil }
        // SignerInfo SEQ -> children; find [0] signedAttrs, OCTET STRING sig, signingTime, unsignedAttrs
        pos = siRange.lowerBound
        var attrsContent = Data(), signature = Data(), md = Data()
        var signingTime: String? = nil, hasTS = false, tstTime: String? = nil
        let siEnd = siRange.upperBound
        pos += tlv(pos).1                        // into SignerInfo content
        pos += tlv(pos).1 + tlv(pos).2           // version
        pos += tlv(pos).1 + tlv(pos).2           // sid
        pos += tlv(pos).1 + tlv(pos).2           // digestAlg
        if pos < siEnd {
            let (tag, hh, ll) = tlv(pos)
            if tag == 0xA0 {
                attrsContent = d.subdata(in: (pos + hh)..<(pos + hh + ll))
                let attrs = attrsContent
                // messageDigest OID inside attrs
                if let r = attrs.range(of: Data([0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x09, 0x04])) {
                    var p = r.upperBound
                    if attrs[p] == 0x31 { p += skipH(attrs, at: p) }
                    if attrs[p] == 0x04 {
                        let hl = skipH(attrs, at: p)
                        let ml = tlvLen(attrs, at: p) - hl
                        md = attrs.subdata(in: (p + hl)..<(p + hl + ml))
                    }
                }
                if let r = attrs.range(of: Data([0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x09, 0x05])) {
                    var p = r.upperBound
                    if attrs[p] == 0x31 { p += skipH(attrs, at: p) }
                    if attrs[p] == 0x17 || attrs[p] == 0x18 {
                        let hl = skipH(attrs, at: p)
                        let tl = tlvLen(attrs, at: p) - hl
                        let s = String(decoding: attrs.subdata(in: (p + hl)..<(p + hl + tl)), as: UTF8.self)
                        signingTime = s
                    }
                }
                pos += hh + ll
            }
        }
        pos += tlv(pos).1 + tlv(pos).2           // signatureAlg
        if pos < siEnd {
            let (tag, hh, ll) = tlv(pos)
            if tag == 0x04 {
                signature = d.subdata(in: (pos + hh)..<(pos + hh + ll))
                pos += hh + ll
            }
        }
        // unsignedAttrs [1]
        if pos < siEnd, tlv(pos).0 == 0xA1 {
            let (_, hh, ll) = tlv(pos)
            let u = d.subdata(in: (pos + hh)..<(pos + hh + ll))
            if u.contains(Data([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x09, 0x10, 0x02, 0x0E])) {
                hasTS = true
                // genTime: first GeneralizedTime (0x18) after TSTInfo OID
                if let r = u.range(of: Data([0x06, 0x0B, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x09, 0x10, 0x02, 0x04])),
                   let t = u.range(of: Data([0x18]), in: r.upperBound..<u.endIndex) {
                    let hl = skipH(u, at: t.lowerBound)
                    let tl = tlvLen(u, at: t.lowerBound) - hl
                    if tl > 0, tl < 30 {
                        tstTime = String(decoding: u.subdata(in: (t.lowerBound + hl)..<(t.lowerBound + hl + tl)), as: UTF8.self)
                    }
                }
            }
        }
        return CMSParts(messageDigest: md, signingTime: signingTime, attrsContent: attrsContent,
                        signature: signature, cert: certDER, hasTimestamp: hasTS, tstGenTime: tstTime)
    }

    private static func skipH(_ d: Data, at off: Int) -> Int {
        let l1 = Int(d[off + 1])
        if l1 < 0x80 { return 2 }
        if l1 == 0x81 { return 3 }
        if l1 == 0x82 { return 4 }
        return 5
    }
    private static func tlvLen(_ d: Data, at off: Int) -> Int {
        let l1 = Int(d[off + 1])
        if l1 < 0x80 { return 2 + l1 }
        if l1 == 0x81 { return 3 + Int(d[off + 2]) }
        if l1 == 0x82 { return 4 + Int(d[off + 2]) * 256 + Int(d[off + 3]) }
        return 2
    }
    private static func lengthBytes(_ n: Int) -> Data {
        if n < 0x80 { return Data([UInt8(n)]) }
        if n < 0x100 { return Data([0x81, UInt8(n)]) }
        if n < 0x10000 { return Data([0x82, UInt8(n >> 8), UInt8(n & 0xFF)]) }
        return Data([0x83, UInt8(n >> 16), UInt8((n >> 8) & 0xFF), UInt8(n & 0xFF)])
    }
    static func stripDERPadding(_ d: Data) -> Data {
        let l1 = Int(d[1])
        if l1 == 0x82 { return d.subdata(in: 0..<(4 + Int(d[2]) * 256 + Int(d[3]))) }
        if l1 == 0x83 { return d.subdata(in: 0..<(5 + Int(d[2]) * 65536 + Int(d[3]) * 256 + Int(d[4]))) }
        if l1 < 0x80 { return d.subdata(in: 0..<(2 + l1)) }
        return d
    }
    /// Subject CN decoded for display ("Ștefan Mîndru", not "M\C3\AEndru"); full subject if there is no CN.
    public static func subjectCN(_ der: Data) -> String? {
        guard let name = try? XAdESSigner.nameDER(Data(der), subject: true) else { return nil }
        return X509Name.commonName(name) ?? X509Name.displayString(name)
    }
}

// MARK: - XAdES XML signature validation (DOM-light, matches our/iaik structures)

private struct XMLSig {
    let doc: String
    let files: [String: Data]

    func signatures() -> [Validator.Report] {
        var reps: [Validator.Report] = []
        // SignedInfo
        guard let siStart = doc.range(of: "<ds:SignedInfo"),
              let siEnd = doc.range(of: "</ds:SignedInfo>") else { return reps }
        let signedInfo = String(doc[siStart.lowerBound..<siEnd.upperBound])
        let sigId = attr("Id", in: doc, after: doc.range(of: "<ds:Signature ")?.lowerBound ?? doc.startIndex) ?? "?"

        var r = Validator.Report(kind: "XAdES", name: sigId, signer: "?", contentIntact: false,
                                 signatureValid: false, chainTrusted: false,
                                 signingTime: "-", timestampTime: nil, level: "XAdES-BES")

        // SignedProperties (digest -> compare)
        var allRefsOk = true
        if let spStart = doc.range(of: "<xades:SignedProperties"),
           let spEnd = doc.range(of: "</xades:SignedProperties>"),
           spEnd.lowerBound > siEnd.upperBound ||
           spEnd.lowerBound < siStart.lowerBound ||
           true {
            let sp = String(doc[spStart.lowerBound..<spEnd.upperBound])
            // canonical: inject inherited ns
            let c14n = c14nSubset(sp, rootTag: "xades:SignedProperties",
                                  namespaces: [("ds", "http://www.w3.org/2000/09/xmldsig#"),
                                               ("xades", "http://uri.etsi.org/01903/v1.3.2#")])
            // find Reference URI=#SignedProperties-... DigestValue
            if let refURI = findRefURI(doc: doc, prefix: "#SignedProperties-"),
               let dv = digestValue(of: refURI, in: signedInfo) {
                allRefsOk = allRefsOk && (dv == digestAlgorithm(of: refURI, in: signedInfo).hash(c14n).base64EncodedString())
            } else { allRefsOk = false }
        }
        // enveloped content (signatureType "Embedded"): digest over the C14N of its ds:Object
        for uri in refURIs(doc: signedInfo, prefix: "#FileObject-") {
            let objectId = String(uri.dropFirst())
            guard let os = doc.range(of: "<ds:Object Encoding=\"UTF-8\" Id=\"\(objectId)\""),
                  let oe = doc.range(of: "</ds:Object>", range: os.upperBound..<doc.endIndex),
                  let dv = digestValue(of: uri, in: signedInfo) else { allRefsOk = false; continue }
            let c14n = c14nSubset(String(doc[os.lowerBound..<oe.upperBound]), rootTag: "ds:Object",
                                  namespaces: [("ds", "http://www.w3.org/2000/09/xmldsig#")])
            allRefsOk = allRefsOk && (dv == digestAlgorithm(of: uri, in: signedInfo).hash(c14n).base64EncodedString())
        }
        // file references
        let fileRefs = refURIs(doc: signedInfo, prefix: "file:/")
        for uri in fileRefs {
            let fname = String(uri.dropFirst(6))
            guard let bytes = files[fname],
                  let dv = digestValue(of: uri, in: signedInfo) else { allRefsOk = false; continue }
            let comp = digestAlgorithm(of: uri, in: signedInfo).hash(bytes).base64EncodedString()
            allRefsOk = allRefsOk && (dv == comp)
        }

        // signature validity: c14n(SignedInfo) + seckey verify
        let siC14n = c14nSubset(signedInfo, rootTag: "ds:SignedInfo",
                                namespaces: [("ds", "http://www.w3.org/2000/09/xmldsig#")])
        if let kiRange = doc.range(of: "<ds:X509Certificate>"),
           let kiEnd = doc.range(of: "</ds:X509Certificate>"),
           let certDER = Data(base64Encoded: String(doc[kiRange.upperBound..<kiEnd.lowerBound])
                                .replacingOccurrences(of: "\\s", with: "", options: .regularExpression)),
           let svStart = doc.range(of: "<ds:SignatureValue"),
           let svEnd = doc.range(of: "</ds:SignatureValue>") {
            guard let gt = doc.range(of: ">", range: svStart.upperBound..<svEnd.lowerBound) else { return reps }
            let svBody = String(doc[gt.upperBound..<svEnd.lowerBound])
            if let sig = Data(base64Encoded: svBody.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)) {
                let method: XAdESSigner.DigestAlgorithm = signedInfo.contains("xmldsig#rsa-sha1\"") ? .sha1 : .sha256
                r.signatureValid = RSAVerifier.verify(certDER: certDER, digest: method.hash(siC14n), signature: sig, algorithm: method)
                r.chainTrusted = Validator.verifiesOfflineChain(leafDER: certDER)
                r.signer = Validator.subjectCN(certDER) ?? "?"
                r.certificateDetails = Validator.certificateDetails(certDER)
            }
        }
        if let t = doc.range(of: "<xades:SigningTime>"), let te = doc.range(of: "</xades:SigningTime>") {
            r.signingTime = Validator.readableDate(String(doc[t.upperBound..<te.lowerBound]))
        }
        if doc.contains("<xades:SignatureTimeStamp") {
            r.level = "XAdES-T"
            r.timestampTime = "(present)"
            if doc.contains("CompleteCertificateRefs") { r.level = "XAdES-C" }
        }
        r.contentIntact = allRefsOk
        reps.append(r)
        return reps
    }

    private func attr(_ name: String, in s: String, after: String.Index) -> String? {
        guard let r = s.range(of: "\(name)=\"", range: after..<s.endIndex) else { return nil }
        guard let e = s[r.upperBound...].firstIndex(of: "\"") else { return nil }
        return String(s[r.upperBound..<e])
    }
    private func findRefURI(doc: String, prefix: String) -> String? {
        guard let r = doc.range(of: "URI=\"" + prefix) else { return nil }
        guard let e = doc[r.upperBound...].firstIndex(of: "\"") else { return nil }
        let from = doc.index(r.upperBound, offsetBy: -prefix.count)
        return String(doc[from..<e])
    }
    private func refURIs(doc: String, prefix: String) -> [String] {
        var out: [String] = []
        var start = doc.startIndex
        while let r = doc.range(of: "URI=\"" + prefix, range: start..<doc.endIndex) {
            guard let e = doc[r.upperBound...].firstIndex(of: "\"") else { break }
            let from = doc.index(r.upperBound, offsetBy: -prefix.count)
            out.append(String(doc[from..<e]))
            start = e
        }
        return out
    }
    /// DigestMethod of the Reference with this URI (SHA-1 or SHA-256).
    private func digestAlgorithm(of uri: String, in signedInfo: String) -> XAdESSigner.DigestAlgorithm {
        guard let ur = signedInfo.range(of: "URI=\"" + uri + "\""),
              let dm = signedInfo.range(of: "<ds:DigestMethod Algorithm=\"", range: ur.upperBound..<signedInfo.endIndex),
              let e = signedInfo[dm.upperBound...].firstIndex(of: "\"") else { return .sha256 }
        return signedInfo[dm.upperBound..<e].hasSuffix("#sha1") ? .sha1 : .sha256
    }
    private func digestValue(of uri: String, in signedInfo: String) -> String? {
        guard let ur = signedInfo.range(of: "URI=\"" + uri + "\"") else { return nil }
        guard let dv = signedInfo.range(of: "<ds:DigestValue>", range: ur.lowerBound..<signedInfo.endIndex),
              let de = signedInfo.range(of: "</ds:DigestValue>", range: dv.upperBound..<signedInfo.endIndex) else { return nil }
        return String(signedInfo[dv.upperBound..<de.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private func c14nSubset(_ xml: String, rootTag: String, namespaces: [(String, String)]) -> Data {
        let nsStr = namespaces.sorted { $0.0 < $1.0 }
            .map { " xmlns:\($0.0)=\"\($0.1)\"" }.joined()
        guard let r = xml.range(of: "<\(rootTag) ") ?? xml.range(of: "<\(rootTag)>") else { return canonicalize(xml) }
        var out = xml
        out.insert(contentsOf: nsStr, at: xml.index(r.lowerBound, offsetBy: rootTag.count + 1))
        return canonicalize(out)
    }

    /// Quote-aware empty-element expansion: <e a="u/v"/> -> <e a="u/v"></e> (inclusive C14N).
    private func canonicalize(_ xml: String) -> Data {
        let chars = Array(xml)
        var out = ""
        var i = 0
        let n = chars.count
        while i < n {
            if chars[i] == "<", i + 1 < n, chars[i + 1] != "/", chars[i + 1] != "?", chars[i + 1] != "!" {
                // start tag: find its end respecting quoted attribute values
                var j = i + 1
                var tag = ""
                while j < n, chars[j] != " ", chars[j] != ">", chars[j] != "/" { tag.append(chars[j]); j += 1 }
                var inQuote = false
                while j < n {
                    if chars[j] == "\"" { inQuote = !inQuote }
                    if !inQuote, chars[j] == ">" { break }
                    j += 1
                }
                guard j < n else { break }
                let seg = String(chars[i...j])
                if seg.hasSuffix("/>") {
                    out += String(seg.dropLast(2)) + "></" + tag + ">"
                } else {
                    out += seg
                }
                i = j + 1
            } else {
                out.append(chars[i])
                i += 1
            }
        }
        return Data(out.utf8)
    }
}

extension String {
    var hexByte: Data { Data(hex: self) }
}
extension Data {
    init?(hexString: String) {
        guard hexString.count % 2 == 0 else { return nil }
        self.init(hex: hexString)
        if self.count != hexString.count / 2 { return nil }
    }
}
