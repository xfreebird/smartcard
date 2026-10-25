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
        // Split header (CLA INS P1 P2) and body
        let header = apdu.prefix(4)
        var cla = header[0] | 0x0C  // SM bit
        let ins = header[1]
        let p1 = header[2]
        let p2 = header[3]

        var dataField = Data()
        var calcMac = Data()

        // Parse original APDU body
        let body = Data(apdu.dropFirst(4))
        var lc: Int = 0
        var cmdData = Data()
        var le: UInt8? = nil

        if body.count == 1 {
            // Case 2 APDU: CLA INS P1 P2 Le (no data, just expected length)
            le = body[0]
            lc = 0
        } else if body.count > 1 {
            lc = Int(body[0])
            if lc > 0 && (1 + lc) <= body.count {
                cmdData = body.subdata(in: 1..<(1 + lc))
            }
            if body.count > 1 + lc {
                le = body[body.count - 1]
            }
        }

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
            let tlv = buildTLV(0x97, Data([le]))
            calcMac += tlv
            dataField += tlv
        }

        // MAC: SSC1 + calcMac, ISO padded, AES-CMAC truncated to 8
        let toMac = AES.iso9797Pad(ssc1 + calcMac)
        print("    SM DEBUG: SSC1=\(ssc1.hexString)")
        print("    SM DEBUG: IV=\(aesENC.ecbEncrypt(ssc1).hexString)")
        print("    SM DEBUG: toMac(\(toMac.count)B)=\(toMac.hexString)")
        print("    SM DEBUG: MAC=\(AES.cmac(key: sessMAC, message: toMac).prefix(8).hexString)")
        let fullMac = AES.cmac(key: sessMAC, message: toMac)
        let mac8 = fullMac.prefix(8)
        dataField += buildTLV(0x8E, mac8)

        // Build final APDU
        var result = Data([cla, ins, p1, p2, UInt8(dataField.count)])
        result += dataField
        result.append(0x00) // Lua always appends Le=00
        return result
    }

    /// Unwrap an SM response
    mutating func unwrap(_ response: Data) throws -> (data: Data, sw: Data) {
        guard response.count > 2 else { return (Data(), response) }

        let swFromTail = response.suffix(2)
        var body = Data(response.dropLast(2))

        // Parse TLVs
        var resultData = Data()
        var resultSW = Data()
        var respMac = Data()
        var calcMac = Data()
        let ssc1 = incSSC()
        calcMac = ssc1

        var pos = body.startIndex
        while pos < body.endIndex {
            let tag = body[pos]
            var len: Int
            var hdrLen: Int
            let l1 = body[body.index(after: pos)]

            if l1 < 0x80 {
                len = Int(l1)
                hdrLen = 2
            } else if l1 == 0x81 {
                len = Int(body[body.index(pos, offsetBy: 2)])
                hdrLen = 3
            } else if l1 == 0x82 {
                len = Int(body[body.index(pos, offsetBy: 2)]) << 8 | Int(body[body.index(pos, offsetBy: 3)])
                hdrLen = 4
            } else {
                break
            }

            let contentStart = body.index(pos, offsetBy: hdrLen)
            let contentEnd = body.index(pos, offsetBy: hdrLen + len)
            guard contentEnd <= body.endIndex else { break }
            let content = body.subdata(in: contentStart..<contentEnd)
            let fullTLV = body.subdata(in: pos..<contentEnd)

            switch tag {
            case 0x87:
                calcMac += fullTLV
                let enc = content.count > 1 ? content.dropFirst() : content
                let iv = aesENC.ecbEncrypt(ssc1)
                resultData = try aesENC.cbcDecrypt(enc, iv: iv)
            case 0x85:
                calcMac += fullTLV
                let iv = aesENC.ecbEncrypt(ssc1)
                resultData = try aesENC.cbcDecrypt(content, iv: iv)
            case 0x99:
                calcMac += fullTLV
                resultSW = content
            case 0x8E:
                respMac = content
            default:
                break
            }

            pos = contentEnd
        }

        // Verify MAC
        if !respMac.isEmpty {
            let toMac = AES.iso9797Pad(calcMac)
            let expected = AES.cmac(key: sessMAC, message: toMac).prefix(8)
            guard expected == respMac else {
                throw CardError.macVerificationFailed
            }
        }

        // Unpad decrypted data
        if !resultData.isEmpty {
            resultData = AES.iso9797Unpad(resultData)
        }

        return (resultData, resultSW.isEmpty ? swFromTail : resultSW)
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
