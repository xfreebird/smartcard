import Foundation

public struct PasswordFileProcessor: PasswordFileProcessing, Sendable {
    private let signingService: SigningService

    public init(signingService: SigningService = .shared) {
        self.signingService = signingService
    }

    public func process(_ input: URL, operation: FileProtectionOperation, password: String) throws -> Data? {
        try Task.checkCancellation()
        #if !os(Linux)
        let access = input.startAccessingSecurityScopedResource()
        defer { if access { input.stopAccessingSecurityScopedResource() } }
        #endif
        switch operation {
        case .remove:
            try ProtectedFileIO.overwriteAndRemove(input)
            return nil
        case .encryptPassword(let algorithm):
            return try PasswordFileProtection.encrypt(ProtectedFileIO.read(input), password: password, algorithm: algorithm)
        case .decrypt:
            return try PasswordFileProtection.decrypt(ProtectedFileIO.read(input), password: password)
        case .encryptCertificate(let certificate):
            return try CertificateFileProtection.encrypt(ProtectedFileIO.read(input), certificate: certificate)
        case .encryptCardPublicKey(let certificate):
            return try CertificateFileProtection.encrypt(ProtectedFileIO.read(input), certificate: certificate, policy: .cardPublicKey)
        case .decryptCertificate(let reader, let identity):
            let envelope = try ProtectedFileIO.read(input)
            return try signingService.withCard(reader: reader) { card in
                try card.decryptFile(envelope, identity: identity, pin: password)
            }
        }
    }
}
