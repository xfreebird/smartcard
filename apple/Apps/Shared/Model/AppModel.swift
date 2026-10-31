import SwiftUI
import MoldSignKit
#if APP_STORE
import CryptoTokenKit
#endif

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

    /// Web links opened with the app are routed to the foreground iOS browser.
    var browserURL: URL?

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
            AppPreferencesStore.defaults.set(bridgeEnabled, forKey: "bridgeEnabled")
            bridgeEnabled ? startBridge() : stopBridge()
        }
    }

    /// macOS brings the auth panel forward (the request may come from the menu bar or the browser).
    @ObservationIgnored var presentInsertedCard: (() -> Void)?
    @ObservationIgnored var presentAuthUI: (() -> Void)?

    @ObservationIgnored let service: SigningService
    @ObservationIgnored private let certificateReader: any CertificateReading
    @ObservationIgnored private let documentSigner: any DocumentSigning
    @ObservationIgnored private let documentVerifier: any DocumentVerifying
    @ObservationIgnored private let liveActivityStore: any ActivityStoring
    @ObservationIgnored private let demoActivityStore = MemoryActivityStore()
    private var activityStore: any ActivityStoring { demoMode ? demoActivityStore : liveActivityStore }
    @ObservationIgnored private let liveVault: any PinStoring
    @ObservationIgnored private let demoVault = MemoryPinVault()
    var vault: any PinStoring { demoMode ? demoVault : liveVault }
    @ObservationIgnored private let monitor: any ReaderMonitoring
    @ObservationIgnored private let transportFactory: (String?) throws -> CardTransport
    @ObservationIgnored private let selectedReader = SelectedReader()
    @ObservationIgnored private var server: MoldSignServer?
    @ObservationIgnored private var pinContinuation: CheckedContinuation<(pin: String, remember: Bool)?, Never>?
    @ObservationIgnored private var consentContinuation: CheckedContinuation<(approved: Bool, trust: Bool), Never>?
    @ObservationIgnored private var trustedUntil: [String: Date] = [:]
    private(set) var readers: [String] = []
    private var muteCard = false
    private var signing = false
    private var obtainingPIN = false
    @ObservationIgnored private let batchRunner = SigningBatchRunner()
    private(set) var demoMode = false
    private var fixtureMode = false
    private var started = false
    private var readingCount = 0
    private var verifying = false
    @ObservationIgnored private let hardwareGate: DemoHardwareGate
    @ObservationIgnored private let demoFiles: DemoDocumentFiles
    @ObservationIgnored private let liveReaders: () -> [String]

    var canChangeDemoMode: Bool {
        !signing && !obtainingPIN && !verifying && readingCount == 0 &&
        pinRequest == nil && consentRequest == nil && currentStep == nil && !fixtureMode
    }
    private var vaultRevision = 0

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
        if demoMode { return "eSemnBun · \(L10n.text(.demo_banner))" }
        if cardConnected {
            let holder = certificate?.holder ?? cards.compactMap(\.certificate).first?.holder
            return holder.map { L10n.text(.ui_esemnbun_card_connected_value, $0) } ?? L10n.text(.ui_esemnbun_card_connected)
        }
        switch status {
        case .error, .unavailable: return "eSemnBun · \(status.title)"
        default: return L10n.text(.ui_esemnbun_no_card_connected)
        }
    }

    /// Text twin of `light` (tooltip, VoiceOver).
    var lightLabel: String {
        if demoMode { return L10n.text(.demo_banner) }
        switch light {
        case .ready:
            let ready = cards.compactMap(\.certificate)
            let holder = certificate?.holder ?? ready.first?.holder ?? L10n.text(.ui_)
            return ready.count > 1 ? L10n.text(.ui_card_ready_count_count_cards, holder, ready.count)
                                   : L10n.text(.ui_card_ready_value, holder)
        case .reader: return L10n.text(.ui_reader_connected_insert_the_card)
        case .busy: return L10n.text(.ui_signing)
        case .error: return status.title
        case .idle: return L10n.text(.ui_connect_the_reader)
        }
    }

    init(service: SigningService = .shared, monitor: any ReaderMonitoring = ReaderMonitor(),
         vault: any PinStoring = PinVault(),
         certificateReader: (any CertificateReading)? = nil,
         documentSigner: (any DocumentSigning)? = nil,
         documentVerifier: (any DocumentVerifying)? = nil,
         activityStore: (any ActivityStoring)? = nil,
         transportFactory: @escaping (String?) throws -> CardTransport = AppModel.defaultTransport) {
        self.service = service
        self.certificateReader = certificateReader ?? CoreCertificateReader(service: service)
        self.documentSigner = documentSigner ?? CoreDocumentSigner(service: service)
        self.documentVerifier = documentVerifier ?? CoreDocumentVerifier(service: service)
        #if DEBUG
        let offlineQA = ProcessInfo.processInfo.environment["MSIGN_QA_NO_HARDWARE"] == "1" &&
            ProcessInfo.processInfo.environment["MSIGN_DEMO_PREFERENCES_SUITE"]?.hasPrefix("md.esemnbun.qa.") == true
        self.monitor = offlineQA ? MockReaderMonitor() : monitor
        #else
        self.monitor = monitor
        #endif
        #if DEBUG
        let fixture = ProcessInfo.processInfo.environment["MSIGN_DEMO_CARDS"] != nil
        #else
        let fixture = false
        #endif
        let demo = fixture || AppPreferencesStore.defaults.bool(forKey: "demoModeEnabled")
        fixtureMode = fixture
        demoMode = demo
        hardwareGate = DemoHardwareGate(demo: demo)
        demoFiles = DemoDocumentFiles(directory: FileManager.default.temporaryDirectory
            .appendingPathComponent("eSemnBun-demo-\(UUID().uuidString)", isDirectory: true), notice: L10n.text(.demo_output_notice))
        #if DEBUG
        liveReaders = offlineQA ? { [] } : service.readersWithCards
        #else
        liveReaders = service.readersWithCards
        #endif
        self.liveActivityStore = activityStore ?? PreferencesActivityStore()
        self.liveVault = vault
        #if DEBUG
        self.transportFactory = offlineQA ? { _ in throw CardError.noCard } : transportFactory
        #else
        self.transportFactory = transportFactory
        #endif
        bridgeEnabled = AppPreferencesStore.defaults.object(forKey: "bridgeEnabled") as? Bool ?? true
        activity = self.activityStore.load()
        recentsClearedAt = self.activityStore.recentsClearedAt
        pruneMissingFiles()
    }

    nonisolated static func defaultTransport(_ reader: String?) throws -> CardTransport {
        #if APP_STORE
        return try TKSmartCardTransport.connect(slotName: reader)
        #else
        return try CardTransports.connect(reader: reader)
        #endif
    }

    func start() {
        guard !started else { return }
        started = true
        MSLog.sink = nil   // SEC-04: no SM traces or session keys in app logs
        let selected = selectedReader
        let connect = transportFactory
        let gate = hardwareGate
        service.transportFactory = { reader in
            guard gate.begin() else { throw CardError.noCard }
            do { return GatedCardTransport(base: try connect(reader ?? selected.name), gate: gate) }
            catch { gate.end(); throw error }
        }
        let readers = liveReaders
        service.readersWithCards = {
            guard gate.begin() else { return [] }
            defer { gate.end() }
            #if APP_STORE
            guard let manager = TKSmartCardSlotManager.default else { return [] }
            return manager.slotNames.filter { manager.slotNamed($0)?.state == .validCard }
            #else
            return readers()
            #endif
        }
        if demoMode {
            #if DEBUG
            if let demo = ProcessInfo.processInfo.environment["MSIGN_DEMO_CARDS"] {
                loadDemoCards(min(max(Int(demo == "none" ? "0" : demo) ?? 0, 0), 8))
                runDemoCardTransitionsIfRequested()
                return
            }
            #endif
            loadDemoCards(2)
            signItems = (try? demoFiles.inputs().map(SignItem.init)) ?? []
            return
        }
        startLiveMonitoring()
    }

    private func startLiveMonitoring() {
        monitor.onChange = { [weak self] snapshot in self?.apply(snapshot) }
        monitor.start()
        if bridgeEnabled { startBridge() }
    }

    /// The transport gate rejects changing modes while a connected operation is active. No pending
    /// PIN/consent, selected real input, credentials or demo results cross this boundary.
    @discardableResult
    func setDemoMode(_ enabled: Bool) -> Bool {
        guard enabled != demoMode else { return true }
        guard canChangeDemoMode, hardwareGate.changeMode(demo: enabled) else {
            lastError = (L10n.text(.ui_demo_mode), L10n.text(.demo_switch_unavailable))
            return false
        }
        monitor.stop()
        monitor.onChange = nil
        stopBridge()
        trustedUntil.removeAll()
        demoMode = enabled
        AppPreferencesStore.defaults.set(enabled, forKey: "demoModeEnabled")
        cards = []; readers = []; selectedReaderName = nil
        signItems = []; lastSigned = []; lastError = nil
        verifyFile = nil; verifyReports = nil; browserURL = nil
        vaultRevision += 1
        activity = activityStore.load()
        recentsClearedAt = activityStore.recentsClearedAt
        if enabled {
            loadDemoCards(2)
            signItems = (try? demoFiles.inputs().map(SignItem.init)) ?? []
        } else {
            status = .noReader
            startLiveMonitoring()
        }
        return true
    }

    // MARK: - Reader state

    private func apply(_ snapshot: ReaderMonitor.Snapshot) {
        guard !demoMode else { return }
        guard snapshot.available else { status = .unavailable; return }
        let previousReaders = Set(readers)
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
        if (!toRead.isEmpty || !Set(readers).subtracting(previousReaders).isEmpty),
           AppPreferencesStore.defaults.bool(forKey: "openOnCardInsertion") { presentInsertedCard?() }
    }

    /// PIN-less certificate read so the UI can greet the holder (MAC-02). Ignored if the card changed meanwhile.
    private func readCertificate(of card: CardSlot) async {
        guard !demoMode else { return }
        readingCount += 1
        defer { readingCount -= 1 }
        let reader = card.reader
        let result: Result<SigningService.CertificateSummary, Error>
        do { result = .success(try await certificateReader.readCertificate(reader: reader)) }
        catch { result = .failure(error) }
        guard let index = cards.firstIndex(where: { $0.reader == reader && $0.generation == card.generation }) else { return }
        switch result {
        case .success(let summary): cards[index].certificate = summary; cards[index].problem = nil
        case .failure(let error): cards[index].problem = Self.describe(error).message
        }
        recomputeStatus()
    }

    /// Fictional cards for the user-controlled demo and Debug screenshot scenarios.
    private func loadDemoCards(_ count: Int) {
        demoMode = true
        let holders = ["Popescu Ion", L10n.text(.ui_mindru_stefan), "Rusu Ana"]   // CN order on Moldovan certificates
        readers = (0..<count).map { $0 == 0 ? "bit4id miniLector POCKET EVO" : "bit4id miniLector POCKET EVO 0\($0)" }
        cards = readers.enumerated().map { index, reader in
            let sha = String(format: "%02x", Int(UInt8(truncatingIfNeeded: index * 97 + 20))) + String(repeating: "0", count: 38)
            let cert = SigningService.CertificateSummary(
                der: Data(), holder: holders[index % holders.count], subjectDN: "CN=\(holders[index % holders.count]),C=MD",
                issuer: "CN=MDQSign,C=MD", issuerName: "MDQSign", serialDecimal: "1298074214877499210738125554536943",
                sha1Hex: sha, notAfter: Calendar.current.date(byAdding: .year, value: 4 - index, to: Date()))
            return CardSlot(reader: reader, generation: 1, certificate: cert)
        }
        #if DEBUG
        if let files = ProcessInfo.processInfo.environment["MSIGN_DEMO_FILES"] {
            addFiles(files.split(separator: ":").map { URL(filePath: String($0)) })
        }
        let selected = ProcessInfo.processInfo.environment["MSIGN_DEMO_SELECTED"].flatMap(Int.init) ?? 0
        selectedReaderName = cards.isEmpty ? nil : cards[min(max(selected, 0), cards.count - 1)].reader
        bridgeState = fixtureMode ? .running : .stopped
        recomputeStatus()
        applyDemoScenario(ProcessInfo.processInfo.environment["MSIGN_DEMO_SCENARIO"] ?? "ready")
        FileHandle.standardOutput.write(Data("MSIGN_DEMO_READY\n".utf8))
        #else
        selectedReaderName = cards.first?.reader
        bridgeState = .stopped
        recomputeStatus()
        #endif
    }

    #if DEBUG
    /// Exercise reader removal/reinsertion against a rendered wallet without touching hardware.
    /// Only an explicitly isolated QA fixture can enable the sequence.
    private func runDemoCardTransitionsIfRequested() {
        let environment = ProcessInfo.processInfo.environment
        guard environment["MSIGN_QA_NO_HARDWARE"] == "1",
              environment["MSIGN_DEMO_CARD_TRANSITIONS"] == "1",
              environment["MSIGN_DEMO_PREFERENCES_SUITE"]?.hasPrefix("md.esemnbun.qa.") == true,
              cards.count >= 3 else { return }
        let initialCards = cards
        Task { @MainActor in
            for count in [2, 1, 0, 3] {
                try? await Task.sleep(for: .seconds(2))
                guard self.demoMode else { return }
                self.cards = Array(initialCards.prefix(count))
                self.readers = self.cards.map(\.reader)
                if !self.cards.contains(where: { $0.reader == self.selectedReaderName }) {
                    self.selectedReaderName = self.cards.first?.reader
                }
                self.recomputeStatus()
                FileHandle.standardOutput.write(Data("MSIGN_QA_CARD_COUNT=\(count)\n".utf8))
            }
        }
    }

    /// Presentation fixtures never connect a reader, start a listener, or submit a PIN.
    private func applyDemoScenario(_ scenario: String) {
        switch scenario {
        case "no-reader": cards = []; readers = []; status = .noReader
        case "empty-reader": cards = []; readers = ["USB demo reader"]; status = .empty(reader: readers[0])
        case "unavailable": cards = []; readers = []; status = .unavailable
        case "reading":
            if !cards.isEmpty { cards[0].certificate = nil; recomputeStatus() }
        case "error":
            if !cards.isEmpty {
                cards[0].certificate = nil
                cards[0].problem = L10n.text(.ui_the_card_does_not_respond)
                recomputeStatus()
            }
        case "signing": currentStep = .timestamping
        case "success":
            lastSigned = signItems.map(\.url)
            signItems = []
        case "pin":
            pinRequest = PinRequest(holder: certificate?.holder ?? "Popescu Ion", attemptsLeft: 3, canRemember: true,
                                    documentNames: signItems.map { $0.url.lastPathComponent })
            presentAuthUI?()
        default: break
        }
    }
    #endif

    /// "Recitește cardul": forget what we know about the inserted cards and read them again.
    func rereadCards() {
        guard !demoMode else { return }
        for index in cards.indices {
            cards[index].certificate = nil
            cards[index].problem = nil
        }
        recomputeStatus()
        for card in cards { Task { await readCertificate(of: card) } }
    }

    func selectCard(_ reader: String) {
        guard selectedReaderName != reader else { return }
        selectedReaderName = reader
    }

    private func recomputeStatus() {
        guard !signing else { return }
        guard let firstReader = readers.first else { status = .noReader; return }
        guard let card = selectedCard else {
            status = muteCard
                ? .error(message: L10n.text(.ui_the_card_does_not_respond), recovery: L10n.text(.ui_remove_and_re_insert_the_card))
                : .empty(reader: firstReader)
            return
        }
        if let cert = card.certificate {
            status = .ready(reader: card.reader, holder: cert.holder, validUntil: cert.notAfter)
        } else if let problem = card.problem {
            status = .error(message: problem, recovery: L10n.text(.ui_remove_and_re_insert_the_card))
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

    /// Freezes the selected files/card before authorization. One credential is scoped to this batch;
    /// completed files leave the queue, additions remain queued, and any failure stops without retry.
    func signAll() async {
        if demoMode { await signDemoBatch(); return }
        guard !signing, !batchRunner.isRunning, let card = selectedCard, let cert = card.certificate,
              status.canSign, !signItems.isEmpty else { return }
        let items = signItems
        let context = BatchContext(reader: card.reader, certificate: cert)
        lastError = nil
        lastSigned = []
        signing = true
        status = .busy(reader: context.reader, holder: cert.holder)
        defer {
            currentStep = nil
            signing = false
            recomputeStatus()
        }
        var didAttemptPINStorage = false
        _ = await batchRunner.run(
            items: items, context: context,
            authorize: { context, batch in
                await self.obtainPIN(certID: context.certificate.sha1Hex, holder: context.certificate.holder,
                                     allowRemember: true, documentNames: batch.map { $0.url.lastPathComponent })
            },
            sign: { item, context, entry in
                // The core checks this original certificate before every VERIFY, including after a card swap.
                try await self.sign(item, pin: entry.pin, reader: context.reader,
                                    certificateSHA1: context.certificate.sha1Hex)
            },
            didSign: { item, output, entry in
                self.lastSigned.append(output)
                self.remove(item)
                self.log(ActivityItem(title: output.lastPathComponent,
                                      subtitle: L10n.text(.ui_signed_value, item.format.label), ok: true, fileURL: output))
                if entry.remember && !didAttemptPINStorage {
                    didAttemptPINStorage = true
                    try? self.vault.save(entry.pin, certID: context.certificate.sha1Hex)
                }
            },
            didFail: { item, error in
                self.handleCardError(error, certID: context.certificate.sha1Hex)
                self.log(ActivityItem(title: item.url.lastPathComponent, subtitle: self.lastError?.message ?? L10n.text(.ui_), ok: false))
                if case CardError.cardChanged = error { self.rereadCards() }
            }
        )
    }

    private func signDemoBatch() async {
        guard !signing, status.canSign, !signItems.isEmpty else { return }
        signing = true
        lastError = nil; lastSigned = []
        let batch = signItems
        let signer = DemoDocumentSigner(files: demoFiles)
        defer { signing = false; currentStep = nil; recomputeStatus() }
        for item in batch {
            do {
                let output = try await signer.sign(item, pin: "", reader: "", certificateSHA1: "") { [weak self] step in
                    Task { @MainActor in self?.currentStep = step }
                }
                lastSigned.append(output)
                remove(item)
                log(ActivityItem(title: output.lastPathComponent, subtitle: L10n.text(.demo_simulation_complete), ok: true, fileURL: output))
            } catch {
                lastError = (L10n.text(.ui_demo_mode), L10n.text(.demo_output_notice))
                break
            }
        }
    }

    private struct BatchContext {
        let reader: String
        let certificate: SigningService.CertificateSummary
    }

    private func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String) async throws -> URL {
        try await documentSigner.sign(item, pin: pin, reader: reader, certificateSHA1: certificateSHA1) { [weak self] step in
            Task { @MainActor in self?.currentStep = step }
        }
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

    private func obtainPIN(certID: String, holder: String, allowRemember: Bool,
                           documentNames: [String] = []) async -> (pin: String, remember: Bool)? {
        // A browser request may arrive while the manual batch is authorizing. Never replace its continuation.
        guard !obtainingPIN else { return nil }
        obtainingPIN = true
        defer { obtainingPIN = false }
        let reason: String
        if documentNames.isEmpty {
            reason = L10n.text(.ui_signing_with_certificate_value, holder)
        } else {
            let action = documentNames.count == 1 ? L10n.text(.ui_sign)
                : L10n.text(.ui_sign_count_documents, documentNames.count)
            reason = [action, documentNames.joined(separator: ", "), holder].joined(separator: " · ")
        }
        if vault.hasPIN(certID: certID) {
            // Cancelling device-owner authentication cancels this batch instead of opening another prompt.
            guard let stored = await vault.load(certID: certID, reason: reason) else { return nil }
            return (stored, false)
        }
        return await withCheckedContinuation { continuation in
            pinContinuation = continuation
            pinRequest = PinRequest(holder: holder, attemptsLeft: lastAttemptsLeft,
                                    canRemember: allowRemember, documentNames: documentNames)
            presentAuthUI?()
        }
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
        if let cert = certificate { forgetPIN(certID: cert.sha1Hex) }
    }

    func forgetPIN(certID: String) {
        vault.delete(certID: certID)
        vaultRevision += 1
    }

    var hasStoredPIN: Bool {
        _ = vaultRevision
        return certificate.map { vault.hasPIN(certID: $0.sha1Hex) } ?? false
    }

    // MARK: - Verify

    func verify(_ url: URL) async {
        guard !verifying else { return }
        verifying = true
        defer { verifying = false }
        if demoMode {
            verifyFile = url
            verifyReports = await DemoDocumentVerifier().verify(url)
            return
        }
        verifyFile = url
        verifyReports = nil
        let reports = await documentVerifier.verify(url)
        verifyReports = reports
        let verdict = Verdict(reports)
        log(ActivityItem(title: url.lastPathComponent, subtitle: L10n.text(.ui_verified),
                         ok: { if case .valid = verdict { return true } else { return false } }(), fileURL: url))
    }

    // MARK: - Bridge (MAC-07, IOS-06)

    func startBridge() {
        guard !demoMode else { return }
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
                guard let self, !self.demoMode else { return }
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
                guard let self, !self.demoMode else { return }
                self.bridgeState = MoldSignServer.isAddressInUse(error) ? .portBusy : .failed("\(error)")
            }
        }
        do {
            #if os(macOS)
            // msign.gov.md only talks to https://localhost.cts.md:18443; http alone looks like "no identities".
            try server.start(requireHTTPS: true)
            #else
            try server.start()
            #endif
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
        guard !demoMode else { return .deny }
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
        if request.batchSession != nil { what += L10n.text(.ui_batch) }
        guard let error else { return ActivityItem(title: host, subtitle: L10n.text(.ui_signed_value, what), ok: true) }
        return ActivityItem(title: host, subtitle: L10n.text(.ui_failed_value_value, what, describe(error).message), ok: false)
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

    private(set) var recentsClearedAt = Date.distantPast

    func clearRecents() {
        recentsClearedAt = Date()
        activityStore.recentsClearedAt = recentsClearedAt
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
        activityStore.save(activity)
    }

    private static func fileExists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
    }

    // MARK: - Errors (docs/09 §3.3)

    static func describe(_ error: Error) -> (message: String, recovery: String) {
        switch error {
        case CardError.wrongPIN(let remaining):
            return (L10n.text(.ui_incorrect_pin), L10n.text(.ui_attempts_left_count, remaining))
        case CardError.pinBlocked:
            return (L10n.text(.ui_pin_blocked), L10n.text(.ui_unblock_it_at_cev))
        case CardError.noReader:
            return (L10n.text(.ui_connect_the_reader), L10n.text(.ui_))
        case CardError.noCard:
            return (L10n.text(.ui_insert_the_card), L10n.text(.ui_))
        case CardError.cardChanged:
            return (L10n.text(.ui_the_card_in_the_reader_changed), L10n.text(.ui_check_the_holder_and_sign_again))
        case CardError.apduError(0x6985):
            return (L10n.text(.ui_the_card_is_in_an_invalid_state), L10n.text(.ui_remove_and_re_insert_the_card))
        case CardError.apduError(0x6988), CardError.macVerificationFailed:
            return (L10n.text(.ui_the_secure_session_was_interrupted), L10n.text(.ui_try_again))
        case CardError.signFailed(let message) where message.hasPrefix("TSA"):
            return (L10n.text(.ui_the_timestamp_service_is_not_responding), L10n.text(.ui_check_the_connection_and_try_again))
        case is TrustServices.NetworkError:
            return (L10n.text(.ui_pki_services_are_not_responding), L10n.text(.ui_check_the_connection_and_try_again))
        default:
            return (error.localizedDescription, L10n.text(.ui_try_again))
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
