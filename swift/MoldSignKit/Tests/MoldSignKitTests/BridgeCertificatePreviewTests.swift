import XCTest
@testable import MoldSignKit

final class BridgeCertificatePreviewTests: XCTestCase {
    func testPreviewListsFictionalIdentityAndRejectsSigningWithoutAccessingHardware() throws {
        let original = SigningService.shared.readersWithCards
        SigningService.shared.readersWithCards = { XCTFail("Preview must never enumerate physical cards"); return [] }
        defer { SigningService.shared.readersWithCards = original }
        let certificate = SigningService.CertificateSummary(der: ChainCerts.mdQSign, holder: "DEMO PREVIEW",
            subjectDN: "CN=DEMO PREVIEW", issuer: "CN=DEMO ISSUER", issuerName: "DEMO ISSUER",
            serialDecimal: "1", sha1Hex: "fixture", notAfter: nil)
        let server = MoldSignServer(tlsP12: nil, httpPort: 28770, httpsPort: 28771,
                                    allowsFileSystemRoutes: false, previewCertificates: [certificate])
        server.authorize = { _ in XCTFail("Preview must never request a PIN"); return .deny }
        try server.start()
        defer { server.stop() }
        func request(_ method: String, _ path: String) throws -> String {
            let raw = try PlainHTTP.sendReturningRaw(method: method, url: "http://127.0.0.1:28770" + path,
                body: method == "POST" ? Data("{}".utf8) : nil, contentType: "application/json",
                extraHeaders: ["Origin: https://msign.gov.md"], timeout: 10)
            return String(decoding: raw, as: UTF8.self)
        }
        let listed = try request("GET", "/certificates")
        XCTAssertTrue(listed.contains("200 OK"))
        XCTAssertTrue(listed.contains("DEMO PREVIEW"))
        XCTAssertTrue(try request("GET", "/hello").contains("200 OK"))
        XCTAssertTrue(try request("POST", "/certificates/refresh").contains("200 OK"))
        let denied = try request("POST", "/sign/data")
        XCTAssertTrue(denied.contains("403"))
        XCTAssertTrue(denied.contains("signing is disabled"))
        XCTAssertTrue(try request("GET", "/sign/pdf").contains("403"))
    }
}
