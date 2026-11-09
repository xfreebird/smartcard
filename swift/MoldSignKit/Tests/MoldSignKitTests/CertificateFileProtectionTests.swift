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
}
#endif
