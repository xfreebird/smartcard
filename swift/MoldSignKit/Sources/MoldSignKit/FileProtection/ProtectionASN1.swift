import Foundation

/// Bounded BER reader for legacy streaming CMS; retains exact certificate TLVs.
struct ProtectionASN1 {
    let tag: UInt8
    let content: Data
    let encoded: Data
    let children: [ProtectionASN1]
    static func parse(_ input: Data) throws -> ProtectionASN1 {
        guard input.count <= PasswordFileProtection.maximumSize + 8192 else { throw FileProtectionError.tooLarge }
        let bytes = [UInt8](input)
        var position = 0, budget = 100_000, storage = 4 * 1024 * 1024
        let node = try read(bytes, &position, end: bytes.count, depth: 0, budget: &budget, storage: &storage)
        guard position == bytes.count else { throw FileProtectionError.invalidFormat }
        return node
    }
    /// PKCS#15 directory files contain consecutive records followed by zero padding.
    static func records(_ input: Data) throws -> [ProtectionASN1] {
        guard input.count <= 32768 else { throw FileProtectionError.tooLarge }
        let bytes = [UInt8](input)
        var position = 0, budget = 4096, storage = 4 * 1024 * 1024
        var result: [ProtectionASN1] = []
        while position < bytes.count {
            if bytes[position] == 0 {
                guard bytes[position...].allSatisfy({ $0 == 0 }) else { throw FileProtectionError.invalidFormat }
                break
            }
            result.append(try read(bytes, &position, end: bytes.count, depth: 0, budget: &budget, storage: &storage))
            guard result.count <= 128 else { throw FileProtectionError.invalidFormat }
        }
        return result
    }
    func positiveInteger() throws -> Int {
        guard !content.isEmpty, content.count <= 4, content[0] & 0x80 == 0 else { throw FileProtectionError.invalidFormat }
        return content.reduce(0) { $0 * 256 + Int($1) }
    }
    private static func read(_ b: [UInt8], _ p: inout Int, end: Int, depth: Int, budget: inout Int, storage: inout Int) throws -> ProtectionASN1 {
        guard depth < 24, budget > 0, p + 2 <= end else { throw FileProtectionError.invalidFormat }
        budget -= 1
        let start = p, tag = b[p]; p += 1
        guard tag != 0, tag & 0x1f != 0x1f else { throw FileProtectionError.invalidFormat }
        let first = b[p]; p += 1
        let indefinite = first == 0x80
        var length = Int(first)
        if first > 0x80 {
            let count = Int(first & 0x7f)
            guard count <= 4, p + count <= end else { throw FileProtectionError.invalidFormat }
            length = 0
            for _ in 0..<count { length = length * 256 + Int(b[p]); p += 1 }
        }
        guard (!indefinite || tag & 0x20 != 0), indefinite || length <= end - p else { throw FileProtectionError.invalidFormat }
        let body = p, boundary = indefinite ? end : p + length
        var children: [ProtectionASN1] = []
        if tag & 0x20 != 0 {
            while p < boundary {
                if indefinite, p + 2 <= end, b[p] == 0, b[p+1] == 0 { break }
                children.append(try read(b, &p, end: boundary, depth: depth+1, budget: &budget, storage: &storage))
            }
        } else { p = boundary }
        let contentEnd = p
        if indefinite {
            guard p + 2 <= end, b[p] == 0, b[p+1] == 0 else { throw FileProtectionError.invalidFormat }
            p += 2
        }
        let retain = tag != 4 && p-start <= 65536
        if retain { storage -= p-start; guard storage >= 0 else { throw FileProtectionError.invalidFormat } }
        // CMS ciphertext can be large. Constructed nodes need only children; retain
        // full TLVs only for bounded certificate/recipient metadata, avoiding one
        // full ciphertext copy per ASN.1 nesting level.
        return .init(tag: tag,
                     content: tag & 0x20 == 0 ? Data(b[body..<contentEnd]) : Data(),
                     encoded: retain ? Data(b[start..<p]) : Data(), children: children)
    }
    static func wrap(_ tag: UInt8, _ content: Data) -> Data {
        var length = content.count
        var encodedLength = Data()
        if length < 128 { encodedLength.append(UInt8(length)) }
        else {
            var bytes: [UInt8] = []
            while length > 0 { bytes.insert(UInt8(length & 255), at: 0); length >>= 8 }
            encodedLength = Data([0x80 | UInt8(bytes.count)] + bytes)
        }
        return Data([tag]) + encodedLength + content
    }
    func require(_ expected: UInt8, count: Int? = nil) throws -> [ProtectionASN1] {
        guard tag == expected, count == nil || children.count == count else { throw FileProtectionError.invalidFormat }
        return children
    }
    func octets(context: Bool = false) throws -> Data {
        if tag == 0x04 || (context && tag == 0x80) { return content }
        guard tag == 0x24 || (context && tag == 0xa0) else { throw FileProtectionError.invalidFormat }
        return try children.reduce(into: Data()) { $0.append(try $1.octets()) }
    }
}
