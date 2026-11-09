import Foundation

/// A discovered capability, not a caller-supplied key/PIN reference.
public struct CardEncryptionIdentity: Equatable, Sendable {
    public let label: String
    public let certificate: Data
    public var fingerprint: String { certificate.sha256().hexString }
    let key: CardEncryptionDirectory.Key
    init(key: CardEncryptionDirectory.Key, certificate: Data) {
        self.key = key; self.certificate = certificate; self.label = key.label
    }
}

extension CosmoXCard {
    /// Reads public metadata only. Must run under SigningService.withCard serialization.
    public func encryptionIdentities() throws -> [CardEncryptionIdentity] {
        let authentication = try protectionFile(Data([0x70,0x01]))
        let keys = try protectionFile(Data([0x70,0x02]))
        let certificates = try protectionFile(Data([0x70,0x05]))
        return try CardEncryptionDirectory.keys(privateKeys: keys, certificates: certificates, authentication: authentication).compactMap { key in
            let file = try protectionFile(key.certificatePath)
            let records = try ProtectionASN1.records(file)
            guard records.count == 1 else { return nil }
            let certificate = records[0].encoded
            guard (try? CertificateFileProtection.recipientIdentity(certificate)) != nil,
                  (try? CertificateFileProtection.modulusBytes(certificate)) == key.modulusBytes else { return nil }
            return CardEncryptionIdentity(key: key, certificate: certificate)
        }
    }

    /// Requires explicit consent for this file and identity. Never retries a PIN.
    public func decryptFile(_ envelope: Data, identity: CardEncryptionIdentity, pin: String) throws -> Data {
        // Parse/recipient checks happen before discovery, VERIFY or any private-key operation.
        try CertificateFileProtection.decrypt(envelope, certificate: identity.certificate) { wrapped in
            guard wrapped.count == identity.key.modulusBytes else { throw FileProtectionError.invalidFormat }
            guard try encryptionIdentities().contains(identity) else { throw CardError.cardChanged }
            guard (identity.key.minimumPINLength...identity.key.maximumPINLength).contains(pin.utf8.count),
                  pin.utf8.allSatisfy({ (48...57).contains($0) }), identity.key.pinReference == 3 else {
                throw FileProtectionError.cannotDecrypt
            }
            try selectMF()
            try selectGenericADF()
            try verifyPIN(pin)
            let mse = Data([0x80,0x01,0x1a,0x84,0x01,identity.key.reference | 0x80])
            let (_, mseStatus) = try smTransmit(Data([0x00,0x22,0x41,0xb8,UInt8(mse.count)]) + mse)
            try checkSW(mseStatus)
            let payload = Data([0x81]) + wrapped
            let command = Data([0x00,0x2a,0x80,0x86,0x00,UInt8(payload.count >> 8),UInt8(payload.count & 255)]) + payload + Data([0,0])
            let (key, status) = try smTransmit(command)
            try checkSW(status)
            guard key.count == 16 else { throw FileProtectionError.cannotDecrypt }
            return key
        }
    }

    private func protectionFile(_ path: Data) throws -> Data {
        guard path.count == 2 else { throw FileProtectionError.invalidFormat }
        try selectMF(); try selectGenericADF()
        let (_, selected) = try smTransmit(Data([0x00,0xa4,0x02,0x04,0x02]) + path + Data([0]))
        try checkSW(selected)
        var result = Data()
        while result.count < 32768 {
            let offset = result.count
            let (chunk, status) = try smTransmit(Data([0x00,0xb0,UInt8(offset >> 8),UInt8(offset & 255),0x80]))
            if status == Data([0x6b,0x00]), !result.isEmpty { break }
            guard status == Data([0x90,0x00]) || status == Data([0x62,0x82]), chunk.count <= 128 else {
                try checkSW(status); throw FileProtectionError.invalidFormat
            }
            result += chunk
            if chunk.count < 128 || status == Data([0x62,0x82]) { return result }
        }
        guard result.count < 32768 else { throw FileProtectionError.tooLarge }
        return result
    }
}
