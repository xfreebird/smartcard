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
