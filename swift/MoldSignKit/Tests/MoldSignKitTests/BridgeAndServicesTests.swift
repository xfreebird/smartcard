import XCTest
@testable import MoldSignKit

final class BridgeOriginPolicyTests: XCTestCase {
    func testVendorListMatchesSpec() throws {
        let url = VectorTests.repoRoot.appendingPathComponent("spec/bridge/allowed-origins.properties")
        let fromSpec = BridgeOriginPolicy(propertiesText: try String(contentsOf: url, encoding: .utf8))
        XCTAssertEqual(fromSpec.patterns, BridgeOriginPolicy.vendorPatterns, "regenerate BridgeOriginPolicy.vendorPatterns from spec/")
    }

    func testOrigins() {
        let p = BridgeOriginPolicy.vendorDefault
        XCTAssertTrue(p.allows(origin: "https://msign.gov.md", moldSignHeader: nil))
        XCTAssertTrue(p.allows(origin: "https://mpass.gov.md", moldSignHeader: nil))
        XCTAssertTrue(p.allows(origin: "https://sgre.micb.md", moldSignHeader: nil))
        XCTAssertFalse(p.allows(origin: "https://evil.example", moldSignHeader: nil))
        XCTAssertFalse(p.allows(origin: "https://msign.gov.md.evil.example", moldSignHeader: nil))
        // the header only counts for origin-less (non-browser) clients, like the vendor server
        XCTAssertFalse(p.allows(origin: "https://evil.example", moldSignHeader: "DesktopSuiteClient"))
        XCTAssertTrue(p.allows(origin: nil, moldSignHeader: "DesktopSuiteClient"))
        XCTAssertFalse(p.allows(origin: nil, moldSignHeader: nil))
    }
}

final class TrustServicesTests: XCTestCase {
    func testOCSPRequestStructure() throws {
        // leaf = MDQSign (issued by mdtrustca): CertID must carry sha1(issuer DN), sha1(issuer key), leaf serial
        let req = try TrustServices.ocspRequest(issuerDER: ChainCerts.mdTrustCA, certDER: ChainCerts.mdQSign)
        let issuer = try CertFields(ChainCerts.mdTrustCA)
        let leaf = try CertFields(ChainCerts.mdQSign)
        XCTAssertEqual(req.first, 0x30)
        XCTAssertNotNil(req.range(of: issuer.subjectDER.sha1()))
        XCTAssertNotNil(req.range(of: issuer.publicKeyBits.sha1()))
        XCTAssertNotNil(req.range(of: leaf.serialTLV))
        // RSA-4096 key: BIT STRING content is the RSAPublicKey SEQUENCE
        XCTAssertEqual(issuer.publicKeyBits.first, 0x30)
    }

    func testCertificateSummary() {
        let s = SigningService.CertificateSummary(der: ChainCerts.mdQSign)
        XCTAssertEqual(s.holder, "MDQSign")
        XCTAssertNotNil(s.notAfter)
        XCTAssertEqual(s.sha1Hex.count, 40)
    }

    func testOutputNamingNeverOverwrites() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let input = dir.appendingPathComponent("contract.pdf")
        let first = SigningService.outputURL(for: input)
        XCTAssertEqual(first.lastPathComponent, "contract-semnat.pdf")
        FileManager.default.createFile(atPath: first.path, contents: Data())
        XCTAssertEqual(SigningService.outputURL(for: input).lastPathComponent, "contract-semnat 2.pdf")
        XCTAssertEqual(SigningService.outputURL(for: input, pathExtension: "xml").lastPathComponent, "contract-semnat.xml")
    }
}

/// Live calls to the public MD PKI (TSA, CRL, OCSP). Opt-in: MSIGN_NETWORK_TESTS=1.
final class TrustServicesNetworkTests: XCTestCase {
    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["MSIGN_NETWORK_TESTS"] == "1", "set MSIGN_NETWORK_TESTS=1")
    }

    func testTimestampToken() throws {
        let token = try PAdESSigner.fetchTimestampToken(data: Data("moldsign network test".utf8))
        XCTAssertEqual(token.first, 0x30)
        // ContentInfo { id-signedData, ... }
        XCTAssertNotNil(token.range(of: Data([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x07, 0x02])))
    }

    func testCRLRef() throws {
        let ref = try XCTUnwrap(XAdESSigner.fetchCRLRef(for: ChainCerts.mdQSign))
        XCTAssertTrue(ref.contains("http://pki.md/crl/mdtrustca.crl"), ref)
    }

    func testOCSPNativeMatchesOpenSSL() throws {
        let native = try XCTUnwrap(try XAdESSigner.fetchOCSPResponse(issuerDER: ChainCerts.mdQSign,
                                                                      certDER: try Self.leafCert()))
        let nativeInfo = try XCTUnwrap(XAdESSigner.parseOCSPInfo(native))
        #if os(macOS)
        let viaOpenSSL = try XCTUnwrap(try XAdESSigner.fetchOCSPResponseViaOpenSSL(issuerDER: ChainCerts.mdQSign,
                                                                                     certDER: try Self.leafCert()))
        XCTAssertEqual(XAdESSigner.parseOCSPInfo(viaOpenSSL)?.responder, nativeInfo.responder)
        #endif
    }

    /// A certificate issued by MDQSign (e.g. `moldsign cert --out leaf.der`). Personal data, so not a fixture:
    /// pass it via MSIGN_TEST_LEAF_CERT (default /tmp/cert.der).
    static func leafCert() throws -> Data {
        let path = ProcessInfo.processInfo.environment["MSIGN_TEST_LEAF_CERT"] ?? "/tmp/cert.der"
        try XCTSkipUnless(FileManager.default.fileExists(atPath: path), "no leaf certificate at \(path)")
        return try Data(contentsOf: URL(fileURLWithPath: path))
    }
}

/// Real signature from the vendor middleware (re/sig1.der): exercises RSA verify + offline chain on
/// whichever backend this build uses (Security.framework, or OpenSSL in MOLDSIGN_PORTABLE / Linux).
final class RealSignatureTests: XCTestCase {
    func testMiddlewareCMSSignatureAndChainVerify() throws {
        let url = VectorTests.repoRoot.appendingPathComponent("re/sig1.der")
        try XCTSkipUnless(FileManager.default.fileExists(atPath: url.path), "re/sig1.der not present")
        let report = Validator.validateCMS(try Data(contentsOf: url), content: Data(), name: "sig1", kind: "CAdES")
        XCTAssertTrue(report.signatureValid, report.summary)
        XCTAssertTrue(report.chainTrusted, report.summary)
    }

    func testTamperedSignatureFails() throws {
        let url = VectorTests.repoRoot.appendingPathComponent("re/sig1.der")
        try XCTSkipUnless(FileManager.default.fileExists(atPath: url.path), "re/sig1.der not present")
        var cms = try Data(contentsOf: url)
        let parts = try XCTUnwrap(Validator.parseSignedData(cms))
        let sigStart = try XCTUnwrap(cms.range(of: parts.signature)).lowerBound
        cms[sigStart + 10] ^= 0x01
        XCTAssertFalse(Validator.validateCMS(cms, content: Data(), name: "sig1", kind: "CAdES").signatureValid)
    }
}

final class BuildInfoTests: XCTestCase {
    func testBackendMatchesBuildMode() {
        XCTAssertEqual(BuildInfo.cryptoBackend, BuildInfo.isPortable ? "OpenSSL" : "CommonCrypto/CryptoKit")
    }
}

/// Live loopback test of the consent hook (SEC-02) and the sign-result callback (MAC-05, LNX-11).
final class BridgeConsentTests: XCTestCase {
    func testDeniedRequestReportsResultAndNeverTouchesTheCard() throws {
        let server = MoldSignServer(tlsP12: nil, httpPort: 28490, httpsPort: 28491)
        let asked = expectation(description: "consent asked")
        let reported = expectation(description: "result reported")
        var seen: (BridgeRequest, Error?)?
        server.authorize = { request in
            XCTAssertEqual(request.origin, "https://msign.gov.md")
            XCTAssertEqual(request.operation, .signData)
            asked.fulfill()
            return .deny
        }
        server.onSignResult = { request, error in
            seen = (request, error)
            reported.fulfill()
        }
        SigningService.shared.transportFactory = { _ in XCTFail("card must not be touched after a denial"); throw CardError.noReader }
        defer {
            server.stop()
            SigningService.shared.transportFactory = { try CardTransports.connect(reader: $0) }
        }
        try server.start()

        let body = Data(#"{"data":"PGEvPg==","contentType":"xml","signFormat":"XAdES-BES"}"#.utf8)
        let created = try request("POST", "/sign/data", body: body)
        XCTAssertTrue(created.hasPrefix("HTTP/1.1 201"), created)
        wait(for: [asked, reported], timeout: 10)
        XCTAssertNotNil(seen?.1, "a denial must be reported as an error")

        // the poll now returns the error payload to the browser
        let location = try XCTUnwrap(created.components(separatedBy: "\r\n").first { $0.hasPrefix("Location:") })
        let path = try XCTUnwrap(location.components(separatedBy: "127.0.0.1").last)
        let polled = try request("GET", path, body: nil)
        XCTAssertTrue(polled.hasPrefix("HTTP/1.1 400"), polled)                      // vendor-style failure
        XCTAssertTrue(polled.contains("error: user denied the signing request"), polled)
    }

    /// Regression: the poll must be held until the user decides (vendor long-poll), never answered with 303.
    /// Browsers follow at most 20 redirects, so 0.5 s/303 loops failed whenever consent + PIN took > ~10 s.
    func testPollIsLongHeldWhileConsentIsPending() throws {
        let server = MoldSignServer(tlsP12: nil, httpPort: 28492, httpsPort: 28493)
        server.authorize = { _ in
            Thread.sleep(forTimeInterval: 3)   // the user reading the consent sheet
            return .deny
        }
        SigningService.shared.transportFactory = { _ in throw CardError.noReader }
        defer {
            server.stop()
            SigningService.shared.transportFactory = { try CardTransports.connect(reader: $0) }
        }
        try server.start()
        let body = Data(#"{"data":"PGEvPg==","contentType":"xml","signFormat":"XAdES-BES"}"#.utf8)
        let created = try request("POST", "/sign/data", body: body, port: 28492)
        let location = try XCTUnwrap(created.components(separatedBy: "\r\n").first { $0.hasPrefix("Location:") })
        let path = try XCTUnwrap(location.components(separatedBy: "127.0.0.1").last)
        let started = Date()
        let polled = try request("GET", path, body: nil, port: 28492)
        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(started), 2.5, "the poll must wait for the decision")
        XCTAssertFalse(polled.hasPrefix("HTTP/1.1 303"), polled)
        XCTAssertTrue(polled.hasPrefix("HTTP/1.1 400"), polled)
        // a second poll for a consumed session is a clean 404, not a hang
        XCTAssertTrue(try request("GET", path, body: nil, port: 28492).hasPrefix("HTTP/1.1 404"))
    }

    /// Raw request through the core's plain-HTTP client (no proxy, no HSTS), as an allowed browser origin.
    private func request(_ method: String, _ path: String, body: Data?, port: Int = 28490) throws -> String {
        let raw = try PlainHTTP.sendReturningRaw(method: method, url: "http://127.0.0.1:\(port)\(path)", body: body,
                                                 contentType: body == nil ? nil : "application/json",
                                                 extraHeaders: ["Origin: https://msign.gov.md"], timeout: 10)
        return String(decoding: raw, as: UTF8.self)
    }
}

/// Diacritics in certificate names must display as written (bug: "M\C3\AEndru").
final class X509NameTests: XCTestCase {
    private func name(_ cn: Data, tag: UInt8) -> Data {
        DER.seq(DER.tlv(0x31, DER.seq(DER.tlv(0x06, Data([0x55, 0x04, 0x06])) + DER.tlv(0x13, Data("MD".utf8))))
                + DER.tlv(0x31, DER.seq(DER.tlv(0x06, Data([0x55, 0x04, 0x07])) + DER.tlv(0x0C, Data("Chișinău".utf8))))
                + DER.tlv(0x31, DER.seq(DER.tlv(0x06, Data([0x55, 0x04, 0x03])) + DER.tlv(tag, cn))))
    }

    func testDirectoryStringsDecode() {
        XCTAssertEqual(X509Name.commonName(name(Data("Ștefan Mîndru".utf8), tag: 0x0C)), "Ștefan Mîndru")              // UTF8String
        XCTAssertEqual(X509Name.commonName(name(Data("Ștefan Țurcanu".utf16BigEndianBytes), tag: 0x1E)), "Ștefan Țurcanu") // BMPString
        XCTAssertEqual(X509Name.commonName(name(Data([0x52, 0xE9, 0x6D, 0x79]), tag: 0x14)), "Rémy")              // Teletex/Latin-1
        XCTAssertEqual(X509Name.displayString(name(Data("Ștefan Mîndru".utf8), tag: 0x0C)), "CN=Ștefan Mîndru,L=Chișinău,C=MD")
    }

    func testRealCANamesDecodeButXAdESKeepsVendorEscapes() throws {
        // MDQSign's O and L contain ț/ș/ă/ș: decoded for display …
        let summary = SigningService.CertificateSummary(der: ChainCerts.mdQSign)
        XCTAssertEqual(summary.holder, "MDQSign")
        XCTAssertEqual(summary.issuerName, "mdtrustca")
        XCTAssertTrue(summary.subjectDN.contains("L=Chișinău"), summary.subjectDN)
        XCTAssertFalse(summary.subjectDN.contains("\\"), summary.subjectDN)
        // … while the XAdES X509IssuerName keeps the byte-exact vendor form
        XCTAssertTrue(try XAdESSigner.parseIssuer(ChainCerts.mdQSign).issuerDNRFC2253.contains("Chi\\C8\\99in\\C4\\83u"))
    }

    #if canImport(Security)
    func testCardHolderWithDiacritics() throws {
        let identity = try TestIdentity(commonName: "Ștefan Mîndru")
        XCTAssertEqual(SigningService.CertificateSummary(der: identity.certDER).holder, "Ștefan Mîndru")
        XCTAssertEqual(Validator.subjectCN(identity.certDER), "Ștefan Mîndru")
    }
    #endif
}

private extension String {
    var utf16BigEndianBytes: [UInt8] { utf16.flatMap { [UInt8($0 >> 8), UInt8($0 & 0xFF)] } }
}
