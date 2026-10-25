import Foundation
#if canImport(CryptoKit) && !MOLDSIGN_PORTABLE
import CryptoKit
#endif
import CPCSC

enum CryptoError: Error {
    case cbcFailed(Int32)
    case invalidLength
}

struct AES {
    let key: [UInt8]  // 32 bytes

    init(key: Data) { self.key = [UInt8](key) }

    /// Single-block ECB encrypt
    func ecbEncrypt(_ block: Data) -> Data {
        var out = [UInt8](repeating: 0, count: 16)
        let inBytes = [UInt8](block)
        _ = c_aes256_ecb_encrypt(key, UInt32(key.count), inBytes, &out)
        return Data(out)
    }

    /// CBC encrypt, no padding (input must be multiple of 16)
    func cbcEncrypt(_ data: Data, iv: Data) throws -> Data {
        guard data.count % 16 == 0, iv.count == 16 else { throw CryptoError.invalidLength }
        let inBytes = [UInt8](data)
        let ivBytes = [UInt8](iv)
        var out = [UInt8](repeating: 0, count: data.count + 32)
        var outLen = UInt32(out.count)
        let st = c_aes256_cbc_encrypt(key, UInt32(key.count), ivBytes, inBytes, UInt32(inBytes.count), &out, &outLen)
        guard st == 0 else { throw CryptoError.cbcFailed(st) }
        return Data(out.prefix(Int(outLen)))
    }

    /// CBC decrypt, no padding
    func cbcDecrypt(_ data: Data, iv: Data) throws -> Data {
        guard data.count % 16 == 0, iv.count == 16 else { throw CryptoError.invalidLength }
        let inBytes = [UInt8](data)
        let ivBytes = [UInt8](iv)
        var out = [UInt8](repeating: 0, count: data.count + 32)
        var outLen = UInt32(out.count)
        let st = c_aes256_cbc_decrypt(key, UInt32(key.count), ivBytes, inBytes, UInt32(inBytes.count), &out, &outLen)
        guard st == 0 else { throw CryptoError.cbcFailed(st) }
        return Data(out.prefix(Int(outLen)))
    }

    /// AES-CMAC (RFC 4493) — full 16-byte tag (via C wrapper)
    static func cmac(key: Data, message: Data) -> Data {
        let keyBytes = [UInt8](key)
        let msgBytes = [UInt8](message)
        var out = [UInt8](repeating: 0, count: 16)
        c_aes256_cmac(keyBytes, UInt32(keyBytes.count), msgBytes, UInt32(msgBytes.count), &out)
        return Data(out)
    }

    static func xorBytes(_ a: Data, _ b: Data) -> Data {
        let n = min(a.count, b.count)
        var out = Data(repeating: 0, count: n)
        for i in 0..<n { out[i] = a[a.startIndex + i] ^ b[b.startIndex + i] }
        return out
    }

    static func iso9797Pad(_ data: Data, blockSize: Int = 16) -> Data {
        var out = data; out.append(0x80)
        while out.count % blockSize != 0 { out.append(0) }
        return out
    }

    static func iso9797Unpad(_ data: Data) -> Data {
        var out = data
        while out.last == 0 && !out.isEmpty { out = out.dropLast() }
        if out.last == 0x80 { out = out.dropLast() }
        return out
    }
}

extension Data {
    public var hexString: String { map { String(format: "%02X", $0) }.joined() }
    public init(hex: String) {
        var data = Data()
        var i = hex.startIndex
        while i < hex.endIndex {
            let j = hex.index(i, offsetBy: 2, limitedBy: hex.endIndex) ?? hex.endIndex
            if let b = UInt8(hex[i..<j], radix: 16) { data.append(b) }
            i = j
        }
        self = data
    }
    #if canImport(CryptoKit) && !MOLDSIGN_PORTABLE
    public func sha256() -> Data { Data(SHA256.hash(data: self)) }
    public func sha1() -> Data { Data(Insecure.SHA1.hash(data: self)) }
    #else
    // Linux (and MOLDSIGN_PORTABLE test builds): OpenSSL via the C shim
    public func sha256() -> Data {
        var out = [UInt8](repeating: 0, count: 32)
        withUnsafeBytes { c_sha256($0.bindMemory(to: UInt8.self).baseAddress, count, &out) }
        return Data(out)
    }
    public func sha1() -> Data {
        var out = [UInt8](repeating: 0, count: 20)
        withUnsafeBytes { c_sha1($0.bindMemory(to: UInt8.self).baseAddress, count, &out) }
        return Data(out)
    }
    #endif
}
