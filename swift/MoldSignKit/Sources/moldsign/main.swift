import Foundation
#if canImport(Glibc)
import Glibc
#endif
import MoldSignKit

// `esemnbun` (codename moldsign) — macOS and Linux implementation of spec/cli.md (CLI-02, LNX-*).
setbuf(stdout, nil)

/// Use the validator's own reference interpretation instead of a separate filesystem parser.
/// Supported XML syntax remains defined by the existing vendor-oriented validator.
func verifyDetached(_ xml: Data, directory: URL) -> [Validator.Report] {
    let initial = Validator.validateXAdES(xml, referencedFiles: [:])
    let names = Set(initial.flatMap(\.missingDetachedReferences))
    guard !names.isEmpty else { return initial }
    var files: [String: Data] = [:]
    for name in names { files[name] = try? DetachedDocumentAccess.read(name, beneath: directory) }
    return Validator.validateXAdES(xml, referencedFiles: files)
}

// MARK: - Read-only machine-readable capability discovery

// This gate runs before option parsing, card discovery or PIN/environment access. JSON is
// available for capabilities and offline verification; no other command may use this flag.
let discoveryArguments = Array(CommandLine.arguments.dropFirst())
let discoveryCommand = discoveryArguments.first { $0 != "--quiet" && $0 != "--json" }
if discoveryCommand == "verify", discoveryArguments.contains("--json") {
    MSLog.sink = nil
    func jsonResult(_ body: [String: Any], exitCode: Int32) -> Never {
        var envelope = body
        envelope["schemaVersion"] = 1
        do {
            let encoded = try JSONSerialization.data(withJSONObject: envelope, options: [.sortedKeys])
            FileHandle.standardOutput.write(encoded)
            FileHandle.standardOutput.write(Data([10]))
        } catch {
            FileHandle.standardError.write(Data("error: verification output could not be encoded.\n".utf8))
            exit(1)
        }
        exit(exitCode)
    }
    func jsonFailure(_ code: String, _ message: String) -> Never {
        FileHandle.standardError.write(Data("error: \(message)\n".utf8))
        jsonResult(["ok": false, "error": ["code": code, "retryable": false, "message": message]], exitCode: 1)
    }
    let words = discoveryArguments.filter { $0 != "--json" && $0 != "--quiet" }
    guard (2...3).contains(words.count), words.first == "verify",
          words.dropFirst().allSatisfy({ !$0.hasPrefix("-") }),
          discoveryArguments.filter({ $0 == "--json" }).count == 1,
          discoveryArguments.filter({ $0 == "--quiet" }).count <= 1 else {
        jsonFailure("INVALID_ARGUMENT", "Use esemnbun verify --json <file.pdf|signature.xml> [documents_directory].")
    }
    let input = URL(fileURLWithPath: words[1])
    guard ["pdf", "xml"].contains(input.pathExtension.lowercased()) else {
        jsonFailure("UNSUPPORTED", "Structured verification accepts PDF and XML files.")
    }
    // The command only reads an explicit regular file; a pipe/device cannot hang automation.
    let data: Data
    do { data = try DetachedDocumentAccess.read(input.lastPathComponent, beneath: input.deletingLastPathComponent()) }
    catch { jsonFailure("INPUT_UNREADABLE", "The input document could not be read as a regular file.") }
    let reports: [Validator.Report]
    if input.pathExtension.lowercased() == "pdf" {
        guard words.count == 2 else { jsonFailure("INVALID_ARGUMENT", "A documents directory is only used with XML signatures.") }
        reports = Validator.validatePDF(data)
    } else {
        let directory = URL(fileURLWithPath: words.count == 3 ? words[2] : FileManager.default.currentDirectoryPath,
                            isDirectory: true)
        reports = verifyDetached(data, directory: directory)
    }
    let incomplete = reports.contains { !$0.missingDetachedReferences.isEmpty }
    let invalid = reports.contains { !$0.signatureValid || (!$0.contentIntact && $0.missingDetachedReferences.isEmpty) }
    let status = invalid ? "invalid" : incomplete ? "incomplete" : reports.isEmpty ? "no_recognized_signature" :
        reports.allSatisfy(\.chainTrusted) ? "valid" : "unconfirmed"
    let signatures: [[String: Any]] = reports.enumerated().map { index, report in
        ["index": index + 1, "kind": report.kind, "level": report.level,
         "contentIntact": report.contentIntact, "signatureValid": report.signatureValid,
         "chainTrusted": report.chainTrusted, "missingDocumentCount": report.missingDetachedReferences.count]
    }
    jsonResult(["ok": true, "data": ["status": status, "mode": "offline", "revocationChecked": false,
                                     "signatureCount": reports.count, "signatures": signatures]],
               exitCode: status == "valid" || status == "unconfirmed" ? 0 : 2)
}
if discoveryCommand == "capabilities" || discoveryArguments.contains("--json") {
    MSLog.sink = nil
    let json = discoveryArguments.contains("--json")
    let words = discoveryArguments.filter { $0 != "--quiet" && $0 != "--json" }
    let valid = words == ["capabilities"] &&
        discoveryArguments.filter { $0 == "--json" }.count <= 1 &&
        discoveryArguments.filter { $0 == "--quiet" }.count <= 1
    if !valid {
        let unsupported = discoveryCommand.map { $0 != "capabilities" && !$0.hasPrefix("-") } ?? false
        let code = unsupported ? "UNSUPPORTED" : "INVALID_ARGUMENT"
        let message = unsupported ? "JSON output is currently supported only for capabilities and verify." :
            "Use esemnbun capabilities [--json] [--quiet]."
        if json {
            let envelope: [String: Any] = ["schemaVersion": 1, "ok": false,
                "error": ["code": code, "retryable": false, "message": message]]
            // The envelope contains fixed metadata only, never argument values or secret errors.
            if let encoded = try? JSONSerialization.data(withJSONObject: envelope, options: [.sortedKeys]) {
                FileHandle.standardOutput.write(encoded)
                FileHandle.standardOutput.write(Data([10]))
            }
        }
        FileHandle.standardError.write(Data("error: \(message)\n".utf8))
        exit(1)
    }
    #if os(Linux)
    let platform = "linux"
    #else
    let platform = "macos"
    #endif
    let commands = ["capabilities", "help", "version", "readers", "cert", "sign", "xades", "verify", "server", "sign-hex", "cms-for-hash", "encrypt", "decrypt", "encryption-certs", "remove-file"]
    if json {
        let envelope: [String: Any] = ["schemaVersion": 1, "ok": true, "data": [
            "product": "eSemnBun", "interface": "cli", "platform": platform,
            "commands": commands, "structuredOutputCommands": ["capabilities", "verify"],
            "documentSigning": ["available": true, "formats": ["PAdES-T", "XAdES-BES", "XAdES-T", "XAdES-C"]],
            "verification": ["available": true, "formats": ["PDF", "XAdES"], "requiresCard": false, "json": true],
            "mcpServerAvailable": false, "desktopApprovalBrokerAvailable": false,
        ]]
        do {
            let encoded = try JSONSerialization.data(withJSONObject: envelope, options: [.sortedKeys])
            FileHandle.standardOutput.write(encoded)
            FileHandle.standardOutput.write(Data([10]))
        } catch {
            FileHandle.standardError.write(Data("error: capability output could not be encoded.\n".utf8))
            exit(1)
        }
    } else {
        print("eSemnBun CLI capabilities (schema 1, \(platform))")
        print("Commands: \(commands.joined(separator: ", "))")
        print("Structured output: capabilities --json, verify --json")
        print("Document signing: PAdES-T, XAdES-BES, XAdES-T, XAdES-C")
        print("Verification: PDF, XAdES; offline, no card required; text and JSON output")
        print("MCP server: unavailable; desktop approval broker: unavailable")
    }
    exit(0)
}

// MARK: - Global options

var args = CommandLine.arguments
var pinFromStdin = false
var readerName: String?

if let i = args.firstIndex(of: "--quiet") {
    args.remove(at: i)
    MSLog.sink = nil
}
if let i = args.firstIndex(of: "--pin-stdin") {
    args.remove(at: i)
    pinFromStdin = true
}
if let i = args.firstIndex(of: "--reader"), i + 1 < args.count {
    readerName = args[i + 1]
    args.removeSubrange(i...(i + 1))
}
/// Experimental USB token recognition (Phase TOK): `--experimental-tokens` or MSIGN_EXPERIMENTAL_TOKENS=1.
var experimentalTokens = ProcessInfo.processInfo.environment["MSIGN_EXPERIMENTAL_TOKENS"] == "1"
if let i = args.firstIndex(of: "--experimental-tokens") {
    args.remove(at: i)
    experimentalTokens = true
}
SigningService.shared.experimentalTokens = experimentalTokens

// MARK: - Helpers

/// PIN order (spec/cli.md): --pin-stdin → MSIGN_PIN → prompt without echo. Never hard-code it (F-03, SEC-06).
func cliPIN() -> String {
    if pinFromStdin { return readLine(strippingNewline: true) ?? "" }
    if let pin = ProcessInfo.processInfo.environment["MSIGN_PIN"], !pin.isEmpty { return pin }
    guard let raw = getpass("PIN QSCD: ") else { return "" }
    return String(cString: raw)
}

func openCard() throws -> CosmoXCard {
    let transport = try PCSCTransport(readerName: readerName)
    if experimentalTokens, let family = TokenRecognizer.family(atr: transport.atr) {
        transport.disconnect()
        throw UnsupportedTokenError(family: family)
    }
    return CosmoXCard(transport: transport)
}

/// Exit codes from spec/cli.md.
func fail(_ error: Error) -> Never {
    FileHandle.standardError.write(Data("error: \(error.localizedDescription)\n".utf8))
    switch error {
    case CardError.wrongPIN: exit(3)
    case CardError.pinBlocked: exit(4)
    case CardError.noReader, CardError.noCard: exit(5)
    case is TrustServices.NetworkError: exit(6)
    case CardError.signFailed(let message) where message.hasPrefix("TSA"): exit(6)
    default: exit(1)
    }
}

func usage() -> Never {
    print("""
    Usage: esemnbun <command> [options]
      capabilities [--json]                   supported commands and formats; no card/PIN access
      encrypt <in> <new-out> [--password-stdin | --certificate <DER> | --card <SHA256>]
      decrypt <in> <new-out> [--password-stdin | --card <SHA256>]
      encryption-certs [--card SHA256 --out NEW.cer] [--card-public-key]
      Add --card-public-key to certificate/card encrypt or decrypt for explicit compatibility.
      remove-file <path> --confirm-removal     best-effort overwrite/removal; not physical erasure
      readers                                  list readers and card presence
      cert [--out <file.der>]                  read the signing certificate (no PIN)
      sign <in.pdf> [<out.pdf>]                PAdES-T signature
      xades <XAdES-BES|XAdES-T|XAdES-C> <in> <out.xml> [--enveloping] [--digest SHA-1|SHA-256]
      verify [--json] <file.pdf|sig.xml> [<docs_dir>]   offline validation
      server [<port> [<https_port>]]           browser bridge (MoldSign Server protocol)
      sign-hex <digestinfo_hex>                raw card signature (developer)
      cms-for-hash <sha256_hex>                detached CMS for a content digest (developer)
    Options: --reader <name>  --quiet  --pin-stdin      PIN: MSIGN_PIN or prompt
             --experimental-tokens (or MSIGN_EXPERIMENTAL_TOKENS=1): recognize USB tokens (not signing yet)
    """)
    exit(1)
}

/// PAdES flow (unchanged since the portal-proven CLI): connect → authenticate → PIN → sign.
func signPDF(_ inputPath: String, _ outputPath: String) -> Never {
    guard FileManager.default.fileExists(atPath: inputPath) else {
        FileHandle.standardError.write(Data("error: input PDF not found at \(inputPath)\n".utf8))
        exit(1)
    }
    print("Input:  \(inputPath)")
    print("Output: \(outputPath)")
    let pdfData = FileManager.default.contents(atPath: inputPath)!
    print("PDF size: \(pdfData.count) bytes")
    do {
        print("\nConnecting to card reader...")
        let card = try openCard()
        defer { card.disconnect() }
        print("Authenticating...")
        try card.authenticate()
        let pin = cliPIN()
        guard !pin.isEmpty else { FileHandle.standardError.write(Data("error: no PIN provided\n".utf8)); exit(1) }
        print("Signing PDF...")
        let signedPDF = try card.signPDF(pdfData, pin: pin)
        FileManager.default.createFile(atPath: outputPath, contents: signedPDF)
        print("\n✅ Signed PDF saved to: \(outputPath)")
        print("Verify at: https://msign.gov.md/#/")
    } catch {
        fail(error)
    }
    exit(0)
}

// MARK: - Commands

guard args.count >= 2 else { usage() }

do { if try runFileProtectionCLI(args, reader: readerName, pin: cliPIN) { exit(0) } } catch { fail(error) }

switch args[1] {
case "readers":
    let names = PCSCTransport.readerNames()
    if names.isEmpty {
        FileHandle.standardError.write(Data("error: no card reader found\n".utf8))
        exit(5)
    }
    let saved = MSLog.sink
    MSLog.sink = nil
    for name in names {
        let state: String
        if let t = try? PCSCTransport(readerName: name) {
            let token = experimentalTokens ? TokenRecognizer.family(atr: t.atr) : nil
            t.disconnect()
            state = token.map { "card present — USB token \($0.displayName), not supported yet" } ?? "card present"
        } else { state = "no card" }
        print("\(name) — \(state)")
    }
    MSLog.sink = saved
    exit(0)

case "cert":
    do {
        let card = try openCard()
        defer { card.disconnect() }
        try card.authenticate()
        try card.selectMF()
        try card.selectGenericADF()
        let der = try card.readCertificate()
        let s = SigningService.CertificateSummary(der: der)
        print("Holder:   \(s.holder)")
        print("Subject:  \(s.subjectDN)")
        print("Issuer:   \(s.issuer)")
        print("Serial:   \(s.serialDecimal)")
        if let notAfter = s.notAfter { print("Valid to: \(ISO8601DateFormatter().string(from: notAfter))") }
        print("SHA-1:    \(s.sha1Hex)")
        if let i = args.firstIndex(of: "--out"), i + 1 < args.count {
            try der.write(to: URL(fileURLWithPath: args[i + 1]))
            print("Saved:    \(args[i + 1])")
        }
    } catch {
        fail(error)
    }
    exit(0)

case "sign":
    guard args.count >= 3 else { usage() }
    let output = args.count >= 4 ? args[3] : SigningService.outputURL(for: URL(fileURLWithPath: args[2])).path
    signPDF(args[2], output)

// sign-hex <digestinfo_hex> — signs a raw DigestInfo, outputs signature hex
case "sign-hex":
    guard args.count >= 3 else { usage() }
    let digestInfo = Data(hex: args[2])
    do {
        let card = try openCard()
        defer { card.disconnect() }
        try card.authenticate()
        try card.selectMF()
        try card.selectGenericADF()
        try card.verifyPIN(cliPIN())
        let sig = try card.sign(digestInfo: digestInfo)
        print(sig.hexString)
    } catch {
        fail(error)
    }
    exit(0)

// cms-for-hash <content_sha256_hex> — builds full detached CMS for an externally
// computed PDF content digest, outputs CMS hex (used by the Python PDF template builder)
case "cms-for-hash":
    guard args.count >= 3 else { usage() }
    let contentDigest = Data(hex: args[2])
    guard contentDigest.count == 32 else {
        FileHandle.standardError.write(Data("error: expected 64-char SHA-256 hex\n".utf8))
        exit(1)
    }
    do {
        let card = try openCard()
        defer { card.disconnect() }
        try card.authenticate()
        try card.selectMF()
        try card.selectGenericADF()
        try card.verifyPIN(cliPIN())
        let cert = try card.readCertificate()
        print("CMS_CERT:\(cert.hexString)")
        let signer = PAdESSigner()
        let cms = try signer.buildDetachedCMS(contentDigest: contentDigest, certDER: cert) { di in
            try card.sign(digestInfo: di)
        }
        print("CMS_HEX:\(cms.hexString)")
    } catch {
        fail(error)
    }
    exit(0)

// xades <XAdES-BES|XAdES-T|XAdES-C> <input-file> <output-signature.xml> [--enveloping]
case "xades":
    guard args.count >= 5 else { usage() }
    let format: XAdESSigner.Format
    switch args[2] {
    case "XAdES-BES": format = .bes
    case "XAdES-T": format = .t
    case "XAdES-C": format = .c
    default:
        FileHandle.standardError.write(Data("error: format must be XAdES-BES, XAdES-T or XAdES-C\n".utf8))
        exit(1)
    }
    let inPath = args[3]
    let outPath = args[4]
    let type: XAdESSigner.SigType = args.contains("--enveloping") ? .enveloping : .detached
    let digestArg = args.firstIndex(of: "--digest").flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil }
    let digest = XAdESSigner.DigestAlgorithm(requested: digestArg)
    guard FileManager.default.fileExists(atPath: inPath) else {
        FileHandle.standardError.write(Data("error: input file not found\n".utf8))
        exit(1)
    }
    do {
        print("Connecting to card reader...")
        let card = try openCard()
        defer { card.disconnect() }
        print("Authenticating...")
        try card.authenticate()
        let pin = cliPIN()
        guard !pin.isEmpty else { FileHandle.standardError.write(Data("error: no PIN provided\n".utf8)); exit(1) }
        try card.selectMF()
        try card.selectGenericADF()
        try card.verifyPIN(pin)
        let cert = try card.readCertificate()
        print("Signing (\(args[2]))...")
        let signer = XAdESSigner()
        let sig = try signer.sign(files: [URL(fileURLWithPath: inPath)], format: format, type: type, digest: digest,
                                  certDER: cert, chainDER: [ChainCerts.mdQSign],
                                  signBlock: { canonicalBytes in try card.sign(digestInfo: digest.digestInfo(of: canonicalBytes)) },
                                  tsaBlock: { data in try PAdESSigner.fetchTimestampToken(data: data) },
                                  ocspDerBlock: { issuer, c in try XAdESSigner.fetchOCSPResponse(issuerDER: issuer, certDER: c) })
        try sig.write(to: URL(fileURLWithPath: outPath))
        print("✅ XAdES signature saved to: \(outPath)")
    } catch {
        fail(error)
    }
    exit(0)

// verify <file.pdf|sig.xml> [docs_dir] — offline signature validation report
case "verify":
    guard args.count >= 3 else { usage() }
    let path = args[2]
    guard let data = FileManager.default.contents(atPath: path) else {
        FileHandle.standardError.write(Data("error: file not found\n".utf8))
        exit(1)
    }
    var reports: [Validator.Report] = []
    if path.lowercased().hasSuffix(".pdf") {
        reports = Validator.validatePDF(data)
    } else {
        // XAdES detached: resolve file:/ references relative to a docs dir (arg 3 or cwd)
        let docsDir = args.count >= 4 ? args[3] : FileManager.default.currentDirectoryPath
        reports = verifyDetached(data, directory: URL(fileURLWithPath: docsDir, isDirectory: true))
    }
    if reports.isEmpty {
        print("No signatures found.")
        exit(2)
    }
    var anyInvalid = false
    for r in reports {
        print(r.summary)
        if !(r.contentIntact && r.signatureValid) { anyInvalid = true }
    }
    exit(anyInvalid ? 2 : 0)

// server [port] — MoldSign Server protocol replica on 127.0.0.1
case "server":
    let port: UInt16 = args.count >= 3 ? (UInt16(args[2]) ?? 18480) : 18480
    let tlsPort: UInt16 = args.count >= 4 ? (UInt16(args[3]) ?? 18443) : 18443
    do {
        try MoldSignServer(httpPort: port, httpsPort: tlsPort).run()
    } catch {
        fail(error)
    }

case "-h", "--help", "help":
    usage()

case "--version", "version":
    print("esemnbun (MoldSignKit) · crypto: \(BuildInfo.cryptoBackend) · smart cards: \(BuildInfo.smartCardStack)")
    exit(0)

default:
    // Legacy form: esemnbun <input.pdf> <output.pdf>
    guard args.count >= 3 else { usage() }
    signPDF(args[1], args[2])
}
