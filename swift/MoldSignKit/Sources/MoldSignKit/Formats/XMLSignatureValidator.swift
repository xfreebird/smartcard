import Foundation

// MARK: - XAdES XML signature validation (DOM-light, matches our/iaik structures)

struct XMLSig {
    let doc: String
    let files: [String: Data]

    func signatures() -> [Validator.Report] {
        var reps: [Validator.Report] = []
        // SignedInfo
        guard let siStart = doc.range(of: "<ds:SignedInfo"),
              let siEnd = doc.range(of: "</ds:SignedInfo>", range: siStart.upperBound..<doc.endIndex) else { return reps }
        let signedInfo = String(doc[siStart.lowerBound..<siEnd.upperBound])
        let sigId = attr("Id", in: doc, after: doc.range(of: "<ds:Signature ")?.lowerBound ?? doc.startIndex) ?? "?"

        var r = Validator.Report(kind: "XAdES", name: sigId, signer: "?", contentIntact: false,
                                 signatureValid: false, chainTrusted: false,
                                 signingTime: "-", timestampTime: nil, level: "XAdES-BES")

        // SignedProperties (digest -> compare)
        var allRefsOk = true
        if let spStart = doc.range(of: "<xades:SignedProperties"),
           let spEnd = doc.range(of: "</xades:SignedProperties>", range: spStart.upperBound..<doc.endIndex) {
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
        } else {
            // A valid SignedInfo signature does not make a missing signed-properties reference intact.
            allRefsOk = false
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
            guard let bytes = files[fname] else {
                r.missingDetachedReferences.append(fname)
                allRefsOk = false
                continue
            }
            guard let dv = digestValue(of: uri, in: signedInfo) else { allRefsOk = false; continue }
            let comp = digestAlgorithm(of: uri, in: signedInfo).hash(bytes).base64EncodedString()
            allRefsOk = allRefsOk && (dv == comp)
        }

        // signature validity: c14n(SignedInfo) + seckey verify
        let siC14n = c14nSubset(signedInfo, rootTag: "ds:SignedInfo",
                                namespaces: [("ds", "http://www.w3.org/2000/09/xmldsig#")])
        if let kiRange = doc.range(of: "<ds:X509Certificate>"),
           let kiEnd = doc.range(of: "</ds:X509Certificate>", range: kiRange.upperBound..<doc.endIndex),
           let certDER = Data(base64Encoded: String(doc[kiRange.upperBound..<kiEnd.lowerBound])
                                .replacingOccurrences(of: "\\s", with: "", options: .regularExpression)),
           let svStart = doc.range(of: "<ds:SignatureValue"),
           let svEnd = doc.range(of: "</ds:SignatureValue>", range: svStart.upperBound..<doc.endIndex) {
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
        if let t = doc.range(of: "<xades:SigningTime>"), let te = doc.range(of: "</xades:SigningTime>", range: t.upperBound..<doc.endIndex) {
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
