import XCTest
import CPCSC
@testable import MoldSignKit

final class CryptoFailureTests: XCTestCase {
    func testInvalidLengthsCannotProduceCryptoOutput() {
        for count in [0, 16, 24, 31, 33] {
            let key = Data(count: count)
            XCTAssertThrowsError(try AES.cmac(key: key, message: Data()))
            XCTAssertThrowsError(try AES(key: key).ecbEncrypt(Data(count: 16)))
            XCTAssertThrowsError(try AES(key: key).cbcEncrypt(Data(count: 16), iv: Data(count: 16)))
        }
        for count in [0, 15, 17] {
            XCTAssertThrowsError(try AES(key: Data(count: 32)).ecbEncrypt(Data(count: count)))
        }
    }

    func testCmacPropagatesInitialAndLaterBlockFailuresWithoutReturningATag() {
        let key = [UInt8](repeating: 1, count: 32)
        let message: [UInt8] = [1]
        var output = [UInt8](repeating: 0xff, count: 16)
        let first = c_aes256_cmac_with_block(key, 32, message, 1, &output) { _, _, _, _ in -99 }
        XCTAssertEqual(first, -99)
        XCTAssertEqual(output, [UInt8](repeating: 0, count: 16))
        output = [UInt8](repeating: 0xff, count: 16)
        let later = c_aes256_cmac_with_block(key, 32, message, 1, &output) { key, length, input, output in
            guard let input else { return -99 }
            if (0..<16).contains(where: { input[$0] != 0 }) { return -99 }
            return c_aes256_ecb_encrypt(key, length, input, output)
        }
        XCTAssertEqual(later, -99)
        XCTAssertEqual(output, [UInt8](repeating: 0, count: 16))
    }

    func testInvalidSessionCannotWrapAPinCommand() {
        var channel = SecureChannel(sessENC: Data(count: 32), sessMAC: Data(count: 31), ssc: Data(count: 16))
        XCTAssertThrowsError(try channel.wrap(Data(hex: "002000030431323334")))
        XCTAssertEqual(channel.ssc, Data(count: 16))
    }
}
