import XCTest
@testable import MoldSignKit
#if canImport(Security) && !MOLDSIGN_PORTABLE
import Security

final class CertificateFileProtectionTests: XCTestCase {
    private var fixtures: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("spec/vectors/encryption")
    }
    func testVendorCMSAndNativeRoundTrip() throws {
        func data(_ name: String) throws -> Data { try Data(contentsOf: fixtures.appendingPathComponent(name)) }
        let cert = try data("test-recipient.der"), plain = try data("plain-1024.bin")
        let pkcs8 = try ProtectionASN1.parse(data("test-private-key.pk8"))
        let keyData = pkcs8.children[2].content
        let attributes: [CFString: Any] = [kSecAttrKeyType: kSecAttrKeyTypeRSA, kSecAttrKeyClass: kSecAttrKeyClassPrivate]
        let key = try XCTUnwrap(SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, nil))
        let unwrap: (Data) throws -> Data = { wrapped in
            try XCTUnwrap(SecKeyCreateDecryptedData(key, .rsaEncryptionPKCS1, wrapped as CFData, nil)) as Data
        }
        XCTAssertEqual(try CertificateFileProtection.decrypt(data("vendor-certificate.asymmetric.p7m"), certificate: cert, unwrap: unwrap), plain)
        let native = try CertificateFileProtection.encrypt(plain, certificate: cert)
        XCTAssertEqual(try CertificateFileProtection.decrypt(native, certificate: cert, unwrap: unwrap), plain)
        if let output = ProcessInfo.processInfo.environment["MSIGN_ENCRYPTION_ORACLE_OUTPUT"] {
            try native.write(to: URL(fileURLWithPath: output).appendingPathComponent("native-certificate.asymmetric.p7m"))
        }
        var callbacks = 0
        XCTAssertThrowsError(try CertificateFileProtection.decrypt(Data(native.dropLast()), certificate: cert) { _ in callbacks += 1; return Data() })
        XCTAssertEqual(callbacks, 0)
    }
    func testRejectsMaliciousBER() {
        for bytes: [UInt8] in [[0x30,0x80], [0x30,0x84,0xff,0xff,0xff,0xff], [0x04,0x80,0,0], [0x30,0,0]] {
            XCTAssertThrowsError(try ProtectionASN1.parse(Data(bytes)))
        }
    }
    func testSharedSigningOnlyFixtureRequiresExplicitCompatibility() throws {
        let certificate=try Data(contentsOf:fixtures.appendingPathComponent("test-signing-only.der"))
        let other=try Data(contentsOf:fixtures.appendingPathComponent("test-recipient.der"))
        let keyInfo=try ProtectionASN1.parse(Data(contentsOf:fixtures.appendingPathComponent("test-private-key.pk8")))
        let attributes:[CFString:Any]=[kSecAttrKeyType:kSecAttrKeyTypeRSA,kSecAttrKeyClass:kSecAttrKeyClassPrivate]
        let key=try XCTUnwrap(SecKeyCreateWithData(keyInfo.children[2].content as CFData,attributes as CFDictionary,nil))
        let plain=Data([0,1,0x80,0,255])
        XCTAssertThrowsError(try CertificateFileProtection.validateRecipient(certificate))
        XCTAssertThrowsError(try CertificateFileProtection.encrypt(plain,certificate:certificate))
        let envelope=try CertificateFileProtection.encrypt(plain,certificate:certificate,policy:.cardPublicKey)
        var calls=0
        let unwrap:(Data)throws->Data={wrapped in calls += 1;return try XCTUnwrap(SecKeyCreateDecryptedData(key,.rsaEncryptionPKCS1,wrapped as CFData,nil)) as Data}
        XCTAssertThrowsError(try CertificateFileProtection.decrypt(envelope,certificate:certificate,unwrap:unwrap))
        XCTAssertThrowsError(try CertificateFileProtection.decrypt(envelope,certificate:other,policy:.cardPublicKey,unwrap:unwrap))
        XCTAssertEqual(calls,0)
        XCTAssertEqual(try CertificateFileProtection.decrypt(envelope,certificate:certificate,policy:.cardPublicKey,unwrap:unwrap),plain)
        XCTAssertEqual(calls,1)
    }
}
#endif
