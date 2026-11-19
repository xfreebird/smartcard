#if canImport(Security)
import Foundation
import Security
@testable import MoldSignKit

/// RSA key + self-signed certificate standing in for the card's signing identity, so tests can produce
/// signatures the Validator genuinely verifies (the real card's key never leaves the chip).
final class TestIdentity {
    static let shared = try! TestIdentity()

    let privateKey: SecKey
    let certDER: Data

    init(commonName: String = "TEST SEMNATAR", encryption: Bool = false, keySize: Int = 2048) throws {
        let attrs: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeRSA, kSecAttrKeySizeInBits as String: keySize]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateRandomKey(attrs as CFDictionary, &error),
              let pub = SecKeyCopyPublicKey(key),
              let pkcs1 = SecKeyCopyExternalRepresentation(pub, &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        privateKey = key
        let rsaEncryption = DER.seq(DER.tlv(0x06, Data([0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01])) + Data([0x05, 0x00]))
        let spki = DER.seq(rsaEncryption + DER.tlv(0x03, Data([0x00]) + pkcs1))
        let sha256WithRSA = DER.seq(DER.tlv(0x06, PAdESSigner.oidSha256WithRSA) + Data([0x05, 0x00]))
        let name = DER.seq(DER.tlv(0x31, DER.seq(DER.tlv(0x06, Data([0x55, 0x04, 0x03])) + DER.tlv(0x0C, Data(commonName.utf8)))))
        let validity = DER.seq(DER.tlv(0x17, Data("250101000000Z".utf8)) + DER.tlv(0x17, Data("350101000000Z".utf8)))
        let extensions = encryption ? DER.tlv(0xA3, DER.seq(DER.seq(DER.tlv(0x06, Data([0x55,0x1D,0x0F])) + DER.tlv(0x04, DER.tlv(0x03, Data([5,0x20])))))) : Data()
        let tbs = DER.seq(DER.tlv(0xA0, DER.tlv(0x02, Data([0x02]))) + DER.tlv(0x02, Data([0x01, 0x23, 0x45]))
                          + sha256WithRSA + name + validity + name + spki + extensions)
        guard let signature = SecKeyCreateSignature(key, .rsaSignatureMessagePKCS1v15SHA256, tbs as CFData, &error) as Data? else {
            throw error!.takeRetainedValue() as Error
        }
        certDER = DER.seq(tbs + sha256WithRSA + DER.tlv(0x03, Data([0x00]) + signature))
    }

    /// What the card's INTERNAL AUTHENTICATE does: PKCS#1 v1.5 padding over the DigestInfo it is given.
    func sign(digestInfo: Data) -> Data {
        SecKeyCreateSignature(privateKey, .rsaSignatureDigestPKCS1v15Raw, digestInfo as CFData, nil)! as Data
    }
}

/// Card state that survives reconnects, like the chip: PIN, retry counter, what happened.
final class SimulatedCardState: @unchecked Sendable {
    let pin: String
    let maxTries: Int
    private(set) var triesLeft: Int
    private(set) var verifyAttempts = 0
    private(set) var signedDigestInfos: [Data] = []
    private let lock = NSLock()

    init(pin: String = "1234", tries: Int = 3) {
        self.pin = pin
        maxTries = tries
        triesLeft = tries
    }

    func verify(_ candidate: String) -> UInt16 {
        lock.lock(); defer { lock.unlock() }
        verifyAttempts += 1
        guard triesLeft > 0 else { return 0x6983 }
        if candidate == pin { triesLeft = maxTries; return 0x9000 }
        triesLeft -= 1
        return triesLeft == 0 ? 0x6983 : 0x63C0 | UInt16(triesLeft)
    }

    func recordSignature(_ digestInfo: Data) {
        lock.lock(); signedDigestInfos.append(digestInfo); lock.unlock()
    }
}

/// Card side of the CosmoX ID-A protocol: plain SELECT/READ of D003/D004, mutual authentication
/// (EXTERNAL AUTHENTICATE with CMAC + session keys), then secure messaging for SELECT, VERIFY,
/// READ BINARY (EF 0001 = certificate), MSE SET and INTERNAL AUTHENTICATE. Mirrors docs/01; every
/// byte the host sends is checked (MACs, challenge), so protocol regressions fail here, not on a real card.
final class SimulatedCosmoXCard: CardTransport {
    let readerName = "Simulated miniLector"
    private let state: SimulatedCardState
    private let identity: TestIdentity
    var extraFiles: [Data: Data] = [:]
    /// Contact-card variant: a short final READ mirrors authenticated 6282 outside SM.
    var mirrorsEOFWarning = false
    private(set) var decryptAttempts = 0
    private var decryptionSelected = false
    private let serial = Data("51180B0A2B597D33".utf8)
    private let seed = Data("32972F83F5A65D4C".utf8)
    private var selectedFile: [UInt8] = []
    private var rndICC = Data()
    private var verified = false
    private var sessENC: AES?
    private var sessMAC = Data()
    private var ssc = Data()

    init(state: SimulatedCardState, identity: TestIdentity = .shared) {
        self.state = state
        self.identity = identity
    }

    func disconnect() {}

    func transmit(_ apdu: Data) throws -> Data {
        let a = [UInt8](apdu)
        if a[0] & 0x0C == 0x0C { return try secureMessaging(a) }
        switch a[1] {
        case 0xA4:
            selectedFile = Array(a[5..<(5 + Int(a[4]))])
            return sw(0x9000)
        case 0xB0 where selectedFile == [0xD0, 0x03]:
            return Data([0x04, 0x10]) + serial + sw(0x9000)
        case 0xB0 where selectedFile == [0xD0, 0x04]:
            return seed + sw(0x9000)
        case 0x22:
            return sw(0x9000)
        case 0x84:
            rndICC = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
            return rndICC + sw(0x9000)
        case 0x82:
            return try externalAuthenticate(Data(a[5..<(5 + Int(a[4]))]))
        default:
            return sw(0x6D00)
        }
    }

    // MARK: - Mutual authentication

    private func externalAuthenticate(_ payload: Data) throws -> Data {
        let base = seed + serial + CosmoXCard.mkClass
        let kenc = (base + Data(hex: "00000002")).sha256()
        let kmac = (base + Data(hex: "00000003")).sha256()
        let ct = payload.prefix(80), mac = payload.suffix(16)
        guard AES.cmac(key: kmac, message: ct) == mac else { return sw(0x6300) }
        let aes = AES(key: kenc)
        let plain = try aes.cbcDecrypt(Data(ct), iv: Data(count: 16))
        let rndIFD = plain.prefix(16), snIFD = plain.subdata(in: 16..<24), kIFD = plain.subdata(in: 48..<80)
        guard plain.subdata(in: 24..<40) == rndICC else { return sw(0x6300) }
        let kICC = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let reply = rndICC + serial.suffix(8) + rndIFD + snIFD + kICC
        let replyCT = try aes.cbcEncrypt(reply, iv: Data(count: 16))
        let secret = AES.xorBytes(kICC, kIFD)
        sessENC = AES(key: (secret + Data(hex: "00000001")).sha256())
        sessMAC = (secret + Data(hex: "00000002")).sha256()
        ssc = Data(rndICC.suffix(8) + rndIFD.suffix(8))
        verified = false
        return replyCT + AES.cmac(key: kmac, message: replyCT) + sw(0x9000)
    }

    // MARK: - Secure messaging

    private func secureMessaging(_ a: [UInt8]) throws -> Data {
        guard let enc = sessENC else { return sw(0x6988) }
        bumpSSC()
        // parse TLVs: 87 (01 || ct) / 97 (Le) / 8E (MAC)
        let extended = a[4] == 0
        var pos = extended ? 7 : 5
        var end = pos + (extended ? Int(a[5]) * 256 + Int(a[6]) : Int(a[4]))
        guard end + (extended ? 2 : 1) == a.count else { return sw(0x6700) }
        var cipher: Data?, le: Int?, mac = Data(), macInput = Data()
        while pos < end {
            let tag = a[pos]
            var len = Int(a[pos + 1]), hdr = 2
            if a[pos + 1] == 0x81 { len = Int(a[pos + 2]); hdr = 3 }
            if a[pos + 1] == 0x82 { len = Int(a[pos + 2]) << 8 | Int(a[pos + 3]); hdr = 4 }
            let value = Data(a[(pos + hdr)..<(pos + hdr + len)])
            switch tag {
            case 0x87: cipher = value.dropFirst(); macInput += Data(a[pos..<(pos + hdr + len)])
            case 0x97: le = value.reduce(0) { $0 * 256 + Int($1) }; macInput += Data(a[pos..<(pos + hdr + len)])
            case 0x8E: mac = value
            default: break
            }
            pos += hdr + len
        }
        end = pos
        let header = AES.iso9797Pad(Data(a[0..<4]))
        guard AES.cmac(key: sessMAC, message: AES.iso9797Pad(ssc + header + macInput)).prefix(8) == mac else {
            return sw(0x6988)
        }
        var body = Data()
        if let cipher { body = AES.iso9797Unpad(try enc.cbcDecrypt(Data(cipher), iv: enc.ecbEncrypt(ssc))) }

        let (data, status) = execute(ins: a[1], p1: a[2], p2: a[3], body: body, le: le ?? 0)
        bumpSSC()
        var out = Data()
        if !data.isEmpty {
            let ct = try enc.cbcEncrypt(AES.iso9797Pad(data), iv: enc.ecbEncrypt(ssc))
            out += tlv(0x87, Data([0x01]) + ct)
        }
        out += Data([0x99, 0x02, UInt8(status >> 8), UInt8(status & 0xFF)])
        let respMAC = AES.cmac(key: sessMAC, message: AES.iso9797Pad(ssc + out)).prefix(8)
        return out + Data([0x8E, 0x08]) + respMAC + sw(mirrorsEOFWarning && [0x6282,0x6b00].contains(status) ? status : 0x9000)
    }

    private func execute(ins: UInt8, p1: UInt8, p2: UInt8, body: Data, le: Int) -> (Data, UInt16) {
        switch ins {
        case 0xA4:
            selectedFile = [UInt8](body)
            return (Data(), 0x9000)
        case 0x20:
            let status = state.verify(String(decoding: body, as: UTF8.self))
            verified = status == 0x9000
            return (Data(), status)
        case 0xB0:
            guard let file = extraFiles[Data(selectedFile)] ?? (selectedFile == [0x00,0x01] ? identity.certDER : nil) else { return (Data(),0x6A82) }
            let offset = Int(p1 & 0x7F) << 8 | Int(p2)
            guard offset < file.count else { return (Data(), 0x6B00) }
            let requested = le == 0 ? 256 : le
            let bytes = file.subdata(in: offset..<min(file.count, offset + requested))
            return (bytes, mirrorsEOFWarning && bytes.count < requested ? 0x6282 : 0x9000)
        case 0x22:
            decryptionSelected = p1 == 0x41 && p2 == 0xB8 && body == Data([0x80,0x01,0x1a,0x84,0x01,0x82])
            return (Data(), 0x9000)
        case 0x2a:
            decryptAttempts += 1
            guard verified, decryptionSelected, p1 == 0x80, p2 == 0x86, body.count == 257, body.first == 0x81,
                  let result = SecKeyCreateDecryptedData(identity.privateKey, .rsaEncryptionPKCS1, Data(body.dropFirst()) as CFData, nil) as Data? else { return (Data(),0x6982) }
            return (result,0x9000)
        case 0x88:
            guard verified else { return (Data(), 0x6982) }
            state.recordSignature(body)
            return (identity.sign(digestInfo: body), 0x9000)
        default:
            return (Data(), 0x6D00)
        }
    }

    private func bumpSSC() {
        var s = [UInt8](ssc)
        for i in stride(from: 15, through: 0, by: -1) { s[i] &+= 1; if s[i] != 0 { break } }
        ssc = Data(s)
    }

    private func tlv(_ tag: UInt8, _ value: Data) -> Data {
        if value.count < 0x80 { return Data([tag, UInt8(value.count)]) + value }
        if value.count < 0x100 { return Data([tag, 0x81, UInt8(value.count)]) + value }
        return Data([tag, 0x82, UInt8(value.count >> 8), UInt8(value.count & 0xFF)]) + value
    }

    private func sw(_ value: UInt16) -> Data { Data([UInt8(value >> 8), UInt8(value & 0xFF)]) }
}
#endif
