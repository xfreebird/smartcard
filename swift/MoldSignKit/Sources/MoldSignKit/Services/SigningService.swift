import Foundation

/// App-facing facade over the card + formats (docs/09 §3.4).
///
/// Serializes every card operation behind one lock (MAC-11): two interleaved SM sessions desync the
/// SSC (`6988`). All methods block. Call them off the main thread.
public final class SigningService: @unchecked Sendable {
    public static let shared = SigningService()

    public enum Step: String, CaseIterable, Sendable {
        case connecting, authenticating, readingCertificate, verifyingPIN, signing, timestamping, writing, done
    }

    public struct CertificateSummary: Equatable, Sendable {
        public let der: Data
        public let holder: String
        public let subjectDN: String
        public let issuer: String
        /// Issuer CN for display ("MDQSign").
        public let issuerName: String
        public let serialDecimal: String
        public let sha1Hex: String
        public let notAfter: Date?
        /// For the ID-card face: the subject's SN / GN, else `holder` split at the first space
        /// (Moldovan CNs are "Surname Given").
        public let surname: String
        public let givenNames: String

        public init(der: Data) {
            self.der = der
            holder = Validator.subjectCN(der) ?? "—"
            let subjectDER = try? XAdESSigner.nameDER(der, subject: true)
            subjectDN = subjectDER.map(X509Name.displayString) ?? ""
            let subject = subjectDER.map(X509Name.attributes) ?? []
            (surname, givenNames) = Self.nameParts(holder: holder,
                                                   surname: subject.last { $0.type == "SN" }?.value,
                                                   givenNames: subject.last { $0.type == "GN" }?.value)
            let name = try? XAdESSigner.parseIssuer(der)
            let issuerDER = try? XAdESSigner.nameDER(der, subject: false)
            issuer = issuerDER.map(X509Name.displayString) ?? ""
            issuerName = issuerDER.flatMap(X509Name.commonName) ?? issuer
            serialDecimal = name?.serialDecimal ?? ""
            sha1Hex = der.sha1().hexString.lowercased()
            notAfter = Self.notAfter(der)
        }

        /// Explicit values (SwiftUI previews, debug demo cards, tests).
        public init(der: Data, holder: String, subjectDN: String, issuer: String, issuerName: String,
                    serialDecimal: String, sha1Hex: String, notAfter: Date?,
                    surname: String? = nil, givenNames: String? = nil) {
            self.der = der
            self.holder = holder
            self.subjectDN = subjectDN
            self.issuer = issuer
            self.issuerName = issuerName
            self.serialDecimal = serialDecimal
            self.sha1Hex = sha1Hex
            self.notAfter = notAfter
            (self.surname, self.givenNames) = Self.nameParts(holder: holder, surname: surname, givenNames: givenNames)
        }

        static func nameParts(holder: String, surname: String?, givenNames: String?) -> (String, String) {
            if let surname, !surname.isEmpty { return (surname, givenNames ?? "") }
            let parts = holder.split(separator: " ", maxSplits: 1).map(String.init)
            return (parts.first ?? holder, parts.count > 1 ? parts[1] : "")
        }

        /// Validity.notAfter from the TBS (UTCTime or GeneralizedTime).
        static func notAfter(_ der: Data) -> Date? {
            guard let fields = try? X509Validity(Data(der)) else { return nil }
            return fields.notAfter
        }
    }

    /// A card and the reader it sits in (several eID cards can be connected at once).
    public struct CardEntry: Equatable, Sendable {
        public let reader: String
        public let certificate: CertificateSummary
    }

    /// Opens a reader by name (nil = the app's current choice, else the first reader with a card).
    /// Apps pin their selection here; tests inject simulated cards.
    public var transportFactory: (String?) throws -> CardTransport = { try CardTransports.connect(reader: $0) }
    /// Readers holding a card, for `listCards()`.
    public var readersWithCards: () -> [String] = { CardTransports.readersWithCards() }

    private let cardLock = NSLock()
    private let cacheLock = NSLock()
    private let optionsLock = NSLock()
    private var tokensEnabled = false

    /// Experimental USB token support (Phase TOK), off by default and switched from the apps' settings.
    /// On: a reader holding a recognized token (`TokenRecognizer`, by ATR) fails with `UnsupportedTokenError`
    /// before any APDU is sent, instead of the eID error. Off: exactly the eID-only behavior.
    public var experimentalTokens: Bool {
        get { optionsLock.lock(); defer { optionsLock.unlock() }; return tokensEnabled }
        set { optionsLock.lock(); tokensEnabled = newValue; optionsLock.unlock() }
    }
    private var certificateByReader: [String: CertificateSummary] = [:]

    public init() {}

    /// Runs `body` with a freshly authenticated card (secure channel up), serialized with every other card call.
    public func withCard<T>(reader: String? = nil, progress: ((Step) -> Void)? = nil,
                            _ body: (CosmoXCard) throws -> T) throws -> T {
        cardLock.lock()
        defer { cardLock.unlock() }
        progress?(.connecting)
        let transport = try transportFactory(reader)
        try ExperimentalTokens.refuseRecognizedToken(on: transport, enabled: experimentalTokens)
        let card = CosmoXCard(transport: transport)
        defer { card.disconnect() }
        progress?(.authenticating)
        try card.authenticate()
        return try body(card)
    }

    /// Certificate without a PIN (reader monitor greets the holder by name).
    public func readCertificate(reader: String? = nil) throws -> CertificateSummary {
        let summary = try withCard(reader: reader) { card in
            try card.selectMF()
            try card.selectGenericADF()
            return CertificateSummary(der: try card.readCertificate())
        }
        if let reader { remember(summary, in: reader) }
        return summary
    }

    /// Every inserted card with its certificate (PIN-less reads; unreadable cards are skipped).
    public func listCards() -> [CardEntry] {
        let readers = readersWithCards()
        let entries = readers.compactMap { reader in
            (try? readCertificate(reader: reader)).map { CardEntry(reader: reader, certificate: $0) }
        }
        cacheLock.lock()
        certificateByReader = certificateByReader.filter { readers.contains($0.key) }
        cacheLock.unlock()
        return entries
    }

    /// Reader holding the card with this certificate: cache first, then a fresh scan (cards move between readers).
    public func reader(forCertificateSHA1 sha1: String) -> String? {
        func cached() -> String? {
            cacheLock.lock(); defer { cacheLock.unlock() }
            return certificateByReader.first { $0.value.sha1Hex == sha1.lowercased() }?.key
        }
        if let reader = cached(), readersWithCards().contains(reader) { return reader }
        return listCards().first { $0.certificate.sha1Hex == sha1.lowercased() }?.reader
    }

    private func remember(_ summary: CertificateSummary, in reader: String) {
        cacheLock.lock(); certificateByReader[reader] = summary; cacheLock.unlock()
    }

    /// PAdES-T, same card sequence as `CosmoXCard.signPDF` (the CLI-proven path).
    /// `expectedCertificateSHA1`: the card the PIN belongs to; a different card fails with `.cardChanged`
    /// before VERIFY.
    public func signPDF(_ pdf: Data, pin: String, reader: String? = nil, expectedCertificateSHA1: String? = nil,
                        appearance: PDFStampPlacement? = nil, expectedCertificateSHA256: String? = nil,
                        progress: ((Step) -> Void)? = nil) throws -> Data {
        try withCard(reader: reader, progress: progress) { card in
            try card.selectMF()
            try card.selectGenericADF()
            progress?(.readingCertificate)
            let cert = try card.readCertificate()
            if let expected = expectedCertificateSHA1, cert.sha1().hexString.lowercased() != expected.lowercased() {
                throw CardError.cardChanged
            }
            if let expected = expectedCertificateSHA256, cert.sha256().hexString.lowercased() != expected.lowercased() {
                throw CardError.cardChanged
            }
            let signed = try PAdESSigner().signPDF(pdf, certDER: cert, appearance: appearance) { digestInfo in
                try card.selectGenericADF()
                progress?(.verifyingPIN)
                try card.verifyPIN(pin)
                try card.selectMF()
                try card.selectGenericADF()
                progress?(.signing)
                let signature = try card.sign(digestInfo: digestInfo)
                progress?(.timestamping)
                return signature
            }
            progress?(.done)
            return signed
        }
    }

    /// XAdES BES/T/C, same card sequence as the CLI `xades` mode.
    public func signXAdES(files: [URL], format: XAdESSigner.Format, type: XAdESSigner.SigType = .detached,
                          digest: XAdESSigner.DigestAlgorithm = .sha256,
                          pin: String, reader: String? = nil, expectedCertificateSHA1: String? = nil,
                          progress: ((Step) -> Void)? = nil) throws -> Data {
        try withCard(reader: reader, progress: progress) { card in
            progress?(.readingCertificate)
            let cert = try card.prepareForSigning(pin: pin, expectedCertificateSHA1: expectedCertificateSHA1)
            try card.selectMF()
            try card.selectGenericADF()
            progress?(.signing)
            let xml = try XAdESSigner().sign(
                files: files, format: format, type: type, digest: digest, certDER: cert, chainDER: [ChainCerts.mdQSign],
                signBlock: { bytes in try card.sign(digestInfo: digest.digestInfo(of: bytes)) },
                tsaBlock: { data in
                    progress?(.timestamping)
                    return try PAdESSigner.fetchTimestampToken(data: data)
                },
                ocspDerBlock: { issuer, c in try XAdESSigner.fetchOCSPResponse(issuerDER: issuer, certDER: c) })
            progress?(.done)
            return xml
        }
    }

    /// Offline validation of a PDF or an XAdES document (detached files keyed by basename).
    public func verify(_ data: Data, isPDF: Bool, detached: [String: Data] = [:]) -> [Validator.Report] {
        isPDF ? Validator.validatePDF(data) : Validator.validateXAdES(data, referencedFiles: detached)
    }

    /// `<name>-semnat.<ext>` next to the input; never overwrites (D-06): appends ` 2`, ` 3`…
    public static func outputURL(for input: URL, pathExtension: String? = nil) -> URL {
        let dir = input.deletingLastPathComponent()
        let base = input.deletingPathExtension().lastPathComponent + "-semnat"
        let ext = pathExtension ?? input.pathExtension
        var candidate = dir.appendingPathComponent(base).appendingPathExtension(ext)
        var n = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = dir.appendingPathComponent("\(base) \(n)").appendingPathExtension(ext)
            n += 1
        }
        return candidate
    }
}

/// notBefore / notAfter of an X.509 certificate.
struct X509Validity {
    let notBefore: Date?
    let notAfter: Date?

    init(_ cert: Data) throws {
        var (h, _) = try DER.header(cert, at: 0)
        var pos = h
        (h, _) = try DER.header(cert, at: pos)
        pos += h
        func skip() throws { let (hh, len) = try DER.header(cert, at: pos); pos += hh + len }
        if cert[pos] == 0xA0 { try skip() }   // version
        try skip()                             // serial
        try skip()                             // signature
        try skip()                             // issuer
        let (vh, _) = try DER.header(cert, at: pos)
        pos += vh                              // into Validity
        func time() throws -> Date? {
            let tag = cert[pos]
            let (th, len) = try DER.header(cert, at: pos)
            let text = String(decoding: cert.subdata(in: (pos + th)..<(pos + th + len)), as: UTF8.self)
            pos += th + len
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.timeZone = TimeZone(identifier: "UTC")
            f.dateFormat = tag == 0x17 ? "yyMMddHHmmss'Z'" : "yyyyMMddHHmmss'Z'"
            return f.date(from: text)
        }
        notBefore = try time()
        notAfter = try time()
    }
}
