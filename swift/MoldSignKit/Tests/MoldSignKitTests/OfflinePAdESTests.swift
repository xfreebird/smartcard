#if canImport(Security)
import XCTest
@testable import MoldSignKit

/// PAdES-T end to end without the internet: the simulated card signs with a test key and a loopback
/// responder answers RFC 3161 requests with the public MDQTSA fixture token.
final class OfflinePAdESTests: XCTestCase {
    private var card: SimulatedCardState!
    private var tsa: LoopbackHTTPServer!
    private var savedSink: ((MSLog.Level, String) -> Void)?
    private var savedTSA = ""

    override func setUpWithError() throws {
        savedSink = MSLog.sink
        MSLog.sink = nil
        card = SimulatedCardState(pin: "1234", tries: 3)
        let state = card!
        SigningService.shared.transportFactory = { _ in SimulatedCosmoXCard(state: state) }
        SigningService.shared.readersWithCards = { ["Simulated miniLector"] }
        let token = try Fixtures.data("tstoken.der")
        tsa = try LoopbackHTTPServer { request in
            // TimeStampResp { PKIStatusInfo { granted }, timeStampToken }
            let response = DER.seq(DER.seq(DER.tlv(0x02, Data([0x00]))) + token)
            return String(decoding: request, as: UTF8.self).hasPrefix("POST /moldsign2/ ")
                ? LoopbackHTTPServer.response(200, response, contentType: "application/timestamp-reply")
                : LoopbackHTTPServer.response(404, Data())
        }
        savedTSA = PAdESSigner.tsaURL
        PAdESSigner.tsaURL = "http://127.0.0.1:\(tsa.port)/moldsign2/"
    }

    override func tearDown() {
        PAdESSigner.tsaURL = savedTSA
        tsa?.stop()
        MSLog.sink = savedSink
        SigningService.shared.transportFactory = { try CardTransports.connect(reader: $0) }
        SigningService.shared.readersWithCards = { CardTransports.readersWithCards() }
    }

    private func assertValidSignedPDF(_ signed: Data, original: Data, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(signed.prefix(original.count), original, "incremental update must keep the original bytes", file: file, line: line)
        let reports = Validator.validatePDF(signed)
        XCTAssertEqual(reports.count, 1, file: file, line: line)
        XCTAssertEqual(reports.first?.contentIntact, true, file: file, line: line)
        XCTAssertEqual(reports.first?.signatureValid, true, reports.first?.summary ?? "", file: file, line: line)
        XCTAssertEqual(reports.first?.signer, "TEST SEMNATAR", file: file, line: line)
        XCTAssertEqual(reports.first?.level, "PAdES-B-T", "the RFC 3161 token is embedded", file: file, line: line)
    }

    // MARK: - Timestamp client

    func testTimestampTokenRequestsTheSignatureDigest() throws {
        let signature = Data("signature value".utf8)
        let token = try PAdESSigner.fetchTimestampToken(data: signature)
        XCTAssertEqual(token, try Fixtures.data("tstoken.der"))
        let request = try XCTUnwrap(tsa.requests.last)
        XCTAssertEqual(LoopbackHTTPServer.body(of: request), TimestampRequest.build(messageBytes: signature.sha256()))
        XCTAssertTrue(String(decoding: request, as: UTF8.self).contains("Content-Type: application/timestamp-query\r\n"))
    }

    func testTimestampFailuresAreSigningErrors() throws {
        let unavailable = try LoopbackHTTPServer { _ in LoopbackHTTPServer.response(503, Data()) }
        defer { unavailable.stop() }
        PAdESSigner.tsaURL = unavailable.url
        XCTAssertThrowsError(try PAdESSigner.fetchTimestampToken(data: Data([1]))) { error in
            guard case CardError.signFailed(let message) = error else { return XCTFail("\(error)") }
            XCTAssertTrue(message.hasPrefix("TSA request failed (HTTP 503"), message)
        }
        let rejected = try LoopbackHTTPServer { _ in
            LoopbackHTTPServer.response(200, DER.seq(DER.seq(DER.tlv(0x02, Data([0x02])))))   // rejection, no token
        }
        defer { rejected.stop() }
        PAdESSigner.tsaURL = rejected.url
        XCTAssertThrowsError(try PAdESSigner.fetchTimestampToken(data: Data([1]))) { error in
            guard case CardError.signFailed("TSA response has no token") = error else { return XCTFail("\(error)") }
        }
        XCTAssertTrue(card.signedDigestInfos.isEmpty)
    }

    // MARK: - Card and service

    func testServiceSignsAPDFWithTheCardAndTimestampInOrder() throws {
        let original = try Fixtures.data("unsigned.pdf")
        var steps: [SigningService.Step] = []
        let signed = try SigningService.shared.signPDF(
            original, pin: "1234", expectedCertificateSHA1: TestIdentity.shared.certDER.sha1().hexString) { steps.append($0) }
        assertValidSignedPDF(signed, original: original)
        XCTAssertEqual(Array(steps.drop { $0 != .readingCertificate }),
                       [.readingCertificate, .verifyingPIN, .signing, .timestamping, .done])
        XCTAssertEqual(card.verifyAttempts, 1)
        XCTAssertEqual(card.signedDigestInfos.count, 1)
        XCTAssertEqual(tsa.requests.count, 1)
    }

    func testDirectCardPDFSigningUsesTheSameSequence() throws {
        let original = try Fixtures.data("unsigned.pdf")
        let cosmo = CosmoXCard(transport: SimulatedCosmoXCard(state: card))
        defer { cosmo.disconnect() }
        assertValidSignedPDF(try cosmo.signPDF(original, pin: "1234"), original: original)
        XCTAssertEqual(card.verifyAttempts, 1)
        XCTAssertEqual(cosmo.readerName, "Simulated miniLector")
    }

    func testTimestampOutageLeavesNoSignedOutput() throws {
        tsa.stop()
        XCTAssertThrowsError(try SigningService.shared.signPDF(try Fixtures.data("unsigned.pdf"), pin: "1234")) { error in
            guard case CardError.signFailed(let message) = error else { return XCTFail("\(error)") }
            XCTAssertTrue(message.hasPrefix("TSA request failed"), message)
        }
        XCTAssertEqual(card.signedDigestInfos.count, 1, "the card signed once; the missing timestamp aborts the output")
    }

    // MARK: - Bridge

    func testPortalPDFDataIsSignedAfterConsent() throws {
        let server = try makeServer()
        var requests: [BridgeRequest] = []
        server.authorize = { request in requests.append(request); return .allow(pin: "1234") }
        try server.start()
        defer { server.stop() }
        let original = try Fixtures.data("unsigned.pdf")
        let body = try JSONSerialization.data(withJSONObject: ["data": original.base64EncodedString(), "contentType": "Pdf"])
        let created = try bridge(server, "POST", "/sign/data", body: body, headers: ["Origin: https://msign.gov.md"])
        XCTAssertTrue(created.hasPrefix("HTTP/1.1 201"), created)
        let result = try bridge(server, "GET", try path(ofLocation: created), headers: ["Origin: https://msign.gov.md"])
        XCTAssertTrue(result.hasPrefix("HTTP/1.1 200"), result)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(try XCTUnwrap(result.components(separatedBy: "\r\n\r\n").last).utf8)) as? [String: String])
        assertValidSignedPDF(try XCTUnwrap(Data(base64Encoded: try XCTUnwrap(json["base64File"]))), original: original)
        XCTAssertEqual(requests.map(\.format), ["PAdES-T"])
        XCTAssertEqual(requests.first?.documentName, "document.pdf")
    }

    func testDesktopPDFPathSigningWritesTheRequestedFile() throws {
        let server = try makeServer()
        server.authorize = { _ in .allow(pin: "1234") }
        try server.start()
        defer { server.stop() }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let input = directory.appendingPathComponent("contract.pdf")
        let output = directory.appendingPathComponent("contract-signed.pdf")
        let original = try Fixtures.data("unsigned.pdf")
        try original.write(to: input)
        let body = Data("<signPdfModel><originalFile>\(input.path)</originalFile><signedFile>\(output.path)</signedFile></signPdfModel>".utf8)
        let created = try bridge(server, "POST", "/sign/pdf", body: body, contentType: "application/xml",
                                 headers: ["moldSign: DesktopSuiteClient"])
        let result = try bridge(server, "GET", try path(ofLocation: created), headers: ["moldSign: DesktopSuiteClient"])
        XCTAssertTrue(result.hasPrefix("HTTP/1.1 200"), result)
        XCTAssertTrue(result.hasSuffix(#"{"path":"\#(BridgeWireFormat.jsonEsc(output.path))"}"#), String(result.suffix(300)))
        let signed = try Data(contentsOf: output)
        assertValidSignedPDF(signed, original: original)

        // The bridge's own verification routes agree, and reject the unsigned original.
        for (file, expected) in [(output, true), (input, false)] {
            let verify = Data("<verifyPdfModel><signedFile>\(file.path)</signedFile></verifyPdfModel>".utf8)
            let started = try bridge(server, "POST", "/sign/pdf/verify", body: verify, contentType: "application/xml",
                                     headers: ["moldSign: DesktopSuiteClient"])
            let answer = try bridge(server, "GET", try path(ofLocation: started), headers: ["moldSign: DesktopSuiteClient"])
            XCTAssertTrue(answer.hasSuffix("<verifyPdfResponseModel><valid>\(expected)</valid></verifyPdfResponseModel>"), String(answer.suffix(300)))
        }
    }

    func testDetachedXAdESVerificationRouteChecksTheReferencedFile() throws {
        let server = try makeServer()
        try server.start()
        defer { server.stop() }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let document = directory.appendingPathComponent("request.txt")
        try Data("Cerere semnata".utf8).write(to: document)
        let signature = directory.appendingPathComponent("request.xml")
        try SigningService.shared.signXAdES(files: [document], format: .bes, type: .detached, pin: "1234").write(to: signature)

        func verify() throws -> String {
            let body = Data("<verifySignedFileModel><signedFiles>\(document.path)</signedFiles><signature>\(signature.path)</signature></verifySignedFileModel>".utf8)
            let started = try bridge(server, "POST", "/sign/file/verify", body: body, contentType: "application/xml",
                                     headers: ["moldSign: DesktopSuiteClient"])
            return try bridge(server, "GET", try path(ofLocation: started), headers: ["moldSign: DesktopSuiteClient"])
        }
        XCTAssertTrue(try verify().hasSuffix("<verifySignedFileResponseModel><valid>true</valid></verifySignedFileResponseModel>"))
        try Data("Cerere modificata".utf8).write(to: document)
        XCTAssertTrue(try verify().hasSuffix("<valid>false</valid></verifySignedFileResponseModel>"))
        try FileManager.default.removeItem(at: signature)
        XCTAssertTrue(try verify().hasSuffix("<valid>false</valid></verifySignedFileResponseModel>"))
    }

    func testPreflightUnknownRoutesAndMalformedRequestLines() throws {
        let server = try makeServer()
        try server.start()
        defer { server.stop() }
        let preflight = try bridge(server, "OPTIONS", "/sign/data", headers: ["Origin: https://msign.gov.md"])
        XCTAssertTrue(preflight.hasPrefix("HTTP/1.1 200"), preflight)
        XCTAssertTrue(preflight.contains("Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n"))
        XCTAssertTrue(preflight.contains("Access-Control-Allow-Private-Network: true\r\n"))
        XCTAssertTrue(preflight.contains("Access-Control-Allow-Origin: https://msign.gov.md\r\n"))
        let unknown = try bridge(server, "GET", "/no/such/route", headers: ["Origin: https://msign.gov.md"])
        XCTAssertTrue(unknown.hasPrefix("HTTP/1.1 404") && unknown.hasSuffix(#"{"error":"not found"}"#), unknown)
        // "GET x /hello HTTP/1.1": the request target is not an absolute path.
        let malformed = try bridge(server, "GET x", "/hello", headers: ["Origin: https://msign.gov.md"])
        XCTAssertTrue(malformed.hasPrefix("HTTP/1.1 400"), malformed)
        let missing = try bridge(server, "POST", "/sign/pdf", body: Data("{}".utf8), headers: ["moldSign: DesktopSuiteClient"])
        XCTAssertTrue(missing.hasPrefix("HTTP/1.1 400") && missing.contains("missing originalFile"), missing)
    }

    // MARK: - Helpers

    private var bridgePort: UInt16 = 0

    private func makeServer() throws -> MoldSignServer {
        bridgePort = try LoopbackHTTPServer.freePort()
        return MoldSignServer(tlsP12: nil, httpPort: bridgePort, httpsPort: try LoopbackHTTPServer.freePort())
    }

    private func bridge(_ server: MoldSignServer, _ method: String, _ path: String, body: Data? = nil,
                        contentType: String = "application/json", headers: [String]) throws -> String {
        String(decoding: try PlainHTTP.sendReturningRaw(method: method, url: "http://127.0.0.1:\(bridgePort)\(path)",
            body: body, contentType: body == nil ? nil : contentType, extraHeaders: headers, timeout: 30), as: UTF8.self)
    }

    private func path(ofLocation response: String) throws -> String {
        let line = try XCTUnwrap(response.components(separatedBy: "\r\n").first { $0.hasPrefix("Location:") }, response)
        let url = try XCTUnwrap(URLComponents(string: line.dropFirst("Location:".count).trimmingCharacters(in: .whitespaces)))
        return url.path
    }
}
#endif
