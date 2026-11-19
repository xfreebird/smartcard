#if DEBUG && canImport(Security) && !MOLDSIGN_PORTABLE
import Foundation
import Security

/// Diagnostic only: does not reinterpret the signing certificate as an approved
/// encryption certificate or change the production CMS certificate policy.
extension CosmoXCard {
    public func probeDecipherCapability(pin: String, beforeVerify: () throws -> Void) throws -> Bool {
        let auth = try inspectPublicEncryptionFile(0x7001)
        let privateKeys = try inspectPublicEncryptionFile(0x7002)
        let certificates = try inspectPublicEncryptionFile(0x7005)
        let keys = try CardEncryptionDirectory.keys(privateKeys: privateKeys, certificates: certificates, authentication: auth)
        guard keys.count == 1, let key = keys.first, key.reference == 1, key.pinReference == 3,
              key.modulusBytes == 512, key.certificatePath == Data([0,1]),
              (key.minimumPINLength...key.maximumPINLength).contains(pin.utf8.count),
              pin.utf8.allSatisfy({ (48...57).contains($0) }) else { throw FileProtectionError.cannotDecrypt }

        // Check actual on-card control parameters before any PIN attempt.
        var controls: [String:Data] = [:]
        try inspectDecipherControlParameters { controls[$0] = $1 }
        guard let rsa = controls["RSA-key-1-control"], let pinControl = controls["PIN-3-control"] else {
            throw FileProtectionError.cannotDecrypt
        }
        let rsaFields = try ProbeControlParameters.fields(rsa, objectClass: 0x90, reference: 1)
        let pinFields = try ProbeControlParameters.fields(pinControl, objectClass: 0x81, reference: 3)
        guard rsaFields[0x80] == Data([2,0]), rsaFields[0x9e] == Data([0]),
              let access = rsaFields[0xa1],
              try ProbeControlParameters.contactCondition(access, operationBit: 4) == [0x13],
              let remaining = pinFields[0x9b], remaining.count == 1, remaining[0] >= 3 else {
            throw FileProtectionError.cannotDecrypt
        }

        let certificate = try readCertificate()
        guard try CertificateFileProtection.modulusBytes(certificate) == key.modulusBytes,
              let parsed = SecCertificateCreateWithData(nil, certificate as CFData),
              let publicKey = SecCertificateCopyKey(parsed),
              SecKeyIsAlgorithmSupported(publicKey, .encrypt, .rsaEncryptionPKCS1) else {
            throw FileProtectionError.cannotDecrypt
        }
        var challenge = PasswordFileProtection.random(16)
        defer { challenge.resetBytes(in: 0..<challenge.count) }
        var error: Unmanaged<CFError>?
        guard let encrypted = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionPKCS1, challenge as CFData, &error) as Data?,
              encrypted.count == key.modulusBytes else { throw FileProtectionError.cannotDecrypt }

        // Bind the actual card again immediately before the only VERIFY.
        guard try readCertificate() == certificate else { throw CardError.cardChanged }
        try selectMF(); try selectGenericADF()
        try beforeVerify() // The caller exclusively creates its persistent one-attempt lock.
        try verifyPIN(pin)
        // Exact vendor CosmoXIASSmartCard.pso_dec PKCS#1 v1.5 sequence.
        let (_, selected) = try smTransmit(Data([0,0x22,0x41,0xb8,6,0x80,1,0x1a,0x84,1,0x81]))
        try checkSW(selected)
        let payload = Data([0x81]) + encrypted
        let command = Data([0,0x2a,0x80,0x86,0,UInt8(payload.count >> 8),UInt8(payload.count & 255)]) + payload + Data([0,0])
        var (plain, status) = try smTransmit(command)
        defer { plain.resetBytes(in: 0..<plain.count) }
        try checkSW(status)
        guard plain.count == challenge.count else { throw FileProtectionError.cannotDecrypt }
        return zip(plain,challenge).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }
}

/// Small bounded reader for public DOCP metadata. No private key/PIN bytes are requested.
enum ProbeControlParameters {
    static func fields(_ data: Data, objectClass: UInt8, reference: UInt8) throws -> [UInt8:Data] {
        func strip(_ data: Data, tag: [UInt8]) throws -> Data {
            let bytes = [UInt8](data)
            guard bytes.count > tag.count, Array(bytes.prefix(tag.count)) == tag else { throw FileProtectionError.invalidFormat }
            var offset = tag.count, length = Int(bytes[offset]); offset += 1
            if length & 0x80 != 0 {
                let count = length & 0x7f
                guard (1...2).contains(count), offset + count <= bytes.count else { throw FileProtectionError.invalidFormat }
                length = bytes[offset..<offset+count].reduce(0) { $0 * 256 + Int($1) }; offset += count
            }
            guard length <= 4096, offset + length == bytes.count else { throw FileProtectionError.invalidFormat }
            return Data(bytes[offset...])
        }
        let wrapper = try strip(data, tag: [0x70])
        let object = try strip(wrapper, tag: [0xbf,objectClass,reference])
        let parameters = try strip(object, tag: [0xa0])
        return try flatFields(parameters)
    }
    private static func flatFields(_ data: Data) throws -> [UInt8:Data] {
        guard data.count <= 4096 else { throw FileProtectionError.invalidFormat }
        var offset = 0, fields: [UInt8:Data] = [:]
        while offset < data.count {
            let item = try DER.element(data, at: offset)
            guard fields[item.tag] == nil, item.range.upperBound > offset else { throw FileProtectionError.invalidFormat }
            fields[item.tag] = data.subdata(in: item.content)
            offset = item.range.upperBound
        }
        return fields
    }
    static func contactCondition(_ access: Data, operationBit: Int) throws -> [UInt8] {
        guard (0...6).contains(operationBit), let contact = try flatFields(access)[0x8c] else { throw FileProtectionError.invalidFormat }
        let bytes = [UInt8](contact)
        var offset = 0, result: [UInt8] = []
        while offset < bytes.count {
            let mask = bytes[offset]; offset += 1
            for bit in stride(from: 6, through: 0, by: -1) where mask & (1 << bit) != 0 {
                guard offset < bytes.count else { throw FileProtectionError.invalidFormat }
                if bit == operationBit { result.append(bytes[offset]) }
                offset += 1
            }
        }
        return result
    }
}
#endif
