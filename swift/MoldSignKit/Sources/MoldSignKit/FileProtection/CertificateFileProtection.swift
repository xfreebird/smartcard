import Foundation
#if canImport(Security) && !MOLDSIGN_PORTABLE
import Security
#endif
import CPCSC

/// CMS EnvelopedData interoperability with MoldSign Desktop.
public enum CertificateFileProtection {
    public static let suffix = ".asymmetric.p7m"
    private static let enveloped = Data(hex: "2a864886f70d010703")
    private static let dataOID = Data(hex: "2a864886f70d010701")
    private static let rsa = Data(hex: "2a864886f70d010101")
    private static let aes128 = Data(hex: "608648016503040102")
    private static func w(_ tag: UInt8, _ content: Data) -> Data { ProtectionASN1.wrap(tag, content) }

    public static func encrypt(_ plaintext: Data, certificate: Data) throws -> Data {
        guard plaintext.count <= PasswordFileProtection.maximumSize else { throw FileProtectionError.tooLarge }
        let identity = try recipientIdentity(certificate)
        var key = PasswordFileProtection.random(16)
        defer { key.resetBytes(in: 0..<key.count) }
        let iv = PasswordFileProtection.random(16)
        let wrapped = try wrapKey(key, certificate: certificate)
        let recipient = w(0x30, w(2, Data([0])) + identity + w(0x30, w(6, rsa) + Data([5,0])) + w(4, wrapped))
        let content = w(0x30, w(6, dataOID) + w(0x30, w(6, aes128) + w(4, iv)) + w(0x80, try PasswordFileProtection.crypt(plaintext, key: key, iv: iv, encrypt: true)))
        return w(0x30, w(6, enveloped) + w(0xa0, w(0x30, w(2, Data([0])) + w(0x31, recipient) + content)))
    }
    /// The callback must require consent and unwrap with the matching encryption key.
    /// It is called only after envelope structure, algorithm and recipient checks.
    public static func decrypt(_ envelope: Data, certificate: Data, unwrap: (Data) throws -> Data) throws -> Data {
        let identity = try recipientIdentity(certificate)
        let root = try ProtectionASN1.parse(envelope)
        let outer = try root.require(0x30)
        let body: [ProtectionASN1]
        if outer.first?.tag == 2 { body = try root.require(0x30, count: 3) }
        else {
            guard outer.count == 2, outer[0].tag == 6, outer[0].content == enveloped else { throw FileProtectionError.invalidFormat }
            let explicit = try outer[1].require(0xa0, count: 1)
            body = try explicit[0].require(0x30, count: 3)
        }
        guard body[0].tag == 2, body[0].content == Data([0]) else { throw FileProtectionError.invalidFormat }
        let recipients = try body[1].require(0x31)
        guard !recipients.isEmpty, recipients.count <= 32 else { throw FileProtectionError.invalidFormat }
        var encryptedKey: Data?
        for recipient in recipients {
            let r = try recipient.require(0x30, count: 4)
            let algorithm = try r[2].require(0x30)
            guard r[0].tag == 2, r[0].content == Data([0]), r[3].tag == 4,
                  (1...2).contains(algorithm.count), algorithm[0].tag == 6,
                  algorithm[0].content == rsa,
                  algorithm.count == 1 || (algorithm[1].tag == 5 && algorithm[1].content.isEmpty) else { throw FileProtectionError.invalidFormat }
            if r[1].encoded == identity {
                guard encryptedKey == nil, r[3].content.count == (try modulusBytes(certificate)) else { throw FileProtectionError.invalidFormat }
                encryptedKey = r[3].content
            }
        }
        guard let encryptedKey else { throw FileProtectionError.cannotDecrypt }
        let content = try body[2].require(0x30, count: 3)
        let algorithm = try content[1].require(0x30, count: 2)
        guard content[0].tag == 6, content[0].content == dataOID,
              algorithm[0].tag == 6, algorithm[0].content == aes128,
              algorithm[1].tag == 4, algorithm[1].content.count == 16 else { throw FileProtectionError.invalidFormat }
        let encrypted = try content[2].octets(context: true)
        guard !encrypted.isEmpty, encrypted.count % 16 == 0 else { throw FileProtectionError.invalidFormat }
        var key = try unwrap(encryptedKey)
        defer { key.resetBytes(in: 0..<key.count) }
        guard key.count == 16 else { throw FileProtectionError.cannotDecrypt }
        return try PasswordFileProtection.crypt(encrypted, key: key, iv: algorithm[1].content, encrypt: false)
    }
    static func recipientIdentity(_ certificate: Data) throws -> Data {
        guard certificate.count <= 64 * 1024 else { throw FileProtectionError.invalidFormat }
        let cert = try ProtectionASN1.parse(certificate).require(0x30, count: 3)
        let tbs = try cert[0].require(0x30)
        let offset = tbs.first?.tag == 0xa0 ? 1 : 0
        guard tbs.count >= offset + 6, tbs[offset].tag == 2, tbs[offset+2].tag == 0x30 else { throw FileProtectionError.invalidFormat }
        // Reject signing-only certificates before asking for a PIN or encrypting data.
        guard let extensions = tbs.first(where: { $0.tag == 0xa3 }), extensions.children.count == 1 else { throw FileProtectionError.invalidFormat }
        var allowed = false
        for ext in try extensions.children[0].require(0x30) {
            let fields = try ext.require(0x30)
            if fields.first?.tag == 6, fields.first?.content == Data(hex: "551d0f"),
               let value = fields.last, value.tag == 4 {
                let usage = try ProtectionASN1.parse(value.content)
                allowed = usage.tag == 3 && usage.content.count >= 2 && usage.content[1] & 0x20 != 0
            }
        }
        guard allowed else { throw FileProtectionError.invalidFormat }
        return w(0x30, tbs[offset+2].encoded + tbs[offset].encoded)
    }
    static func modulusBytes(_ certificate: Data) throws -> Int {
        let cert = try ProtectionASN1.parse(certificate).require(0x30, count: 3)
        let tbs = try cert[0].require(0x30)
        let offset = tbs.first?.tag == 0xa0 ? 1 : 0
        guard tbs.count > offset + 5 else { throw FileProtectionError.invalidFormat }
        let spki = try tbs[offset+5].require(0x30, count: 2)
        let algorithm = try spki[0].require(0x30)
        guard algorithm.first?.tag == 6, algorithm.first?.content == rsa,
              spki[1].tag == 3, spki[1].content.first == 0 else { throw FileProtectionError.invalidFormat }
        let key = try ProtectionASN1.parse(Data(spki[1].content.dropFirst())).require(0x30, count: 2)
        guard key[0].tag == 2, key[1].tag == 2 else { throw FileProtectionError.invalidFormat }
        let modulus = key[0].content.drop(while: { $0 == 0 })
        guard (256...1024).contains(modulus.count) else { throw FileProtectionError.invalidFormat }
        return modulus.count
    }
    private static func wrapKey(_ key: Data, certificate: Data) throws -> Data {
        #if canImport(Security) && !MOLDSIGN_PORTABLE
        guard let cert = SecCertificateCreateWithData(nil, certificate as CFData), let publicKey = SecCertificateCopyKey(cert),
              SecKeyGetBlockSize(publicKey) >= 256, SecKeyGetBlockSize(publicKey) <= 1024,
              SecKeyIsAlgorithmSupported(publicKey, .encrypt, .rsaEncryptionPKCS1) else { throw FileProtectionError.invalidFormat }
        var error: Unmanaged<CFError>?
        guard let result = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionPKCS1, key as CFData, &error) else { throw FileProtectionError.invalidFormat }
        return result as Data
        #else
        var output = [UInt8](repeating: 0, count: 1024), length = 1024
        guard c_file_rsa_wrap([UInt8](certificate), certificate.count, [UInt8](key), key.count, &output, &length) == 1 else { throw FileProtectionError.invalidFormat }
        return Data(output.prefix(length))
        #endif
    }
}
