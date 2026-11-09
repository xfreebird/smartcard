import Foundation
import CPCSC

/// Read-only support for older MoldSign CMS password files. New files always use AES.
enum LegacyPasswordProtection {
    static func decrypt(_ envelope: Data, password: String) throws -> Data {
        let root = try ProtectionASN1.parse(envelope)
        let outer = try root.require(0x30)
        let body: [ProtectionASN1]
        if outer.first?.tag == 2 { body = try root.require(0x30,count:2) }
        else {
            guard outer.count == 2, outer[0].tag == 6, outer[0].content == Data(hex:"2a864886f70d010706") else { throw FileProtectionError.invalidFormat }
            body = try outer[1].require(0xa0,count:1)[0].require(0x30,count:2)
        }
        guard body[0].tag == 2, body[0].content == Data([0]) else { throw FileProtectionError.invalidFormat }
        let content = try body[1].require(0x30,count:3), algorithm = try content[1].require(0x30,count:2)
        guard content[0].tag == 6, content[0].content == Data(hex:"2a864886f70d010701"), algorithm[0].tag == 6 else { throw FileProtectionError.invalidFormat }
        let kind: Int32
        switch algorithm[0].content {
        case Data(hex:"2a864886f70d010c0103"): kind=1
        case Data(hex:"2a864886f70d010503"): kind=2
        case Data(hex:"2a864886f70d010c0106"): kind=3
        default: throw FileProtectionError.invalidFormat
        }
        let parameters = try algorithm[1].require(0x30,count:2)
        guard parameters[0].tag == 4, (1...64).contains(parameters[0].content.count), parameters[1].tag == 2 else { throw FileProtectionError.invalidFormat }
        let iterations = try parameters[1].positiveInteger()
        guard (1...1_000_000).contains(iterations), password.utf16.count < 2048 else { throw FileProtectionError.invalidFormat }
        let ciphertext = try content[2].octets(context:true)
        guard !ciphertext.isEmpty, ciphertext.count % 8 == 0 else { throw FileProtectionError.invalidFormat }
        var passwordBytes = password.utf16.flatMap { [UInt8($0 >> 8),UInt8($0 & 255)] }
        if !passwordBytes.isEmpty {passwordBytes += [0,0]}
        var result = [UInt8](repeating:0,count:ciphertext.count), count = ciphertext.count
        defer {for i in passwordBytes.indices {passwordBytes[i]=0};for i in result.indices {result[i]=0}}
        let salt = [UInt8](parameters[0].content)
        guard c_file_legacy_decrypt(kind,passwordBytes,passwordBytes.count,salt,salt.count,UInt32(iterations),[UInt8](ciphertext),ciphertext.count,&result,&count) == 0 else { throw FileProtectionError.cannotDecrypt }
        return Data(result.prefix(count))
    }
}
