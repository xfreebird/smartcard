import XCTest
@testable import MoldSignKit

final class CertificateDetailsTests: XCTestCase {
    func testDistinguishedNamesBecomeSeparateUnicodeFields() {
        let details = Validator.certificateDetails(ChainCerts.mdQSign)
        XCTAssertEqual(details["Subject · Name"], "MDQSign")
        XCTAssertEqual(details["Issuer · Name"], "mdtrustca")
        XCTAssertEqual(details["Issuer · City"], "Chișinău")
        XCTAssertEqual(details["Subject · Organization identifier"], "NTRMD-1003600096694")
        XCTAssertNil(details["Subject"])
        XCTAssertNil(details["Issuer"])
    }

    func testFingerprintUsesOnlyLeafCertificateAndURIsAreBounded() {
        let leaf = ChainCerts.mdQSign
        let details = Validator.certificateDetails(leaf + ChainCerts.mdTrustCA)
        XCTAssertEqual(details["SHA-256 fingerprint"], leaf.sha256().hexString)
        XCTAssertTrue(details["OCSP responder"]?.contains("http://mdtrustca.ocsp.pki.md") == true)
        XCTAssertFalse(details["OCSP responder"]?.contains("\u{06}") == true)
    }

    func testIssuerOrganizationIdentifierIsNeverUsedAsIDNP() {
        var report = Validator.Report(kind: "PAdES", name: "Signature1", signer: "Fixture",
                                      contentIntact: true, signatureValid: true, chainTrusted: true,
                                      signingTime: "-", timestampTime: nil, level: "PAdES-B-B")
        report.certificateDetails = ["Issuer · Organization identifier": "NTRMD-1003600096694"]
        XCTAssertNil(report.signerIDNP)
        report.certificateDetails["Subject · Personal identifier"] = "1234567890123"
        XCTAssertEqual(report.signerIDNP, "1234567890123")
        report.certificateDetails["Subject · Personal identifier"] = "not-an-IDNP"
        XCTAssertNil(report.signerIDNP)
    }
}
