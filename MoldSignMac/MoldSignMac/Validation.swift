import Foundation
import Security

/// Offline signature validation for PAdES PDFs and XAdES documents produced by
/// this app or the MoldSign middleware. No card required.
enum Validator {

    struct Report {
        var kind: String              // "PAdES" / "XAdES"
        var name: String              // signature field name or Signature Id
        var signer: String            // CN from signing cert
        var contentIntact: Bool       // referenced content digest matches
        var signatureValid: Bool      // RSA signature over attrs/SignedInfo valid
        var chainTrusted: Bool        // chain builds to embedded mdtrustca root
        var signingTime: String
        var timestampTime: String?    // RFC3161 genTime if present
        var level: String             // "PAdES-B-T" / "XAdES-C" etc.

        var summary: String {
            let ok = contentIntact && signatureValid
            return "\(name): \(ok ? "VALID" : "INVALID") — \(signer), \(level)" +
                   ", signed \(signingTime)" + (timestampTime.map { ", tst \($0)" } ?? "") +
                   ", chain \(chainTrusted ? "trusted" : "untrusted")" +
                   (contentIntact ? "" : ", content modified!") +
                   (signatureValid ? "" : ", bad signature!")
        }
    }

    // MARK: - PAdES

    static func validatePDF(_ pdf: Data) -> [Report] {
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
                let objRegion = text[r0.lowerBound..<objEnd.lowerBound]
                if let cre = try? NSRegularExpression(pattern: #"/Contents\s*<([0-9A-Fa-f\s]+)>"#),
                   let cm = cre.firstMatch(in: String(objRegion), range: NSRange(objRegion.startIndex..., in: objRegion)),
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

    static func validateXAdES(_ xml: Data, referencedFiles: [String: Data]) -> [Report] {
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
        }
        r.signingTime = parts.signingTime ?? "-"
        r.contentIntact = (parts.messageDigest == content.sha256())
        if parts.hasTimestamp {
            r.level = kind + "-B-T"
            r.timestampTime = parts.tstGenTime
        }

        // RSA verify: signature over sha256(SET(attrs)) with signer cert key
        if let certDER = parts.cert,
           let cert = SecCertificateCreateWithData(nil, certDER as CFData),
           let key = SecCertificateCopyKey(cert) {
            let attrsHash = "31".hexByte + lengthBytes(parts.attrsContent.count) + parts.attrsContent
            var error: Unmanaged<CFError>?
            let ok = SecKeyVerifySignature(key, .rsaSignatureDigestPKCS1v15SHA256,
                                           attrsHash.sha256() as CFData,
                                           parts.signature as CFData, &error)
            r.signatureValid = ok
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
              let (caTBS, caIss, caSig) = certBits(ChainCerts.mdQSign),
              let rootKey = secKey(ChainCerts.mdTrustCA),
              let caKey = secKey(ChainCerts.mdQSign) else { return false }
        let caSubj = subjectDNData(ChainCerts.mdQSign)
        let rootSubj = subjectDNData(ChainCerts.mdTrustCA)
        guard leafIss == caSubj, caIss == rootSubj else { return false }
        var e1: Unmanaged<CFError>?, e2: Unmanaged<CFError>?
        let ok1 = SecKeyVerifySignature(caKey, .rsaSignatureMessagePKCS1v15SHA256,
                                        leafTBS as CFData, leafSig as CFData, &e1)
        let ok2 = SecKeyVerifySignature(rootKey, .rsaSignatureMessagePKCS1v15SHA256,
                                        caTBS as CFData, caSig as CFData, &e2)
        return ok1 && ok2
    }

    private static func secKey(_ der: Data) -> SecKey? {
        guard let c = SecCertificateCreateWithData(nil, der as CFData) else { return nil }
        return SecCertificateCopyKey(c)
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
    static func subjectCN(_ der: Data) -> String? {
        guard let t = try? XAdESSigner.parseSubject(der) else { return nil }
        // extract CN= component
        for part in t.split(separator: ",") {
            if part.hasPrefix("CN=") { return String(part.dropFirst(3)) }
        }
        return t
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
            let spDigest = c14n.sha256().base64EncodedString()
            // find Reference URI=#SignedProperties-... DigestValue
                       if let refURI = findRefURI(doc: doc, prefix: "#SignedProperties-"),
               let dv = digestValue(of: refURI, in: signedInfo) {
                allRefsOk = allRefsOk && (dv == spDigest)
            } else { allRefsOk = false }
        }
        // file references
        let fileRefs = refURIs(doc: signedInfo, prefix: "file:/")
        for uri in fileRefs {
            let fname = String(uri.dropFirst(6))
            guard let bytes = files[fname],
                  let dv = digestValue(of: uri, in: signedInfo) else { allRefsOk = false; continue }
            let comp = bytes.sha256().base64EncodedString()
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
            if let sig = Data(base64Encoded: svBody.replacingOccurrences(of: "\\s", with: "", options: .regularExpression)),
               let cert = SecCertificateCreateWithData(nil, certDER as CFData),
               let key = SecCertificateCopyKey(cert) {
                var error: Unmanaged<CFError>?
                r.signatureValid = SecKeyVerifySignature(key, .rsaSignatureDigestPKCS1v15SHA256,
                                                         siC14n.sha256() as CFData, sig as CFData, &error)
                r.chainTrusted = Validator.verifiesOfflineChain(leafDER: certDER)
                r.signer = Validator.subjectCN(certDER) ?? "?"
            }
        }
        if let t = doc.range(of: "<xades:SigningTime>"), let te = doc.range(of: "</xades:SigningTime>") {
            r.signingTime = String(doc[t.upperBound..<te.lowerBound])
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
