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
    private var signingCards: [CardSlot]?
    var displayedCards: [CardSlot] { signingCards ?? cards }
    var selectedReaderName: String? {
        didSet { selectedReader.name = selectedCard?.reader; recomputeStatus() }
    }
    var lastAttemptsLeft: Int?

    /// The card the UI signs with: the user's pick, else the first inserted one.
    var selectedCard: CardSlot? {
        if let frozen = signingCards?.first(where: { $0.reader == selectedReaderName }) ?? signingCards?.first { return frozen }
        guard let reader = ReaderSelectionPolicy.activeReader(preferred: selectedReaderName,
                                                               available: cards.map(\.reader)) else { return nil }
        return cards.first { $0.reader == reader }
    }
    var certificate: SigningService.CertificateSummary? { selectedCard?.certificate }

    // Sign
    var signItems: [SignItem] = [] {
        didSet {
            // A changed queue starts a new review context. Keep per-document errors on
            // remaining items, but never carry a previous attempt's banner to new files.
            if oldValue.map(\.id) != signItems.map(\.id) { lastError = nil }
        }
    }
    var currentStep: SigningService.Step?
    var lastSigned: [URL] = []
    var lastError: PresentedError?

    /// Web links opened with the app are routed to the foreground iOS browser.
    var browserURL: URL?

    // Verify
    private let verification = DocumentVerificationModel()
    var verifyFile: URL? {
        get { verification.file }
        set { verification.file = newValue }
    }
    var verifiedDocuments: [(url: URL, reports: [Validator.Report])] {
        get { verification.documents }
        set { verification.documents = newValue }
    }
    var verifyReports: [Validator.Report]? {
        get { verification.reports }
        set { verification.reports = newValue }
    }

    // Sheets
    private let pinCoordinator = PINCoordinator()
    var pinRequest: PinRequest? {
        get { pinCoordinator.request }
        set { pinCoordinator.request = newValue }
    }
    private let authorization = BridgeAuthorizationCoordinator()
    var consentRequest: ConsentRequest? {
        get { authorization.request }
        set { authorization.request = newValue }
    }
    struct BridgeStampRequest: Identifiable { let id = UUID(); let url: URL; let holder: String; let origin: String? }
    var bridgeStampRequest: BridgeStampRequest?
    @ObservationIgnored private var pendingStampDecision: PDFStampDecision?
    @ObservationIgnored private let stampDecision = DecisionChannel<PDFStampDecision>()
    var browserStampsEnabled: Bool {
        get { AppPreferencesStore.defaults.bool(forKey: "browserStampsEnabled") }
        set { AppPreferencesStore.defaults.set(newValue, forKey: "browserStampsEnabled") }
    }

    // Activity + bridge
    private let library: DocumentLibraryModel
    var activity: [ActivityItem] {
        get { library.activity }
        set { library.activity = newValue }
    }
    private(set) var savedDocuments: [ActivityItem] {
        get { library.savedDocuments }
        set { library.savedDocuments = newValue }
    }
    var bridgeState: BridgeState = .stopped
    var bridgeEnabled: Bool {
        didSet {
            guard AppDistribution.browserBridge else {
                if bridgeEnabled { bridgeEnabled = false }
                stopBridge()
                return
            }
            AppPreferencesStore.defaults.set(bridgeEnabled, forKey: "bridgeEnabled")
            bridgeEnabled ? startBridge() : stopBridge()
        }
    }

    /// macOS brings the auth panel forward (the request may come from the menu bar or the browser).
    @ObservationIgnored var presentInsertedCard: (() -> Void)?
    @ObservationIgnored var presentAuthUI: (() -> Void)?

    @ObservationIgnored let fileProtection: any FileProtectionProcessing
    @ObservationIgnored let service: SigningService
    @ObservationIgnored private let certificateReader: any CertificateReading
    @ObservationIgnored private let liveDocumentSigner: any DocumentSigning
    private var documentSigner: any DocumentSigning { demoMode ? demoServices.signer : liveDocumentSigner }
    @ObservationIgnored private let liveDocumentVerifier: any DocumentVerifying
    private var documentVerifier: any DocumentVerifying { demoMode ? demoServices.verifier : liveDocumentVerifier }
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
    @ObservationIgnored private let bridgeRequests = CancellableRequestScope()
    @ObservationIgnored private var bridgeRecovery: Task<Void, Never>?
    private(set) var readers: [String] = []
    private var muteCard = false
    private var signing = false
    private var obtainingPIN: Bool { pinCoordinator.isObtaining }
    @ObservationIgnored private let batchRunner = SigningBatchRunner()
    private(set) var demoMode = false
    private var fixtureMode = false
    private var started = false
    private var readingCount = 0
    private var verifying: Bool {
        get { verification.isVerifying }
        set { verification.isVerifying = newValue }
    }
    @ObservationIgnored private let hardwareGate: DemoHardwareGate
    @ObservationIgnored private let demoServices: any DemoServiceProviding
    private var demoFiles: any DemoDocumentProviding { demoServices.files }
    @ObservationIgnored private let liveReaders: () -> [String]

    var canChangeDemoMode: Bool {
        !signing && !obtainingPIN && !verifying && readingCount == 0 &&
        pinRequest == nil && consentRequest == nil && bridgeStampRequest == nil && currentStep == nil && !fixtureMode
    }
    private var vaultRevision = 0

    /// Tray / menu-bar light (UX-01).
    var light: StatusLight {
        if signing || pinRequest != nil || consentRequest != nil || bridgeStampRequest != nil { return .busy }
        if cards.contains(where: { $0.certificate != nil }) { return .ready }
        switch status {
        case .error, .unavailable: return .error
        default: break
        }
        return readers.isEmpty ? .idle : .reader
    }

    /// Menu-bar dot (docs/10 §0.2b, UX-11): green while a card is inserted (reading, ready or signing), gray otherwise.
    var cardConnected: Bool { cards.contains { $0.problem == nil } }

    /// Only isolated Debug screenshot fixtures may hide the UI notice; real demo mode stays labelled.
    var isScreenshotCapture: Bool {
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if fixtureMode && env["MSIGN_SCREENSHOT_CAPTURE"] == "1" &&
            env["MSIGN_QA_NO_HARDWARE"] == "1" &&
            env["MSIGN_DEMO_PREFERENCES_SUITE"]?.hasPrefix("md.esemnbun.qa.") == true { return true }
        #endif
        return false
    }

    var protectionPreview: ProtectionPreview? {
        guard isScreenshotCapture else { return nil }
        return demoServices.protectionPreview(scenario: ProcessInfo.processInfo.environment["MSIGN_DEMO_SCENARIO"] ?? "")
    }

    var showsDemoNotice: Bool { demoMode && !isScreenshotCapture }

    var trayLabel: String {
        if showsDemoNotice { return "eSemnBun · \(L10n.text(.demo_banner))" }
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
        if showsDemoNotice { return L10n.text(.demo_banner) }
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
         demoServices: (any DemoServiceProviding)? = nil,
         fileProtection: (any FileProtectionProcessing)? = nil,
         transportFactory: @escaping (String?) throws -> CardTransport = AppModel.defaultTransport) {
        self.fileProtection = fileProtection ?? FileProtectionService(outputDirectory:
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Protected", isDirectory: true))
        self.service = service
        self.certificateReader = certificateReader ?? CoreCertificateReader(service: service)
        self.liveDocumentSigner = documentSigner ?? CoreDocumentSigner(service: service)
        self.liveDocumentVerifier = documentVerifier ?? CoreDocumentVerifier(service: service)
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
        self.demoServices = demoServices ?? DemoServices()
        #if DEBUG
        liveReaders = offlineQA ? { [] } : service.readersWithCards
        #else
        liveReaders = service.readersWithCards
        #endif
        self.liveActivityStore = activityStore ?? PreferencesActivityStore(defaults: AppPreferencesStore.defaults)
        self.liveVault = vault
        #if DEBUG
        self.transportFactory = offlineQA ? { _ in throw CardError.noCard } : transportFactory
        #else
        self.transportFactory = transportFactory
        #endif
        bridgeEnabled = AppDistribution.browserBridge && (AppPreferencesStore.defaults.object(forKey: "bridgeEnabled") as? Bool ?? true)
        library = DocumentLibraryModel(store: demo ? demoActivityStore : self.liveActivityStore,
                                       onDocumentsChanged: demo ? {} : { DocumentDiscovery.refresh() })
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
            lastError = PresentedError(messageText: .localized(.ui_demo_mode), recoveryText: .localized(.demo_switch_unavailable))
            return false
        }
        monitor.stop()
        monitor.onChange = nil
        stopBridge()
        authorization.resetTrust()
        demoMode = enabled
        AppPreferencesStore.defaults.set(enabled, forKey: "demoModeEnabled")
        cards = []; readers = []; selectedReaderName = nil
        signItems = []; lastSigned = []; lastError = nil
        verification.clear(); browserURL = nil
        vaultRevision += 1
        library.reload(store: activityStore,
                       onDocumentsChanged: enabled ? {} : { DocumentDiscovery.refresh() })
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

    private var pendingReaderSnapshot: ReaderMonitor.Snapshot?
    private func apply(_ snapshot: ReaderMonitor.Snapshot) {
        if signing { pendingReaderSnapshot = snapshot; return }
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
        if signing {
            // PC/SC probes can temporarily lose the card while its exclusive signing session is active.
            return
        }
        cards = next
        // Reader state can briefly become probing or empty during a signing session. Keep the
        // user's preference through that transient absence; selectedCard supplies a safe fallback.
        selectedReaderName = ReaderSelectionPolicy.preferredReader(previous: selectedReaderName,
                                                                    available: next.map(\.reader))
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
        case .success(let summary): cards[index].certificate = summary; cards[index].problemText = nil
        case .failure(let error): cards[index].problemText = Self.describe(error).messageText
        }
        recomputeStatus()
    }

    /// Fictional cards for the user-controlled demo and Debug screenshot scenarios.
    /// Opt-in, isolated simulator fixture for Safari interoperability checks. No signing or hardware.
    private var simulatorBridgeCertificates: [SigningService.CertificateSummary]? {
        #if DEBUG && targetEnvironment(simulator)
        let env = ProcessInfo.processInfo.environment
        guard fixtureMode, demoMode, env["MSIGN_SIMULATOR_BRIDGE"] == "1",
              env["MSIGN_QA_NO_HARDWARE"] == "1",
              env["MSIGN_DEMO_PREFERENCES_SUITE"]?.hasPrefix("md.esemnbun.qa.") == true,
              let encoded = env["MSIGN_SIMULATOR_CERTIFICATES"] else { return nil }
        let certificates = encoded.split(separator: ":").compactMap { value -> SigningService.CertificateSummary? in
            guard let der = Data(base64Encoded: String(value)), der.first == 0x30 else { return nil }
            let certificate = SigningService.CertificateSummary(der: der)
            return certificate.holder.hasPrefix("DEMO ") ? certificate : nil
        }
        return certificates.isEmpty ? nil : certificates
        #else
        return nil
        #endif
    }

    private func loadDemoCards(_ count: Int) {
        demoMode = true
        cards = demoServices.cards(count: count, certificates: simulatorBridgeCertificates)
        readers = cards.map(\.reader)
        #if DEBUG
        if let files = ProcessInfo.processInfo.environment["MSIGN_DEMO_FILES"] {
            if ["fixture", "fixture-single"].contains(files), isScreenshotCapture {
                let inputs = (try? demoFiles.inputs()) ?? []
                addFiles(files == "fixture-single" ? Array(inputs.prefix(1)) : inputs)
            } else {
                addFiles(files.split(separator: ":").map { URL(filePath: String($0)) })
            }
        }
        let selected = ProcessInfo.processInfo.environment["MSIGN_DEMO_SELECTED"].flatMap(Int.init) ?? 0
        selectedReaderName = cards.isEmpty ? nil : cards[min(max(selected, 0), cards.count - 1)].reader
        bridgeState = fixtureMode && AppDistribution.browserBridge ? .running : .stopped
        recomputeStatus()
        applyDemoScenario(ProcessInfo.processInfo.environment["MSIGN_DEMO_SCENARIO"] ?? "ready")
        if simulatorBridgeCertificates != nil {
            bridgeState = .stopped
            if bridgeEnabled { startBridge() }
        }
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
                self.selectedReaderName = ReaderSelectionPolicy.preferredReader(
                    previous: self.selectedReaderName, available: self.cards.map(\.reader))
                self.selectedReader.name = self.selectedCard?.reader
                self.recomputeStatus()
                FileHandle.standardOutput.write(Data("MSIGN_QA_CARD_COUNT=\(count)\n".utf8))
            }
        }
    }

    /// Presentation fixtures never connect a reader, start a listener, or submit a PIN.
    private func applyDemoScenario(_ scenario: String) {
        let state = DemoScenarioState(scenario: scenario, screenshot: isScreenshotCapture,
            cards: cards, readers: readers, status: status, items: signItems,
            holder: certificate?.holder, directory: demoFiles.directory)
        cards = state.cards
        readers = state.readers
        status = state.status
        signItems = state.signItems
        if state.recomputeReaderStatus { recomputeStatus() }
        if let step = state.currentStep { currentStep = step }
        if let outputs = state.lastSigned { lastSigned = outputs }
        if let preview = state.verification {
            verifyFile = preview.url
            verifyReports = preview.loading ? nil : preview.reports
            verifiedDocuments = preview.loading ? [] : [(preview.url, preview.reports)]
            verifying = preview.loading
        }
        if let records = state.activity {
            savedDocuments = records
            activity = records
            demoActivityStore.save(records)
            demoActivityStore.saveDocuments(records)
        }
        if let consent = state.consent { consentRequest = consent; presentAuthUI?() }
        if let pin = state.pin { pinRequest = pin; presentAuthUI?() }
    }

    #endif

    /// "Recitește cardul": forget what we know about the inserted cards and read them again.
    func rereadCards() {
        guard !demoMode, !signing else { return }
        for index in cards.indices {
            cards[index].certificate = nil
            cards[index].problemText = nil
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
                ? .error(message: .localized(.ui_the_card_does_not_respond), recovery: .localized(.ui_remove_and_re_insert_the_card))
                : .empty(reader: firstReader)
            return
        }
        if let cert = card.certificate {
            status = .ready(reader: card.reader, holder: cert.holder, validUntil: cert.notAfter)
        } else if let problem = card.problemText {
            status = .error(message: problem, recovery: .localized(.ui_remove_and_re_insert_the_card))
        } else {
            status = .reading(reader: card.reader)
        }
    }

    // MARK: - Signing

    func addFiles(_ urls: [URL]) {
        signItems += DocumentImportPolicy.newFiles(urls, excluding: signItems.map(\.url)).map(SignItem.init)
    }

    func remove(_ item: SignItem) {
        signItems.removeAll { $0.id == item.id }
    }

    /// Freezes the selected files/card before authorization. One credential is scoped to this batch;
    /// completed files leave the queue, additions remain queued, and document failures continue without retry; card and credential failures stop.
    func signAll(only itemID: UUID? = nil) async {
        if demoMode { await signDemoBatch(only: itemID); return }
        guard bridgeStampRequest == nil, !signing, !batchRunner.isRunning, let card = selectedCard, let cert = card.certificate,
              status.canSign, !signItems.isEmpty else { return }
        let items = signItems.filter { itemID == nil || $0.id == itemID }
        guard !items.isEmpty else { return }
        for index in signItems.indices where items.contains(where: { $0.id == signItems[index].id }) {
            signItems[index].signingError = nil
        }
        let context = BatchContext(reader: card.reader, certificate: cert)
        lastError = nil
        if itemID == nil { lastSigned = [] }
        signingCards = cards
        signing = true
        status = .busy(reader: context.reader, holder: cert.holder)
        defer {
            currentStep = nil
            signing = false
            if let snapshot = pendingReaderSnapshot { pendingReaderSnapshot = nil; apply(snapshot) }
            signingCards = nil
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
                                      subtitle: L10n.text(.ui_signed_value, item.format.label), ok: true, fileURL: output, signedOutput: true))
                if entry.remember && !didAttemptPINStorage {
                    didAttemptPINStorage = true
                    try? self.vault.save(entry.pin, certID: context.certificate.sha1Hex)
                }
            },
            didFail: { item, error in
                self.handleCardError(error, certID: context.certificate.sha1Hex)
                if let index = self.signItems.firstIndex(where: { $0.id == item.id }) {
                    self.signItems[index].signingError = self.lastError?.message
                }
                self.log(ActivityItem(title: item.url.lastPathComponent, subtitle: self.lastError?.message ?? L10n.text(.ui_), ok: false))
                if case CardError.cardChanged = error { self.rereadCards() }
            },
            shouldContinue: { error in
                if case CardError.signFailed = error { return true }
                return error is CocoaError || error is TrustServices.NetworkError
            }
        )
    }

    #if os(macOS) && !APP_STORE
    enum AgentSigningError: Error { case busy, noCard, cancelled }

    /// A separate foreground approval is mandatory even when a PIN is saved. The exact
    /// bytes and certificate are frozen before approval; no request can reuse this decision.
    func signAgentPDF(_ pdf: Data, name: String,
                      approve: (SigningService.CertificateSummary) async -> Bool,
                      stillAuthorized: () -> Bool, willSign: () -> Void) async throws -> Data {
        guard !demoMode, !signing, !batchRunner.isRunning, !obtainingPIN,
              consentRequest == nil, bridgeStampRequest == nil else { throw AgentSigningError.busy }
        guard let card = selectedCard, let cert = card.certificate, status.canSign else {
            throw AgentSigningError.noCard
        }
        signing = true
        signingCards = cards
        status = .busy(reader: card.reader, holder: cert.holder)
        defer {
            signing = false
            signingCards = nil
            currentStep = nil
            if let snapshot = pendingReaderSnapshot { pendingReaderSnapshot = nil; apply(snapshot) }
            recomputeStatus()
        }
        guard stillAuthorized(), await approve(cert), stillAuthorized() else { throw AgentSigningError.cancelled }
        guard let entry = await obtainPIN(certID: cert.sha1Hex, holder: cert.holder,
                                         allowRemember: false, documentNames: [name]),
              stillAuthorized() else { throw AgentSigningError.cancelled }
        let service = service
        let digest = cert.der.sha256().hexString
        willSign()
        do {
            return try await Task.detached {
                try service.signPDF(pdf, pin: entry.pin, reader: card.reader,
                                    expectedCertificateSHA1: cert.sha1Hex,
                                    expectedCertificateSHA256: digest)
            }.value
        } catch {
            handleCardError(error, certID: cert.sha1Hex)
            throw error
        }
    }
    #endif

    private func signDemoBatch(only itemID: UUID? = nil) async {
        guard !signing, status.canSign, !signItems.isEmpty else { return }
        signing = true
        lastError = nil
        if itemID == nil { lastSigned = [] }
        let batch = signItems.filter { itemID == nil || $0.id == itemID }
        let signer = documentSigner
        defer { signing = false; currentStep = nil; recomputeStatus() }
        _ = await batchRunner.run(
            items: batch, context: (), authorize: { _, _ in Optional(()) },
            sign: { item, _, _ in
                try await signer.sign(item, pin: "", reader: "", certificateSHA1: "") { [weak self] step in
                    Task { @MainActor in self?.currentStep = step }
                }
            },
            didSign: { item, output, _ in
                self.lastSigned.append(output)
                self.remove(item)
                self.log(ActivityItem(title: output.lastPathComponent, subtitle: L10n.text(.demo_simulation_complete), ok: true, fileURL: output, signedOutput: true))
            },
            didFail: { item, error in
                if let index = self.signItems.firstIndex(where: { $0.id == item.id }) {
                    self.signItems[index].signingError = Self.describe(error).message
                }
                self.lastError = Self.describe(error)
                self.log(ActivityItem(title: item.url.lastPathComponent, subtitle: Self.describe(error).message, ok: false))
            },
            shouldContinue: { error in
                if case CardError.signFailed = error { return true }
                return error is CocoaError || error is TrustServices.NetworkError
            }
        )
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
        await pinCoordinator.obtain(certID: certID, holder: holder, allowRemember: allowRemember,
                                    documentNames: documentNames, vault: vault, attemptsLeft: lastAttemptsLeft,
                                    present: { [weak self] in self?.presentAuthUI?() })
    }

    func submitPIN(_ pin: String, remember: Bool) { pinCoordinator.submitPIN(pin, remember: remember) }
    func cancelPIN() { pinCoordinator.cancelPIN() }

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

    var verificationGeneration: UUID { verification.generation }
    func clearVerification() { verification.clear() }

    func verifyFiles(_ urls: [URL]) async {
        await verification.verify(urls, using: documentVerifier) { [weak self] url, reports in
            let verdict = Verdict(reports)
            self?.log(ActivityItem(title: url.lastPathComponent, subtitle: L10n.text(.ui_verified),
                                  ok: { if case .valid = verdict { return true } else { return false } }(),
                                  fileURL: url, signedOutput: false))
        }
    }

    func verify(_ url: URL) async { await verifyFiles([url]) }

    // MARK: - Bridge (MAC-07, IOS-06)

    func startBridge() {
        guard AppDistribution.browserBridge, !demoMode || simulatorBridgeCertificates != nil else { return }
        guard server == nil else { return }
        #if os(macOS) && APP_STORE
        // Store uses the packaged identity only, without probing vendor or development paths.
        let identity = Bundle.main.url(forResource: "localhost", withExtension: "p12")
            .flatMap { try? Data(contentsOf: $0) }
        let server = MoldSignServer(tlsP12: identity, allowsFileSystemRoutes: AppDistribution.bridgeFileAccess)
        #else
        #if os(macOS)
        let legacyDesktop = AppPreferencesStore.defaults.bool(forKey: "legacyDesktopClientEnabled")
        #else
        let legacyDesktop = false
        #endif
        let server = MoldSignServer(allowsFileSystemRoutes: simulatorBridgeCertificates == nil && AppDistribution.bridgeFileAccess,
                                    allowsLegacyDesktopClient: legacyDesktop,
                                    previewCertificates: simulatorBridgeCertificates)
        #endif
        // UserDefaults reads are thread-safe; the setting must also apply to cached batches.
        server.previewPDFEnabled = { AppPreferencesStore.defaults.bool(forKey: "browserStampsEnabled") }
        server.previewPDF = { [weak self, weak server] request, data in
            let answer = StampDecisionBox()
            let done = DispatchSemaphore(value: 0)
            Task { @MainActor in
                if let self, let server, self.server === server {
                    answer.value = await self.bridgeRequests.run(fallback: .cancel) {
                        await self.previewBridgePDF(request, data: data)
                    }
                }
                done.signal()
            }
            done.wait(); return answer.value
        }
        server.authorize = { [weak self, weak server] request in
            let box = BridgeDecisionBox()
            let done = DispatchSemaphore(value: 0)
            Task { @MainActor in
                if let self, let server, self.server === server {
                    box.value = await self.bridgeRequests.run(fallback: .deny) { await self.authorize(request) }
                }
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
                guard let error, let certID = request.certificateSHA1 ?? self.certificate?.sha1Hex else { return }
                switch error {
                case CardError.wrongPIN, CardError.pinBlocked: self.handleCardError(error, certID: certID)
                default: break
                }
            }
        }
        server.onListenerError = { [weak self, weak server] _, error in
            Task { @MainActor in
                guard let self, let server, self.server === server, !self.demoMode || self.simulatorBridgeCertificates != nil else { return }
                self.bridgeState = MoldSignServer.isAddressInUse(error) ? .portBusy : .failed("\(error)")
                if self.bridgeState == .portBusy { self.scheduleBridgeRecovery() }
            }
        }
        do {
            // Government portals use HTTPS on localhost.cts.md:18443 on both Apple platforms.
            // Refuse HTTP-only startup so a missing identity cannot look like a working bridge.
            try server.start(requireHTTPS: true)
            bridgeState = .running
            self.server = server
        } catch {
            bridgeState = MoldSignServer.isAddressInUse(error) ? .portBusy : .failed(error.localizedDescription)
            if bridgeState == .portBusy { scheduleBridgeRecovery() }
        }
    }

    private func scheduleBridgeRecovery() {
        guard bridgeRecovery == nil else { return }
        bridgeRecovery = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(3)) } catch { return }
                guard let self, self.bridgeEnabled, !self.demoMode, self.bridgeState == .portBusy else { break }
                self.server?.stop()
                self.server = nil
                self.startBridge()
            }
            self?.bridgeRecovery = nil
        }
    }

    func stopBridge() {
        bridgeRequests.cancelAll()
        pendingStampDecision = nil
        answerBridgeStamp(.cancel)
        bridgeRecovery?.cancel()
        bridgeRecovery = nil
        server?.stop()
        server = nil
        bridgeState = .stopped
    }

    /// Consent (unless the origin is trusted for 10 minutes), then the PIN unless the page sent one.
    private func previewBridgePDF(_ request: BridgeRequest, data: Data) async -> PDFStampDecision {
        guard browserStampsEnabled else { return .proceed(nil) }
        guard !demoMode, !signing, !stampDecision.isPending, pinRequest == nil, consentRequest == nil else { return .cancel }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            defer { try? FileManager.default.removeItem(at: folder) }
            let url = folder.appendingPathComponent("document.pdf")
            try data.write(to: url)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
            return await stampDecision.request(fallback: .cancel, present: {
                bridgeStampRequest = BridgeStampRequest(url: url, holder: request.certificateHolder ?? certificate?.holder ?? "", origin: request.origin)
                presentAuthUI?()
            }, dismiss: { [weak self] in self?.bridgeStampRequest = nil })
        } catch { return .cancel }
    }

    func answerBridgeStamp(_ decision: PDFStampDecision, afterDismissal: Bool = false) {
        if afterDismissal { pendingStampDecision = decision; bridgeStampRequest = nil; return }
        bridgeStampRequest = nil
        stampDecision.resolve(decision)
    }

    private func authorize(_ request: BridgeRequest) async -> BridgeDecision {
        guard !demoMode, !signing, !obtainingPIN, consentRequest == nil else { return .deny }
        let target = request.certificateSHA1.flatMap { sha in cards.first { $0.certificate?.sha1Hex == sha }?.certificate }
            ?? (request.certificateSHA1 == nil ? certificate : nil)
        return await authorization.authorize(request, target: target, vault: vault,
            present: { [weak self] in self?.presentAuthUI?() },
            obtainPIN: { [weak self] certID, holder in
                await self?.obtainPIN(certID: certID, holder: holder, allowRemember: false)?.pin
            })
    }

    func finishBridgeStampDismissal() {
        let decision = pendingStampDecision ?? .cancel; pendingStampDecision = nil
        answerBridgeStamp(decision)
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
        authorization.answer(approved: approved, trust: trust)
    }

    // MARK: - Activity

    /// Details are checked independently of the Verify workspace and do not create a history entry.
    func inspectDocument(_ url: URL, companions: [URL] = []) async throws -> [Validator.Report] {
        #if DEBUG
        if isScreenshotCapture {
            return ScreenshotFixtures.reports(ProcessInfo.processInfo.environment["MSIGN_DEMO_SCENARIO"] ?? "documents-valid")
        }
        #endif
        return try await documentVerifier.inspect(url, companions: companions)
    }

    func log(_ item: ActivityItem) { library.log(item) }
    var recentDocuments: [ActivityItem] { library.recentDocuments }
    var recentsClearedAt: Date { library.recentsClearedAt }
    func clearRecents() { library.clearRecents() }
    func pruneMissingFiles() { library.pruneMissingFiles() }
    func deleteSavedDocuments(_ items: [ActivityItem]) -> Bool { library.deleteSavedDocuments(items) }
    func clearActivity() { library.clearActivity() }

    // MARK: - Errors (docs/09 §3.3)

    static func describe(_ error: Error) -> PresentedError {
        switch error {
        case CardError.wrongPIN(let remaining):
            return PresentedError(messageText: .localized(.ui_incorrect_pin), recoveryText: .count(.ui_attempts_left_count, remaining))
        case CardError.pinBlocked:
            return PresentedError(messageText: .localized(.ui_pin_blocked), recoveryText: .localized(.ui_unblock_it_at_cev))
        case CardError.noReader:
            return PresentedError(messageText: .localized(.ui_connect_the_reader), recoveryText: .localized(.ui_))
        case CardError.noCard:
            return PresentedError(messageText: .localized(.ui_insert_the_card), recoveryText: .localized(.ui_))
        case CardError.cardChanged:
            return PresentedError(messageText: .localized(.ui_the_card_in_the_reader_changed), recoveryText: .localized(.ui_check_the_holder_and_sign_again))
        case CardError.apduError(0x6985):
            return PresentedError(messageText: .localized(.ui_the_card_is_in_an_invalid_state), recoveryText: .localized(.ui_remove_and_re_insert_the_card))
        case CardError.apduError(0x6988), CardError.macVerificationFailed:
            return PresentedError(messageText: .localized(.ui_the_secure_session_was_interrupted), recoveryText: .localized(.ui_try_again))
        case CardError.signFailed(let message) where message.hasPrefix("TSA"):
            return PresentedError(messageText: .localized(.ui_the_timestamp_service_is_not_responding), recoveryText: .localized(.ui_check_the_connection_and_try_again))
        case CardError.signFailed:
            return PresentedError(messageText: .verbatim("This document could not be signed. It may be damaged or use an unsupported format."), recoveryText: .verbatim(""))
        case is TrustServices.NetworkError:
            return PresentedError(messageText: .localized(.ui_pki_services_are_not_responding), recoveryText: .localized(.ui_check_the_connection_and_try_again))
        default:
            return PresentedError(messageText: .verbatim(error.localizedDescription), recoveryText: .localized(.ui_try_again))
        }
    }
}
