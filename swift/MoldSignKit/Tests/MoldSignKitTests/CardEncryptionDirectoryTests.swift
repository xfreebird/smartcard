import XCTest
@testable import MoldSignKit

final class CardEncryptionDirectoryTests: XCTestCase {
    private func w(_ tag: UInt8, _ bytes: Data) -> Data { ProtectionASN1.wrap(tag, bytes) }
    func fixture(consent: Bool = false, usage: UInt8 = 0x40, pinReference: UInt8 = 3) -> (Data,Data,Data) {
        let common = w(0x30, w(12, Data("Encryption key".utf8)) + w(4, Data([1])) + (consent ? w(2,Data([1])) : Data()))
        let attributes = w(0x30,w(4,Data([2])) + w(3,Data([6,usage])) + w(2,Data([2])))
        let type = w(0xa1,w(0x30,w(0x30,w(4,Data())) + w(2,Data([0x08,0]))))
        let key = w(0x30, common + attributes + type)
        let certificate = w(0x30,w(0x30,Data()) + w(0x30,w(4,Data([2]))) + w(0xa1,w(0x30,w(0x30,w(4,Data([0,2]))))))
        let pin = w(0x30,w(0x30,Data()) + w(0x30,w(4,Data([1]))) + w(0xa1,w(0x30,
            w(3,Data([0,0x08])) + w(10,Data([1])) + w(2,Data([4])) + w(2,Data([8])) + w(0x80,Data([pinReference])))))
        return (key,certificate,pin)
    }
    func testJoinsEncryptionKeyCertificateAndPIN() throws {
        let (key,cert,pin) = fixture()
        let result = try CardEncryptionDirectory.keys(privateKeys: key + Data(repeating: 0,count: 32), certificates: cert, authentication: pin)
        XCTAssertEqual(result.count,1)
        XCTAssertEqual(result.first?.modulusBytes,256)
        XCTAssertEqual(result.first?.reference,2)
        XCTAssertEqual(result.first?.certificatePath,Data([0,2]))
    }
    func testSigningOnlyAndAmbiguousMetadataNeverBecomeCapabilities() throws {
        for fixture in [fixture(consent: true),fixture(usage: 0x20),fixture(pinReference: 4)] {
            XCTAssertTrue(try CardEncryptionDirectory.keys(privateKeys: fixture.0, certificates: fixture.1, authentication: fixture.2).isEmpty)
        }
        let (key,cert,pin) = fixture()
        XCTAssertTrue(try CardEncryptionDirectory.keys(privateKeys:key+key,certificates:cert,authentication:pin).isEmpty)
        XCTAssertTrue(try CardEncryptionDirectory.keys(privateKeys:key,certificates:cert+cert,authentication:pin).isEmpty)
        XCTAssertTrue(try CardEncryptionDirectory.keys(privateKeys:key,certificates:cert,authentication:Data()).isEmpty)
        XCTAssertThrowsError(try CardEncryptionDirectory.keys(privateKeys:key+Data([0,1]),certificates:cert,authentication:pin))
    }
}
