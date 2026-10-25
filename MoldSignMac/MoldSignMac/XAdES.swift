import Foundation

/// XAdES signer producing structures matching the MoldSign middleware
/// (IAIK xades): detached signatures, formats BES / T / C (see SignXAdESWorker).
class XAdESSigner {
    enum Format { case bes, t, c
        var needsTimestamp: Bool { self != .bes }
        var needsCompleteRefs: Bool { self == .c }
    }

    static let nsDS = "http://www.w3.org/2000/09/xmldsig#"
    static let nsXAdES = "http://uri.etsi.org/01903/v1.3.2#"
    static let algC14N = "http://www.w3.org/TR/2001/REC-xml-c14n-20010315"
    static let algSigRSA256 = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
    static let algSHA256 = "http://www.w3.org/2001/04/xmlenc#sha256"
    static let tsaURL = "http://tsp.pki.gov.md/moldsign2/"

    struct CertName { let issuerDNRFC2253: String   // reversed, organizationIdentifier numeric
                      let issuerDNRFC2253Named: String // reversed, "organizationIdentifier=" name
                      let serialDecimal: String }

    // MARK: - Public API

    enum SigType { case detached, enveloping }

    /// XAdES signature document for the given files (detached or data-enveloping).
    func sign(files: [URL], format: Format, type: SigType = .detached, certDER: Data, chainDER: [Data],
              signBlock: (Data) throws -> Data,
              tsaBlock: (Data) throws -> Data,
              ocspDerBlock: (Data?, Data) throws -> Data? = { _, _ in nil }) throws -> Data {
        let u = UUID().uuidString
        let name = try Self.parseIssuer(certDER)

        // per-file digests over raw bytes
        var sigRefs = ""
        var dataObjFmt = ""
        var fileObjects = ""
        for f in files {
            let bytes = try Data(contentsOf: f)
            let base = f.lastPathComponent
            let mime = base.lowercased().hasSuffix(".txt") ? "text/plain" : "application/octet-stream"
            if type == .enveloping {
                // ds:Object with embedded base64; digest over its C14N form (per middleware/iaik)
                let objBase = "<ds:Object Encoding=\"UTF-8\" Id=\"FileObject-\(u)\">" + bytes.base64EncodedString() + "</ds:Object>"
                fileObjects += objBase
                let canon = inject(into: objBase, tag: "ds:Object", namespaces: [("ds", Self.nsDS)])
                sigRefs += """
                <ds:Reference Id="SignedFile-Reference-\(u)-\(base)" URI="#FileObject-\(u)"><ds:DigestMethod Algorithm="\(Self.algSHA256)"></ds:DigestMethod><ds:DigestValue>\(canon.sha256().base64EncodedString())</ds:DigestValue></ds:Reference>
                """
            } else {
                sigRefs += """
                <ds:Reference Id="SignedFile-Reference-\(u)-\(base)" URI="file:/\(base)"><ds:DigestMethod Algorithm="\(Self.algSHA256)"></ds:DigestMethod><ds:DigestValue>\(bytes.sha256().base64EncodedString())</ds:DigestValue></ds:Reference>
                """
            }
            dataObjFmt += """
            <xades:DataObjectFormat ObjectReference="SignedFile-Reference-\(u)-\(f.path)"><xades:Description>\(f.path)</xades:Description><xades:MimeType>\(mime)</xades:MimeType></xades:DataObjectFormat>
            """
        }

        // SignedProperties
        let signingTime = Self.iso8601(Date())
        let certDigest = certDER.sha256().base64EncodedString()
        let signedProps = """
        <xades:SignedProperties Id="SignedProperties-\(u)"><xades:SignedSignatureProperties><xades:SigningTime>\(signingTime)</xades:SigningTime><xades:SigningCertificate><xades:Cert><xades:CertDigest><ds:DigestMethod Algorithm="\(Self.algSHA256)"></ds:DigestMethod><ds:DigestValue>\(certDigest)</ds:DigestValue></xades:CertDigest><xades:IssuerSerial><ds:X509IssuerName>\(name.issuerDNRFC2253)</ds:X509IssuerName><ds:X509SerialNumber>\(name.serialDecimal)</ds:X509SerialNumber></xades:IssuerSerial></xades:Cert></xades:SigningCertificate></xades:SignedSignatureProperties><xades:SignedDataObjectProperties Id="SignedDataObjectProperties-\(u)">\(dataObjFmt)</xades:SignedDataObjectProperties></xades:SignedProperties>
        """

        // digest of the SignedProperties (inclusive C14N: inject inherited xmlns:ds + xmlns:xades)
        let spCanonical = inject(into: signedProps, tag: "xades:SignedProperties",
                                 namespaces: [("ds", Self.nsDS), ("xades", Self.nsXAdES)])
        let spDigest = spCanonical.sha256().base64EncodedString()

        // SignedInfo
        let siC14N = type == .enveloping ? Self.algC14N + "#WithComments" : Self.algC14N
        let signedInfo = """
        <ds:SignedInfo Id="SignedInfo-\(u)"><ds:CanonicalizationMethod Algorithm="\(siC14N)"></ds:CanonicalizationMethod><ds:SignatureMethod Algorithm="\(Self.algSigRSA256)"></ds:SignatureMethod><ds:Reference Id="SignedProperties-Reference-\(u)" Type="http://uri.etsi.org/01903#SignedProperties" URI="#SignedProperties-\(u)"><ds:DigestMethod Algorithm="\(Self.algSHA256)"></ds:DigestMethod><ds:DigestValue>\(spDigest)</ds:DigestValue></ds:Reference>\(sigRefs)</ds:SignedInfo>
        """

        // sign canonicalized SignedInfo (inherited xmlns:ds injected)
        let siCanonical = inject(into: signedInfo, tag: "ds:SignedInfo", namespaces: [("ds", Self.nsDS)])
        let signature = try signBlock(siCanonical)
        let sigB64 = signature.base64EncodedString()
        let sigValueXML = "<ds:SignatureValue Id=\"SignatureValue-\(u)\">\(sigB64)</ds:SignatureValue>"

        let keyInfo = """
        <ds:KeyInfo Id="KeyInfo-\(u)"><ds:X509Data><ds:X509Certificate>\(certDER.base64EncodedString())</ds:X509Certificate></ds:X509Data></ds:KeyInfo>
        """

        // UnsignedProperties
        var unsignedProps = ""
        if format.needsTimestamp {
            // timestamp over canonicalized SignatureValue element (xmlns:ds inherited)
            let sigValCanonical = inject(into: sigValueXML, tag: "ds:SignatureValue",
                                         namespaces: [("ds", Self.nsDS)])
            let token = try tsaBlock(sigValCanonical)
            unsignedProps += "<xades:SignatureTimeStamp Id=\"SignatureTimeStamp-\(u)\"><ds:CanonicalizationMethod Algorithm=\"\(Self.algC14N)\"></ds:CanonicalizationMethod><xades:EncapsulatedTimeStamp Encoding=\"http://uri.etsi.org/01903/v1.2.2#DER\">\(token.base64EncodedString())</xades:EncapsulatedTimeStamp></xades:SignatureTimeStamp>"
        }
        if format.needsCompleteRefs {
            unsignedProps += try buildCompleteRefs(u: u, certDER: certDER, chainDER: chainDER,
                                                   name: name, ocspDerBlock: ocspDerBlock)
        }
        if !unsignedProps.isEmpty {
            unsignedProps = "<xades:UnsignedProperties><xades:UnsignedSignatureProperties>\(unsignedProps)</xades:UnsignedSignatureProperties></xades:UnsignedProperties>"
        }

        let qpObj = "<ds:Object><xades:QualifyingProperties xmlns:xades=\"\(Self.nsXAdES)\" Target=\"#Signature-\(u)\">\(signedProps)\(unsignedProps)</xades:QualifyingProperties></ds:Object>"
        let object = qpObj + fileObjects
        let sig = "<ds:Signature xmlns:ds=\"\(Self.nsDS)\" Id=\"Signature-\(u)\">\(signedInfo)\(sigValueXML)\(keyInfo)\(object)</ds:Signature>"
        return Data(("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>" + sig).utf8)
    }

    // MARK: - XAdES-C complete refs

    private func buildCompleteRefs(u: String, certDER: Data, chainDER: [Data],
                                   name: CertName,
                                   ocspDerBlock: (Data?, Data) throws -> Data?) throws -> String {
        let certs = [certDER] + chainDER     // signer + issuers (excluding self-signed root)
        var certRefs = ""
        var crlRefs = ""
        var ocspRefs = ""
        var issuerName: CertName? = nil
        for (idx, c) in certs.enumerated() {
            let n = try Self.parseIssuer(c)
            let dig = c.sha256().base64EncodedString()
            certRefs += "<xades:Cert><xades:CertDigest><ds:DigestMethod Algorithm=\"\(Self.algSHA256)\"></ds:DigestMethod><ds:DigestValue>\(dig)</ds:DigestValue></xades:CertDigest><xades:IssuerSerial><ds:X509IssuerName>\(n.issuerDNRFC2253Named)</ds:X509IssuerName><ds:X509SerialNumber>\(n.serialDecimal)</ds:X509SerialNumber></xades:IssuerSerial></xades:Cert>"

            // CRL ref for the issuer of this cert (skip if no CRL DP known)
            if let crlRef = Self.fetchCRLRef(for: c) { crlRefs += crlRef }

            // middleware quirk: OCSP is queried for the SIGNER cert in every chain iteration,
            // producing one identical OCSPRef per cert (signer + each issuer)
            if certs.count > 1,
               let resp = try ocspDerBlock(certs[1], certs[0]),
               let oref = Self.buildOCSPRef(response: resp, uri: "http://mdqsign.ocsp.pki.md") {
                ocspRefs += oref
            }
            issuerName = n
        }
        return "<xades:CompleteCertificateRefs Id=\"CompleteCertificateRefs-\(u)\"><xades:CertRefs>\(certRefs)</xades:CertRefs></xades:CompleteCertificateRefs>" +
               "<xades:CompleteRevocationRefs Id=\"CompleteRevocationRefs-\(u)\"><xades:CRLRefs>\(crlRefs)</xades:CRLRefs><xades:OCSPRefs>\(ocspRefs)</xades:OCSPRefs></xades:CompleteRevocationRefs>"
    }

    // MARK: - CRL/OCSP helpers (via system tools, DER digests + identifiers)

    static func fetchCRLRef(for certDER: Data) -> String? {
        // CRL Distribution Points URI
        guard let url = extractExtensionURI(certDER, oidBytes: [0x55, 0x1D, 0x1F]) else { return nil }
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("msa-crl-\(UUID().uuidString).crl")
        defer { try? FileManager.default.removeItem(at: tmp) }
        let proc = Process(); proc.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
        proc.arguments = ["-sS", "-m", "30", url, "-o", tmp.path]
        guard (try? proc.run()) != nil else { return nil }
        proc.waitUntilExit()
        guard proc.terminationStatus == 0, let crl = try? Data(contentsOf: tmp), crl.count > 100 else { return nil }
        let digest = crl.sha256().base64EncodedString()
        guard let info = parseCRLInfo(crl) else { return nil }
        return "<xades:CRLRef><xades:DigestAlgAndValue><ds:DigestMethod Algorithm=\"\(algSHA256)\"></ds:DigestMethod><ds:DigestValue>\(digest)</ds:DigestValue></xades:DigestAlgAndValue><xades:CRLIdentifier URI=\"\(url)\"><xades:Issuer>\(info.issuer)</xades:Issuer><xades:IssueTime>\(info.issueTime)</xades:IssueTime><xades:Number>\(info.number)</xades:Number></xades:CRLIdentifier></xades:CRLRef>"
    }

    static func buildOCSPRef(response: Data, uri: String) -> String? {
        guard let info = parseOCSPInfo(response) else { return nil }
        let digest = response.sha256().base64EncodedString()
        return "<xades:OCSPRef><xades:OCSPIdentifier URI=\"\(uri)\"><xades:ResponderID><xades:ByName>\(info.responder)</xades:ByName></xades:ResponderID><xades:ProducedAt>\(info.producedAt)</xades:ProducedAt></xades:OCSPIdentifier><xades:DigestAlgAndValue><ds:DigestMethod Algorithm=\"\(algSHA256)\"></ds:DigestMethod><ds:DigestValue>\(digest)</ds:DigestValue></xades:DigestAlgAndValue></xades:OCSPRef>"
    }

    // first URI in an X509v3 extension (AIA / CRL DP) given its DER OID bytes
    static func extractExtensionURI(_ der: Data, oidBytes: [UInt8]) -> String? {
        var d = der
        guard let r = d.range(of: Data(oidBytes)) else { return nil }
        d = d.subdata(in: r.lowerBound..<d.count)
        guard let http = d.range(of: Data("http://".utf8)) else { return nil }
        let rest = String(decoding: d.subdata(in: http.lowerBound..<min(d.count, http.lowerBound + 200)), as: UTF8.self)
        guard let re = try? NSRegularExpression(pattern: #"https?://[^\s\"]+\.(crl|crt|cer)"#),
              let m = re.firstMatch(in: rest, range: NSRange(rest.startIndex..., in: rest)),
              let r2 = Range(m.range, in: rest) else { return nil }
        return String(rest[r2])
    }

    struct CRLInfo { let issuer: String; let issueTime: String; let number: String }
    static func parseCRLInfo(_ der: Data) -> CRLInfo? {
        // CertificateList ::= SEQ { TBSCertList SEQ { version?, sigAlg, issuer Name, thisUpdate, ... } }
        do {
            var pos = skipTLVHeaderLen(der, at: 0)
            pos += skipTLVHeaderLen(der, at: pos)   // into TBSCertList
            guard pos + 2 < der.count else { return nil }
            if der[pos] == 0x02 { pos += skipTLV(der, at: pos) }  // version INTEGER
            pos += skipTLV(der, at: pos)            // signature alg
            let issStart = pos
            let issLen = skipTLV(der, at: pos)
            let issuerDER = der.subdata(in: issStart..<issStart + issLen)
            pos += issLen
            // thisUpdate UTCTime/GeneralizedTime
            let timeStr = parseASN1Time(der, at: pos)
            // CRL number: find OID 2.5.29.20
            var number = "0"
            if let r = der.range(of: Data([0x55, 0x1D, 0x14])) {
                var p = r.upperBound
                // skip: extnValue wrapper(s) down to INTEGER
                for _ in 0..<4 {
                    guard p + 2 < der.count else { break }
                    if der[p] == 0x02 { // INTEGER
                        let l = skipTLVHeaderLen(der, at: p)
                        let il = Int(der[p + 1])
                        guard p + l + il <= der.count else { break }
                        let intBytes = der.subdata(in: (p + l)..<(p + l + il))
                        number = bigIntDecimal(Data(intBytes))
                        break
                    }
                    p += skipTLVHeaderLen(der, at: p)
                }
            }
            return CRLInfo(issuer: rfc2253Name(issuerDER, useNamedOrgId: true),
                           issueTime: timeStr, number: number)
        }
    }

    struct OCSPInfo { let responder: String; let producedAt: String }
    static func parseOCSPInfo(_ der: Data) -> OCSPInfo? {
        // OCSPResponse { status, [0] responseBytes { ResponseType oid, OCTET STRING BasicOCSPResponse } }
        var pos = der.startIndex + skipTLVHeaderLen(der, at: 0)
        pos += skipTLV(der, at: pos)              // status enum -> now at [0]
        guard pos < der.count else { return nil }
        pos += skipTLVHeaderLen(der, at: pos)     // into [0] content
        pos += skipTLVHeaderLen(der, at: pos)     // into ResponseBytes SEQ
        pos += skipTLV(der, at: pos)              // skip OID
        // BasicOCSPResponse inside OCTET STRING
        pos += skipTLVHeaderLen(der, at: pos)
        let basic = der.subdata(in: pos..<der.count)
        var pb = basic.startIndex + skipTLVHeaderLen(basic, at: 0)      // into Basic content -> tbs SEQ tag
        guard pb + 2 < basic.count else { return nil }
        pb += skipTLVHeaderLen(basic, at: pb)                            // into tbsResponseData content
        // skip version [0] (explicit)
        if pb < basic.count && basic[pb] == 0xA0 { pb += skipTLV(basic, at: pb) }
        // responderID [1] byName or [2] byKey
        var responder = ""
        guard pb + 2 < basic.count else { return nil }
        if basic[pb] == 0xA1 {
            let h = skipTLVHeaderLen(basic, at: pb)
            let l = skipTLV(basic, at: pb) - h
            guard l > 0, pb + h + l <= basic.count else { return nil }
            let nameDER = basic.subdata(in: (pb + h)..<(pb + h + l))
            responder = rfc2253Name(nameDER, useNamedOrgId: true, reverse: true)
            pb += skipTLV(basic, at: pb)
        } else if basic[pb] == 0xA2 {
            pb += skipTLV(basic, at: pb)
        }
        let producedAt = parseASN1Time(basic, at: pb)
        return OCSPInfo(responder: responder, producedAt: producedAt)
    }

    // MARK: - ASN.1/DN helpers

    static func parseIssuer(_ der: Data) throws -> CertName {
        var pos = skipTLVHeaderLen(der, at: 0)   // Certificate SEQ
        pos += skipTLVHeaderLen(der, at: pos)    // TBSCertificate SEQ
        if der[pos] == 0xA0 { pos += skipTLV(der, at: pos) }
        let serialStart = pos
        pos += skipTLVHeaderLen(der, at: pos)
        var intLen = Int(der[serialStart + 1])
        var hdr = 2
        if intLen > 0x80 { hdr = 2 + (intLen - 0x80); intLen = skipTLV(der, at: serialStart) - hdr }
        let serialBytes = der.subdata(in: (serialStart + hdr)..<(serialStart + hdr + intLen))
        pos = serialStart + skipTLV(der, at: serialStart)
        pos += skipTLV(der, at: pos)             // signature alg
        let issStart = pos
        let issLen = skipTLV(der, at: pos)
        let issuerDER = der.subdata(in: issStart..<issStart + issLen)
        return CertName(issuerDNRFC2253: rfc2253Name(issuerDER, useNamedOrgId: false),
                        issuerDNRFC2253Named: rfc2253Name(issuerDER, useNamedOrgId: true),
                        serialDecimal: bigIntDecimal(serialBytes))
    }

    static func parseSubject(_ der: Data) throws -> String {
        var pos = skipTLVHeaderLen(der, at: 0)
        pos += skipTLVHeaderLen(der, at: pos)          // TBS
        if der[pos] == 0xA0 { pos += skipTLV(der, at: pos) }
        pos += skipTLV(der, at: pos)                   // serial
        pos += skipTLV(der, at: pos)                   // sig alg
        pos += skipTLV(der, at: pos)                   // issuer
        pos += skipTLV(der, at: pos)                   // validity
        let sStart = pos
        let sLen = skipTLV(der, at: pos)
        return rfc2253Name(der.subdata(in: sStart..<(sStart + sLen)), useNamedOrgId: true)
    }

    /// Render an X.501 Name DER as RFC2253 (most significant RDN first = DER reversed),
    /// UTF-8 bytes >= 0x7F escaped as \XX (matches iaik/IAIK output).
    static func rfc2253Name(_ nameDER: Data, useNamedOrgId: Bool, reverse: Bool = true, cnFirst: Bool = false) -> String {
        struct AVA { let oid: String; let numericOID: String; let value: String }
        var avas: [AVA] = []
        let oidNames: [String: String] = [
            "55 04 06": "C", "55 04 08": "ST", "55 04 07": "L",
            "55 04 0A": "O", "55 04 03": "CN", "55 04 05": "serialNumber",
            "55 04 61": "organizationIdentifier", "55 04 14": "T"
        ]
        var pos = nameDER.startIndex + skipTLVHeaderLen(nameDER, at: nameDER.startIndex)
        var sets: [Data] = []
        while pos < nameDER.endIndex {
            let l = skipTLV(nameDER, at: pos)
            sets.append(nameDER.subdata(in: pos..<(pos + l)))
            pos += l
        }
        if reverse { sets.reverse() }
        var avaList: [AVA] = []
        for s in sets {
            var p = s.startIndex + skipTLVHeaderLen(s, at: s.startIndex)
            while p < s.endIndex {
                let seqLen = skipTLV(s, at: p)
                let seq = s.subdata(in: p..<(p + seqLen))
                var q = seq.startIndex + skipTLVHeaderLen(seq, at: seq.startIndex)
                let oidLen = skipTLV(seq, at: q)
                let oidBytes = seq.subdata(in: (q + skipTLVHeaderLen(seq, at: q))..<(q + oidLen))
                let hex = oidBytes.map { String(format: "%02X", $0) }.joined(separator: " ")
                q += oidLen
                let vHdr = skipTLVHeaderLen(seq, at: q)
                let vLen = skipTLV(seq, at: q) - vHdr
                let raw = seq.subdata(in: (q + vHdr)..<(q + vHdr + vLen))
                var val = ""
                for b in raw {
                    if b >= 0x7F || b == 0x00 { val += String(format: "\\%02X", b) } else { val += String(UnicodeScalar(b)) }
                }
                let named = oidNames[hex] ?? numericOID(hex)
                let rendered = useNamedOrgId ? named : (named == "organizationIdentifier" ? numericOID(hex) : named)
                avaList.append(AVA(oid: rendered, numericOID: numericOID(hex), value: val))
                p += seqLen
            }
        }
        if cnFirst, let i = avaList.firstIndex(where: { $0.oid.contains("CN") }) {
            let cn = avaList.remove(at: i)
            avaList.insert(cn, at: 0)
        }
        return avaList.map { "\($0.oid)=\($0.value)" }.joined(separator: ",")
    }

    private static func numericOID(_ hex: String) -> String {
        let bytes = hex.split(separator: " ").compactMap { UInt8($0, radix: 16) }
        guard !bytes.isEmpty else { return hex }
        var parts = [String(bytes[0] / 40), String(bytes[0] % 40)]
        var acc: UInt64 = 0
        for b in bytes.dropFirst() {
            acc = (acc << 7) | UInt64(b & 0x7F)
            if b & 0x80 == 0 { parts.append(String(acc)); acc = 0 }
        }
        return parts.joined(separator: ".")
    }

    static func bigIntDecimal(_ bytes: Data) -> String {
        var digits = [0]  // little-endian decimal digits
        for b in bytes {
            var carry = Int(b)
            for i in 0..<digits.count {
                let v = digits[i] * 256 + carry
                digits[i] = v % 10
                carry = v / 10
            }
            while carry > 0 { digits.append(carry % 10); carry /= 10 }
        }
        while digits.count > 1 && digits.last == 0 { digits.removeLast() }
        return digits.reversed().map(String.init).joined()
    }

    static func parseASN1Time(_ d: Data, at pos: Int) -> String {
        guard pos + 2 < d.count else { return "" }
        let tag = d[pos]
        let hdr = skipTLVHeaderLen(d, at: pos)
        let len = skipTLV(d, at: pos) - hdr
        guard len > 0, pos + hdr + len <= d.count else { return "" }
        let s = String(decoding: d.subdata(in: (pos + hdr)..<(pos + hdr + len)), as: UTF8.self)
        let df = DateFormatter(); df.locale = Locale(identifier: "en_US_POSIX")
        if tag == 0x17 {
            df.dateFormat = "yyMMddHHmmss'Z'"; df.timeZone = TimeZone(identifier: "UTC")
        } else {
            df.dateFormat = "yyyyMMddHHmmss'Z'"; df.timeZone = TimeZone(identifier: "UTC")
        }
        guard let date = df.date(from: s) else { return s }
        return iso8601(date)
    }

    static func iso8601(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxx"
        return f.string(from: date)
    }

    // MARK: - TLV helpers

    static func skipTLV(_ d: Data, at offset: Int) -> Int {
        guard offset + 1 < d.count else { return 0 }
        let l1 = Int(d[offset + 1])
        if l1 < 0x80 { return 2 + l1 }
        if l1 == 0x81 { return 3 + Int(d[offset + 2]) }
        if l1 == 0x82 { return 4 + Int(d[offset + 2]) * 256 + Int(d[offset + 3]) }
        if l1 == 0x83 { return 5 + Int(d[offset + 2]) * 65536 + Int(d[offset + 3]) * 256 + Int(d[offset + 4]) }
        return 2
    }

    static func skipTLVHeaderLen(_ d: Data, at offset: Int) -> Int {
        guard offset + 1 < d.count else { return 0 }
        let l1 = Int(d[offset + 1])
        if l1 < 0x80 { return 2 }
        if l1 == 0x81 { return 3 }
        if l1 == 0x82 { return 4 }
        if l1 == 0x83 { return 5 }
        return 2
    }

    /// Inject inherited namespace declarations into the root tag, sorted by prefix,
    /// matching inclusive C14N of a document subset. Builders must already emit expanded tags.
    private func inject(into xml: String, tag: String, namespaces: [(String, String)]) -> Data {
        let nsStr = namespaces.sorted { $0.0 < $1.0 }
            .map { " xmlns:\($0.0)=\"\($0.1)\"" }.joined()
        guard let r = xml.range(of: "<\(tag) ") ?? xml.range(of: "<\(tag)>") else { return Data(xml.utf8) }
        var out = xml
        out.insert(contentsOf: nsStr, at: r.upperBound == xml.endIndex || xml[r.upperBound...].hasPrefix(" ") ? xml.index(before: r.upperBound) : r.upperBound)
        // simpler: insert right after the tag name
        out = xml
        let nameEnd = xml.index(r.lowerBound, offsetBy: tag.count + 1)
        out.insert(contentsOf: nsStr, at: nameEnd)
        return Data(out.utf8)
    }
}

/// Simple DER digest input for RSA signing (same DigestInfo construction as CMS path).
extension XAdESSigner {
    static func digestInfoForSHA256(_ hash: Data) -> Data {
        let oidSha256 = Data([0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01])
        func der(_ t: UInt8, _ c: Data) -> Data {
            var o = Data([t]); let n = c.count
            if n < 0x80 { o.append(UInt8(n)) } else if n < 0x100 { o.append(0x81); o.append(UInt8(n)) }
            else { o.append(0x82); o.append(UInt8(n >> 8)); o.append(UInt8(n & 0xFF)) }
            return o + c
        }
        return der(0x30, der(0x30, der(0x06, oidSha256) + Data([0x05, 0x00])) + der(0x04, hash))
    }
}

/// OCSP query via openssl CLI (sandbox-safe).
extension XAdESSigner {
    static func fetchOCSPResponse(issuerDER: Data?, certDER: Data) throws -> Data? {
        guard let issuerDER = issuerDER else { return nil }
        func pem(_ der: Data) -> String {
            let b64 = der.base64EncodedString()
            var wrapped = ""
            var i = b64.startIndex
            while i < b64.endIndex {
                let j = b64.index(i, offsetBy: 64, limitedBy: b64.endIndex) ?? b64.endIndex
                wrapped += b64[i..<j] + "\n"
                i = j
            }
            return "-----BEGIN CERTIFICATE-----\n" + wrapped + "-----END CERTIFICATE-----\n"
        }
        let tmp = FileManager.default.temporaryDirectory
        let id = UUID().uuidString
        let caFile = tmp.appendingPathComponent("msa-ca-\(id).pem")
        let certFile = tmp.appendingPathComponent("msa-cert-\(id).pem")
        let respFile = tmp.appendingPathComponent("msa-ocsp-\(id).der")
        try pem(issuerDER).write(to: caFile, atomically: true, encoding: .utf8)
        try pem(certDER).write(to: certFile, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: caFile)
            try? FileManager.default.removeItem(at: certFile)
            try? FileManager.default.removeItem(at: respFile)
        }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/openssl")
        proc.arguments = ["ocsp", "-issuer", caFile.path, "-cert", certFile.path,
                          "-url", "http://mdqsign.ocsp.pki.md", "-noverify",
                          "-respout", respFile.path, "-timeout", "20"]
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try proc.run()
        proc.waitUntilExit()
        guard proc.terminationStatus == 0, let resp = try? Data(contentsOf: respFile),
              resp.count > 100 else { return nil }
        return resp
    }
}
