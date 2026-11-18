import XCTest
@testable import MoldSignKit

final class PasswordFileProtectionTests: XCTestCase {
    private let password = "Test-șț-🔐-2026"
    private var fixtures: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("spec/vectors/encryption")
    }
    func testVendorFilesAndNativeRoundTrips() throws {
        for length in [0, 1, 15, 16, 17, 1024] {
            let plaintext = try Data(contentsOf: fixtures.appendingPathComponent("plain-\(length).bin"))
            for bits in [128, 192, 256] {
                let vendor = try Data(contentsOf: fixtures.appendingPathComponent("vendor-\(bits)-\(length).symmetric.p7m"))
                XCTAssertEqual(try PasswordFileProtection.decrypt(vendor, password: password), plaintext)
            }
            let encrypted = try PasswordFileProtection.encrypt(plaintext, password: password)
            XCTAssertEqual(try PasswordFileProtection.decrypt(encrypted, password: password), plaintext)
            if let export = ProcessInfo.processInfo.environment["MSIGN_ENCRYPTION_ORACLE_OUTPUT"] {
                try encrypted.write(to: URL(fileURLWithPath: export).appendingPathComponent("native-\(length).symmetric.p7m"))
            }
        }
    }
    func testChosenKeySizeMatchesVendorMarkerAndDecryptsAutomatically() async throws {
        let plainURL = fixtures.appendingPathComponent("plain-17.bin")
        let plain = try Data(contentsOf: plainURL)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let service = FileProtectionService(outputDirectory: folder)
        for algorithm in PasswordEncryptionAlgorithm.allCases {
            let name = "vendor-\(algorithm.rawValue)-17.symmetric.p7m"
            let vendor = try Data(contentsOf: fixtures.appendingPathComponent(name))
            let result = try await service.process(plainURL, operation: .encryptPassword(algorithm), password: password)
            let encrypted = try XCTUnwrap(result)
            let bytes = try Data(contentsOf: encrypted)
            XCTAssertEqual(bytes[32..<96], vendor[32..<96])
            XCTAssertFalse(try ProtectedFileIO.usesRecipientCertificate(encrypted))
            XCTAssertEqual(encrypted.lastPathComponent, "plain-17.bin.symmetric.p7m")
            XCTAssertEqual(try PasswordFileProtection.decrypt(bytes, password: password), plain)
        }
        XCTAssertFalse(try ProtectedFileIO.usesRecipientCertificate(fixtures.appendingPathComponent("vendor-legacy-DES_CBC-17.p7m")))
        XCTAssertTrue(try ProtectedFileIO.usesRecipientCertificate(fixtures.appendingPathComponent("vendor-certificate.asymmetric.p7m")))
        let cert = try Data(contentsOf: fixtures.appendingPathComponent("test-recipient.der"))
        let result = try await service.process(plainURL, operation: .encryptCertificate(cert), password: "")
        let encrypted = try XCTUnwrap(result)
        XCTAssertEqual(encrypted.lastPathComponent, "plain-17.bin.asymmetric.p7m")
        XCTAssertTrue(try ProtectedFileIO.usesRecipientCertificate(encrypted))
    }

    func testInvalidInputAndWrongPassword() throws {
        let vendor = try Data(contentsOf: fixtures.appendingPathComponent("vendor-256-1024.symmetric.p7m"))
        // Legacy CBC can accept random valid padding even with a wrong password.
        if let wrong = try? PasswordFileProtection.decrypt(vendor, password: "wrong") {
            XCTAssertNotEqual(wrong, try Data(contentsOf: fixtures.appendingPathComponent("plain-1024.bin")))
        }
        for length in [0, 31, 95, 96, 111, 113] {
            XCTAssertThrowsError(try PasswordFileProtection.decrypt(Data(vendor.prefix(length)), password: password))
        }
        var unknown = vendor; unknown[32] ^= 1
        XCTAssertThrowsError(try PasswordFileProtection.decrypt(unknown, password: password))
        XCTAssertThrowsError(try PasswordFileProtection.encrypt(Data(), password: ""))
        XCTAssertThrowsError(try PasswordFileProtection.encrypt(Data(), password: String(repeating: "x", count: 2048)))
    }
    func testLegacyVendorFiles() throws {
        for algorithm in ["3_KeyTripleDES_CBC","DES_CBC","RC2_CBC"] {
            for length in [0,1,15,16,17,1024] {
                let envelope = try Data(contentsOf: fixtures.appendingPathComponent("vendor-legacy-\(algorithm)-\(length).p7m"))
                XCTAssertEqual(try PasswordFileProtection.decrypt(envelope,password:"Legacy-Test-2026"),try Data(contentsOf: fixtures.appendingPathComponent("plain-\(length).bin")))
            }
        }
    }
    func testFreshSaltAndIV() throws {
        XCTAssertNotEqual(try PasswordFileProtection.encrypt(Data(), password: password), try PasswordFileProtection.encrypt(Data(), password: password))
    }
}
