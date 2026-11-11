import XCTest
@testable import MoldSignKit

final class MalformedEnvelopeTests: XCTestCase {
    func testDerBoundsRejectTruncatedOrImpossibleLengths() {
        for bytes: [UInt8] in [[], [0x30], [0x30, 0x82], [0x30, 0x82, 0xff, 0xff],
                              [0x30, 0x80], [0x30, 0x03, 0x01]] {
            let data = Data(bytes)
            XCTAssertThrowsError(try DER.element(data, at: 0))
            XCTAssertTrue(Validator.stripDERPadding(data).isEmpty)
        }
        XCTAssertThrowsError(try DER.header(Data([0x30, 0]), at: Int.max))
        XCTAssertThrowsError(try DER.header(Data([0x30, 0]), at: -1))
    }

    func testCertificateFieldsRejectEveryTruncatedPrefix() throws {
        let certificate = ChainCerts.mdQSign
        let full = try CertFields(certificate)
        XCTAssertFalse(full.serialTLV.isEmpty)
        XCTAssertFalse(full.subjectDER.isEmpty)
        XCTAssertFalse(full.publicKeyBits.isEmpty)
        for count in 0..<certificate.count {
            XCTAssertThrowsError(try CertFields(Data(certificate.prefix(count))))
        }
    }

    func testMalformedCertificateFailsBeforeSigningCallback() {
        var signCalls = 0
        XCTAssertThrowsError(try PAdESSigner().buildFullCMS(contentDigest: Data(repeating: 0, count: 32),
            certDER: Data([0x30, 0x82, 0xff, 0xff]), tsaUnsignedAttr: Data()) { _ in
                signCalls += 1
                return Data([1])
            })
        XCTAssertEqual(signCalls, 0)
    }

    func testTimestampTokenExtractionIsBoundedAndPreservesValidBytes() throws {
        let status = DER.seq(DER.tlv(0x02, Data([0])))
        let token = DER.seq(DER.tlv(0x06, Data([0x2a, 0x03])))
        let response = DER.seq(status + token)
        XCTAssertEqual(try PAdESSigner.timestampToken(from: response), token)
        for count in 0..<response.count {
            XCTAssertThrowsError(try PAdESSigner.timestampToken(from: Data(response.prefix(count))))
        }
        XCTAssertThrowsError(try PAdESSigner.timestampToken(from: DER.seq(status)))
    }

    func testReversedXmlClosingTagsNeverProduceValidSignatureOrCrash() {
        for tag in ["ds:SignedInfo", "xades:SignedProperties", "ds:X509Certificate", "ds:SignatureValue", "xades:SigningTime"] {
            let xml = "<ds:Signature Id=\"fixture\"></\(tag)><\(tag)>" +
                "<ds:SignedInfo></ds:SignedInfo></ds:Signature>"
            let reports = Validator.validateXAdES(Data(xml.utf8), referencedFiles: [:])
            XCTAssertFalse(reports.contains { $0.signatureValid }, tag)
        }
    }
}
