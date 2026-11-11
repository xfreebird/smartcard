import Foundation

// MARK: - Minimal DER helpers

enum DER {
    static func tlv(_ tag: UInt8, _ content: Data) -> Data {
        var out = Data([tag])
        let n = content.count
        if n < 0x80 {
            out.append(UInt8(n))
        } else if n < 0x100 {
            out += [0x81, UInt8(n)]
        } else if n < 0x10000 {
            out += [0x82, UInt8(n >> 8), UInt8(n & 0xFF)]
        } else {
            out += [0x83, UInt8(n >> 16), UInt8((n >> 8) & 0xFF), UInt8(n & 0xFF)]
        }
        return out + content
    }

    static func seq(_ content: Data) -> Data { tlv(0x30, content) }

    /// (header length, content length) of the TLV at `offset` in a zero-based Data.
    static func header(_ d: Data, at offset: Int) throws -> (Int, Int) {
        guard offset >= 0, offset < d.count, d.count - offset >= 2 else { throw CardError.signFailed("DER truncated") }
        let l1 = Int(d[offset + 1])
        if l1 < 0x80 { return (2, l1) }
        let n = l1 & 0x7F
        guard (1...3).contains(n), offset + 1 + n < d.count else { throw CardError.signFailed("DER length") }
        var len = 0
        for i in 0..<n { len = len << 8 | Int(d[offset + 2 + i]) }
        return (2 + n, len)
    }

    struct Element {
        let tag: UInt8
        let range: Range<Int>
        let content: Range<Int>
    }

    /// A fully bounded element. Callers can slice only after the declared payload has been checked.
    static func element(_ data: Data, at offset: Int) throws -> Element {
        let (header, length) = try self.header(data, at: offset)
        guard header <= data.count - offset, length <= data.count - offset - header else {
            throw CardError.signFailed("DER truncated payload")
        }
        return Element(tag: data[offset], range: offset..<(offset + header + length),
                       content: (offset + header)..<(offset + header + length))
    }
}
