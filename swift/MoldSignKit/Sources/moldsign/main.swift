import Foundation
#if canImport(Glibc)
import Glibc
#endif
import MoldSignKit

// `moldsign` — macOS and Linux implementation of spec/cli.md (CLI-02, LNX-*).
setbuf(stdout, nil)

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

// MARK: - Helpers

/// PIN order (spec/cli.md): --pin-stdin → MSIGN_PIN → prompt without echo. Never hard-code it (F-03, SEC-06).
func cliPIN() -> String {
    if pinFromStdin { return readLine(strippingNewline: true) ?? "" }
    if let pin = ProcessInfo.processInfo.environment["MSIGN_PIN"], !pin.isEmpty { return pin }
    guard let raw = getpass("PIN QSCD: ") else { return "" }
    return String(cString: raw)
}

func openCard() throws -> CosmoXCard {
    let card = CosmoXCard(transport: try PCSCTransport(readerName: readerName))
    return card
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
    Usage: moldsign <command> [options]
      readers                                  list readers and card presence
      cert [--out <file.der>]                  read the signing certificate (no PIN)
      sign <in.pdf> [<out.pdf>]                PAdES-T signature
      xades <XAdES-BES|XAdES-T|XAdES-C> <in> <out.xml> [--enveloping] [--digest SHA-1|SHA-256]
      verify <file.pdf|sig.xml> [<docs_dir>]   offline validation
      server [<port> [<https_port>]]           browser bridge (MoldSign Server protocol)
      sign-hex <digestinfo_hex>                raw card signature (developer)
      cms-for-hash <sha256_hex>                detached CMS for a content digest (developer)
    Options: --reader <name>  --quiet  --pin-stdin      PIN: MSIGN_PIN or prompt
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
        if let t = try? PCSCTransport(readerName: name) { t.disconnect(); state = "card present" } else { state = "no card" }
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
        var files: [String: Data] = [:]
        let text = String(data: data, encoding: .utf8) ?? ""
        var start = text.startIndex
        while let r = text.range(of: "URI=\"file:/", range: start..<text.endIndex),
              let e = text[r.upperBound...].firstIndex(of: "\"") {
            let name = String(text[r.upperBound..<e])
            if let d = try? Data(contentsOf: URL(fileURLWithPath: docsDir + "/" + name)) {
                files[name] = d
            }
            start = e
        }
        reports = Validator.validateXAdES(data, referencedFiles: files)
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
    print("moldsign (MoldSignKit) · crypto: \(BuildInfo.cryptoBackend) · smart cards: \(BuildInfo.smartCardStack)")
    exit(0)

default:
    // Legacy form: moldsign <input.pdf> <output.pdf>
    guard args.count >= 3 else { usage() }
    signPDF(args[1], args[2])
}
