import Foundation


private func dbg(_ s: String) {
    FileHandle.standardError.write(Data((s + "\n").utf8))
}

/// PAdES signer — builds a CAdES detached CMS (chain + RFC3161 timestamp) and embeds it
/// in a PDF incremental update structured like the MoldSign/iText output.
class PAdESSigner {
    // OIDs as raw DER bytes
    static let oidSha256 = Data([0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01])
    static let oidSha256WithRSA = Data([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x0B])
    static let oidIdData = Data([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x07, 0x01])
    static let oidIdSignedData = Data([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x07, 0x02])
    static let oidContentType = Data([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x09, 0x03])
    static let oidSigningTime = Data([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x09, 0x05])
    static let oidMessageDigest = Data([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x09, 0x04])
    static let oidSigningCertificateV2 = Data([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x09, 0x10, 0x02, 0x2F])
    static let oidTimeStampToken = Data([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x09, 0x10, 0x02, 0x0E])

    static let tsaURL = "http://tsp.pki.gov.md/moldsign2/"
    static let placeholderHexLen = 37960   // same reserve as the MoldSign Java app

    // MARK: - DER helpers

    private func der(_ tag: UInt8, _ content: Data) -> Data {
        var out = Data([tag])
        let len = content.count
        if len < 0x80 {
            out.append(UInt8(len))
        } else if len < 0x100 {
            out.append(0x81); out.append(UInt8(len))
        } else if len < 0x10000 {
            out.append(0x82); out.append(UInt8(len >> 8)); out.append(UInt8(len & 0xFF))
        } else {
            out.append(0x83); out.append(UInt8(len >> 16)); out.append(UInt8((len >> 8) & 0xFF)); out.append(UInt8(len & 0xFF))
        }
        return out + content
    }

    private func seq(_ c: Data) -> Data { der(0x30, c) }
    private func set(_ c: Data) -> Data { der(0x31, c) }
    private func oid(_ o: Data) -> Data { der(0x06, o) }
    private func octetString(_ d: Data) -> Data { der(0x04, d) }

    // MARK: - PDF signing (incremental update, iText/MoldSign style)

    func signPDF(_ pdfData: Data, certDER: Data, tsaUnsignedAttr: Data? = nil,
                 signBlock: (Data) throws -> Data) throws -> Data {
        let text = String(decoding: pdfData, as: UTF8.self) // latin-1-ish view for regex scanning
        dbg("S1 text ok")

        // --- trailer info ---
        guard let eofDRange = pdfData.range(of: Data("%%EOF".utf8), options: .backwards) else {
            throw CardError.signFailed("Cannot find %%EOF")
        }
        let appendOffset = pdfData.distance(from: pdfData.startIndex, to: eofDRange.lowerBound) + 5
        guard let startxrefRange = text.range(of: "startxref", options: .backwards),
              let eofRange = text.range(of: "%%EOF", options: .backwards) else {
            throw CardError.signFailed("Cannot find trailer")
        }
        let sxNumStr = text[startxrefRange.upperBound..<eofRange.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let origXref = Int(sxNumStr) else { throw CardError.signFailed("Bad startxref") }

        dbg("S2 eof/startxref ok")
        let trailerTail = String(text.suffix(2048))
        guard let rootNum = firstMatchInt(trailerTail, #"/Root (\d+) 0 R"#) else {
            throw CardError.signFailed("No /Root in trailer")
        }
        let idPair = firstMatch(trailerTail, #"/ID\s*\[\s*<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>"#)

        // --- original catalog object (plain-text search) ---
        dbg("S3 root=\(rootNum)")
        guard let catDict = findObjectDict(text, num: rootNum) else {
            throw CardError.signFailed("Catalog object not found")
        }
        // multi-signature: reuse the existing AcroForm and append our field to /Fields
        let existingAcroNum = firstMatchInt(catDict, #"/AcroForm (\d+) 0 R"#)

        dbg("S4 catDict ok")
        // object numbers for the update
        let maxObj = (try? NSRegularExpression(pattern: #"(\d+) 0 obj"#)
            .matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap { Range($0.range(at: 1), in: text).map { Int(text[$0])! } }
            .max()) ?? 0
        let sigNum = maxObj + 1, acroNum = maxObj + 2, fieldNum = maxObj + 3

        dbg("S5 maxObj=\(maxObj)")
        // first page object for the widget's /P (optional)
        let pageNum = findFirstPage(text)

        dbg("S6 page=\(String(describing: pageNum))")
        // --- build appended objects (ByteRange + Contents use fixed-width placeholders) ---
        let brDummy = "/ByteRange [0 0000000000 0000000000 0000000000 ]"
        let contents = "/Contents<" + String(repeating: "0", count: Self.placeholderHexLen) + ">"
        let sigDict = "\n\(sigNum) 0 obj\n<</Type/Sig /Filter/Adobe.PPKLite /SubFilter/ETSI.CAdES.detached \(brDummy) \(contents) /M(\(pdfDate())) /Reason(MoldSign Signature) /Location(Moldova) /ContactInfo() /Prop_Build<</App<</Name/>>>>>>\nendobj\n"
        let acroForm = "\(acroNum) 0 obj\n<</Fields[\(fieldNum) 0 R]/SigFlags 3>>\nendobj\n"
        let pref = pageNum.map { "/P \($0) 0 R" } ?? ""
        // next unique field name: max existing "/T (SignatureN)" index (whitespace-tolerant)
        var sigCount = 0
        if let nameRE = try? NSRegularExpression(pattern: #"/T\s*\(\s*Signature(\d+)"#) {
            for m in nameRE.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                if let r = Range(m.range(at: 1), in: text), let n = Int(text[r]) { sigCount = max(sigCount, n) }
            }
        }
        let sigField = "\(fieldNum) 0 obj\n<</FT/Sig /T(Signature\(sigCount + 1)) /Type/Annot /Subtype/Widget /Rect[0 0 0 0] /F 0 \(pref) /V \(sigNum) 0 R>>\nendobj\n"

        let chunks: [String]
        if let acroRef = existingAcroNum, let acroDict = findObjectDict(text, num: acroRef) {
            // counter-sign: update the existing AcroForm's /Fields; catalog keeps pointing at it
            guard let fieldsRE = try? NSRegularExpression(pattern: #"/Fields\s*\[([^\]]*)\]"#),
                  let m = fieldsRE.firstMatch(in: acroDict, range: NSRange(acroDict.startIndex..., in: acroDict)),
                  let rAll = Range(m.range, in: acroDict), let r1 = Range(m.range(at: 1), in: acroDict) else {
                throw CardError.signFailed("AcroForm /Fields not found")
            }
            let oldFields = acroDict[r1].trimmingCharacters(in: .whitespaces)
            var newAcroDict = acroDict.replacingCharacters(in: rAll, with: "/Fields[\(oldFields) \(fieldNum) 0 R]")
            if !newAcroDict.contains("/SigFlags") {
                newAcroDict = dictInserting(newAcroDict, "/SigFlags 3")
            }
            chunks = [sigDict, sigField, "\(acroRef) 0 obj\n\(newAcroDict)\nendobj\n"]
        } else {
            let acroForm = "\(acroNum) 0 obj\n<</Fields[\(fieldNum) 0 R]/SigFlags 3>>\nendobj\n"
            let esic = "/Extensions<</ESIC<</BaseVersion/1.7/ExtensionLevel 2>>>>"
            let catUpdated = "\(rootNum) 0 obj\n\(dictInserting(catDict, "/AcroForm \(acroNum) 0 R \(esic)"))\nendobj\n"
            chunks = [sigDict, acroForm, sigField, catUpdated]
        }

        dbg("S7 objs built")
        var body = chunks.map { Data($0.utf8) }.reduce(Data(), +)

        // --- xref (per-object subsections, iText style) ---
        var offsets: [(Int, Int)] = [] // (objNum, offset)
        var pos = appendOffset
        for chunk in chunks {
            let num = Int(chunk.drop(while: { !$0.isNumber }).prefix(while: { $0.isNumber })) ?? 0
            offsets.append((num, pos + (chunk.hasPrefix("\n") ? 1 : 0)))
            pos += chunk.utf8.count
        }
        dbg("S8 offsets ok")
        let xrefPos = appendOffset + body.count
        var xref = "xref\n0 1\n0000000000 65535 f \n"
        for (num, off) in offsets.sorted(by: { $0.0 < $1.0 }) {
            xref += "\(num) 1\n\(pad10(off)) 00000 n \n"
        }
        var trailer = "trailer\n<</Size \(maxObj + 4) /Root \(rootNum) 0 R /Prev \(origXref)"
        if let idPair = idPair { trailer += " /ID [<\(idPair[1])><\(idPair[2])>]" }
        trailer += ">>\nstartxref\n\(xrefPos)\n%%EOF\n"

        dbg("S9 xref/trailer ok")
        var signedPDF = pdfData + body + Data(xref.utf8) + Data(trailer.utf8)

        // --- ByteRange around the /Contents hex (single canonical occurrence) ---
        let marker = Data("/Contents<".utf8)
        guard let mRange = signedPDF.range(of: marker, options: .backwards) else {
            throw CardError.signFailed("Contents marker not found")
        }
        dbg("S10 contents marker ok")
        let cStart = signedPDF.distance(from: signedPDF.startIndex, to: mRange.upperBound)   // first hex char
        let cEnd = cStart + Self.placeholderHexLen                                        // byte after last hex char
        let total = signedPDF.count
        let brActual = "/ByteRange [0 \(pad10(cStart - 1)) \(pad10(cEnd + 1)) \(pad10(total - cEnd - 1)) ]"

        // patch the ByteRange in place (same width as dummy)
        let brDummyBytes = Data(brDummy.utf8)
        guard let brRange = signedPDF.range(of: brDummyBytes) else {
            throw CardError.signFailed("ByteRange placeholder not found")
        }
        dbg("S11 br found")
        signedPDF.replaceSubrange(brRange, with: Data(brActual.utf8))

        // content digest over the two ranges (hex region excluded, '<'/'>' excluded)
        var digestInput = Data()
        digestInput += signedPDF.subdata(in: 0..<(cStart - 1))
        digestInput += signedPDF.subdata(in: (cEnd + 1)..<total)
        dbg("S12 ranges ok")
        let contentDigest = digestInput.sha256()
        print("    Content digest: \(contentDigest.hexString)")

        // --- CMS ---
        dbg("S13 digest ok")
        let cms = try buildFullCMS(contentDigest: contentDigest, certDER: certDER, tsaUnsignedAttr: tsaUnsignedAttr, signBlock: signBlock)
        let cmsHex = cms.hexString.lowercased()
        guard cmsHex.count <= Self.placeholderHexLen else {
            throw CardError.signFailed("CMS too large for placeholder")
        }
        let paddedHex = cmsHex + String(repeating: "0", count: Self.placeholderHexLen - cmsHex.count)
        let hexBytes = Data(paddedHex.utf8)
        for i in 0..<hexBytes.count { signedPDF[cStart + i] = hexBytes[i] }
        return signedPDF
    }

    /// Build full detached CMS via buildFullCMS (legacy entry used by cms-for-hash mode).
    func buildDetachedCMS(contentDigest: Data, certDER: Data,
                          signBlock: (Data) throws -> Data) throws -> Data {
        try buildFullCMS(contentDigest: contentDigest, certDER: certDER, signBlock: signBlock)
    }

    /// Full CAdES CMS: signedAttrs (contentType, signingTime, messageDigest, signingCertificateV2),
    /// CA chain, and an RFC3161 timestamp unsignedAttr from MDQTSA.
    /// tsaUnsignedAttr: pre-built timestamp unsignedAttr (tests); nil = fetch live from MDQTSA.
    func buildFullCMS(contentDigest: Data, certDER: Data,
                      tsaUnsignedAttr: Data? = nil,
                      signBlock: (Data) throws -> Data) throws -> Data {
        let certInfo = try parseCertInfo(certDER)
        let signingTime = formatUTCTime()
        let rawAttrs = try buildSignedAttrs(digest: contentDigest, certDER: certDER, signingTime: signingTime)
        let attrsHash = set(rawAttrs).sha256()
        let digestInfo = seq(seq(oid(Self.oidSha256) + Data([0x05, 0x00])) + der(0x04, attrsHash))
        let signature = try signBlock(digestInfo)
        guard !signature.isEmpty else { throw CardError.signFailed("Empty signature") }
        let unsignedAttr = try tsaUnsignedAttr ?? buildTimestampUnsignedAttr(signature: signature)
        return try buildCMS(signature: signature, signedAttrs: rawAttrs,
                            certDER: certDER, certInfo: certInfo, unsignedAttr: unsignedAttr)
    }

    // MARK: - RFC 3161 timestamp (MDQTSA)

    /// Fetch an RFC3161 TimeStampToken (ContentInfo) over the SHA-256 digest of `data` from MDQTSA.
    static func fetchTimestampToken(data: Data) throws -> Data {
        let req = TimestampRequest.build(messageBytes: data.sha256())
        let tmp = FileManager.default.temporaryDirectory
        let reqFile = tmp.appendingPathComponent("msa-tsreq-\(UUID().uuidString).bin")
        let respFile = tmp.appendingPathComponent("msa-tsresp-\(UUID().uuidString).bin")
        try req.write(to: reqFile)
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
        proc.arguments = ["-sS", "-m", "30", "-X", "POST", PAdESSigner.tsaURL,
                          "-H", "Content-Type: application/timestamp-query",
                          "--data-binary", "@\(reqFile.path)", "-o", respFile.path]
        try proc.run()
        proc.waitUntilExit()
        defer { try? FileManager.default.removeItem(at: reqFile); try? FileManager.default.removeItem(at: respFile) }
        guard proc.terminationStatus == 0,
              let tsResp = try? Data(contentsOf: respFile), tsResp.count > 10 else {
            throw CardError.signFailed("TSA request failed (curl status \(proc.terminationStatus))")
        }
        // TimeStampResponse { status, timeStampToken ContentInfo OPTIONAL } — take 2nd element
        var pos = skipTLVHeaderStatic(tsResp, at: 0)
        pos += skipTLVStatic(tsResp, at: pos)
        guard pos < tsResp.count else { throw CardError.signFailed("TSA response has no token") }
        let tokenLen = skipTLVStatic(tsResp, at: pos)
        return tsResp.subdata(in: pos..<(pos + tokenLen))
    }

    private static func skipTLVStatic(_ d: Data, at off: Int) -> Int {
        let l1 = Int(d[off + 1])
        if l1 < 0x80 { return 2 + l1 }
        if l1 == 0x81 { return 3 + Int(d[off + 2]) }
        if l1 == 0x82 { return 4 + Int(d[off + 2]) * 256 + Int(d[off + 3]) }
        return 2
    }
    private static func skipTLVHeaderStatic(_ d: Data, at off: Int) -> Int {
        let l1 = Int(d[off + 1])
        if l1 < 0x80 { return 2 }
        if l1 == 0x81 { return 3 }
        if l1 == 0x82 { return 4 }
        return 2
    }

    private func buildTimestampUnsignedAttr(signature: Data) throws -> Data {
        let token = try Self.fetchTimestampToken(data: signature)

        // unsignedAttr: SEQUENCE { OID id-aa-timeStampToken, SET { token } }
        return seq(oid(Self.oidTimeStampToken) + set(token))
    }

    // MARK: - Signed attributes

    private func buildSignedAttrs(digest: Data, certDER: Data, signingTime: String) throws -> Data {
        var attrs = Data()
        attrs += seq(oid(Self.oidContentType) + set(oid(Self.oidIdData)))
        attrs += seq(oid(Self.oidSigningTime) + set(der(0x17, Data(signingTime.utf8))))
        attrs += seq(oid(Self.oidMessageDigest) + set(octetString(digest)))
        // signingCertificateV2: SET { SEQ { SEQ { SEQ { OCTET STRING sha256(cert) } } } }
        let essCertIDv2 = seq(octetString(certDER.sha256()))
        attrs += seq(oid(Self.oidSigningCertificateV2) + set(seq(seq(essCertIDv2))))
        return attrs
    }

    // MARK: - CMS

    private func buildCMS(signature: Data, signedAttrs: Data, certDER: Data,
                          certInfo: CertInfo, unsignedAttr: Data?) throws -> Data {
        let version = der(0x02, Data([0x01]))
        let sha256Alg = der(0x30, der(0x06, Self.oidSha256) + Data([0x05, 0x00]))
        let digestAlgs = der(0x31, sha256Alg)
        let encapContent = der(0x30, der(0x06, Self.oidIdData))
        // signer + MDQSign CA + mdtrustca root (same set the MoldSign app embeds)
        let certs = der(0xA0, certDER + ChainCerts.mdQSign + ChainCerts.mdTrustCA)

        let siVersion = der(0x02, Data([0x01]))
        let iasn = der(0x30, certInfo.issuer + certInfo.serial)
        let siDigestAlg = der(0x30, der(0x06, Self.oidSha256) + Data([0x05, 0x00]))
        let signedAttrsImplicit = der(0xA0, signedAttrs)
        let siSigAlg = der(0x30, der(0x06, Self.oidSha256WithRSA) + Data([0x05, 0x00]))
        let siSig = der(0x04, signature)
        let unsignedPart = unsignedAttr.map { der(0xA1, $0) } ?? Data()

        let signerInfo = der(0x30, siVersion + iasn + siDigestAlg + signedAttrsImplicit + siSigAlg + siSig + unsignedPart)
        let signerInfos = der(0x31, signerInfo)
        let signedData = der(0x30, version + digestAlgs + encapContent + certs + signerInfos)
        return der(0x30, der(0x06, Self.oidIdSignedData) + der(0xA0, signedData))
    }

    // MARK: - Certificate parsing (minimal)

    struct CertInfo {
        let issuer: Data
        let serial: Data
    }

    private func parseCertInfo(_ der: Data) throws -> CertInfo {
        let d = der
        var pos = 4 // skip Certificate SEQ header
        pos += 4 // skip TBS SEQUENCE header
        if d[pos] == 0xA0 { pos += skipTLV(d, at: pos) } // [0] version
        let serialStart = pos
        let serialLen = skipTLV(d, at: pos)
        let serial = d.subdata(in: serialStart..<(serialStart + serialLen))
        pos += serialLen
        pos += skipTLV(d, at: pos) // signature AlgorithmIdentifier
        let issuerStart = pos
        let issuerLen = skipTLV(d, at: pos)
        let issuer = d.subdata(in: issuerStart..<(issuerStart + issuerLen))
        return CertInfo(issuer: issuer, serial: serial)
    }

    /// Full TLV length (tag+len+content) at offset.
    private func skipTLV(_ d: Data, at offset: Int) -> Int {
        guard offset + 1 < d.count else { return 0 }
        let l1 = Int(d[offset + 1])
        if l1 < 0x80 { return 2 + l1 }
        if l1 == 0x81 { return 3 + Int(d[offset + 2]) }
        if l1 == 0x82 { return 4 + Int(d[offset + 2]) * 256 + Int(d[offset + 3]) }
        if l1 == 0x83 { return 5 + Int(d[offset + 2]) * 65536 + Int(d[offset + 3]) * 256 + Int(d[offset + 4]) }
        return 2
    }

    /// Length of just the TLV header (tag+length bytes).
    private func skipTLVHeader(_ d: Data, at offset: Int) -> Int {
        guard offset + 1 < d.count else { return 0 }
        let l1 = Int(d[offset + 1])
        if l1 < 0x80 { return 2 }
        if l1 == 0x81 { return 3 }
        if l1 == 0x82 { return 4 }
        if l1 == 0x83 { return 5 }
        return 2
    }

    // MARK: - Helpers

    private func formatUTCTime() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyMMddHHmmss'Z'"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: Date())
    }

    private func pdfDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "'D:'yyyyMMddHHmmssXXX"
        let s = f.string(from: Date()) // +03:00 -> +03'00'
        return s.replacingOccurrences(of: ":00", with: "'00'")
    }

    /// Insert dictionary entries immediately before the final ">>" of a "<< ... >>" dict.
    private func dictInserting(_ dict: String, _ entries: String) -> String {
        var d = dict
        guard let r = d.range(of: ">>", options: .backwards) else { return dict }
        d.replaceSubrange(r, with: entries + ">>")
        return d
    }

    private func pad10(_ v: Int) -> String {
        let s = String(v)
        return String(repeating: "0", count: max(0, 10 - s.count)) + s
    }

    private func firstMatch(_ text: String, _ pattern: String) -> [String]? {
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        return (0..<re.numberOfCaptureGroups + 1).compactMap { Range(m.range(at: $0), in: text).map { String(text[$0]) } }
    }

    private func firstMatchInt(_ text: String, _ pattern: String) -> Int? {
        guard let g = firstMatch(text, pattern), g.count > 1 else { return nil }
        return Int(g[1])
    }

    /// Extract the "<< ... >>" dictionary of the LATEST version of object `num` (plain-text objects only).
    private func findObjectDict(_ text: String, num: Int) -> String? {
        guard let re = try? NSRegularExpression(pattern: "(?<!\\d)\(num) 0 obj") else { return nil }
        let ns = text as NSString
        let matches = re.matches(in: text, range: NSRange(location: 0, length: ns.length))
        guard let last = matches.last, let rLast = Range(last.range, in: text) else { return nil }
        let objRange = rLast
        var i = objRange.upperBound
        guard let start = text.range(of: "<<", range: i..<text.endIndex) else { return nil }
        var depth = 0
        i = start.lowerBound
        while i < text.endIndex {
            if text[i...].hasPrefix("<<") {
                depth += 1; i = text.index(i, offsetBy: 2)
            } else if text[i...].hasPrefix(">>") {
                depth -= 1; i = text.index(i, offsetBy: 2)
                if depth == 0 { return String(text[start.lowerBound..<i]) }
            } else {
                i = text.index(after: i)
            }
        }
        return nil
    }

    private func findFirstPage(_ text: String) -> Int? {
        let ns = text as NSString
        guard let re = try? NSRegularExpression(pattern: #"(\d+) 0 obj"#) else { return nil }
        for m in re.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            let after = m.range.upperBound
            let slice = ns.substring(with: NSRange(location: after, length: min(300, ns.length - after)))
            if slice.contains("/Type/Page"), !slice.contains("/Type/Pages") {
                return Int(ns.substring(with: m.range(at: 1)))
            }
        }
        return nil
    }
}

extension Data {
    func replacingData(_ target: Data, with replacement: Data) -> Data {
        var result = Data()
        var searchStart = startIndex
        while let r = range(of: target, in: searchStart..<endIndex) {
            result += subdata(in: searchStart..<r.lowerBound)
            result += replacement
            searchStart = r.upperBound
        }
        result += subdata(in: searchStart..<endIndex)
        return result
    }

    func range(of data: Data, in range: Range<Data.Index>) -> Range<Data.Index>? {
        let slice = subdata(in: range)
        guard let r = slice.range(of: data) else { return nil }
        return range.lowerBound + slice.distance(from: slice.startIndex, to: r.lowerBound)..<range.lowerBound + slice.distance(from: slice.startIndex, to: r.upperBound)
    }
}
