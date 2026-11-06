import XCTest
@testable import MoldSignKit

/// Fixtures live in Tests/MoldSignKitTests/Fixtures (F-08): public PKI artifacts only
/// (MDQTSA token, MD CRLs, an OCSP response) plus a tiny unsigned PDF. No personal certificate.
enum Fixtures {
    static func data(_ name: String) throws -> Data {
        let parts = name.split(separator: ".")
        guard let url = Bundle.module.url(forResource: String(parts[0]), withExtension: String(parts[1]), subdirectory: "Fixtures") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try Data(contentsOf: url)
    }

    /// Any certificate works for structural signing tests; MDQSign is public.
    static var dummySignerCert: Data { ChainCerts.mdQSign }
}

final class PdfSigningTests: XCTestCase {
    private func prebuiltTSAAttr() throws -> Data {
        // token issued by MDQTSA during dev (any token exercises the encoding path)
        let token = try Fixtures.data("tstoken.der")
        // wrap: SEQUENCE { OID 1.2.840.113549.1.9.16.2.14, SET { token } }
        func der(_ tag: UInt8, _ c: Data) -> Data {
            var o = Data([tag]); let n = c.count
            if n < 0x80 { o.append(UInt8(n)) }
            else if n < 0x100 { o.append(0x81); o.append(UInt8(n)) }
            else if n < 0x10000 { o.append(0x82); o.append(UInt8(n>>8)); o.append(UInt8(n&0xFF)) }
            else { o.append(0x83); o.append(UInt8(n>>16)); o.append(UInt8((n>>8)&0xFF)); o.append(UInt8(n&0xFF)) }
            return o + c
        }
        return der(0x30, der(0x06, Data([0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x09,0x10,0x02,0x0E])) + der(0x31, token))
    }

    func sign(_ pdf: Data) throws -> Data {
        let signer = PAdESSigner()
        let signed = try signer.signPDF(pdf, certDER: Fixtures.dummySignerCert, tsaUnsignedAttr: try prebuiltTSAAttr()) { _ in
            Data(repeating: 0xAB, count: 512)
        }
        XCTAssertGreaterThan(signed.count, pdf.count)
        XCTAssertEqual(signed.prefix(pdf.count), pdf, "incremental update must not touch the original bytes")
        return signed
    }

    func testSignUnsignedPDFOffline() throws {
        let signed = try sign(try Fixtures.data("unsigned.pdf"))
        let text = String(decoding: signed, as: UTF8.self)
        XCTAssertTrue(text.contains("/SubFilter/ETSI.CAdES.detached"))
        XCTAssertTrue(text.contains("/T(Signature1)"))
        XCTAssertTrue(text.contains("/Extensions<</ESIC<</BaseVersion/1.7/ExtensionLevel 2>>>>"))
        // ByteRange covers everything except the /Contents hex
        let reports = Validator.validatePDF(signed)
        XCTAssertEqual(reports.count, 1)
        XCTAssertEqual(reports.first?.contentIntact, true)
    }

    func testVisibleCounterSignatureCoversAppearanceAndPreservesPriorBytes() throws {
        let first = try sign(Fixtures.data("unsigned.pdf"))
        let stamped = try PAdESSigner().signPDF(first, certDER: Fixtures.dummySignerCert,
            tsaUnsignedAttr: prebuiltTSAAttr(), appearance: .init()) { _ in Data(repeating: 0xAB, count: 512) }
        XCTAssertEqual(stamped.prefix(first.count), first)
        let reports = Validator.validatePDF(stamped)
        XCTAssertEqual(reports.count, 2)
        XCTAssertTrue(reports.allSatisfy { $0.contentIntact })
        let text = String(data: stamped, encoding: .isoLatin1)!
        let xref = text.range(of: "\nxref\n", options: .backwards)!
        let tail = String(text[xref.upperBound...])
        let entries = try NSRegularExpression(pattern: #"(\d+) 1\n(\d{10}) 00000 n"#)
            .matches(in: tail, range: NSRange(tail.startIndex..., in: tail))
        for entry in entries {
            let n = String(tail[Range(entry.range(at: 1), in: tail)!])
            let offset = Int(tail[Range(entry.range(at: 2), in: tail)!])!
            XCTAssertTrue(String(decoding: stamped.dropFirst(offset).prefix(n.utf8.count + 6), as: UTF8.self).hasPrefix("\(n) 0 obj"))
        }
    }

    func testSecondSignaturePreservesFirst() throws {
        // signed by "someone else" (our dummy-signed output acts as the pre-signed document)
        let once = try sign(try Fixtures.data("unsigned.pdf"))
        let twice = try sign(once)
        let text = String(decoding: twice, as: UTF8.self)
        XCTAssertTrue(text.contains("/T(Signature2)"))
        let reports = Validator.validatePDF(twice)
        XCTAssertEqual(reports.count, 2)
        XCTAssertTrue(reports.allSatisfy { $0.contentIntact }, "\(reports.map(\.summary))")
    }
}

final class XAdESComponentTests: XCTestCase {
    func testCRLParse() throws {
        for f in ["mdqsign.crl", "mdtrustca.crl"] {
            let info = XAdESSigner.parseCRLInfo(try Fixtures.data(f))
            XCTAssertNotNil(info, f)
        }
    }
    func testExtensionURI() throws {
        XCTAssertEqual(XAdESSigner.extractExtensionURI(ChainCerts.mdQSign, oidBytes: [0x55,0x1D,0x1F]),
                       "http://pki.md/crl/mdtrustca.crl")
    }
    func testOCSPParse() throws {
        let info = XAdESSigner.parseOCSPInfo(try Fixtures.data("ocsp.der"))
        XCTAssertNotNil(info)
    }
    func testIssuerParseChain() throws {
        for der in [ChainCerts.mdQSign, ChainCerts.mdTrustCA] {
            let n = try XAdESSigner.parseIssuer(der)
            XCTAssertTrue(n.issuerDNRFC2253.contains("CN=mdtrustca"), n.issuerDNRFC2253)
            XCTAssertFalse(n.serialDecimal.isEmpty)
        }
    }
}

final class XAdESValidationDebug: XCTestCase {
    func testDebugExtract() throws {
        let refPath = "/tmp/ref-t.xml"
        try XCTSkipUnless(FileManager.default.fileExists(atPath: refPath), "vendor reference signature not present")
        let xml = try Data(contentsOf: URL(fileURLWithPath: refPath))
        let doc = String(data: xml, encoding: .utf8)!
        let siStart = doc.range(of: "<ds:SignedInfo")!
        let siEnd = doc.range(of: "</ds:SignedInfo>")!
        let signedInfo = String(doc[siStart.lowerBound..<siEnd.upperBound])
        print("SIGNEDINFO LEN:", signedInfo.count)
        // bytes after extraction: first 120 chars
        print("SIGNEDINFO HEAD:", String(signedInfo.prefix(160)))
        // swift-side sha256 of full extracted substring c14n (no ns injection issues here
        // since we only compare reference block)
    }
}


final class XMLSearchDebug: XCTestCase {
    func testSearch() throws {
        try XCTSkipUnless(FileManager.default.fileExists(atPath: "/tmp/ref-t.xml"), "vendor reference signature not present")
        let doc = try String(contentsOfFile: "/tmp/ref-t.xml")
        print("HAS URI SP:", doc.contains("URI=\"#SignedProperties-"))
        if let r = doc.range(of: "URI=\"#SignedProperties-") {
            print("FOUND at prefix:", String(doc[r.lowerBound...].prefix(80)))
        } else {
            // dump around Reference
            if let rr = doc.range(of: "SignedProperties-Reference") {
                print("REF CONTEXT:", String(doc[doc.index(rr.lowerBound, offsetBy: -40)...].prefix(180)))
            }
        }
    }
}

/// The portal's XML/Text flow asks for signatureType "Embedded": the content must travel inside the signature.
final class XAdESEnvelopingTests: XCTestCase {
    func testEnvelopingSignatureEmbedsTheContent() throws {
        let content = Data("<doc>conținut de semnat</doc>".utf8)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("msa-env-\(UUID().uuidString).xml")
        try content.write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        let xml = try XAdESSigner().sign(files: [file], format: .bes, type: .enveloping,
                                         certDER: ChainCerts.mdQSign, chainDER: [ChainCerts.mdQSign],
                                         signBlock: { _ in Data(repeating: 0xAB, count: 512) },
                                         tsaBlock: { _ in XCTFail("BES needs no timestamp"); return Data() },
                                         ocspDerBlock: { _, _ in nil })
        let text = String(decoding: xml, as: UTF8.self)
        XCTAssertTrue(text.contains(#"<ds:Object Encoding="UTF-8" Id="FileObject-"#), text.prefix(400).description)
        XCTAssertTrue(text.contains(content.base64EncodedString()), "content must be embedded")
        XCTAssertTrue(text.contains("REC-xml-c14n-20010315#WithComments"))
        XCTAssertFalse(text.contains(#"URI="file:/"#), "enveloping must not reference an external file")
    }
}
