import Foundation

/// IAS/ECC secure messaging channel for the CosmoX ID-A card
struct SecureChannel {
    let sessENC: Data  // 32 bytes AES-256 key
    let sessMAC: Data  // 32 bytes AES-256 key
    var ssc: Data      // 16-byte send sequence counter

    let aesENC: AES
    let aesMAC: AES

    init(sessENC: Data, sessMAC: Data, ssc: Data) {
        self.sessENC = sessENC
        self.sessMAC = sessMAC
        self.ssc = ssc
        self.aesENC = AES(key: sessENC)
        self.aesMAC = AES(key: sessMAC)
    }

    /// Increment SSC as big-endian 128-bit
    mutating func incSSCPublic() -> Data { incSSC() }

    private mutating func incSSC() -> Data {
        var s = ssc
        for i in stride(from: 15, through: 0, by: -1) {
            s[i] = s[i] &+ 1
            if s[i] != 0 { break }
        }
        ssc = s
        return s
    }

    /// Wrap an APDU in secure messaging
    mutating func wrap(_ apdu: Data) throws -> Data {
        guard apdu.count >= 4 else { throw CryptoError.invalidLength }
        let header = Data(apdu.prefix(4))
        let cla = header[0] | 0x0C, ins = header[1], p1 = header[2], p2 = header[3]
        let body = Data(apdu.dropFirst(4))
        var cmdData = Data(), le: Data? = nil
        let extended = body.count > 1 && body[0] == 0
        if body.count == 1 { le = body }
        else if extended {
            guard body.count >= 3 else { throw CryptoError.invalidLength }
            if body.count == 3 { le = Data(body.suffix(2)) }
            else {
                let count = Int(body[1]) * 256 + Int(body[2])
                guard count > 0, body.count == count + 3 || body.count == count + 5 else { throw CryptoError.invalidLength }
                cmdData = body.subdata(in: 3..<(3+count))
                if body.count == count+5 { le = Data(body.suffix(2)) }
            }
        } else if body.count > 1 {
            let count = Int(body[0])
            guard body.count == count + 1 || body.count == count + 2 else { throw CryptoError.invalidLength }
            cmdData = body.subdata(in: 1..<(1+count))
            if body.count == count + 2 { le = Data(body.suffix(1)) }
        }
        var dataField = Data(), calcMac = Data()

        guard cmdData.count <= 65488 else { throw CryptoError.invalidLength }
        let ssc1 = incSSC()

        // Pad header for MAC
        let paddedHeader = AES.iso9797Pad(Data([cla, ins, p1, p2]))
        calcMac = paddedHeader

        // Encrypt data if present
        if !cmdData.isEmpty {
            let iv = aesENC.ecbEncrypt(ssc1)
            let padded = AES.iso9797Pad(cmdData)
            let enc = try aesENC.cbcEncrypt(padded, iv: iv)

            // Even INS → tag 87 (with 01 prefix), odd INS → tag 85
            let tlv: Data
            if ins % 2 == 0 {
                tlv = buildTLV(0x87, Data([0x01]) + enc)
            } else {
                tlv = buildTLV(0x85, enc)
            }
            calcMac += tlv
            dataField += tlv
        }

        // Le as tag 97
        if let le = le {
            let tlv = buildTLV(0x97, le)
            calcMac += tlv
            dataField += tlv
        }

        // MAC: SSC1 + calcMac, ISO padded, AES-CMAC truncated to 8
        let toMac = AES.iso9797Pad(ssc1 + calcMac)
        let fullMac = AES.cmac(key: sessMAC, message: toMac)
        let mac8 = fullMac.prefix(8)
        dataField += buildTLV(0x8E, mac8)

        // Build final APDU
        guard dataField.count <= 65535 else { throw CryptoError.invalidLength }
        var result = Data([cla, ins, p1, p2])
        if extended || dataField.count > 255 {
            result += Data([0, UInt8(dataField.count >> 8), UInt8(dataField.count & 255)]) + dataField + Data([0,0])
        } else { result += Data([UInt8(dataField.count)]) + dataField + Data([0]) }
        return result
    }

    /// Unwrap an SM response
    mutating func unwrap(_ response: Data) throws -> (data: Data, sw: Data) {
        guard response.count >= 2 else { throw CardError.cardNotResponding }
        let ssc1 = incSSC()
        let outer = Data(response.suffix(2))
        if response.count == 2 {
            guard outer != Data([0x90, 0]) else { throw CardError.macVerificationFailed }
            return (Data(), outer)
        }
        guard outer == Data([0x90, 0]) else { throw CardError.cardNotResponding }
        let body = Data(response.dropLast(2))
        var parts: [DER.Element] = []
        var offset = 0
        while offset < body.count {
            guard let element = try? DER.element(body, at: offset), element.range.upperBound > offset else {
                throw CardError.macVerificationFailed
            }
            parts.append(element)
            offset = element.range.upperBound
        }
        let tags = parts.map(\.tag)
        guard tags == [0x99, 0x8E] || tags == [0x87, 0x99, 0x8E] || tags == [0x85, 0x99, 0x8E],
              let status = parts.first(where: { $0.tag == 0x99 }), status.content.count == 2,
              let mac = parts.last, mac.content.count == 8 else { throw CardError.macVerificationFailed }
        let authenticated = body.subdata(in: 0..<mac.range.lowerBound)
        let expected = Data(AES.cmac(key: sessMAC, message: AES.iso9797Pad(ssc1 + authenticated)).prefix(8))
        let actual = body.subdata(in: mac.content)
        var difference: UInt8 = 0
        for (a, b) in zip(expected, actual) { difference |= a ^ b }
        guard difference == 0 else { throw CardError.macVerificationFailed }
        var result = Data()
        if let encrypted = parts.first, encrypted.tag == 0x87 || encrypted.tag == 0x85 {
            let content = body.subdata(in: encrypted.content)
            if encrypted.tag == 0x87 {
                guard content.first == 1 else { throw CardError.macVerificationFailed }
            }
            let ciphertext = encrypted.tag == 0x87 ? Data(content.dropFirst()) : content
            guard !ciphertext.isEmpty, ciphertext.count % 16 == 0 else { throw CardError.macVerificationFailed }
            var plain = [UInt8](try aesENC.cbcDecrypt(ciphertext, iv: aesENC.ecbEncrypt(ssc1)))
            while plain.last == 0 { plain.removeLast() }
            guard plain.last == 0x80 else { throw CardError.macVerificationFailed }
            plain.removeLast()
            result = Data(plain)
        }
        return (result, body.subdata(in: status.content))
    }

    private func buildTLV(_ tag: UInt8, _ content: Data) -> Data {
        var tlv = Data([tag])
        if content.count < 128 {
            tlv.append(UInt8(content.count))
        } else if content.count < 256 {
            tlv.append(0x81)
            tlv.append(UInt8(content.count))
        } else {
            tlv.append(0x82)
            tlv.append(UInt8(content.count >> 8))
            tlv.append(UInt8(content.count & 0xFF))
        }
        tlv += content
        return tlv
    }
}
