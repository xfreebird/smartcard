import Foundation
import CPCSC

enum CardError: Error, LocalizedError {
    case noReader
    case noCard
    case cardNotResponding
    case macVerificationFailed
    case apduError(UInt16)
    case signFailed(String)

    var errorDescription: String? {
        switch self {
        case .noReader: return "No card reader found"
        case .noCard: return "No card in reader"
        case .cardNotResponding: return "Card not responding"
        case .macVerificationFailed: return "Secure messaging MAC verification failed"
        case .apduError(let sw): return String(format: "APDU error: %04X", sw)
        case .signFailed(let msg): return "Signing failed: \(msg)"
        }
    }
}

/// CosmoX ID-A card driver — implements the full IAS/ECC protocol
class CosmoXCard {
    // MARK: - Constants
    static let iasAID = Data(hex: "A000000077030C60000000FE00000500")
    static let genericADF = Data(hex: "E828BD080FD25047656E65726963")
    static let mkClass = Data(hex: "C1765FCA5C11B6E9F827EB1230FA74C3140619976CE92B66199801CFDB125F1E")
    static let rndIFD = Data(hex: "199F0388C3ACEC2D84C6CE4CE785CB7B")
    static let snIFD = Data(hex: "4A95FED1DB606A62")
    static let kIFD = Data(hex: "445969C4020CEDD4A8C4BFCE4B9820D2BE8CDD972F983B813038A512905BBF08")

    // MARK: - State
    private var ctx: Int64 = 0
    private var hCard: Int64 = 0
    private var activeProtocol: UInt32 = 0
    private var channel: SecureChannel?
    private(set) var serialNumber: Data = Data()
    private(set) var randomSeed: Data = Data()

    // MARK: - Connection

    func connect() throws {
        var ctx: Int64 = 0
        let rv = c_scard_establish(0, &ctx) // SCARD_SCOPE_USER = 0
        guard rv == 0 else { throw CardError.noReader }
        self.ctx = ctx

        var bufLen: UInt32 = 4096
        var readersBuf = [CChar](repeating: 0, count: Int(bufLen))
        let rv2 = c_scard_list_readers(&ctx, &readersBuf, &bufLen)
        guard rv2 == 0, bufLen > 1 else { throw CardError.noReader }

        let readerName = String(cString: readersBuf)
        print("Reader: \(readerName)")

        var hCard: Int64 = 0
        var proto: UInt32 = 0
        let rv3 = c_scard_connect(&ctx, readerName, 2, 3, &hCard, &proto) // shared, T0|T1
        guard rv3 == 0 else { throw CardError.noCard }
        self.hCard = hCard
        self.activeProtocol = proto
        print("Connected, protocol: \(proto)")
    }

    func disconnect() {
        if hCard != 0 { _ = c_scard_disconnect(&hCard, 0); hCard = 0 }
        if ctx != 0 { _ = c_scard_release(&ctx); ctx = 0 }
    }

    // MARK: - Raw APDU

    func transmit(_ apdu: Data) throws -> (data: Data, sw: Data) {
        let sendBytes = [UInt8](apdu)
        var recvBuf = [UInt8](repeating: 0, count: 65536)
        var recvLen: UInt32 = UInt32(recvBuf.count)
        let rv = c_scard_transmit(&hCard, sendBytes, UInt32(sendBytes.count), &recvBuf, &recvLen)
        guard rv == 0, recvLen >= 2 else { throw CardError.cardNotResponding }

        var response = Data(recvBuf[0..<Int(recvLen)])
        let sw = response.suffix(2)
        let data = response.dropLast(2)
        return (Data(data), Data(sw))
    }

    func transmitFull(_ apdu: Data) throws -> (data: Data, sw: Data) {
        var result = Data()
        var (data, sw) = try transmit(apdu)
        while sw.count == 2 && sw[0] == 0x61 {
            result += data
            let getResp = Data([0x00, 0xC0, 0x00, 0x00, sw[1]])
            (data, sw) = try transmit(getResp)
        }
        result += data
        return (result, sw)
    }

    func checkSW(_ sw: Data, context: String = "") throws {
        guard sw.count == 2 else { throw CardError.cardNotResponding }
        if sw[0] == 0x90 && sw[1] == 0x00 { return }
        let swVal = (UInt16(sw[0]) << 8) | UInt16(sw[1])
        throw CardError.apduError(swVal)
    }

    // MARK: - SM-wrapped transmit

    func smTransmit(_ apdu: Data) throws -> (data: Data, sw: Data) {
        guard var ch = channel else { throw CardError.cardNotResponding }
        let wrapped = try ch.wrap(apdu)
        channel = ch
        print("  SM TX: \(wrapped.hexString.prefix(80))\(wrapped.count > 40 ? "..." : "")")
        let (rawResp, rawSW) = try transmitFull(wrapped)
        print("    SM RX raw(\(rawResp.count)B): \(rawResp.hexString.prefix(60))... SW=\(rawSW.hexString)")
        if rawResp.isEmpty {
            // Card advances SSC for the response even when returning SW only.
            // We must increment to stay in sync.
            _ = ch.incSSCPublic()
            channel = ch
            return (Data(), rawSW)
        }
        ch = channel!
        print("    [unwrap: calling with \(rawResp.count + rawSW.count)B...]")
        let (data, sw) = try ch.unwrap(rawResp + rawSW)
        channel = ch
        print("    [unwrap: OK, data=\(data.count)B, sw=\(sw.hexString)]")
        return (data, sw)
    }

    // MARK: - Mutual Authentication

    func authenticate() throws {
        // 1. SELECT IAS AID
        var selectAID = Data([0x00, 0xA4, 0x04, 0x00, UInt8(Self.iasAID.count), 0x00])
        selectAID.insert(contentsOf: Self.iasAID, at: 5)
        let (_, sw) = try transmitFull(selectAID)
        try checkSW(sw)

        // 2. SELECT MF
        _ = try transmitFull(Data([0x00, 0xA4, 0x00, 0x0C, 0x02, 0x3F, 0x00, 0x00]))
        try checkSW(sw)

        // 3. Read serial (D003)
        _ = try transmitFull(Data([0x00, 0xA4, 0x02, 0x04, 0x02, 0xD0, 0x03, 0x00]))
        let (serData, _) = try transmitFull(Data([0x00, 0xB0, 0x00, 0x00, 0x00]))
        serialNumber = serData.dropFirst(2).prefix(16)
        print("Serial: \(String(data: serialNumber, encoding: .ascii) ?? "??")")

        // 4. Read seed (D004)
        _ = try transmitFull(Data([0x00, 0xA4, 0x02, 0x04, 0x02, 0xD0, 0x04, 0x00]))
        let (seedData, _) = try transmitFull(Data([0x00, 0xB0, 0x00, 0x00, 0x10]))
        randomSeed = seedData.prefix(16)
        print("Seed: \(String(data: randomSeed, encoding: .ascii) ?? "??")")

        // 5. Derive admin keys
        let base = randomSeed + serialNumber + Self.mkClass
        let kenc = (base + Data(hex: "00000002")).sha256()
        let kmac = (base + Data(hex: "00000003")).sha256()

        // 6. MSE SET for SM
        let (_, swMSE) = try transmitFull(Data(hex: "0022C1A4098004FF40108C830104"))
        try checkSW(swMSE)

        // 7. GET CHALLENGE
        let (challenge, _) = try transmitFull(Data([0x00, 0x84, 0x00, 0x00, 0x10]))
        let rndICC = challenge.prefix(16)

        // 8. Build and send EXTERNAL AUTHENTICATE
        let snICC = serialNumber.suffix(8)
        let plainBuf = Self.rndIFD + Self.snIFD + rndICC + snICC + Self.kIFD
        let aesKenc = AES(key: kenc)
        let ct = try aesKenc.cbcEncrypt(plainBuf, iv: Data(repeating: 0, count: 16))
        let mac = AES.cmac(key: kmac, message: ct)
        var extAuth = Data([0x00, 0x82, 0x00, 0x00, 0x60])
        extAuth += ct + mac.prefix(16)
        let (respData, swEA) = try transmitFull(extAuth)
        try checkSW(swEA)
        guard respData.count == 96 else { throw CardError.signFailed("Bad ext auth response: \(respData.count)") }

        // 9. Verify response MAC and decode
        let respCT = respData.prefix(80)
        let respMAC = respData.dropFirst(80).prefix(16)
        guard AES.cmac(key: kmac, message: respCT).prefix(16) == respMAC else {
            throw CardError.macVerificationFailed
        }
        let respPlain = try aesKenc.cbcDecrypt(respCT, iv: Data(repeating: 0, count: 16))
        let kICC = respPlain.subdata(in: 48..<80)

        // 10. Derive session keys
        let secret = AES.xorBytes(kICC, Self.kIFD)
        let sessENC = (secret + Data(hex: "00000001")).sha256()
        let sessMAC = (secret + Data(hex: "00000002")).sha256()
        let ssc = Data([UInt8](respPlain.prefix(16).suffix(8)) + [UInt8](Self.rndIFD.suffix(8)))

        print("  K_ICC:   \(kICC.hexString)")
        print("  sessENC:  \(sessENC.hexString)")
        print("  sessMAC:  \(sessMAC.hexString)")
        print("  SSC:      \(ssc.hexString)")
        channel = SecureChannel(sessENC: sessENC, sessMAC: sessMAC, ssc: ssc)
        print("Secure channel established")
    }

    // MARK: - SM Operations

    func selectMF() throws {
        let (_, sw) = try smTransmit(Data([0x00, 0xA4, 0x00, 0x0C, 0x02, 0x3F, 0x00, 0x00]))
        try checkSW(sw)
    }

    func selectGenericADF() throws {
        var apdu = Data([0x00, 0xA4, 0x04, 0x04, UInt8(Self.genericADF.count)])
        apdu += Self.genericADF
        apdu.append(0x00)
        let (_, sw) = try smTransmit(apdu)
        try checkSW(sw)
    }

    func readBinary(offset: Int, length: Int) throws -> Data {
        var result = Data()
        var remaining = length
        var off = offset
        while remaining > 0 {
            let chunkLen = min(remaining, 128)
            let apdu = Data([0x00, 0xB0, UInt8((off >> 8) & 0x7F), UInt8(off & 0xFF), UInt8(chunkLen)])
            let (data, sw) = try smTransmit(apdu)
            try checkSW(sw)
            result += AES.iso9797Unpad(data)
            off += chunkLen
            remaining -= chunkLen
            if data.isEmpty { break }
        }
        return result
    }

    func verifyPIN(_ pin: String) throws {
        guard let pinData = pin.data(using: .ascii), (4...8).contains(pinData.count) else {
            throw CardError.signFailed("PIN must be 4-8 characters")
        }
        // Pass raw PIN bytes; SM ISO-9797-2 padding handles the block alignment
        let padded = pinData

        let apdu = Data([0x00, 0x20, 0x00, 0x03, UInt8(padded.count)]) + padded
        let (_, sw) = try smTransmit(apdu)

        guard sw.count == 2 else { throw CardError.signFailed("Bad VERIFY response") }
        if sw[0] == 0x63 {
            throw CardError.signFailed("Wrong PIN, \(sw[1] & 0x0F) attempts remaining")
        }
        try checkSW(sw)
    }

    func sign(digestInfo: Data) throws -> Data {
        let mseData = Data([0x80, 0x01, 0x02, 0x84, 0x01, 0x81])
        let mseAPDU = Data([0x00, 0x22, 0x41, 0xA4, UInt8(mseData.count)]) + mseData
        let (_, swMSE) = try smTransmit(mseAPDU)
        try checkSW(swMSE)

        var iaAPDU = Data([0x00, 0x88, 0x00, 0x00, UInt8(min(digestInfo.count, 255))])
        iaAPDU += digestInfo
        let (sig, swIA) = try smTransmit(iaAPDU)
        try checkSW(swIA)
        return sig
    }

    func readCertificate() throws -> Data {
        try selectMF()
        try selectGenericADF()
        _ = try smTransmit(Data([0x00, 0xA4, 0x02, 0x04, 0x02, 0x00, 0x01, 0x00]))

        let header = try readBinary(offset: 0, length: 16)
        print("    Cert header(\(header.count)B): \(header.hexString.prefix(32))")
        guard header.count >= 4, header[0] == 0x30, header[1] == 0x82 else {
            throw CardError.signFailed("Cert file doesn't start with SEQUENCE")
        }
        let totalLen = 4 + (Int(header[2]) << 8) + Int(header[3])
        let body = try readBinary(offset: 4, length: totalLen - 4)

        var file = header.prefix(4) + body
        guard file.count > 8, file[4] == 0x30, file[5] == 0x82 else {
            throw CardError.signFailed("No cert in file")
        }
        // The OUTER SEQUENCE (header.prefix(4) + body) IS the full Certificate
        // (TBS + signatureAlgorithm + signatureValue). Return it whole.
        let outerLen = 4 + (Int(header[2]) << 8) + Int(header[3])
        let fullCert = file.prefix(outerLen)
        print("    Full certificate: \(fullCert.count)B (TBS=\(4 + (Int(file[6]) << 8) + Int(file[7]))}B)")
        return Data(fullCert)
    }

    /// Full signing flow
    func signPDF(_ pdfData: Data, pin: String) throws -> Data {
        try authenticate()
        try selectMF()
        try selectGenericADF()

        let certDER = try readCertificate()
        print("Certificate: \(certDER.count) bytes")

        let pades = PAdESSigner()
        print("  [PAdES: starting signPDF...]")
        let result = try pades.signPDF(pdfData, certDER: certDER) { digestInfo in
            print("  [CLOSURE: signing with card, digestInfo=\(digestInfo.count)B]")
            try selectGenericADF()
            try verifyPIN(pin)
            return try sign(digestInfo: digestInfo)
        }
        print("  [PAdES: signPDF returned \(result.count)B]")
        return result
    }
}
