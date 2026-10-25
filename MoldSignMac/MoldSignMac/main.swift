import Foundation

setbuf(stdout, nil)

let args = CommandLine.arguments

// Mode 1: sign-hex <digestinfo_hex> — signs a raw DigestInfo, outputs signature hex
if args.count >= 3 && args[1] == "sign-hex" {
    let digestInfoHex = args[2]
    let digestInfo = Data(hex: digestInfoHex)
    let card = CosmoXCard()
    do {
        try card.connect()
        try card.authenticate()
        try card.selectMF()
        try card.selectGenericADF()
        try card.verifyPIN("REDACTED")
        let sig = try card.sign(digestInfo: digestInfo)
        print(sig.hexString)
    } catch {
        print("ERROR: \(error)")
        exit(1)
    }
    card.disconnect()
    exit(0)
}

// Mode 2: cms-for-hash <content_sha256_hex> — builds full detached CMS for an externally
// computed PDF content digest, outputs CMS hex (used by the Python PDF template builder)
if args.count >= 3 && args[1] == "cms-for-hash" {
    let contentDigest = Data(hex: args[2])
    guard contentDigest.count == 32 else {
        print("ERROR: expected 64-char SHA-256 hex")
        exit(1)
    }
    let card = CosmoXCard()
    do {
        try card.connect()
        try card.authenticate()
        try card.selectMF()
        try card.selectGenericADF()
        try card.verifyPIN("REDACTED")
        let cert = try card.readCertificate()
        print("CMS_CERT:\(cert.hexString)")
        let signer = PAdESSigner()
        let cms = try signer.buildDetachedCMS(contentDigest: contentDigest, certDER: cert) { di in
            try card.sign(digestInfo: di)
        }
        print("CMS_HEX:\(cms.hexString)")
    } catch {
        print("ERROR: \(error)")
        card.disconnect()
        exit(1)
    }
    card.disconnect()
    exit(0)
}

// Mode 2.5: xades <XAdES-BES|XAdES-T|XAdES-C> <input-file> <output-signature.xml>
if args.count >= 5 && args[1] == "xades" {
    let format: XAdESSigner.Format
    switch args[2] {
    case "XAdES-BES": format = .bes
    case "XAdES-T": format = .t
    case "XAdES-C": format = .c
    default:
        print("ERROR: format must be XAdES-BES, XAdES-T or XAdES-C")
        exit(1)
    }
    let inPath = args[3]
    let outPath = args[4]
    guard FileManager.default.fileExists(atPath: inPath) else {
        print("ERROR: input file not found")
        exit(1)
    }
    let card = CosmoXCard()
    do {
        print("Connecting to card reader...")
        try card.connect()
        print("Authenticating...")
        try card.authenticate()
        print("\nEnter your PIN QSCD (6-8 digits):")
        guard let pin = readLine(), !pin.isEmpty else {
            print("ERROR: No PIN provided")
            card.disconnect()
            exit(1)
        }
        try card.selectMF()
        try card.selectGenericADF()
        try card.verifyPIN(pin)
        let cert = try card.readCertificate()
        print("Signing (\(args[2]))...")
        let signer = XAdESSigner()
        let sig = try signer.sign(files: [URL(fileURLWithPath: inPath)], format: format,
                                  certDER: cert, chainDER: [ChainCerts.mdQSign],
                                  signBlock: { canonicalBytes in
                                      try card.sign(digestInfo: XAdESSigner.digestInfoForSHA256(canonicalBytes.sha256()))
                                  },
                                  tsaBlock: { data in try PAdESSigner.fetchTimestampToken(data: data) },
                                  ocspDerBlock: { issuer, c in try XAdESSigner.fetchOCSPResponse(issuerDER: issuer, certDER: c) })
        try sig.write(to: URL(fileURLWithPath: outPath))
        print("✅ XAdES signature saved to: \(outPath)")
    } catch {
        print("❌ \(error)")
        card.disconnect()
        exit(1)
    }
    card.disconnect()
    exit(0)
}

// Mode 2.7: verify <file.pdf|sig.xml> — offline signature validation report
if args.count >= 3 && args[1] == "verify" {
    let path = args[2]
    guard let data = FileManager.default.contents(atPath: path) else {
        print("ERROR: file not found")
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
        exit(1)
    }
    var anyInvalid = false
    for r in reports {
        print(r.summary)
        if !(r.contentIntact && r.signatureValid) { anyInvalid = true }
    }
    exit(anyInvalid ? 1 : 0)
}

// Mode 2.9: server [port] — MoldSign Server protocol replica on 127.0.0.1
if args.count >= 2 && args[1] == "server" {
    let port: UInt16 = args.count >= 3 ? (UInt16(args[2]) ?? 18480) : 18480
    do {
        try MoldSignServer().run()
    } catch {
        print("❌ server failed: \(error)")
        exit(1)
    }
}

// Mode 3: full signing <input.pdf> <output.pdf>
let inputPath: String
let outputPath: String
if args.count >= 3 {
    inputPath = args[1]
    outputPath = args[2]
} else {
    print("Usage: MoldSignMac <input.pdf> <output.pdf>  |  MoldSignMac sign-hex <hex>")
    exit(1)
}

guard FileManager.default.fileExists(atPath: inputPath) else {
    print("ERROR: Input PDF not found at \(inputPath)")
    exit(1)
}

print("Input:  \(inputPath)")
print("Output: \(outputPath)")
let pdfData = FileManager.default.contents(atPath: inputPath)!
print("PDF size: \(pdfData.count) bytes")

let card = CosmoXCard()
do {
    print("\nConnecting to card reader...")
    try card.connect()
    print("Authenticating...")
    try card.authenticate()
    print("\nEnter your PIN QSCD (6-8 digits):")
    guard let pin = readLine(), !pin.isEmpty else {
        print("ERROR: No PIN provided")
        card.disconnect()
        exit(1)
    }
    print("Signing PDF...")
    let signedPDF = try card.signPDF(pdfData, pin: pin)
    FileManager.default.createFile(atPath: outputPath, contents: signedPDF)
    print("\n✅ Signed PDF saved to: \(outputPath)")
    print("Verify at: https://msign.gov.md/#/")
} catch let error as CardError {
    print("❌ \(error.localizedDescription)")
} catch {
    print("❌ Unexpected error: \(error)")
}
card.disconnect()
print("\nDone.")
