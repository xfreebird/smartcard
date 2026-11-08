import Foundation
import MoldSignKit
import MoldSignMCP
#if os(macOS)
import Security
import LocalAuthentication
#endif
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

/// The operator, never an MCP request, chooses the credential provider and identity.
func configuredUnattended(arguments: inout [String], roots: inout [String: TrustedRoot]) throws -> MCPUnattendedTransport? {
    let flags = ["--signing-certificate-sha256", "--signing-output-directory", "--pin-source", "--onepassword-executable", "--secret-tool-executable"]
    let enabled = arguments.contains("--allow-unattended-signing")
    guard enabled else {
        guard !arguments.contains(where: { flags.contains($0) }) else { throw MCPFailure.invalidArgument }
        return nil
    }
    guard arguments.filter({ $0 == "--allow-unattended-signing" }).count == 1 else { throw MCPFailure.invalidArgument }
    arguments.removeAll { $0 == "--allow-unattended-signing" }
    func take(_ key: String) throws -> String? {
        guard let index = arguments.firstIndex(of: key) else { return nil }
        guard arguments.filter({ $0 == key }).count == 1, index + 1 < arguments.count else { throw MCPFailure.invalidArgument }
        let value = arguments[index + 1]
        arguments.removeSubrange(index...index + 1)
        return value
    }
    guard let certificate = try take("--signing-certificate-sha256"),
          certificate.count == 64, certificate.allSatisfy({ $0.isASCII && $0.isHexDigit }),
          let outputPath = try take("--signing-output-directory"),
          let source = try take("--pin-source") else { throw MCPFailure.invalidArgument }
    #if os(Linux)
    let defaultOnePassword = "/usr/bin/op"
    #else
    let defaultOnePassword = "/opt/homebrew/bin/op"
    #endif
    let executable = try take("--onepassword-executable") ?? defaultOnePassword
    let secretToolOption = try take("--secret-tool-executable")
    let secretTool = secretToolOption ?? "/usr/bin/secret-tool"
    guard source.hasPrefix("secret-service:") || secretToolOption == nil else { throw MCPFailure.invalidArgument }
    let output = try TrustedRoot(path: outputPath, privateDirectory: true)
    guard roots["unattended-output"] == nil else { throw MCPFailure.invalidArgument }
    let credentials = try AutomationCredentialSource(source, executable: executable, secretTool: secretTool)
    roots["unattended-output"] = output
    return UnattendedSigningTransport(certificate: certificate.lowercased(), output: output, credentials: credentials)
}

private enum AutomationCredentialSource {
    case environment(String)
    case keychain(service: String, account: String)
    case secretService(service: String, account: String, executable: String)
    case onePassword(reference: String, executable: String)

    init(_ configuration: String, executable: String, secretTool: String) throws {
        if configuration.hasPrefix("env:") {
            let name = String(configuration.dropFirst(4))
            guard !name.isEmpty, name.count <= 128,
                  name.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }) else { throw MCPFailure.invalidArgument }
            self = .environment(name)
        } else if configuration.hasPrefix("keychain:") {
            let pieces = configuration.dropFirst(9).split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard pieces.count == 2, pieces.allSatisfy({ !$0.isEmpty && $0.count <= 255 }) else { throw MCPFailure.invalidArgument }
            #if os(macOS)
            self = .keychain(service: String(pieces[0]), account: String(pieces[1]))
            #else
            throw MCPFailure.unsupported
            #endif
        } else if configuration.hasPrefix("secret-service:") {
            #if os(Linux)
            let pieces = configuration.dropFirst(15).split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard pieces.count == 2, pieces.allSatisfy({ !$0.isEmpty && $0.utf8.count <= 255 && !$0.contains("\0") && !$0.contains("\n") }),
                  secretTool.hasPrefix("/"), !secretTool.contains("\0") else { throw MCPFailure.invalidArgument }
            self = .secretService(service: String(pieces[0]), account: String(pieces[1]), executable: secretTool)
            #else
            throw MCPFailure.unsupported
            #endif
        } else if configuration.hasPrefix("onepassword:") {
            let reference = String(configuration.dropFirst(12))
            guard reference.hasPrefix("op://"), reference.count <= 2048,
                  !reference.contains("\n"), !reference.contains("\0"), executable.hasPrefix("/") else { throw MCPFailure.invalidArgument }
            self = .onePassword(reference: reference, executable: executable)
        } else { throw MCPFailure.invalidArgument }
    }

    func pin() throws -> String {
        let secret: String
        switch self {
        case .environment(let name):
            guard let value = ProcessInfo.processInfo.environment[name] else { throw MCPFailure.credentialUnavailable }
            secret = value
        case .keychain(let service, let account):
            #if os(macOS)
            // Do not weaken or migrate the app's biometric vault. Operators provision a
            // separate item whose ACL permits this executable; UI-protected items fail.
            let context = LAContext(); context.interactionNotAllowed = true
            let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service, kSecAttrAccount as String: account,
                kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne,
                kSecUseAuthenticationContext as String: context]
            var result: CFTypeRef?
            guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
                  let data = result as? Data, data.count <= 32, let value = String(data: data, encoding: .utf8) else {
                throw MCPFailure.credentialUnavailable
            }
            secret = value
            #else
            throw MCPFailure.unsupported
            #endif
        case .secretService(let service, let account, let executable):
            // A separate operator-provisioned item, never the app's stored-PIN record.
            let data = try MCPBoundedCredentialCommand.read(executable: executable,
                arguments: ["lookup", "service", service, "account", account])
            guard var value = String(data: data, encoding: .utf8) else { throw MCPFailure.credentialUnavailable }
            if value.hasSuffix("\n") { value.removeLast() }
            secret = value
        case .onePassword(let reference, let executable):
            let data = try MCPBoundedCredentialCommand.read(executable: executable,
                arguments: ["read", "--no-newline", reference])
            guard let value = String(data: data, encoding: .utf8) else { throw MCPFailure.credentialUnavailable }
            secret = value
        }
        // Refuse malformed credentials before sending anything to a retry-limited card.
        guard (4...8).contains(secret.utf8.count), secret.utf8.allSatisfy({ (48...57).contains($0) }) else {
            throw MCPFailure.credentialUnavailable
        }
        return secret
    }
}

private final class UnattendedSigningTransport: MCPUnattendedTransport {
    private let certificate: String
    private let output: TrustedRoot
    private let credentials: AutomationCredentialSource
    private let service = SigningService()
    private let gate: UnattendedSigningGate
    private var disabled = false
    var available: Bool { !disabled }
    init(certificate: String, output: TrustedRoot, credentials: AutomationCredentialSource) {
        self.certificate = certificate; self.output = output; self.credentials = credentials
        self.gate = UnattendedSigningGate(root: output)
        service.transportFactory = { try PCSCTransport(readerName: $0, exclusive: true) }
    }
    func sign(pdf: Data, name: String) throws -> [String: Any] {
        guard !disabled else { throw MCPFailure.signingDisabled }
        guard pdf.count <= 8 * 1024 * 1024, pdf.starts(with: Data("%PDF-".utf8)) else { throw MCPFailure.invalidArgument }
        let matching = service.listCards().filter { $0.certificate.der.sha256().hexString.lowercased() == certificate }
        guard matching.count == 1, let card = matching.first else { throw MCPFailure.noCard }
        let pin = try credentials.pin()
        do {
            try gate.begin()
            let signed = try service.signPDF(pdf, pin: pin, reader: card.reader,
                                            expectedCertificateSHA1: card.certificate.sha1Hex,
                                            expectedCertificateSHA256: certificate)
            let path = UUID().uuidString + ".pdf"
            try output.writeExclusive(path, data: signed)
            try gate.complete()
            return ["state": "completed", "inputSHA256": pdf.sha256().hexString,
                    "outputSHA256": signed.sha256().hexString,
                    "output": ["rootId": "unattended-output", "relativePath": path]]
        } catch {
            // No retry, including after a response/write/timestamp failure with uncertain
            // card outcome. An operator must inspect and explicitly restart the service.
            disabled = true
            switch error {
            case MCPFailure.signingDisabled: throw MCPFailure.signingDisabled
            case CardError.wrongPIN: throw MCPFailure.pinIncorrect
            case CardError.pinBlocked: throw MCPFailure.pinBlocked
            case CardError.cardChanged: throw MCPFailure.cardChanged
            default: throw MCPFailure.outcomeUnknown
            }
        }
    }
}
