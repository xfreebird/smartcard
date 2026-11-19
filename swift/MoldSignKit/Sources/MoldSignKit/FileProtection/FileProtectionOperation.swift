import Foundation

public enum PasswordEncryptionAlgorithm: Int, CaseIterable, Sendable {
    case aes128 = 128
    case aes192 = 192
    case aes256 = 256
}

public enum FileProtectionOperation: Equatable, Sendable {
    case encryptPassword(PasswordEncryptionAlgorithm)
    case decrypt
    case encryptCertificate(Data)
    case encryptCardPublicKey(Data)
    case decryptCertificate(reader: String, identity: CardEncryptionIdentity)
    case remove

    public static let encrypt = Self.encryptPassword(.aes256)

    func outputName(for name: String) -> String? {
        switch self {
        case .encryptPassword: return name + PasswordFileProtection.suffix
        case .encryptCertificate, .encryptCardPublicKey: return name + CertificateFileProtection.suffix
        case .decrypt: return decryptedName(name, suffix: PasswordFileProtection.suffix)
        case .decryptCertificate: return decryptedName(name, suffix: CertificateFileProtection.suffix)
        case .remove: return nil
        }
    }

    private func decryptedName(_ name: String, suffix: String) -> String {
        "decrypted-" + (name.hasSuffix(suffix) ? String(name.dropLast(suffix.count)) : name)
    }
}
