#if canImport(Security)
import XCTest
@testable import MoldSignKit

/// Card-free end-to-end tests: the simulated CosmoX card runs the real protocol and signs with a test key,
/// so the Validator checks genuine signatures (MAC-19 batches, R-11 SHA-1, wrong-PIN handling).
final class BridgeEndToEndTests: XCTestCase {
    private var card: SimulatedCardState!

    private var savedSink: ((MSLog.Level, String) -> Void)?

    override func setUp() {
        savedSink = MSLog.sink
        MSLog.sink = nil   // simulated SM traces are noise here
        card = SimulatedCardState(pin: "1234", tries: 3)
        let state = card!
        SigningService.shared.transportFactory = { _ in SimulatedCosmoXCard(state: state) }
        SigningService.shared.readersWithCards = { ["Simulated miniLector"] }   // never the host's real readers
    }

    override func tearDown() {
        MSLog.sink = savedSink
        SigningService.shared.transportFactory = { try CardTransports.connect(reader: $0) }
        SigningService.shared.readersWithCards = { CardTransports.readersWithCards() }
    }

    // MARK: - SigningService

    func testSigningServiceXAdESVerifiesWithBothDigests() throws {
        let doc = FileManager.default.temporaryDirectory.appendingPathComponent("msa-e2e-\(UUID().uuidString).xml")
        try Data("<doc>de semnat</doc>".utf8).write(to: doc)
        defer { try? FileManager.default.removeItem(at: doc) }
        for digest in [XAdESSigner.DigestAlgorithm.sha256, .sha1] {
            let xml = try SigningService.shared.signXAdES(files: [doc], format: .bes, type: .enveloping, digest: digest, pin: "1234")
            let report = try XCTUnwrap(Validator.validateXAdES(xml, referencedFiles: [:]).first)
            XCTAssertTrue(report.signatureValid, "\(digest): \(report.summary)")
            XCTAssertTrue(report.contentIntact, "\(digest): \(report.summary)")
            XCTAssertEqual(String(decoding: xml, as: UTF8.self).contains("xmldsig#rsa-sha1"), digest == .sha1)

            // tampering with the embedded content must be caught (FileObject reference)
            let original = Data("<doc>de semnat</doc>".utf8).base64EncodedString()
            let forged = Data("<doc>alt text</doc>".utf8).base64EncodedString()
            let tampered = Data(String(decoding: xml, as: UTF8.self).replacingOccurrences(of: original, with: forged).utf8)
            XCTAssertFalse(try XCTUnwrap(Validator.validateXAdES(tampered, referencedFiles: [:]).first).contentIntact)
        }
        XCTAssertEqual(card.verifyAttempts, 2)
    }

    // MARK: - Bridge

    func testPortalBatchNeedsOneConsentAndHonoursSHA1() throws {
        let server = MoldSignServer(tlsP12: nil, httpPort: 28494, httpsPort: 28495)
        var consents = 0
        server.authorize = { _ in consents += 1; return .allow(pin: "1234") }
        try server.start()
        defer { server.stop() }

        // document 1 of 2: the portal's first poll keeps the PIN session
        let body = Data(#"{"data":"PGRvYz4xPC9kb2M+","contentType":"Xml","signFormat":"XAdES-BES","signatureType":"Embedded","algorithm":"SHA-1"}"#.utf8)
        let first = try post("/sign/data", body, port: 28494)
        let firstLocation = try location(first)
        let firstSession = firstLocation.components(separatedBy: "/PKCS11/")[1].components(separatedBy: "/")[0]
        let result1 = try get(firstLocation + "?keep_pin_session=1", port: 28494)
        XCTAssertTrue(result1.hasPrefix("HTTP/1.1 200"), result1)
        let xml1 = try signedXML(result1)
        let report = try XCTUnwrap(Validator.validateXAdES(xml1, referencedFiles: [:]).first)
        XCTAssertTrue(report.signatureValid && report.contentIntact, report.summary)
        XCTAssertTrue(String(decoding: xml1, as: UTF8.self).contains("xmldsig#rsa-sha1"), "R-11: SHA-1 as requested")
        XCTAssertEqual(card.signedDigestInfos.last?.prefix(15), Data(hex: "3021300906052B0E03021A05000414"))

        // document 2: use_pin_session → no second consent / PIN prompt
        let second = try post("/sign/data?use_pin_session=\(firstSession)", body, port: 28494)
        let result2 = try get(try location(second), port: 28494)
        XCTAssertTrue(result2.hasPrefix("HTTP/1.1 200"), result2)
        XCTAssertEqual(consents, 1, "one consent for the whole batch")
        XCTAssertEqual(card.verifyAttempts, 2, "the card still verifies the (reused) PIN per document")

        // another origin can't ride on the batch's PIN session
        let foreign = try post("/sign/data?use_pin_session=\(firstSession)", body, port: 28494, origin: "https://mpass.gov.md")
        _ = try get(try location(foreign), port: 28494, origin: "https://mpass.gov.md")
        XCTAssertEqual(consents, 2)
    }

    func testWrongPINFromTheBrowserIsTriedOnceAndReported() throws {
        let server = MoldSignServer(tlsP12: nil, httpPort: 28496, httpsPort: 28497)
        server.authorize = { _ in .allow(pin: "9999") }
        let reported = expectation(description: "result")
        var outcome: Error?
        server.onSignResult = { _, error in outcome = error; reported.fulfill() }
        try server.start()
        defer { server.stop() }

        let body = Data(#"{"data":"PGRvYz4xPC9kb2M+","contentType":"Xml","signFormat":"XAdES-BES"}"#.utf8)
        let result = try get(try location(try post("/sign/data", body, port: 28496)), port: 28496)
        wait(for: [reported], timeout: 10)
        XCTAssertTrue(result.hasPrefix("HTTP/1.1 400") && result.contains("error: Signing failed: Wrong PIN, 2 attempts remaining"), result)
        guard case CardError.wrongPIN(let remaining)? = outcome else { return XCTFail("expected wrongPIN, got \(String(describing: outcome))") }
        XCTAssertEqual(remaining, 2)
        XCTAssertEqual(card.verifyAttempts, 1, "never retry a PIN automatically")
        XCTAssertTrue(card.signedDigestInfos.isEmpty)
    }

    func testSandboxBridgeRejectsPathsButSignsDataWithConsent() throws {
        let server = MoldSignServer(tlsP12: nil, httpPort: 28642, httpsPort: 28643,
                                    allowsFileSystemRoutes: false)
        var consents = 0
        server.authorize = { _ in consents += 1; return .allow(pin: "1234") }
        try server.start()
        defer { server.stop() }
        for route in ["/sign/pdf", "/sign/file", "/sign/file/verify", "/verify/pdf", "/sign/pdf/verify"] {
            let denied = try post(route, Data(#"{"path":"/etc/hosts"}"#.utf8), port: 28642)
            XCTAssertTrue(denied.hasPrefix("HTTP/1.1 403"), denied)
            XCTAssertTrue(denied.contains("filesystem routes disabled"))
        }
        XCTAssertEqual(consents, 0)
        XCTAssertEqual(card.verifyAttempts, 0)
        let body = Data(#"{"data":"PGRvYz4xPC9kb2M+","contentType":"Xml","signFormat":"XAdES-BES","signatureType":"Embedded"}"#.utf8)
        let deniedOrigin = try post("/sign/data", body, port: 28642, origin: "https://evil.example")
        XCTAssertTrue(deniedOrigin.hasPrefix("HTTP/1.1 403"))
        XCTAssertFalse(deniedOrigin.contains("Access-Control-Allow-Origin"))
        XCTAssertEqual(consents, 0)
        let created = try post("/sign/data", body, port: 28642)
        let result = try get(location(created), port: 28642)
        XCTAssertTrue(result.hasPrefix("HTTP/1.1 200"), result)
        let report = try XCTUnwrap(Validator.validateXAdES(try signedXML(result), referencedFiles: [:]).first)
        XCTAssertTrue(report.signatureValid && report.contentIntact)
        XCTAssertEqual(consents, 1)
        XCTAssertEqual(card.verifyAttempts, 1)
    }

    // MARK: - HTTP helpers (core plain-HTTP client: no proxy, no HSTS)

    private func post(_ path: String, _ body: Data, port: Int, origin: String = "https://msign.gov.md") throws -> String {
        String(decoding: try PlainHTTP.sendReturningRaw(method: "POST", url: "http://127.0.0.1:\(port)\(path)", body: body,
                                                        contentType: "application/json", extraHeaders: ["Origin: \(origin)"],
                                                        timeout: 30), as: UTF8.self)
    }

    private func get(_ pathOrURL: String, port: Int, origin: String = "https://msign.gov.md") throws -> String {
        let path = pathOrURL.hasPrefix("http") ? "/" + pathOrURL.components(separatedBy: "/").dropFirst(3).joined(separator: "/") : pathOrURL
        return String(decoding: try PlainHTTP.sendReturningRaw(method: "GET", url: "http://127.0.0.1:\(port)\(path)", body: nil,
                                                               contentType: nil, extraHeaders: ["Origin: \(origin)"], timeout: 30), as: UTF8.self)
    }

    private func location(_ response: String) throws -> String {
        let line = try XCTUnwrap(response.components(separatedBy: "\r\n").first { $0.hasPrefix("Location:") }, response)
        return line.dropFirst("Location:".count).trimmingCharacters(in: .whitespaces)
    }

    private func signedXML(_ response: String) throws -> Data {
        let json = try XCTUnwrap(response.components(separatedBy: "\r\n\r\n").last)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        return try XCTUnwrap(Data(base64Encoded: try XCTUnwrap(object["base64File"] as? String)))
    }
}
/// Two eID cards connected at once (two readers): the portal sees both, signs with the one it picked,
/// and a card swapped behind a cached reader never receives a PIN.
final class MultiCardTests: XCTestCase {
    private let identityA = TestIdentity.shared
    private let identityB = try! TestIdentity(commonName: "Ștefan Mîndru")
    private var stateA: SimulatedCardState!
    private var stateB: SimulatedCardState!
    /// reader name → card currently in it
    private var slots: [String: SimulatedCosmoXCardFactory] = [:]
    private var savedSink: ((MSLog.Level, String) -> Void)?

    override func setUp() {
        savedSink = MSLog.sink
        MSLog.sink = nil
        stateA = SimulatedCardState(pin: "1111")
        stateB = SimulatedCardState(pin: "2222")
        slots = ["miniLector EVO": .init(state: stateA, identity: identityA),
                 "miniLector EVO 01": .init(state: stateB, identity: identityB)]
        SigningService.shared.transportFactory = { [unowned self] reader in
            guard let slot = self.slots[reader ?? "miniLector EVO"] else { throw CardError.noCard }
            return slot.make()
        }
        SigningService.shared.readersWithCards = { [unowned self] in self.slots.keys.sorted() }
    }

    override func tearDown() {
        MSLog.sink = savedSink
        SigningService.shared.transportFactory = { try CardTransports.connect(reader: $0) }
        SigningService.shared.readersWithCards = { CardTransports.readersWithCards() }
    }

    func testListCardsAndCertificatesEndpointShowBoth() throws {
        let cards = SigningService.shared.listCards()
        XCTAssertEqual(Set(cards.map(\.certificate.holder)), ["Ștefan Mîndru", "TEST SEMNATAR"])

        let server = MoldSignServer(tlsP12: nil, httpPort: 28498, httpsPort: 28499)
        try server.start()
        defer { server.stop() }
        let raw = try PlainHTTP.sendReturningRaw(method: "GET", url: "http://127.0.0.1:28498/certificates?private_only=true",
                                                 body: nil, contentType: nil, extraHeaders: ["Origin: https://msign.gov.md"], timeout: 30)
        let json = try XCTUnwrap(String(decoding: raw, as: UTF8.self).components(separatedBy: "\r\n\r\n").last)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        let models = try XCTUnwrap(object["certificateModel"] as? [[String: Any]])
        XCTAssertEqual(models.count, 2, "the portal must be offered every connected card")
        // the portal parses subjectDN by splitting on "," and "=" to get CN/O: decoded, not \C3\AE escapes
        XCTAssertTrue(models.contains { ($0["subjectDN"] as? String)?.contains("CN=Ștefan Mîndru") == true }, "\(models)")
    }

    func testPortalChoiceSelectsTheCardThatSigns() throws {
        let server = MoldSignServer(tlsP12: nil, httpPort: 28500, httpsPort: 28501)
        var asked: BridgeRequest?
        server.authorize = { request in
            asked = request
            return .allow(pin: "2222", certificateSHA1: request.certificateSHA1)
        }
        try server.start()
        defer { server.stop() }

        let chosen = identityB.certDER.base64EncodedString()
        let body = Data(#"{"data":"PGRvYz4xPC9kb2M+","contentType":"Xml","signFormat":"XAdES-BES","signatureType":"Embedded","certificate":{"certificateBase64":"\#(chosen)"}}"#.utf8)
        let created = try request("POST", "/sign/data", body, port: 28500)
        let location = try XCTUnwrap(created.components(separatedBy: "\r\n").first { $0.hasPrefix("Location:") })
        let result = try request("GET", "/" + location.components(separatedBy: "/").dropFirst(3).joined(separator: "/"), nil, port: 28500)
        XCTAssertTrue(result.hasPrefix("HTTP/1.1 200"), result)

        XCTAssertEqual(asked?.certificateHolder, "Ștefan Mîndru", "consent shows the chosen card's holder")
        XCTAssertEqual(stateA.verifyAttempts, 0, "the other card is never touched")
        XCTAssertEqual(stateB.verifyAttempts, 1)
        let json = try XCTUnwrap(result.components(separatedBy: "\r\n\r\n").last)
        let xml = try XCTUnwrap(Data(base64Encoded: (try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]))["base64File"] as! String))
        let report = try XCTUnwrap(Validator.validateXAdES(xml, referencedFiles: [:]).first)
        XCTAssertEqual(report.signer, "Ștefan Mîndru")
        XCTAssertTrue(report.signatureValid, report.summary)
    }

    func testSwappedCardIsRefusedBeforeThePIN() throws {
        let doc = FileManager.default.temporaryDirectory.appendingPathComponent("msa-swap-\(UUID().uuidString).xml")
        try Data("<doc/>".utf8).write(to: doc)
        defer { try? FileManager.default.removeItem(at: doc) }
        let expectedA = identityA.certDER.sha1().hexString.lowercased()
        XCTAssertEqual(SigningService.shared.reader(forCertificateSHA1: expectedA), "miniLector EVO")   // cached

        // card A pulled, card B pushed into the same reader: the app still thinks "A is in miniLector EVO"
        slots["miniLector EVO"] = slots["miniLector EVO 01"]
        XCTAssertThrowsError(try SigningService.shared.signXAdES(files: [doc], format: .bes, pin: "1111",
                                                                  reader: "miniLector EVO", expectedCertificateSHA1: expectedA)) {
            guard case CardError.cardChanged = $0 else { return XCTFail("expected cardChanged, got \($0)") }
        }
        XCTAssertEqual(stateB.verifyAttempts, 0, "card A's PIN must never reach card B")
        XCTAssertEqual(stateB.triesLeft, 3)
    }

    private func request(_ method: String, _ path: String, _ body: Data?, port: Int) throws -> String {
        String(decoding: try PlainHTTP.sendReturningRaw(method: method, url: "http://127.0.0.1:\(port)\(path)", body: body,
                                                        contentType: body == nil ? nil : "application/json",
                                                        extraHeaders: ["Origin: https://msign.gov.md"], timeout: 30), as: UTF8.self)
    }
}

/// A card that can be "moved" between simulated readers.
struct SimulatedCosmoXCardFactory {
    let state: SimulatedCardState
    let identity: TestIdentity
    func make() -> SimulatedCosmoXCard { SimulatedCosmoXCard(state: state, identity: identity) }
}
#endif
