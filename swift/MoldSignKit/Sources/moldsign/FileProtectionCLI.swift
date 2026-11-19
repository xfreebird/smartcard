import Foundation
import MoldSignKit
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

/// Returns false for commands owned by the existing CLI dispatcher.
func runFileProtectionCLI(_ arguments: [String], reader: String?, pin: () -> String) throws -> Bool {
    guard let command = arguments.dropFirst().first,
          ["encrypt", "decrypt", "encryption-certs", "remove-file"].contains(command) else { return false }
    var args = Array(arguments.dropFirst(2))
    func take(_ option: String) throws -> String? {
        guard let index = args.firstIndex(of: option) else { return nil }
        guard index + 1 < args.count else { throw FileProtectionError.invalidFormat }
        let value = args[index+1]; args.removeSubrange(index...index+1); return value
    }
    let exportPath = try take("--out")
    guard exportPath == nil || command == "encryption-certs" else { throw FileProtectionError.invalidFormat }
    let certificatePath = try take("--certificate")
    let fingerprint = try take("--card")
    if let fingerprint {
        guard fingerprint.count == 64, fingerprint.utf8.allSatisfy({ (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0) }) else {
            throw CLIProtectionError.message("Expected a full certificate SHA-256 fingerprint.")
        }
    }
    let publicKeyFlag = "--card-public-key"
    guard args.filter({ $0 == publicKeyFlag }).count <= 1 else { throw FileProtectionError.invalidFormat }
    let cardPublicKey = args.contains(publicKeyFlag)
    args.removeAll { $0 == publicKeyFlag }
    let policy: CertificateRecipientPolicy = cardPublicKey ? .cardPublicKey : .encryptionCertificate
    let stdin = args.contains("--password-stdin")
    args.removeAll { $0 == "--password-stdin" }
    let confirmedRemoval = args.contains("--confirm-removal")
    args.removeAll { $0 == "--confirm-removal" }
    guard !args.contains(where: { $0.hasPrefix("--") }),
          !cardPublicKey || command == "encryption-certs" || certificatePath != nil || fingerprint != nil else {
        throw CLIProtectionError.message("--card-public-key requires --certificate or --card, or encryption-certs.")
    }
    let service = SigningService.shared
    if command == "encryption-certs" {
        guard args.isEmpty, certificatePath == nil, (fingerprint == nil) == (exportPath == nil), !stdin, !confirmedRemoval else { throw FileProtectionError.invalidFormat }
        let identities = try service.withCard(reader: reader) { try $0.encryptionIdentities(policy: policy) }
        if let exportPath, let fingerprint {
            guard fingerprint.count == 64, fingerprint.allSatisfy({ $0.isHexDigit }),
                  let identity = identities.first(where: { $0.fingerprint.caseInsensitiveCompare(fingerprint) == .orderedSame }) else {
                throw CLIProtectionError.message("Selected public certificate not found. List encryption-certs with the same compatibility option.")
            }
            try ProtectedFileIO.saveNew(identity.certificate, to: URL(fileURLWithPath: exportPath))
            print(cardPublicKey ? "Exported public certificate for card public-key compatibility." : "Exported public encryption certificate.")
            return true
        }
        for identity in identities { print("\(identity.fingerprint)  \(identity.label)") }
        if identities.isEmpty { FileHandle.standardError.write(Data("No supported card encryption keys found.\n".utf8)) }
        return true
    }
    if command == "remove-file" {
        guard args.count == 1, confirmedRemoval, certificatePath == nil, fingerprint == nil, !stdin, !cardPublicKey else {
            throw CLIProtectionError.message("Use remove-file <path> --confirm-removal. Overwrite/removal cannot erase snapshots, SSD remnants, backups or other copies.")
        }
        try ProtectedFileIO.overwriteAndRemove(URL(fileURLWithPath: args[0]))
        print("Removed. Other copies and physical remnants may remain.")
        return true
    }
    guard args.count == 2, !confirmedRemoval, !(certificatePath != nil && fingerprint != nil),
          !(stdin && (certificatePath != nil || fingerprint != nil)), !(command == "decrypt" && certificatePath != nil) else {
        throw CLIProtectionError.message("Use encrypt|decrypt <input> <new-output> [--password-stdin | --card <SHA256>]; encryption also accepts --certificate <DER>.")
    }
    let source = URL(fileURLWithPath: args[0]), destination = URL(fileURLWithPath: args[1])
    guard !FileManager.default.fileExists(atPath: destination.path) else { throw FileProtectionError.outputExists }
    let input = try ProtectedFileIO.read(source)
    let result: Data
    if let certificatePath {
        let certificate = try ProtectedFileIO.read(URL(fileURLWithPath: certificatePath))
        result = try CertificateFileProtection.encrypt(input, certificate: certificate, policy: policy)
    } else if let fingerprint {
        guard fingerprint.count == 64, fingerprint.utf8.allSatisfy({ (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0) }) else { throw FileProtectionError.invalidFormat }
        let identity = try service.withCard(reader: reader) { card in
            guard let identity = try card.encryptionIdentities(policy: policy).first(where: { $0.fingerprint.lowercased() == fingerprint.lowercased() }) else { throw CardError.cardChanged }
            return identity
        }
        if command == "encrypt" { result = try CertificateFileProtection.encrypt(input,certificate: identity.certificate,policy: identity.recipientPolicy) }
        else {
            var secret = pin()
            defer { secret = "" }
            result = try service.withCard(reader: reader) { try $0.decryptFile(input,identity: identity,pin: secret) }
        }
    } else {
        func secret(_ prompt: String) throws -> String {
            if stdin { return readLine(strippingNewline: true) ?? "" }
            guard isatty(STDIN_FILENO) == 1, let bytes = getpass(prompt) else {
                throw CLIProtectionError.message("Use --password-stdin for non-interactive input. Passwords are never accepted as arguments.")
            }
            let value = String(cString: bytes)
            memset(bytes,0,strlen(bytes))
            return value
        }
        var password = try secret("File password: ")
        defer { password = "" }
        if command == "encrypt" {
            if !stdin, try secret("Confirm file password: ") != password { throw CLIProtectionError.message("Passwords do not match.") }
            result = try PasswordFileProtection.encrypt(input,password:password)
        } else { result = try PasswordFileProtection.decrypt(input,password:password) }
    }
    try ProtectedFileIO.saveNew(result,to:destination)
    print("Saved: \(destination.path)")
    if command == "decrypt" {
        FileHandle.standardError.write(Data("Check the decrypted content before using it. The MoldSign-compatible format does not authenticate content or reliably detect a wrong password.\n".utf8))
    }
    return true
}
private enum CLIProtectionError: LocalizedError {
    case message(String)
    var errorDescription: String? { if case let .message(message) = self { return message }; return nil }
}
