import Foundation

public enum CardError: Error, LocalizedError {
    case noReader
    case noCard
    case cardNotResponding
    case macVerificationFailed
    case apduError(UInt16)
    case signFailed(String)
    /// VERIFY answered 63Cx. Never retry automatically (MAC-05): the stored PIN must be dropped.
    case wrongPIN(remaining: Int)
    /// 6983: PIN blocked, needs unblocking at CEV.
    case pinBlocked
    /// The card in the reader isn't the one the PIN/consent was for (removed + another inserted). Raised
    /// BEFORE VERIFY, so another card's PIN is never sent (it would burn a retry on the wrong card).
    case cardChanged

    public var errorDescription: String? {
        switch self {
        case .noReader: return "No card reader found"
        case .noCard: return "No card in reader"
        case .cardNotResponding: return "Card not responding"
        case .macVerificationFailed: return "Secure messaging MAC verification failed"
        case .apduError(let sw): return String(format: "APDU error: %04X", sw)
        case .signFailed(let msg): return "Signing failed: \(msg)"
        case .wrongPIN(let remaining): return "Signing failed: Wrong PIN, \(remaining) attempts remaining"
        case .pinBlocked: return "PIN blocked"
        case .cardChanged: return "The card in the reader changed; check the holder and sign again"
        }
    }
}

/// CosmoX ID-A card driver — implements the full IAS/ECC protocol over any `CardTransport`.
public final class CosmoXCard {
    // MARK: - Constants
    static let iasAID = Data(hex: "A000000077030C60000000FE00000500")
    static let genericADF = Data(hex: "E828BD080FD25047656E65726963")
    static let mkClass = Data(hex: "C1765FCA5C11B6E9F827EB1230FA74C3140619976CE92B66199801CFDB125F1E")
    static let rndIFD = Data(hex: "199F0388C3ACEC2D84C6CE4CE785CB7B")
    static let snIFD = Data(hex: "4A95FED1DB606A62")
    static let kIFD = Data(hex: "445969C4020CEDD4A8C4BFCE4B9820D2BE8CDD972F983B813038A512905BBF08")

    // MARK: - State
    private var transport: CardTransport?
    private var channel: SecureChannel?
    public private(set) var serialNumber: Data = Data()
    public private(set) var randomSeed: Data = Data()

    public var readerName: String? { transport?.readerName }

    public init() {}

    public init(transport: CardTransport) {
        self.transport = transport
    }

    // MARK: - Connection

    /// Connects through the platform's default transport (PC/SC on macOS, CryptoTokenKit on iOS).
    public func connect() throws {
        transport = try CardTransports.connectDefault()
    }

    public func disconnect() {
        transport?.disconnect()
        transport = nil
        channel = nil
    }

    // MARK: - Raw APDU

    func transmit(_ apdu: Data) throws -> (data: Data, sw: Data) {
        guard let transport else { throw CardError.noCard }
        let response = try transport.transmit(apdu)
        guard response.count >= 2 else { throw CardError.cardNotResponding }
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
        MSLog.debug("  SM TX: \(wrapped.hexString.prefix(80))\(wrapped.count > 40 ? "..." : "")")
        let (rawResp, rawSW) = try transmitFull(wrapped)
        MSLog.debug("    SM RX raw(\(rawResp.count)B): \(rawResp.hexString.prefix(60))... SW=\(rawSW.hexString)")
        if rawResp.isEmpty {
            // Card advances SSC for the response even when returning SW only.
            // We must increment to stay in sync.
            _ = ch.incSSCPublic()
            channel = ch
            return (Data(), rawSW)
        }
        ch = channel!
        MSLog.debug("    [unwrap: calling with \(rawResp.count + rawSW.count)B...]")
        let (data, sw) = try ch.unwrap(rawResp + rawSW)
        channel = ch
        MSLog.debug("    [unwrap: OK, data=\(data.count)B, sw=\(sw.hexString)]")
        return (data, sw)
    }

    /// Test hook: an established channel without running mutual auth against a real card.
    func installSecureChannel(_ channel: SecureChannel) {
        self.channel = channel
    }

    // MARK: - Mutual Authentication

    public func authenticate() throws {
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
        MSLog.info("Serial: \(String(data: serialNumber, encoding: .ascii) ?? "??")")

        // 4. Read seed (D004)
        _ = try transmitFull(Data([0x00, 0xA4, 0x02, 0x04, 0x02, 0xD0, 0x04, 0x00]))
        let (seedData, _) = try transmitFull(Data([0x00, 0xB0, 0x00, 0x00, 0x10]))
        randomSeed = seedData.prefix(16)
        MSLog.debug("Seed: \(String(data: randomSeed, encoding: .ascii) ?? "??")")

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

        MSLog.debug("  K_ICC:   \(kICC.hexString)")
        MSLog.debug("  sessENC:  \(sessENC.hexString)")
        MSLog.debug("  sessMAC:  \(sessMAC.hexString)")
        MSLog.debug("  SSC:      \(ssc.hexString)")
        channel = SecureChannel(sessENC: sessENC, sessMAC: sessMAC, ssc: ssc)
        MSLog.info("Secure channel established")
    }

    // MARK: - SM Operations

    public func selectMF() throws {
        let (_, sw) = try smTransmit(Data([0x00, 0xA4, 0x00, 0x0C, 0x02, 0x3F, 0x00, 0x00]))
        try checkSW(sw)
    }

    public func selectGenericADF() throws {
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
            // unwrap() already removed the SM padding; stripping again truncated chunks ending in 00/80
            result += data
            off += chunkLen
            remaining -= chunkLen
            if data.isEmpty { break }
        }
        return result
    }

    public func verifyPIN(_ pin: String) throws {
        guard let pinData = pin.data(using: .ascii), (4...8).contains(pinData.count) else {
            throw CardError.signFailed("PIN must be 4-8 characters")
        }
        // Pass raw PIN bytes; SM ISO-9797-2 padding handles the block alignment
        let padded = pinData

        let apdu = Data([0x00, 0x20, 0x00, 0x03, UInt8(padded.count)]) + padded
        let (_, sw) = try smTransmit(apdu)

        guard sw.count == 2 else { throw CardError.signFailed("Bad VERIFY response") }
        if sw[0] == 0x63 {
            throw CardError.wrongPIN(remaining: Int(sw[1] & 0x0F))
        }
        if sw[0] == 0x69 && sw[1] == 0x83 {
            throw CardError.pinBlocked
        }
        try checkSW(sw)
    }

    public func sign(digestInfo: Data) throws -> Data {
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

    public func readCertificate() throws -> Data {
        try selectMF()
        try selectGenericADF()
        _ = try smTransmit(Data([0x00, 0xA4, 0x02, 0x04, 0x02, 0x00, 0x01, 0x00]))

        let header = try readBinary(offset: 0, length: 16)
        MSLog.debug("    Cert header(\(header.count)B): \(header.hexString.prefix(32))")
        guard header.count >= 4, header[0] == 0x30, header[1] == 0x82 else {
            throw CardError.signFailed("Cert file doesn't start with SEQUENCE")
        }
        let totalLen = 4 + (Int(header[2]) << 8) + Int(header[3])
        let body = try readBinary(offset: 4, length: totalLen - 4)

        let file = header.prefix(4) + body
        guard file.count > 8, file[4] == 0x30, file[5] == 0x82 else {
            throw CardError.signFailed("No cert in file")
        }
        // The OUTER SEQUENCE (header.prefix(4) + body) IS the full Certificate
        // (TBS + signatureAlgorithm + signatureValue). Return it whole.
        let outerLen = 4 + (Int(header[2]) << 8) + Int(header[3])
        let fullCert = file.prefix(outerLen)
        MSLog.debug("    Full certificate: \(fullCert.count)B (TBS=\(4 + (Int(file[6]) << 8) + Int(file[7]))}B)")
        return Data(fullCert)
    }

    /// SELECT MF → ADF → read EF 0001 → identity check → SELECT ADF → VERIFY (the CLI's PAdES order).
    /// The certificate is read before the PIN goes out, so a swapped card never receives another card's PIN.
    @discardableResult
    public func prepareForSigning(pin: String, expectedCertificateSHA1: String?) throws -> Data {
        try selectMF()
        try selectGenericADF()
        let cert = try readCertificate()
        if let expected = expectedCertificateSHA1, cert.sha1().hexString.lowercased() != expected.lowercased() {
            throw CardError.cardChanged
        }
        try selectGenericADF()
        try verifyPIN(pin)
        return cert
    }

    /// Full signing flow
    public func signPDF(_ pdfData: Data, pin: String) throws -> Data {
        try authenticate()
        try selectMF()
        try selectGenericADF()

        let certDER = try readCertificate()
        MSLog.info("Certificate: \(certDER.count) bytes")

        let pades = PAdESSigner()
        MSLog.debug("  [PAdES: starting signPDF...]")
        let result = try pades.signPDF(pdfData, certDER: certDER) { digestInfo in
            MSLog.debug("  [CLOSURE: signing with card, digestInfo=\(digestInfo.count)B]")
            try selectGenericADF()
            try verifyPIN(pin)
            return try sign(digestInfo: digestInfo)
        }
        MSLog.debug("  [PAdES: signPDF returned \(result.count)B]")
        return result
    }
}
