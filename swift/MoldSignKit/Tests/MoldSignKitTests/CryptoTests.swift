import XCTest
@testable import MoldSignKit

class CryptoTests: XCTestCase {
    static let seed = Data("32972F83F5A65D4C".utf8)
    static let serial = Data("51180B0A2B597D33".utf8)
    static let mkClass = Data(hex: "C1765FCA5C11B6E9F827EB1230FA74C3140619976CE92B66199801CFDB125F1E")

    static var kenc: Data { (Self.seed + Self.serial + Self.mkClass + Data(hex: "00000002")).sha256() }
    static var kmac: Data { (Self.seed + Self.serial + Self.mkClass + Data(hex: "00000003")).sha256() }

    func testKencDerivation() {
        XCTAssertEqual(Self.kenc.hexString, "1BDE993470F87C880481AAA0B4D9BDFEB01DF43194464CEFB49E7E329F2E3DA6")
    }

    func testKmacDerivation() {
        XCTAssertEqual(Self.kmac.hexString, "85CBC3EEDDFA3259F0C3609124CB110863A89DAC73293C228384AC6A156F57C1")
    }

    func testExternalAuthPayload() throws {
        let kenc = AES(key: Self.kenc)
        let kmac = Self.kmac

        let rndIFD = Data(hex: "199F0388C3ACEC2D84C6CE4CE785CB7B")
        let snIFD = Data(hex: "4A95FED1DB606A62")
        let rndICC = Data(hex: "EB63C8C95B758260D5CDD94892B9DAF4")
        let snICC = Data("2B597D33".utf8)
        let kIFD = Data(hex: "445969C4020CEDD4A8C4BFCE4B9820D2BE8CDD972F983B813038A512905BBF08")

        let plain = rndIFD + snIFD + rndICC + snICC + kIFD
        let ct = try kenc.cbcEncrypt(plain, iv: Data(repeating: 0, count: 16))
        let mac = try AES.cmac(key: kmac, message: ct)

        // CBC encryption verified against middleware capture
        XCTAssertEqual(ct.hexString,
            "492D28A5F7722BE4222BA37B4D53FE83E462F9D3B1CDD3CC51D394AA31C662D5FA331118DEF7FAB76EABC3E59665AA5230CD658A0581FD88CFB0A92221D6C1B8822AA242F8E4E5BF9E37B6FB8D94AC59")

        // CMAC of the 80-byte ciphertext (verified with openssl: same value)
        XCTAssertEqual(mac.hexString, "B3FC8B4E4A6ACAFD0CA35E1B80AA3068")
    }

    func testResponseDecode() throws {
        let kenc = AES(key: Self.kenc)
        let kmac = Self.kmac

        // Full 96-byte response from session 0 (challenge 2CA2978A...)
        let fullResponse = Data(hex: "BD017A412B40499E566ADF1F983BE4FD3DE549BF1A3D62F9C8FBFBAC65D3B2147CDBE675816055A5FA8966F576376617C25FD86B99ED17EC79B18D7EFD5462AAC283714BB903E32B0EDF2FC70181D60E6A672FD505BF789BD28E3F3E9C4D0237")
        XCTAssertEqual(fullResponse.count, 96)

        let respCT = fullResponse.prefix(80)  // ciphertext only
        let respMAC = fullResponse.suffix(16)  // MAC

        // CMAC of the 80-byte ciphertext (verified with openssl)
        let calcMAC = try AES.cmac(key: kmac, message: respCT)
        XCTAssertEqual(calcMAC.hexString, respMAC.hexString)

        // Decrypt: first 16 bytes should be the session's challenge
        let plain = try kenc.cbcDecrypt(respCT, iv: Data(repeating: 0, count: 16))
        XCTAssertEqual(plain.prefix(16).hexString, "2CA2978A2A5EB048B12A547F01FC1454")
    }

    func testSessionKeyDerivation() {
        let kICC = Data(hex: "3B7F16CD9E13543B6A207F24619A55EBE3F24C3D4142A05F4E49A74532C6A7CF")
        let kIFD = Data(hex: "445969C4020CEDD4A8C4BFCE4B9820D2BE8CDD972F983B813038A512905BBF08")
        let secret = AES.xorBytes(kICC, kIFD)
        let sessENC = (secret + Data(hex: "00000001")).sha256()
        let sessMAC = (secret + Data(hex: "00000002")).sha256()
        XCTAssertEqual(sessENC.hexString, "7C0749D47D8591E071A2C07788359A01AD12F94CAB3D2CA74F97FFD088CDCEDE")
        XCTAssertEqual(sessMAC.hexString, "A6C8773EFCA56A978389E6D9E1D4D19F6A6E54B05DCE27A84943B7FDB3A3F530")
    }

    func testSMWrapVerify() throws {
        let sessENC = Data(hex: "7C0749D47D8591E071A2C07788359A01AD12F94CAB3D2CA74F97FFD088CDCEDE")
        let sessMAC = Data(hex: "A6C8773EFCA56A978389E6D9E1D4D19F6A6E54B05DCE27A84943B7FDB3A3F530")
        let ssc = Data(hex: "62AB2DF56EFCB9D384C6CE4CE785CB7B")

        var channel = SecureChannel(sessENC: sessENC, sessMAC: sessMAC, ssc: ssc)
        let selectMF = Data([0x00, 0xA4, 0x00, 0x0C, 0x02, 0x3F, 0x00, 0x00])
        let wrapped = try channel.wrap(selectMF)

        XCTAssertEqual(wrapped[0] & 0x0C, 0x0C)
        XCTAssertTrue(wrapped.contains(0x97))
        XCTAssertTrue(wrapped.contains(0x8E))
    }

    func testISO9797Padding() {
        let input = Data([0x01, 0x02, 0x03])
        let padded = AES.iso9797Pad(input)
        XCTAssertEqual(padded.count, 16)
        XCTAssertEqual(padded[3], 0x80)
        XCTAssertEqual(padded[4], 0x00)

        let unpadded = AES.iso9797Unpad(padded)
        XCTAssertEqual(unpadded, input)
    }
}
