import XCTest
@testable import MoldSignKit

/// The Swift reference must pass the shared golden vectors that gate the Kotlin and C# ports (F-09).
final class VectorTests: XCTestCase {
    static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .deletingLastPathComponent()

    private func vectors() throws -> [String: Any] {
        let url = Self.repoRoot.appendingPathComponent("spec/vectors/card-crypto.json")
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }

    private func hex(_ any: Any?) -> Data { Data(hex: any as? String ?? "") }

    func testKDFAndExternalAuth() throws {
        let v = try vectors()
        let c = try XCTUnwrap(v["constants"] as? [String: Any])
        let kdf = try XCTUnwrap(v["kdf"] as? [String: Any])
        let base = Data((kdf["seed_ascii"] as! String).utf8) + Data((kdf["serial_ascii"] as! String).utf8) + hex(c["mk_class"])
        let kenc = (base + Data(hex: "00000002")).sha256()
        let kmac = (base + Data(hex: "00000003")).sha256()
        XCTAssertEqual(kenc.hexString, kdf["kenc"] as? String)
        XCTAssertEqual(kmac.hexString, kdf["kmac"] as? String)
        XCTAssertEqual(CosmoXCard.mkClass, hex(c["mk_class"]))
        XCTAssertEqual(CosmoXCard.kIFD, hex(c["k_ifd"]))
        XCTAssertEqual(CosmoXCard.genericADF, hex(c["generic_adf"]))

        let ea = try XCTUnwrap(v["external_auth"] as? [String: Any])
        let plain = hex(c["rnd_ifd"]) + hex(c["sn_ifd"]) + hex(ea["rnd_icc"]) + Data((ea["sn_icc_ascii"] as! String).utf8) + hex(c["k_ifd"])
        let ct = try AES(key: kenc).cbcEncrypt(plain, iv: Data(count: 16))
        XCTAssertEqual(ct.hexString, ea["ciphertext"] as? String)
        XCTAssertEqual(try AES.cmac(key: kmac, message: ct).hexString, ea["cmac"] as? String)

        let rd = try XCTUnwrap(v["response_decode"] as? [String: Any])
        let resp = hex(rd["response"])
        XCTAssertEqual(try AES.cmac(key: kmac, message: resp.prefix(80)), resp.suffix(16))
        XCTAssertEqual(try AES(key: kenc).cbcDecrypt(resp.prefix(80), iv: Data(count: 16)).prefix(16).hexString, rd["challenge"] as? String)

        let sk = try XCTUnwrap(v["session_keys"] as? [String: Any])
        let secret = AES.xorBytes(hex(sk["k_icc"]), hex(c["k_ifd"]))
        XCTAssertEqual((secret + Data(hex: "00000001")).sha256().hexString, sk["sess_enc"] as? String)
        XCTAssertEqual((secret + Data(hex: "00000002")).sha256().hexString, sk["sess_mac"] as? String)
    }

    func testSecureMessaging() throws {
        let sm = try XCTUnwrap(try vectors()["sm"] as? [String: Any])
        let enc = hex(sm["sess_enc"]), mac = hex(sm["sess_mac"]), ssc = hex(sm["ssc_initial"])
        XCTAssertEqual(try AES(key: enc).ecbEncrypt(ssc).hexString, sm["iv_for_ssc_initial"] as? String)
        for case let w as [String: Any] in sm["wrap"] as? [Any] ?? [] {
            var channel = SecureChannel(sessENC: enc, sessMAC: mac, ssc: ssc)
            XCTAssertEqual(try channel.wrap(hex(w["apdu"])).hexString, w["wrapped"] as? String, w["name"] as? String ?? "")
        }
        let u = try XCTUnwrap(sm["unwrap"] as? [String: Any])
        var channel = SecureChannel(sessENC: enc, sessMAC: mac, ssc: ssc)
        _ = try channel.wrap(hex(u["command_before"]))
        let (data, sw) = try channel.unwrap(hex(u["response"]))
        XCTAssertEqual(data.hexString, u["data"] as? String)
        XCTAssertEqual(sw.hexString, u["sw"] as? String)
    }

    func testCMACPaddingDigestInfo() throws {
        let v = try vectors()
        let cmac = try XCTUnwrap(v["cmac"] as? [String: Any])
        for case let c as [String: Any] in cmac["cases"] as? [Any] ?? [] {
            XCTAssertEqual(try AES.cmac(key: hex(cmac["key"]), message: hex(c["message"])).hexString, c["tag"] as? String,
                           "message=\(c["message"] ?? "")")
        }
        for case let p as [String: Any] in v["iso9797"] as? [Any] ?? [] {
            XCTAssertEqual(AES.iso9797Pad(hex(p["input"])).hexString, p["padded"] as? String)
        }
        let di = try XCTUnwrap(v["digest_info"] as? [String: Any])
        XCTAssertEqual(XAdESSigner.digestInfoForSHA256(Data((di["message_ascii"] as! String).utf8).sha256()).hexString,
                       di["digest_info"] as? String)
    }
}
