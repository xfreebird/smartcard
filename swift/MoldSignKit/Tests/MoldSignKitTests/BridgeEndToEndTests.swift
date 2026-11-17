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

    func testSigningServicePDFRejectsDifferentSHA256BeforePIN() throws {
        let otherIdentity = try TestIdentity(commonName: "OTHER TEST SIGNER")
        XCTAssertThrowsError(try SigningService.shared.signPDF(
            Fixtures.data("unsigned.pdf"), pin: "9999",
            expectedCertificateSHA256: otherIdentity.certDER.sha256().hexString
        )) {
            guard case CardError.cardChanged = $0 else {
                return XCTFail("expected cardChanged, got \($0)")
            }
        }
        XCTAssertEqual(card.verifyAttempts, 0, "a mismatched identity must never receive the PIN")
        XCTAssertEqual(card.triesLeft, 3, "certificate rejection must not consume a PIN retry")
        XCTAssertTrue(card.signedDigestInfos.isEmpty)
    }

    func testSigningServicePDFAcceptsMatchingSHA256BeforePIN() throws {
        // An intentionally wrong simulated PIN stops before the live timestamp request while
        // proving that the matching certificate passes the guard and reaches VERIFY exactly once.
        XCTAssertThrowsError(try SigningService.shared.signPDF(
            Fixtures.data("unsigned.pdf"), pin: "9999",
            expectedCertificateSHA256: TestIdentity.shared.certDER.sha256().hexString.uppercased()
        )) {
            guard case CardError.wrongPIN(remaining: 2) = $0 else {
                return XCTFail("expected wrongPIN after accepting the certificate, got \($0)")
            }
        }
        XCTAssertEqual(card.verifyAttempts, 1)
        XCTAssertEqual(card.triesLeft, 2)
        XCTAssertTrue(card.signedDigestInfos.isEmpty)
    }

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

            // SignedInfo still verifies, but removing the properties it references must invalidate integrity.
            let missingProperties = Data(String(decoding: xml, as: UTF8.self)
                .replacingOccurrences(of: "<xades:SignedProperties", with: "<xades:RemovedProperties")
                .replacingOccurrences(of: "</xades:SignedProperties>", with: "</xades:RemovedProperties>").utf8)
            let missingReport = try XCTUnwrap(Validator.validateXAdES(missingProperties, referencedFiles: [:]).first)
            XCTAssertTrue(missingReport.signatureValid)
            XCTAssertFalse(missingReport.contentIntact)
        }
        XCTAssertEqual(card.verifyAttempts, 2)
    }

    func testDetachedMissingOriginalIsIncompleteAndSelectedBytesResolveIt() throws {
        let doc = FileManager.default.temporaryDirectory.appendingPathComponent("detached-\(UUID().uuidString).txt")
        let content = Data("original content".utf8)
        try content.write(to: doc)
        defer { try? FileManager.default.removeItem(at: doc) }
        let xml = try SigningService.shared.signXAdES(files: [doc], format: .bes, pin: "1234")
        // Optional synthetic fixture handoff for native picker tests. Never exports a real card.
        if let directory = ProcessInfo.processInfo.environment["MSIGN_TEST_EXPORT_DIRECTORY"] {
            let output = URL(fileURLWithPath: directory, isDirectory: true)
            try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
            try xml.write(to: output.appendingPathComponent("detached-signature.xml"))
            try content.write(to: output.appendingPathComponent(doc.lastPathComponent))
        }
        let missing = try XCTUnwrap(Validator.validateXAdES(xml, referencedFiles: [:]).first)
        XCTAssertTrue(missing.signatureValid)
        XCTAssertFalse(missing.contentIntact)
        XCTAssertEqual(missing.missingDetachedReferences, [doc.lastPathComponent])
        XCTAssertTrue(missing.summary.contains("INCOMPLETE"))
        XCTAssertFalse(missing.summary.contains("modified"))
        let resolved = try XCTUnwrap(Validator.validateXAdES(xml, referencedFiles: [doc.lastPathComponent: content]).first)
        XCTAssertTrue(resolved.signatureValid)
        XCTAssertTrue(resolved.contentIntact)
        XCTAssertTrue(resolved.missingDetachedReferences.isEmpty)
        let wrong = try XCTUnwrap(Validator.validateXAdES(xml, referencedFiles: [doc.lastPathComponent: Data("changed".utf8)]).first)
        XCTAssertFalse(wrong.contentIntact)
        XCTAssertTrue(wrong.missingDetachedReferences.isEmpty)
        XCTAssertTrue(wrong.summary.contains("modified"))
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
        // A leaked session identifier is not authority for a different allowed origin.
        let foreignPoll = try get(firstLocation, port: 28494, origin: "https://mpass.gov.md")
        XCTAssertTrue(foreignPoll.hasPrefix("HTTP/1.1 404"), foreignPoll)
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

        // A normal long-poll ends the new PIN session, including when it started before signing finished.
        let secondLocation = try location(second)
        let secondSession = secondLocation.components(separatedBy: "/PKCS11/")[1].components(separatedBy: "/")[0]
        let afterEnd = try post("/sign/data?use_pin_session=\(secondSession)", body, port: 28494)
        _ = try get(try location(afterEnd), port: 28494)
        XCTAssertEqual(consents, 2, "a completed non-retained session needs fresh consent")

        // another origin can't ride on the batch's PIN session
        let foreign = try post("/sign/data?use_pin_session=\(firstSession)", body, port: 28494, origin: "https://mpass.gov.md")
        _ = try get(try location(foreign), port: 28494, origin: "https://mpass.gov.md")
        XCTAssertEqual(consents, 3)
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

    func testLegacyDesktopIsOptInAndNeverBypassesBrowserPolicyOrConsent() throws {
        let port = 28650
        func request(_ path: String, method: String = "GET", headers: [String] = [], body: Data? = nil) throws -> String {
            String(decoding: try PlainHTTP.sendReturningRaw(method: method, url: "http://127.0.0.1:\(port)\(path)",
                body: body, contentType: body == nil ? nil : "application/json", extraHeaders: headers, timeout: 10), as: UTF8.self)
        }
        let disabled = MoldSignServer(tlsP12: nil, httpPort: 28658, httpsPort: 28659)
        disabled.authorize = { _ in .deny }
        try disabled.start()
        let disabledResult = String(decoding: try PlainHTTP.sendReturningRaw(method: "GET",
            url: "http://127.0.0.1:28658/hello", body: nil, contentType: nil, extraHeaders: [], timeout: 10), as: UTF8.self)
        XCTAssertTrue(disabledResult.hasPrefix("HTTP/1.1 403"))
        disabled.stop()

        let server = MoldSignServer(tlsP12: nil, httpPort: UInt16(port), httpsPort: 28651,
                                    allowsLegacyDesktopClient: true)
        var consents = 0
        server.authorize = { _ in consents += 1; return .deny }
        try server.start()
        defer { server.stop() }
        XCTAssertTrue(try request("/hello").hasSuffix("Hello world"))
        for headers in [["Origin: https://evil.example"], ["Origin: null"], ["Origin:"], ["Sec-Fetch-Site: cross-site"]] {
            let response = try request("/hello", headers: headers)
            XCTAssertTrue(response.hasPrefix("HTTP/1.1 403"), response)
        }
        XCTAssertTrue(try request("/sign/data", method: "POST", body: Data("{}".utf8)).hasPrefix("HTTP/1.1 403"))
        let body = Data(#"{"originalFile":"/does/not/exist.pdf","signedFile":"/must/not/write.pdf","pin":"1234"}"#.utf8)
        for route in ["/sign/pdf", "/sign/file", "/sign/file/verify", "/sign/pdf/verify", "/verify/pdf"] {
            for headers in [["Origin: https://msign.gov.md", "moldSign: DesktopSuiteClient"],
                            ["moldSign: DesktopSuiteClient", "Sec-Fetch-Site: same-origin"]] {
                let denied = try request(route, method: "POST", headers: headers, body: body)
                XCTAssertTrue(denied.hasPrefix("HTTP/1.1 403"), denied)
            }
        }
        XCTAssertEqual(consents, 0, "browser filesystem requests must fail before consent")
        let created = try request("/sign/pdf", method: "POST", body: body)
        let resultURL = try location(created)
        XCTAssertTrue(resultURL.hasPrefix("http://localhost.cts.md:\(port)/"), resultURL)
        let result = try request(URLComponents(string: resultURL)!.path)
        XCTAssertTrue(result.hasPrefix("HTTP/1.1 400"), result)
        XCTAssertTrue(result.contains("user denied"))
        XCTAssertEqual(consents, 1, "supplied PIN must not bypass host consent")
        XCTAssertEqual(card.verifyAttempts, 0)
    }

    func testLegacyDesktopJSONXAdESBatchUsesOneConsentAndProducesValidSignature() throws {
        let port = 28652
        let server = MoldSignServer(tlsP12: nil, httpPort: UInt16(port), httpsPort: 28653,
                                    allowsLegacyDesktopClient: true)
        var consents = 0
        server.authorize = { _ in consents += 1; return .allow(pin: "1234") }
        try server.start()
        defer { server.stop() }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let input = directory.appendingPathComponent("contract.txt")
        try Data("Signing from MoldSign desktop".utf8).write(to: input)
        var session: String?
        for index in 0..<2 {
            let output = directory.appendingPathComponent("signed-\(index).xml")
            let body = try JSONSerialization.data(withJSONObject: ["filesToSign": [input.path],
                "destinationFile": output.path, "signFormat": "XAdES-BES", "type": "Detached", "signAlgorithm": "SHA-256"])
            let suffix = session.map { "?use_pin_session=\($0)" } ?? ""
            let created = String(decoding: try PlainHTTP.sendReturningRaw(method: "POST",
                url: "http://127.0.0.1:\(port)/sign/file\(suffix)", body: body, contentType: "application/json",
                extraHeaders: [], timeout: 10), as: UTF8.self)
            let target = try XCTUnwrap(URLComponents(string: location(created)))
            session = target.path.split(separator: "/").last.map(String.init)
            let result = String(decoding: try PlainHTTP.sendReturningRaw(method: "GET",
                url: "http://127.0.0.1:\(port)\(target.path)?keep_pin_session=1", body: nil,
                contentType: nil, extraHeaders: [], timeout: 30), as: UTF8.self)
            XCTAssertTrue(result.hasPrefix("HTTP/1.1 200"), result)
            XCTAssertTrue(result.contains("Content-Type: application/json"), result)
            let resultJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(result.components(separatedBy: "\r\n\r\n").last!.utf8)) as? [String: Any])
            XCTAssertEqual(resultJSON["fileLocation"] as? String, output.path)
            let reports = Validator.validateXAdES(try Data(contentsOf: output), referencedFiles: [input.lastPathComponent: try Data(contentsOf: input)])
            let report = try XCTUnwrap(reports.first)
            XCTAssertTrue(report.signatureValid && report.contentIntact, report.summary)
        }
        // The approved credential cannot be moved to another requested certificate.
        let changed = try JSONSerialization.data(withJSONObject: ["filesToSign": [input.path],
            "destinationFile": directory.appendingPathComponent("must-not-exist.xml").path,
            "signFormat": "XAdES-BES", "certificate": ["certificateBase64": ChainCerts.mdQSign.base64EncodedString()]])
        let created = String(decoding: try PlainHTTP.sendReturningRaw(method: "POST",
            url: "http://127.0.0.1:\(port)/sign/file?use_pin_session=\(session!)", body: changed,
            contentType: "application/json", extraHeaders: [], timeout: 10), as: UTF8.self)
        let target = try XCTUnwrap(URLComponents(string: location(created)))
        let refused = String(decoding: try PlainHTTP.sendReturningRaw(method: "GET",
            url: "http://127.0.0.1:\(port)\(target.path)", body: nil, contentType: nil, extraHeaders: [], timeout: 10), as: UTF8.self)
        XCTAssertTrue(refused.hasPrefix("HTTP/1.1 400"), refused)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.appendingPathComponent("must-not-exist.xml").path))
        XCTAssertEqual(consents, 1)
        XCTAssertEqual(card.verifyAttempts, 2, "never send a batch PIN to a different certificate")
    }

    /// Optional integration probe uses the installed, unmodified vendor Java clients rather
    /// than a handwritten wire client. It never opens a physical reader or submits a real PIN.
    func testInstalledVendorJavaClientListsAndSignsWithSimulatedCard() throws {
        let vendorLib = "/Applications/STISC/MoldSign/lib"
        try XCTSkipUnless(FileManager.default.fileExists(atPath: vendorLib + "/MoldSignClientCardManagement-2.0.jar"),
                          "vendor Java client is not installed")
        let port = 28660
        let server = MoldSignServer(tlsP12: nil, httpPort: UInt16(port), httpsPort: 28661,
                                    allowsLegacyDesktopClient: true)
        var consents = 0
        server.authorize = { _ in consents += 1; return .allow(pin: "1234") }
        try server.start()
        defer { server.stop() }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("VendorProbe.java")
        let input = directory.appendingPathComponent("contract.txt")
        let output = directory.appendingPathComponent("contract-signed.xml")
        try Data("A document for the installed vendor Java client".utf8).write(to: input)
        try #"""
        import jakarta.ws.rs.client.*;
        import java.lang.reflect.*;
        import java.util.*;
        import md.cts.moldsign.msccm.rest.clients.*;
        import md.cts.moldsign.transferobjects.models.*;
        public class VendorProbe {
            static void pointToTestServer(Object object, String base) throws Exception {
                Field clientField = object.getClass().getDeclaredField("client");
                clientField.setAccessible(true);
                Client client = (Client) clientField.get(object);
                client.property("jersey.config.client.connectTimeout", 5000);
                client.property("jersey.config.client.readTimeout", 15000);
                Field target = object.getClass().getDeclaredField("baseTarget");
                target.setAccessible(true);
                target.set(object, client.target(base));
            }
            public static void main(String[] args) throws Exception {
                String base = "http://127.0.0.1:" + args[0];
                CertificatesClient certificates = new CertificatesClient();
                pointToTestServer(certificates, base);
                CertificateListModel listed = certificates.getListOfCertificatesPrivateOnly();
                if (listed.getCertificateModel().size() != 1) throw new AssertionError("certificate list");
                if (!certificates.refreshCertificates()) throw new AssertionError("refresh");
                SignFileClient signing = new SignFileClient();
                pointToTestServer(signing, base);
                SignFileInputModel request = new SignFileInputModel();
                request.setCertificate(listed.getCertificateModel().get(0));
                request.setFilesToSign(Arrays.asList(args[1]));
                request.setDestinationFile(args[2]);
                request.setSignFormat("XAdES-BES");
                request.setSignAlgorithm("SHA-256");
                request.setType("Detached");
                SignFileClient.Inter created = signing.signFilePost(request, null);
                if (created == null) throw new AssertionError("POST did not create session");
                if (!"http".equals(created.location().getScheme())) throw new AssertionError("HTTP result URL");
                var result = signing.signFileGet(created.location(), false);
                if (result == null || !args[2].equals(result.getFileLocation())) throw new AssertionError("result model");
                System.out.println("Vendor Java certificate, refresh, JSON signing and poll passed");
                System.exit(0);
            }
        }
        """#.write(to: source, atomically: true, encoding: .utf8)
        let log = directory.appendingPathComponent("probe.log")
        FileManager.default.createFile(atPath: log.path, contents: nil)
        let handle = try FileHandle(forWritingTo: log)
        defer { try? handle.close() }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/java")
        process.arguments = ["-cp", vendorLib + "/*", source.path, String(port), input.path, output.path]
        process.standardOutput = handle
        process.standardError = handle
        try process.run()
        let timeout = DispatchWorkItem { if process.isRunning { process.terminate() } }
        DispatchQueue.global().asyncAfter(deadline: .now() + 40, execute: timeout)
        process.waitUntilExit()
        timeout.cancel()
        let diagnostics = try String(contentsOf: log, encoding: .utf8)
        XCTAssertEqual(process.terminationStatus, 0, diagnostics)
        let report = try XCTUnwrap(Validator.validateXAdES(try Data(contentsOf: output), referencedFiles: [input.lastPathComponent: try Data(contentsOf: input)]).first)
        XCTAssertTrue(report.signatureValid && report.contentIntact, report.summary)
        XCTAssertEqual(consents, 1)
        XCTAssertEqual(card.verifyAttempts, 1)
    }

    func testLegacyDesktopRequiresFullFilesystemHostAndConsentCallback() throws {
        for (port, filesystem, callback) in [(28654, false, true), (28656, true, false)] {
            let server = MoldSignServer(tlsP12: nil, httpPort: UInt16(port), httpsPort: UInt16(port + 1),
                                        allowsFileSystemRoutes: filesystem, allowsLegacyDesktopClient: true)
            if callback { server.authorize = { _ in .deny } }
            try server.start()
            defer { server.stop() }
            let response = String(decoding: try PlainHTTP.sendReturningRaw(method: "GET",
                url: "http://127.0.0.1:\(port)/hello", body: nil, contentType: nil, extraHeaders: [], timeout: 10), as: UTF8.self)
            XCTAssertTrue(response.hasPrefix("HTTP/1.1 403"), response)
        }
    }

    func testNFCOnlyModeDoesNotListOrUseConnectedReaders() throws {
        let server = MoldSignServer(tlsP12: nil, httpPort: 28728, httpsPort: 28729, allowsFileSystemRoutes: false)
        server.readerCertificatesEnabled = { false }
        server.contactlessCertificates = { [] }
        server.authorize = { _ in .allow(pin: "1234") }
        try server.start()
        defer { server.stop() }
        XCTAssertTrue(try get("/certificates", port: 28728).contains("\"certificateModel\":[]"))
        let body = Data(#"{"data":"PGRvYy8+","contentType":"Xml","signFormat":"XAdES-BES","signatureType":"Embedded"}"#.utf8)
        let created = try post("/sign/data", body, port: 28728)
        XCTAssertTrue(try get(try location(created), port: 28728).hasPrefix("HTTP/1.1 400"))
        XCTAssertEqual(card.verifyAttempts, 0)
        XCTAssertTrue(card.signedDigestInfos.isEmpty)
    }

    func testContactlessIdentityListsWithoutRFAndSignsOnDemand() throws {
        try exerciseContactlessBridge(mode: "success", port: 28720)
    }

    func testContactlessCardSwapStopsBeforePIN() throws {
        try exerciseContactlessBridge(mode: "swapped", port: 28722)
    }

    func testContactlessWrongPINIsAttemptedOnce() throws {
        try exerciseContactlessBridge(mode: "wrongPIN", port: 28724)
    }

    func testContactlessCancellationDoesNotFallBackToReader() throws {
        try exerciseContactlessBridge(mode: "cancel", port: 28726)
    }

    func testContactlessTechnicalErrorsUseHostPresentation() throws {
        try exerciseContactlessBridge(mode: "privateError", port: 28730)
    }

    private func exerciseContactlessBridge(mode: String, port: Int) throws {
        SigningService.shared.readersWithCards = { [] }
        SigningService.shared.transportFactory = { _ in
            XCTFail("NFC must never fall back to a physical reader")
            throw CardError.noCard
        }
        let selected = SigningService.CertificateSummary(der: TestIdentity.shared.certDER)
        let scanned = mode == "swapped" ? try TestIdentity(commonName: "OTHER NFC CARD") : TestIdentity.shared
        let state = card!
        let server = MoldSignServer(tlsP12: nil, httpPort: UInt16(port), httpsPort: UInt16(port + 1), allowsFileSystemRoutes: false)
        var opened = 0
        var authorized = false
        server.contactlessCertificates = { [selected] }
        if mode == "privateError" { server.errorMessage = { _ in "Authentication could not be completed." } }
        server.authorize = { request in
            XCTAssertTrue(request.requiresNativePIN)
            authorized = true
            return .allow(pin: mode == "wrongPIN" ? "9999" : "1234", certificateSHA1: selected.sha1Hex)
        }
        server.openContactlessCard = { expected in
            XCTAssertTrue(authorized, "PIN/consent must precede the RF session")
            XCTAssertEqual(expected, selected.der)
            opened += 1
            if mode == "cancel" { throw CancellationError() }
            if mode == "privateError" { throw NSError(domain: "TechnicalFailure", code: 1, userInfo: [NSLocalizedDescriptionKey: "APDU internal failure"]) }
            return SimulatedCosmoXCard(state: state, identity: scanned)
        }
        try server.start()
        defer { server.stop() }
        let listing = try get("/certificates", port: port)
        XCTAssertTrue(listing.contains(selected.der.base64EncodedString()))
        XCTAssertEqual(opened, 0, "portal polling must not open NFC")
        let body = try JSONSerialization.data(withJSONObject: ["data": Data("<challenge/>".utf8).base64EncodedString(),
            "contentType": "Xml", "signFormat": "XAdES-BES", "signatureType": "Embedded", "algorithm": "SHA-1",
            "certificate": ["certificateBase64": selected.der.base64EncodedString()], "pin": "9999"])
        let created = try post("/sign/data", body, port: port)
        let result = try get(try location(created), port: port)
        XCTAssertEqual(opened, 1)
        if mode == "privateError" {
            XCTAssertTrue(result.contains("Authentication could not be completed."))
            XCTAssertFalse(result.contains("APDU"))
            XCTAssertFalse(result.contains("TechnicalFailure"))
        }
        if mode == "success" {
            XCTAssertTrue(result.hasPrefix("HTTP/1.1 200"), result)
            let report = try XCTUnwrap(Validator.validateXAdES(try signedXML(result), referencedFiles: [:]).first)
            XCTAssertTrue(report.signatureValid && report.contentIntact)
            XCTAssertEqual(state.verifyAttempts, 1)
        } else {
            XCTAssertTrue(result.hasPrefix("HTTP/1.1 400"), result)
            XCTAssertEqual(state.verifyAttempts, mode == "wrongPIN" ? 1 : 0)
            XCTAssertTrue(state.signedDigestInfos.isEmpty)
        }
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
