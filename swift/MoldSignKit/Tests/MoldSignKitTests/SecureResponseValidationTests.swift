import XCTest
@testable import MoldSignKit

final class SecureResponseValidationTests: XCTestCase {
    private let enc = Data(repeating: 1, count: 32)
    private let mac = Data(repeating: 2, count: 32)
    private var responseSSC: Data { Data(count: 15) + Data([1]) }
    private func channel() -> SecureChannel { SecureChannel(sessENC: enc, sessMAC: mac, ssc: Data(count: 16)) }
    private func authenticated(_ body: Data, outer: Data = Data(hex: "9000")) -> Data {
        body + DER.tlv(0x8E, Data(try! AES.cmac(key: mac, message: AES.iso9797Pad(responseSSC + body)).prefix(8))) + outer
    }

    func testAuthenticatedStatusAndEncryptedPayload() throws {
        var statusOnly = channel()
        XCTAssertEqual(try statusOnly.unwrap(authenticated(Data(hex: "99029000"))).sw, Data(hex: "9000"))
        let payload = Data([0x11, 0x80, 0, 0])
        let aes = AES(key: enc)
        let ciphertext = try aes.cbcEncrypt(AES.iso9797Pad(payload), iv: aes.ecbEncrypt(responseSSC))
        var encrypted = channel()
        let response = authenticated(DER.tlv(0x87, Data([1]) + ciphertext) + Data(hex: "99029000"))
        XCTAssertEqual(try encrypted.unwrap(response).data, payload)
    }

    func testMissingTamperedAndMalformedMACAreRejected() {
        var tampered = authenticated(Data(hex: "99029000")); tampered[tampered.count - 3] ^= 1
        let cases = [Data(hex: "9000"), Data(hex: "990290009000"), Data(hex: "990290008E089000"),
                     Data(hex: "990290008E00009000"), tampered,
                     authenticated(Data(hex: "9902900099029000")),
                     authenticated(Data(hex: "8702010099029000"))]
        for response in cases {
            var c = channel()
            XCTAssertThrowsError(try c.unwrap(response)) { error in
                guard case CardError.macVerificationFailed = error else { return XCTFail("Unexpected error \(error)") }
            }
        }
    }

    func testAuthenticatedInvalidPaddingIsRejected() throws {
        let aes = AES(key: enc)
        let ciphertext = try aes.cbcEncrypt(Data(count: 16), iv: aes.ecbEncrypt(responseSSC))
        var c = channel()
        XCTAssertThrowsError(try c.unwrap(authenticated(DER.tlv(0x87, Data([1]) + ciphertext) + Data(hex: "99029000"))))
    }

    func testBareErrorAdvancesCounterButCannotClaimSuccess() throws {
        var c = channel()
        XCTAssertEqual(try c.unwrap(Data(hex: "6988")).sw, Data(hex: "6988"))
        XCTAssertEqual(c.ssc, responseSSC)
    }

    func testMirroredEOFRequiresAuthenticatedStatusAndPreservesFinalChunk() throws {
        let payload = Data([0x30, 0x80, 0, 0])
        let aes = AES(key: enc)
        let ciphertext = try aes.cbcEncrypt(AES.iso9797Pad(payload), iv: aes.ecbEncrypt(responseSSC))
        let body = DER.tlv(0x87, Data([1]) + ciphertext) + Data(hex: "99026282")
        var c = channel()
        let result = try c.unwrap(authenticated(body, outer: Data(hex: "6282")))
        XCTAssertEqual(result.data,payload)
        XCTAssertEqual(result.sw,Data(hex: "6282"))
        XCTAssertEqual(c.ssc,responseSSC)
    }

    func testMirroredEOFCannotBypassStatusOrMACChecks() {
        var tampered = authenticated(Data(hex: "99026282"), outer: Data(hex: "6282"))
        tampered[tampered.count-3] ^= 1
        for response in [tampered, Data(hex: "990262826282"),
                         authenticated(Data(hex: "99029000"), outer: Data(hex: "6282"))] {
            var c = channel()
            XCTAssertThrowsError(try c.unwrap(response))
        }
    }
    func testMirroredErrorIsAuthenticatedAndReturnedToCaller() throws {
        var c = channel()
        let result = try c.unwrap(authenticated(Data(hex: "99026B00"), outer: Data(hex: "6B00")))
        XCTAssertTrue(result.data.isEmpty)
        XCTAssertEqual(result.sw,Data(hex: "6B00"))
    }
}
