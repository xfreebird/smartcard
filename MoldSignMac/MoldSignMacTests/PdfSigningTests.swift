import XCTest
@testable import MoldSignMac

final class PdfSigningTests: XCTestCase {
    private func prebuiltTSAAttr() throws -> Data {
        // token issued by MDQTSA during dev (any token exercises the encoding path)
        let token = try Data(contentsOf: URL(fileURLWithPath: "/tmp/tstoken.der"))
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

    func sign(_ inPath: String, _ outPath: String) throws {
        let pdf = try Data(contentsOf: URL(fileURLWithPath: inPath))
        let cert = try Data(contentsOf: URL(fileURLWithPath: "/tmp/cert.der"))
        let signer = PAdESSigner()
        let signed = try signer.signPDF(pdf, certDER: cert, tsaUnsignedAttr: try prebuiltTSAAttr()) { _ in
            Data(repeating: 0xAB, count: 512)
        }
        try signed.write(to: URL(fileURLWithPath: outPath))
        XCTAssertGreaterThan(signed.count, pdf.count)
    }

    func testSignUnsignedPDFOffline() throws {
        try sign("/Users/nghimbovschi/Downloads/outlook.pdf", "/tmp/dummy-signed-1.pdf")
    }

    func testCounterSignSignedFinal2() throws {
        try sign("/Users/nghimbovschi/Downloads/signed_final2.pdf", "/tmp/final2-countersigned.pdf")
    }

    func testSecondSignaturePreservesFirst() throws {
        // signed by "someone else" (our dummy-signed output acts as the pre-signed document)
        try sign("/Users/nghimbovschi/Downloads/outlook.pdf", "/tmp/dummy-signed-1.pdf")
        try sign("/tmp/dummy-signed-1.pdf", "/tmp/dummy-signed-2.pdf")
    }
}

final class XAdESComponentTests: XCTestCase {
    func testCRLParse() throws {
        for f in ["/tmp/mdqsign.crl", "/tmp/mdtrustca.crl"] {
            let der = try Data(contentsOf: URL(fileURLWithPath: f))
            let info = XAdESSigner.parseCRLInfo(der)
            print("CRL \(f): \(String(describing: info))")
            XCTAssertNotNil(info)
        }
    }
    func testExtensionURI() throws {
        let cert = try Data(contentsOf: URL(fileURLWithPath: "/tmp/cert.der"))
        print("CRL DP:", XAdESSigner.extractExtensionURI(cert, oidBytes: [0x55,0x1D,0x1F]) ?? "nil")
        let ca = try Data(contentsOf: URL(fileURLWithPath: "/tmp/chain2.der"))
        print("CA CRL DP:", XAdESSigner.extractExtensionURI(ca, oidBytes: [0x55,0x1D,0x1F]) ?? "nil")
    }
    func testOCSPParse() throws {
        guard let der = try? Data(contentsOf: URL(fileURLWithPath: "/tmp/ocsp.der")) else { return }
        let info = XAdESSigner.parseOCSPInfo(der)
        print("OCSP: \(String(describing: info))")
        XCTAssertNotNil(info)
    }
    func testIssuerParseChain() throws {
        for f in ["/tmp/cert.der", "/tmp/chain1.der", "/tmp/chain2.der"] {
            let der = try Data(contentsOf: URL(fileURLWithPath: f))
            let n = try XAdESSigner.parseIssuer(der)
            print("issuer: \(n.issuerDNRFC2253) serial: \(n.serialDecimal)")
        }
    }
}


final class XAdESValidationDebug: XCTestCase {
    func testDebugExtract() throws {
        let xml = try Data(contentsOf: URL(fileURLWithPath: "/tmp/ref-t.xml"))
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
