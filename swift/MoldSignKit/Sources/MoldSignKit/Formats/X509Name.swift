import Foundation

/// Human-readable X.501 names: decodes the DirectoryString types, so "Mîndru", "Ștefan" and "Chișinău" show as
/// written, not as RFC 2253 `\C3\AE` escapes.
///
/// For display (UI, verify reports, the bridge's `/certificates` names) only. The XAdES `X509IssuerName`
/// must keep the vendor's escaped form byte for byte: that stays in `XAdESSigner.rfc2253Name`.
public enum X509Name {
    public struct Attribute: Equatable {
        public let type: String      // "CN", "O", … or the dotted OID
        public let value: String
    }

    private static let shortNames: [[UInt8]: String] = [
        [0x55, 0x04, 0x03]: "CN", [0x55, 0x04, 0x04]: "SN", [0x55, 0x04, 0x2A]: "GN", [0x55, 0x04, 0x05]: "serialNumber",
        [0x55, 0x04, 0x06]: "C", [0x55, 0x04, 0x07]: "L", [0x55, 0x04, 0x08]: "ST", [0x55, 0x04, 0x0A]: "O",
        [0x55, 0x04, 0x0B]: "OU", [0x55, 0x04, 0x0C]: "T", [0x55, 0x04, 0x61]: "organizationIdentifier",
    ]

    /// Attributes in DER order (least significant RDN last is the usual X.509 layout: C, L, O, CN).
    public static func attributes(_ nameDER: Data) -> [Attribute] {
        let name = Data(nameDER)
        guard let (h, len) = try? DER.header(name, at: 0), name.first == 0x30 else { return [] }
        var out: [Attribute] = []
        var pos = h
        let end = min(name.count, h + len)
        while pos < end {                                           // SET OF
            guard let (sh, slen) = try? DER.header(name, at: pos) else { break }
            var p = pos + sh
            let setEnd = pos + sh + slen
            while p < setEnd {                                      // SEQUENCE { OID, value }
                guard let (qh, qlen) = try? DER.header(name, at: p),
                      let (oh, olen) = try? DER.header(name, at: p + qh) else { break }
                let oid = [UInt8](name[(p + qh + oh)..<(p + qh + oh + olen)])
                let v = p + qh + oh + olen
                guard let (vh, vlen) = try? DER.header(name, at: v) else { break }
                let value = decode(tag: name[v], name.subdata(in: (v + vh)..<(v + vh + vlen)))
                out.append(Attribute(type: shortNames[oid] ?? dotted(oid), value: value))
                p += qh + qlen
            }
            pos = setEnd
        }
        return out
    }

    /// "CN=Ștefan Mîndru,O=…,C=MD" (most significant last, like RFC 4514 / Java X500Principal).
    public static func displayString(_ nameDER: Data) -> String {
        attributes(nameDER).reversed().map { "\($0.type)=\($0.value)" }.joined(separator: ",")
    }

    public static func commonName(_ nameDER: Data) -> String? {
        attributes(nameDER).last { $0.type == "CN" }?.value
    }

    /// DirectoryString → String. Unknown/invalid encodings fall back to Latin-1, never to escapes.
    static func decode(tag: UInt8, _ raw: Data) -> String {
        switch tag {
        case 0x0C, 0x13, 0x16, 0x1A:                                // UTF8String, Printable, IA5, Visible
            return String(data: raw, encoding: .utf8) ?? String(decoding: raw, as: UTF8.self)
        case 0x1E:                                                  // BMPString (UTF-16BE)
            return String(data: raw, encoding: .utf16BigEndian) ?? ""
        case 0x1C:                                                  // UniversalString (UTF-32BE)
            return String(data: raw, encoding: .utf32BigEndian) ?? ""
        default:                                                    // TeletexString & co.: Latin-1
            return String(data: raw, encoding: .isoLatin1) ?? ""
        }
    }

    private static func dotted(_ oid: [UInt8]) -> String {
        guard let first = oid.first else { return "" }
        var parts = [String(first / 40), String(first % 40)]
        var value = 0
        for b in oid.dropFirst() {
            value = value << 7 | Int(b & 0x7F)
            if b & 0x80 == 0 { parts.append(String(value)); value = 0 }
        }
        return parts.joined(separator: ".")
    }
}

extension XAdESSigner {
    /// Raw subject / issuer Name DER of a certificate.
    static func nameDER(_ cert: Data, subject: Bool) throws -> Data {
        var pos = skipTLVHeaderLen(cert, at: 0)
        pos += skipTLVHeaderLen(cert, at: pos)                     // TBS
        if cert[pos] == 0xA0 { pos += skipTLV(cert, at: pos) }      // version
        pos += skipTLV(cert, at: pos)                              // serial
        pos += skipTLV(cert, at: pos)                              // signature alg
        if subject {
            pos += skipTLV(cert, at: pos)                          // issuer
            pos += skipTLV(cert, at: pos)                          // validity
        }
        let len = skipTLV(cert, at: pos)
        guard len > 0, pos + len <= cert.count else { throw CardError.signFailed("bad certificate name") }
        return cert.subdata(in: pos..<(pos + len))
    }
}
