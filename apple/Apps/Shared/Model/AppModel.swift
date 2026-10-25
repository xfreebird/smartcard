import SwiftUI
import MoldSignKit

/// App state shared by the macOS menu-bar app and the iOS app.
/// UI state lives here on the main actor; card work runs detached through `SigningService` (one card op at a time).
@MainActor @Observable
final class AppModel {
    // Readers / cards (several eID cards can be connected)
    var status: ReaderStatus = .noReader
    var cards: [CardSlot] = []
    var selectedReaderName: String? {
        didSet { selectedReader.name = selectedCard?.reader; recomputeStatus() }
    }
    var lastAttemptsLeft: Int?

    /// The card the UI signs with: the user's pick, else the first inserted one.
    var selectedCard: CardSlot? { cards.first { $0.reader == selectedReaderName } ?? cards.first }
    var certificate: SigningService.CertificateSummary? { selectedCard?.certificate }

    // Sign
    var signItems: [SignItem] = []
    var currentStep: SigningService.Step?
    var lastSigned: [URL] = []
    var lastError: (message: String, recovery: String)?

    // Verify
    var verifyFile: URL?
    var verifyReports: [Validator.Report]?

    // Sheets
    var pinRequest: PinRequest?
    var consentRequest: ConsentRequest?

    // Activity + bridge
    var activity: [ActivityItem] = []
    var bridgeState: BridgeState = .stopped
    var bridgeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(bridgeEnabled, forKey: "bridgeEnabled")
            bridgeEnabled ? startBridge() : stopBridge()
        }
    }

    /// macOS brings the auth panel forward (the request may come from the menu bar or the browser).
    @ObservationIgnored var presentAuthUI: (() -> Void)?

    @ObservationIgnored let service = SigningService.shared
    @ObservationIgnored let vault = PinVault()
    @ObservationIgnored private let monitor = ReaderMonitor()
    @ObservationIgnored private let selectedReader = SelectedReader()
    @ObservationIgnored private var server: MoldSignServer?
    @ObservationIgnored private var pinContinuation: CheckedContinuation<(pin: String, remember: Bool)?, Never>?
    @ObservationIgnored private var consentContinuation: CheckedContinuation<(approved: Bool, trust: Bool), Never>?
    @ObservationIgnored private var trustedUntil: [String: Date] = [:]
    private(set) var readers: [String] = []
    private var muteCard = false
    private var signing = false

    /// Tray / menu-bar light (UX-01).
    var light: StatusLight {
        if signing || pinRequest != nil || consentRequest != nil { return .busy }
        if cards.contains(where: { $0.certificate != nil }) { return .ready }
        switch status {
        case .error, .unavailable: return .error
        default: break
        }
        return readers.isEmpty ? .idle : .reader
    }

    /// Menu-bar dot (docs/10 §0.2b, UX-11): green while a card is inserted (reading, ready or signing), gray otherwise.
    var cardConnected: Bool { cards.contains { $0.problem == nil } }

    var trayLabel: String {
        if cardConnected {
            let holder = certificate?.holder ?? cards.compactMap(\.certificate).first?.holder
            return holder.map { String(localized: "eSemnBun · Card conectat · \($0)") } ?? String(localized: "eSemnBun · Card conectat")
        }
        switch status {
        case .error, .unavailable: return "eSemnBun · \(status.title)"
        default: return String(localized: "eSemnBun · Niciun card conectat")
        }
    }

    /// Text twin of `light` (tooltip, VoiceOver).
    var lightLabel: String {
        switch light {
        case .ready:
            let ready = cards.compactMap(\.certificate)
            let holder = certificate?.holder ?? ready.first?.holder ?? ""
            return ready.count > 1 ? String(localized: "Card pregătit · \(holder) · \(ready.count) carduri")
                                   : String(localized: "Card pregătit · \(holder)")
        case .reader: return String(localized: "Cititor conectat · introdu cardul")
        case .busy: return String(localized: "Se semnează…")
        case .error: return status.title
        case .idle: return String(localized: "Conectează cititorul")
        }
    }

    init() {
        bridgeEnabled = UserDefaults.standard.object(forKey: "bridgeEnabled") as? Bool ?? true
        if let data = UserDefaults.standard.data(forKey: "activity"),
           let items = try? JSONDecoder().decode([ActivityItem].self, from: data) {
            activity = items
            pruneMissingFiles()
        }
    }

    func start() {
        MSLog.sink = nil   // SEC-04: no SM traces or session keys in app logs
        #if DEBUG
        if let demo = ProcessInfo.processInfo.environment["MSIGN_DEMO_CARDS"], let count = Int(demo == "none" ? "0" : demo),
           count > 0 || demo == "none" {
            loadDemoCards(count)
            return
        }
        #endif
        let selected = selectedReader
        // nil (no specific card asked for) → the card selected in the UI
        service.transportFactory = { reader in try CardTransports.connect(reader: reader ?? selected.name) }
        monitor.onChange = { [weak self] snapshot in self?.apply(snapshot) }
        monitor.start()
        if bridgeEnabled { startBridge() }
    }

    // MARK: - Reader state

    private func apply(_ snapshot: ReaderMonitor.Snapshot) {
        guard snapshot.available else { status = .unavailable; return }
        readers = snapshot.slots.map(\.name)
        muteCard = snapshot.slots.contains { $0.state == .mute }
        var next: [CardSlot] = []
        var toRead: [CardSlot] = []
        for slot in snapshot.slots where slot.state == .card {
            if let known = cards.first(where: { $0.reader == slot.name }), known.generation == slot.generation {
                next.append(known)
            } else {
                // new card, or the same reader got a card again (removed + reinserted / swapped): forget the old one
                let fresh = CardSlot(reader: slot.name, generation: slot.generation)
                next.append(fresh)
                toRead.append(fresh)
            }
        }
        cards = next
        if selectedReaderName.map({ name in !next.contains { $0.reader == name } }) ?? true {
            selectedReaderName = next.first?.reader
        }
        selectedReader.name = selectedCard?.reader
        recomputeStatus()
        for card in toRead { Task { await readCertificate(of: card) } }
    }

    /// PIN-less certificate read so the UI can greet the holder (MAC-02). Ignored if the card changed meanwhile.
    private func readCertificate(of card: CardSlot) async {
        let service = self.service
        let reader = card.reader
        let result = await Task.detached { Result { try service.readCertificate(reader: reader) } }.value
        guard let index = cards.firstIndex(where: { $0.reader == reader && $0.generation == card.generation }) else { return }
        switch result {
        case .success(let summary): cards[index].certificate = summary; cards[index].problem = nil
        case .failure(let error): cards[index].problem = Self.describe(error).message
        }
        recomputeStatus()
    }

    #if DEBUG
    /// Screenshots / design QA without hardware: `MSIGN_DEMO_CARDS=2`. Never compiled into release builds.
    private func loadDemoCards(_ count: Int) {
        let holders = ["Popescu Ion", "Mîndru Ștefan", "Rusu Ana"]   // CN order on Moldovan certificates
        readers = (0..<count).map { $0 == 0 ? "bit4id miniLector POCKET EVO" : "bit4id miniLector POCKET EVO 0\($0)" }
        cards = readers.enumerated().map { index, reader in
            let sha = String(format: "%02x", index * 97 + 20) + String(repeating: "0", count: 38)
            let cert = SigningService.CertificateSummary(
                der: Data(), holder: holders[index % holders.count], subjectDN: "CN=\(holders[index % holders.count]),C=MD",
                issuer: "CN=MDQSign,C=MD", issuerName: "MDQSign", serialDecimal: "1298074214877499210738125554536943",
                sha1Hex: sha, notAfter: Calendar.current.date(byAdding: .year, value: 4 - index, to: Date()))
            return CardSlot(reader: reader, generation: 1, certificate: cert)
        }
        if let files = ProcessInfo.processInfo.environment["MSIGN_DEMO_FILES"] {
            addFiles(files.split(separator: ":").map { URL(filePath: String($0)) })
        }
        let selected = ProcessInfo.processInfo.environment["MSIGN_DEMO_SELECTED"].flatMap(Int.init) ?? 0
        selectedReaderName = cards.isEmpty ? nil : cards[min(max(selected, 0), cards.count - 1)].reader
        bridgeState = .running
        recomputeStatus()
    }
    #endif

    /// "Recitește cardul": forget what we know about the inserted cards and read them again.
    func rereadCards() {
        for index in cards.indices {
            cards[index].certificate = nil
            cards[index].problem = nil
        }
        recomputeStatus()
        for card in cards { Task { await readCertificate(of: card) } }
    }

    func selectCard(_ reader: String) {
        selectedReaderName = reader
    }

    private func recomputeStatus() {
        guard !signing else { return }
        guard let firstReader = readers.first else { status = .noReader; return }
        guard let card = selectedCard else {
            status = muteCard
                ? .error(message: String(localized: "Cardul nu răspunde"), recovery: String(localized: "Scoate și reintrodu cardul"))
                : .empty(reader: firstReader)
            return
        }
        if let cert = card.certificate {
            status = .ready(reader: card.reader, holder: cert.holder, validUntil: cert.notAfter)
        } else if let problem = card.problem {
            status = .error(message: problem, recovery: String(localized: "Scoate și reintrodu cardul"))
        } else {
            status = .reading(reader: card.reader)
        }
    }

    // MARK: - Signing

    func addFiles(_ urls: [URL]) {
        let known = Set(signItems.map(\.url))
        signItems += urls.filter { !known.contains($0) && !$0.hasDirectoryPath }.map(SignItem.init)
    }

    func remove(_ item: SignItem) {
        signItems.removeAll { $0.id == item.id }
    }

    /// Signs every queued file with one PIN entry. Wrong PIN: stop, drop the stored PIN, never retry (MAC-05).
    func signAll() async {
        guard let card = selectedCard, let cert = card.certificate, status.canSign, !signItems.isEmpty else { return }
        lastError = nil
        lastSigned = []
        guard let entry = await obtainPIN(certID: cert.sha1Hex, holder: cert.holder, allowRemember: true) else { return }
        let reader = card.reader
        signing = true
        status = .busy(reader: reader, holder: cert.holder)
        defer {
            currentStep = nil
            signing = false
            recomputeStatus()
        }
        for item in signItems {
            do {
                // the expected certificate makes the core refuse a swapped card before the PIN is sent
                let output = try await sign(item, pin: entry.pin, reader: reader, certificateSHA1: cert.sha1Hex)
                lastSigned.append(output)
                log(ActivityItem(title: output.lastPathComponent, subtitle: String(localized: "Semnat · \(item.format.label)"),
                                 ok: true, fileURL: output))
                if entry.remember { try? vault.save(entry.pin, certID: cert.sha1Hex) }
            } catch {
                handleCardError(error, certID: cert.sha1Hex)
                log(ActivityItem(title: item.url.lastPathComponent, subtitle: lastError?.message ?? "", ok: false))
                if case CardError.cardChanged = error { rereadCards() }
                return
            }
        }
        signItems.removeAll()
    }

    private func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String) async throws -> URL {
        let service = self.service
        let input = item.url
        let format = item.format
        let output = outputURL(for: input, format: format)
        let progress: @Sendable (SigningService.Step) -> Void = { [weak self] step in
            Task { @MainActor in self?.currentStep = step }
        }
        let scoped = input.startAccessingSecurityScopedResource()
        defer { if scoped { input.stopAccessingSecurityScopedResource() } }
        try await Task.detached {
            let signed: Data
            if let xades = format.xades {
                signed = try service.signXAdES(files: [input], format: xades, pin: pin, reader: reader,
                                               expectedCertificateSHA1: certificateSHA1, progress: progress)
            } else {
                signed = try service.signPDF(try Data(contentsOf: input), pin: pin, reader: reader,
                                             expectedCertificateSHA1: certificateSHA1, progress: progress)
            }
            progress(.writing)
            try signed.write(to: output, options: .withoutOverwriting)
        }.value
        return output
    }

    private func outputURL(for input: URL, format: SignFormat) -> URL {
        let ext = format == .padesT ? "pdf" : "xml"
        #if os(macOS)
        return SigningService.outputURL(for: input, pathExtension: ext)
        #else
        // iOS: the picked file's folder is usually not writable; keep results in Documents and offer Share
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return SigningService.outputURL(for: documents.appendingPathComponent(input.lastPathComponent), pathExtension: ext)
        #endif
    }

    private func handleCardError(_ error: Error, certID: String) {
        if case CardError.wrongPIN(let remaining) = error {
            lastAttemptsLeft = remaining
            vault.delete(certID: certID)
        }
        if case CardError.pinBlocked = error { vault.delete(certID: certID) }
        lastError = Self.describe(error)
    }

    // MARK: - PIN

    private func obtainPIN(certID: String, holder: String, allowRemember: Bool) async -> (pin: String, remember: Bool)? {
        if let stored = await vault.load(certID: certID, reason: String(localized: "semnarea cu certificatul \(holder)")) {
            return (stored, false)
        }
        pinRequest = PinRequest(holder: holder, attemptsLeft: lastAttemptsLeft, canRemember: allowRemember)
        presentAuthUI?()
        return await withCheckedContinuation { pinContinuation = $0 }
    }

    func submitPIN(_ pin: String, remember: Bool) {
        pinRequest = nil
        pinContinuation?.resume(returning: (pin, remember))
        pinContinuation = nil
    }

    func cancelPIN() {
        pinRequest = nil
        pinContinuation?.resume(returning: nil)
        pinContinuation = nil
    }

    func forgetPIN() {
        if let cert = certificate { vault.delete(certID: cert.sha1Hex) }
    }

    var hasStoredPIN: Bool {
        certificate.map { vault.hasPIN(certID: $0.sha1Hex) } ?? false
    }

    // MARK: - Verify

    func verify(_ url: URL) async {
        verifyFile = url
        verifyReports = nil
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else {
            verifyReports = []
            return
        }
        let isPDF = url.pathExtension.lowercased() == "pdf"
        let detached = isPDF ? [:] : Self.detachedDocuments(for: data, near: url)
        let service = self.service
        let reports = await Task.detached { service.verify(data, isPDF: isPDF, detached: detached) }.value
        verifyReports = reports
        let verdict = Verdict(reports)
        log(ActivityItem(title: url.lastPathComponent, subtitle: String(localized: "Verificat"),
                         ok: { if case .valid = verdict { return true } else { return false } }(), fileURL: url))
    }

    /// XAdES detached references are `file:/<basename>`: look next to the signature (same rule as the CLI).
    private static func detachedDocuments(for xml: Data, near url: URL) -> [String: Data] {
        var files: [String: Data] = [:]
        let text = String(decoding: xml, as: UTF8.self)
        var start = text.startIndex
        while let r = text.range(of: "URI=\"file:/", range: start..<text.endIndex),
              let e = text[r.upperBound...].firstIndex(of: "\"") {
            let name = String(text[r.upperBound..<e])
            files[name] = try? Data(contentsOf: url.deletingLastPathComponent().appendingPathComponent(name))
            start = e
        }
        return files
    }

    // MARK: - Bridge (MAC-07, IOS-06)

    func startBridge() {
        guard server == nil else { return }
        let server = MoldSignServer()
        server.authorize = { [weak self] request in
            let box = DecisionBox()
            let done = DispatchSemaphore(value: 0)
            Task { @MainActor in
                box.value = await self?.authorize(request) ?? .deny
                done.signal()
            }
            done.wait()
            return box.value
        }
        server.onSignResult = { [weak self] request, error in
            Task { @MainActor in
                guard let self else { return }
                self.log(Self.bridgeActivity(request, error))   // MAC-10: outcome, not just "request received"
                // A stored PIN the card rejected during a browser request must go, like in the UI flow (MAC-05).
                guard let error, let cert = self.certificate else { return }
                switch error {
                case CardError.wrongPIN, CardError.pinBlocked: self.handleCardError(error, certID: cert.sha1Hex)
                default: break
                }
            }
        }
        server.onListenerError = { [weak self] _, error in
            Task { @MainActor in
                self?.bridgeState = MoldSignServer.isAddressInUse(error) ? .portBusy : .failed("\(error)")
            }
        }
        do {
            try server.start()
            bridgeState = .running
            self.server = server
        } catch {
            bridgeState = .failed(error.localizedDescription)
        }
    }

    func stopBridge() {
        server?.stop()
        server = nil
        bridgeState = .stopped
    }

    /// Consent (unless the origin is trusted for 10 minutes), then the PIN unless the page sent one.
    private func authorize(_ request: BridgeRequest) async -> BridgeDecision {
        let origin = request.origin ?? "local"
        // the page picked a certificate from /certificates (several cards may be connected): consent + PIN for THAT card
        let target = request.certificateSHA1.flatMap { sha in cards.first { $0.certificate?.sha1Hex == sha }?.certificate }
            ?? (request.certificateSHA1 == nil ? certificate : nil)
        let certID = request.certificateSHA1 ?? target?.sha1Hex
        let holder = target?.holder ?? request.certificateHolder ?? "—"
        if (trustedUntil[origin] ?? .distantPast) < Date() {
            consentRequest = ConsentRequest(request: request, holder: holder,
                                            hasStoredPIN: certID.map { vault.hasPIN(certID: $0) } ?? false)
            presentAuthUI?()
            let answer = await withCheckedContinuation { consentContinuation = $0 }
            consentRequest = nil
            guard answer.approved else { return .deny }
            if answer.trust { trustedUntil[origin] = Date().addingTimeInterval(600) }
        }
        if request.pinIncluded { return .allow(pin: nil, certificateSHA1: certID) }
        guard let certID, let entry = await obtainPIN(certID: certID, holder: holder, allowRemember: false) else { return .deny }
        return .allow(pin: entry.pin, certificateSHA1: certID)
    }

    /// "msign.gov.md · Semnat · XAdES-T (SHA-1) · lot" or the failure reason.
    static func bridgeActivity(_ request: BridgeRequest, _ error: Error?) -> ActivityItem {
        let host = request.origin.flatMap { URL(string: $0)?.host } ?? "localhost"
        var what = request.format ?? "?"
        if XAdESSigner.DigestAlgorithm(requested: request.algorithm) == .sha1, request.format?.hasPrefix("XAdES") == true {
            what += " (SHA-1)"
        }
        if let document = request.documentName { what += " · \(document)" }
        if request.batchSession != nil { what += String(localized: " · lot") }
        guard let error else { return ActivityItem(title: host, subtitle: String(localized: "Semnat · \(what)"), ok: true) }
        return ActivityItem(title: host, subtitle: String(localized: "Eșuat · \(what) · \(describe(error).message)"), ok: false)
    }

    func answerConsent(approved: Bool, trust: Bool) {
        consentContinuation?.resume(returning: (approved, trust))
        consentContinuation = nil
    }

    // MARK: - Activity

    func log(_ item: ActivityItem) {
        activity.insert(item, at: 0)
        if activity.count > 100 { activity.removeLast(activity.count - 100) }
        saveActivity()
    }

    /// Recent documents: signed/verified files that are still on disk (browser requests have no file), newer than the
    /// last "Golește" in the popover. Clearing recents keeps the Activity history; that one has its own clear.
    var recentDocuments: [ActivityItem] {
        activity.filter { item in
            item.date > recentsClearedAt && (item.fileURL.map(Self.fileExists) ?? false)
        }
    }

    private(set) var recentsClearedAt = UserDefaults.standard.object(forKey: "recentsClearedAt") as? Date ?? .distantPast

    func clearRecents() {
        recentsClearedAt = Date()
        UserDefaults.standard.set(recentsClearedAt, forKey: "recentsClearedAt")
    }

    /// Forget entries whose file was moved or deleted (called when a list of them is shown).
    func pruneMissingFiles() {
        let kept = activity.filter { $0.fileURL.map(Self.fileExists) ?? true }
        guard kept.count != activity.count else { return }
        activity = kept
        saveActivity()
    }

    func clearActivity() {
        activity.removeAll()
        saveActivity()
    }

    private func saveActivity() {
        if let data = try? JSONEncoder().encode(activity) { UserDefaults.standard.set(data, forKey: "activity") }
    }

    private static func fileExists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
    }

    // MARK: - Errors (docs/09 §3.3)

    static func describe(_ error: Error) -> (message: String, recovery: String) {
        switch error {
        case CardError.wrongPIN(let remaining):
            return (String(localized: "PIN greșit"), String(localized: "Încercări rămase: \(remaining)"))
        case CardError.pinBlocked:
            return (String(localized: "PIN blocat"), String(localized: "Deblochează-l la CEV"))
        case CardError.noReader:
            return (String(localized: "Conectează cititorul"), "")
        case CardError.noCard:
            return (String(localized: "Introdu cardul în cititor"), "")
        case CardError.cardChanged:
            return (String(localized: "Cardul din cititor s-a schimbat"), String(localized: "Verifică titularul și semnează din nou"))
        case CardError.apduError(0x6985):
            return (String(localized: "Cardul a rămas într-o stare invalidă"), String(localized: "Scoate și reintrodu cardul"))
        case CardError.apduError(0x6988), CardError.macVerificationFailed:
            return (String(localized: "Sesiunea securizată s-a întrerupt"), String(localized: "Încearcă din nou"))
        case CardError.signFailed(let message) where message.hasPrefix("TSA"):
            return (String(localized: "Serviciul de marcă temporală nu răspunde"), String(localized: "Verifică conexiunea și încearcă din nou"))
        case is TrustServices.NetworkError:
            return (String(localized: "Serviciile PKI nu răspund"), String(localized: "Verifică conexiunea și încearcă din nou"))
        default:
            return (error.localizedDescription, String(localized: "Încearcă din nou"))
        }
    }
}

/// Reader chosen by the monitor, read by the transport factory on the card queue.
private final class SelectedReader: @unchecked Sendable {
    private let lock = NSLock()
    private var value: String?
    var name: String? {
        get { lock.lock(); defer { lock.unlock() }; return value }
        set { lock.lock(); value = newValue; lock.unlock() }
    }
}

private final class DecisionBox: @unchecked Sendable {
    var value: BridgeDecision = .deny
}
