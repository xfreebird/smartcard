import Foundation
import CPCSC

public enum FileProtectionError: Error, LocalizedError {
    case invalidFormat, cannotDecrypt, passwordRequired, tooLarge, outputExists
    public var errorDescription: String? {
        switch self {
        case .invalidFormat: return "Unsupported or damaged encrypted file."
        case .cannotDecrypt: return "Unable to decrypt. Check the password and the file."
        case .passwordRequired: return "Enter a password of 1–2,047 UTF-16 characters."
        case .tooLarge: return "Choose a file smaller than 64 MB."
        case .outputExists: return "The destination already exists. Choose another name."
        }
    }
}

/// MoldSign Desktop's custom AES password envelope. This legacy format is NOT
/// authenticated: valid padding cannot establish password correctness or integrity.
public enum PasswordFileProtection {
    public static let maximumSize = 64 * 1024 * 1024 - 128
    public static let suffix = ".symmetric.p7m"
    private static let markers: [Int: Data] = [
        128: Data(hex: "e2bc8ca53e630757ef4a3e8f3d0fc48aac10a66dbe6d14d759d00c21263f4c0623f6841dc3995081f97eff9641ea9be42c9219f66e6c5b9ea9effa1c8450c3fb"),
        192: Data(hex: "cf1b881c8ec7355167290b18c4a4f8b39cab1875514e649ea0f313f210e227ef8330c0fd4ead855f80f02dd158f2e9195c948c5b8edc804b51cf3e36735965cf"),
        256: Data(hex: "3c31b9cf56c4c47f7c95c6ca9d1669c2cbb127220dcd804c42fcf68714a8c38806267e72542d47532598e52090219677cf38bb5d906da1e7a2a2b351b871a82f")
    ]
    public static func encrypt(_ plaintext: Data, password: String, algorithm: PasswordEncryptionAlgorithm = .aes256) throws -> Data {
        // MoldSign first attempts ASN.1 parsing. An impossible length octet forces its
        // AES fallback rather than misclassifying a random salt as CMS (120 random salt bits).
        var salt = random(16); salt[1] = 0xff
        return try encrypt(plaintext, password: password, bits: algorithm.rawValue, salt: salt, iv: random(16))
    }
    // Internal deterministic seam for vendor interoperability fixtures only.
    static func encrypt(_ plaintext: Data, password: String, bits: Int, salt: Data, iv: Data) throws -> Data {
        guard !password.isEmpty else { throw FileProtectionError.passwordRequired }
        guard plaintext.count <= maximumSize else { throw FileProtectionError.tooLarge }
        guard let marker = markers[bits], salt.count == 16, iv.count == 16 else { throw FileProtectionError.invalidFormat }
        var key = try derive(password, salt: salt, bits: bits)
        defer { key.resetBytes(in: 0..<key.count) }
        return salt + iv + marker + (try crypt(plaintext, key: key, iv: iv, encrypt: true))
    }
    public static func decrypt(_ envelope: Data, password: String) throws -> Data {
        guard envelope.count <= maximumSize + 8192 else { throw FileProtectionError.tooLarge }
        let envelope = Data(envelope)
        guard let bits = algorithm(in: envelope)?.rawValue else {
            return try LegacyPasswordProtection.decrypt(envelope,password:password)
        }
        var key = try derive(password, salt: envelope.subdata(in: 0..<16), bits: bits)
        defer { key.resetBytes(in: 0..<key.count) }
        return try crypt(Data(envelope.dropFirst(96)), key: key, iv: envelope.subdata(in: 16..<32), encrypt: false)
    }
    static func algorithm(in envelope: Data) -> PasswordEncryptionAlgorithm? {
        guard envelope.count >= 112, (envelope.count - 96).isMultiple(of: 16) else { return nil }
        let marker = envelope.dropFirst(32).prefix(64)
        return PasswordEncryptionAlgorithm.allCases.first { markers[$0.rawValue] == marker }
    }

    private static func derive(_ password: String, salt: Data, bits: Int) throws -> Data {
        guard password.utf16.count < 2048 else { throw FileProtectionError.passwordRequired }
        var bytes = password.utf16.flatMap { [UInt8($0 >> 8), UInt8($0 & 255)] }
        if !bytes.isEmpty { bytes += [0, 0] }
        defer { for index in bytes.indices { bytes[index] = 0 } }
        var key = [UInt8](repeating: 0, count: bits / 8)
        guard c_file_password_key(bytes, bytes.count, [UInt8](salt), &key, key.count) == 0 else { throw FileProtectionError.cannotDecrypt }
        defer { for index in key.indices { key[index] = 0 } }
        return Data(key)
    }
    static func crypt(_ data: Data, key: Data, iv: Data, encrypt: Bool) throws -> Data {
        guard iv.count == 16, [16,24,32].contains(key.count), data.count <= maximumSize + 128 else { throw FileProtectionError.invalidFormat }
        var output = [UInt8](repeating: 0, count: data.count + 16)
        var length = output.count
        defer { for index in output.indices { output[index] = 0 } }
        let status = c_file_aes_cbc(encrypt ? 1 : 0, [UInt8](key), key.count, [UInt8](iv), [UInt8](data), data.count, &output, &length)
        guard status == 0 else { throw FileProtectionError.cannotDecrypt }
        return Data(output.prefix(length))
    }
    static func random(_ count: Int) -> Data {
        var generator = SystemRandomNumberGenerator()
        return Data((0..<count).map { _ in UInt8.random(in: 0...255, using: &generator) })
    }
}
