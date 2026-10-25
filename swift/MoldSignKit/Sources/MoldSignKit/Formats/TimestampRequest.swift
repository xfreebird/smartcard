import Foundation

/// Minimal RFC3161 TimeStampReq builder.
enum TimestampRequest {
    static func build(messageBytes sha256: Data) -> Data {
        func der(_ t: UInt8, _ c: Data) -> Data {
            var o = Data([t]); let n = c.count
            if n < 0x80 { o.append(UInt8(n)) } else if n < 0x100 { o.append(0x81); o.append(UInt8(n)) }
            else { o.append(0x82); o.append(UInt8(n >> 8)); o.append(UInt8(n & 0xFF)) }
            return o + c
        }
        let oidSha256 = Data([0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01])
        let imprint = der(0x30, der(0x30, der(0x06, oidSha256) + Data([0x05, 0x00])) + der(0x04, sha256))
        return der(0x30, der(0x02, Data([0x01])) + imprint + Data([0x01, 0x01, 0xFF]))
    }
}
