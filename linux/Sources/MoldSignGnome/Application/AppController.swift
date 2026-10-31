import CAdwaita
import Dispatch
import Foundation
import MoldSignKit

/// App state and flows for the GNOME app; the GTK counterpart of apple/Apps/Shared/Model/AppModel.swift.
///
/// Threading: every property is read and written on the GTK main thread only. Card, vault and
/// validation work runs on background queues and comes back through `onMain` (GLib main loop,
/// not DispatchQueue.main). The core serializes card access itself (one card operation at a time).
final class AppController {
    // Readers / cards (several eID cards can be connected)
    private(set) var status: ReaderStatus { get { readers.status } set { readers.status = newValue } }
    private(set) var cards: [CardSlot] { get { readers.cards } set { readers.cards = newValue } }
    var selectedReaderName: String? { readers.selectedReaderName }
    private(set) var lastAttemptsLeft: Int?

    /// The card the UI signs with: the user's pick, else the first inserted one.
    var selectedCard: CardSlot? { cards.first { $0.reader == selectedReaderName } ?? cards.first }
    var certificate: SigningService.CertificateSummary? { selectedCard?.certificate }
    var hasStoredPIN: Bool { selectedCard?.hasStoredPIN ?? false }

    // Sign
    private(set) var signItems: [SignItem] = []
    private(set) var isSigning = false
    private(set) var currentStep: UIStep?
    private(set) var lastSigned: [URL] = []
    private(set) var lastError: (message: String, recovery: String)?

    // Verify
    private(set) var verifyFile: URL?
    private(set) var verifyReports: [SignatureReport]?

    // Activity, settings, bridge, PIN vault
    /// Pruned on load: entries whose file was deleted or moved are dropped (browser requests stay).
    private(set) var activity: [ActivityItem] = Store.loadActivity().filter(\.isShowable)
    var settings: AppSettings { preferences.settings }
    private let preferences: SettingsCoordinator
    var bridgeState: BridgeState { bridge.state }
    private(set) var vaultProblem: String?
    /// A browser request was approved and the card is signing it (blue status light until `onSignResult`).
    private(set) var bridgeSigning = false

    /// docs/10 §0.1 five-state status light, shown in the window (Sign page action bar, UX-01).
    var statusLight: StatusLight {
        StatusLight.from(status: status, cardCount: cards.count, busy: isSigning || bridgeSigning)
    }

    /// docs/10 §0.2b two-state status for the Background portal (UX-11).
    var trayStatus: TrayStatus {
        TrayStatus.from(cards: cards, selected: selectedCard, status: status)
    }

    // UI hooks, installed by MainWindow (all called on the main thread).
    var askPIN: ((PinRequest, @escaping (PinEntry?) -> Void) -> Void)?
    var askConsent: ((ConsentRequest, @escaping (_ approved: Bool, _ trust: Bool) -> Void) -> Void)?
    var askConfirm: ((_ heading: String, _ body: String, _ action: String, @escaping (Bool) -> Void) -> Void)?
    var toast: ((String) -> Void)?
    /// Toast with one button, e.g. "Document semnat" + "Arată".
    var toastWithAction: ((_ text: String, _ button: String, _ action: @escaping () -> Void) -> Void)?
    var presentWindow: (() -> Void)?
    var configureLoginStartup: ((Bool, @escaping (Bool) -> Void) -> Void)?
    private(set) var configuringLoginStartup = false
    /// Shows a file in the file manager (OpenURI portal / FileManager1).
    var reveal: ((URL) -> Void)?

    let service: SigningService
    private let vault: any PINStoring
    private let readers: ReaderSession
    private let batchSigner: any BatchSigning
    private let documentVerifier: any DocumentVerifying

    init(service: SigningService = .shared, vault: any PINStoring = PinVault(),
         monitor: any CardMonitoring = ReaderMonitor(),
         transportFactory: ((String?) throws -> CardTransport)? = nil,
         batchSigner: (any BatchSigning)? = nil, documentVerifier: (any DocumentVerifying)? = nil,
         settingsStore: any SettingsStoring = JSONSettingsStore(), bridge: any BridgeHosting = BridgeHost()) {
        self.bridge = bridge
        self.preferences = SettingsCoordinator(store: settingsStore)
        self.batchSigner = batchSigner ?? BatchSigningService(signer: DocumentSigner(service: service), vault: vault)
        self.documentVerifier = documentVerifier ?? DocumentVerifier(service: service)
        self.service = service
        self.vault = vault
        self.readers = ReaderSession(service: service, vault: vault, monitor: monitor, transportFactory: transportFactory)
        readers.isBusy = { [weak self] in self?.isSigning ?? false }
        readers.onChange = { [weak self] in self?.changed() }
        readers.onInsertion = { [weak self] in self?.presentWindow?() }
        readers.onSelection = { [weak self] in self?.lastAttemptsLeft = nil }
        readers.showOnCardInsertion = { [weak self] in self?.settings.showOnCardInsertion ?? false }
    }
    private let bridge: any BridgeHosting
    private var trustedUntil: [String: Date] = [:]
    private var observers: [Int: () -> Void] = [:]
    private var nextObserver = 0
    private var renderScheduled = false

    private let cardQueue = DispatchQueue(label: "md.moldsign.card")
    private let vaultQueue = DispatchQueue(label: "md.moldsign.vault")
    private let verifyQueue = DispatchQueue(label: "md.moldsign.verify")

    #if MOLDSIGN_DEMO
    /// `MSIGN_DEMO_CARDS` (debug builds only): fake cards, no card/keyring/bridge I/O.
    private let demo = DemoMode.current
    private var demoDocuments: DemoDocuments?
    private(set) var demoPrepared = false
    var showDemoPage: ((String) -> Void)?
    var showDemoPreferences: (() -> Void)?
    var isDemo: Bool { demo != nil }
    #else
    var isDemo: Bool { false }
    #endif

    /// Registers a re-render callback (called once now, then after state changes). Returns a token for `unobserve`.
    @discardableResult
    func observe(_ callback: @escaping () -> Void) -> Int {
        nextObserver += 1
        observers[nextObserver] = callback
        callback()
        return nextObserver
    }

    func unobserve(_ token: Int) {
        observers[token] = nil
    }

    /// Coalesces bursts of changes (progress steps, monitor ticks) into one re-render on the next
    /// main-loop iteration, which also keeps signal handlers from rebuilding the widget that emitted them.
    private func changed() {
        guard !renderScheduled else { return }
        renderScheduled = true
        onMain { [weak self] in
            guard let self else { return }
            self.renderScheduled = false
            self.observers.keys.sorted().forEach { self.observers[$0]?() }
        }
    }

    func start() {
        MSLog.sink = nil   // SEC-04: core traces contain SM session keys
        #if MOLDSIGN_DEMO
        if let demo {
            vaultProblem = DemoMode.screenshotCapture ? nil : L10n.text(.linux_demo_mode)
            activity = []
            preferences.update { $0.bridgeEnabled = false }
            readers.apply(demo.snapshot)
            after(milliseconds: 900) { [weak self] in self?.prepareDemoScenario() }
            if let value = ProcessInfo.processInfo.environment["MSIGN_DEMO_SELECTED"], let index = Int(value),
               cards.indices.contains(index) {
                selectCard(cards[index].reader)
            }
            return
        }
        #endif
        readers.start()
        let vault = self.vault
        vaultQueue.async { [weak self] in
            let problem = vault.availabilityProblem()
            onMain { [weak self] in
                self?.vaultProblem = problem
                self?.changed()
            }
        }
        if settings.bridgeEnabled { startBridge() }
    }

    #if MOLDSIGN_DEMO
    private func prepareDemoScenario() {
        guard isDemo else { return }
        guard let scenario = DemoScenario.current else { demoPrepared = true; return }
        do {
            let files = try DemoDocuments()
            demoDocuments = files
            let now = Date()
            switch scenario {
            case .documents, .signing, .pin, .pinError, .signingError:
                signItems = [SignItem(url: files.input), SignItem(url: files.text)]
            default: break
            }
            switch scenario {
            case .signing:
                isSigning = true
                currentStep = .timestamp
            case .pin, .pinError:
                lastAttemptsLeft = scenario == .pinError ? 2 : nil
            case .signingError:
                lastError = (L10n.text(.ui_the_card_does_not_respond), L10n.text(.ui_remove_and_re_insert_the_card))
            case .success:
                lastSigned = [files.result]
            case .verifyChecking:
                verifyFile = files.input
                verifyReports = nil
            case .verifyValid, .verifyInvalid, .verifyUnknown:
                verifyFile = files.result
                verifyReports = [scenario.report()]
            case .verifyUnsigned:
                verifyFile = files.input
                verifyReports = []
            case .activity:
                activity = [
                    ActivityItem(kind: .signed, title: files.result.lastPathComponent,
                        subtitle: L10n.text(.ui_demo_result_document_is_unsigned), ok: true, date: now.addingTimeInterval(-120), filePath: files.result.path),
                    ActivityItem(kind: .verified, title: files.input.lastPathComponent,
                        subtitle: L10n.text(.ui_valid_signature), ok: true, date: now.addingTimeInterval(-300), filePath: files.input.path),
                    ActivityItem(kind: .bridge, title: "msign.gov.md · DEMO",
                        subtitle: L10n.text(.ui_demo_request_cancelled), ok: false, date: now.addingTimeInterval(-600)),
                ]
            case .settings, .documents: break
            }
            showDemoPage?(scenario.page)
            changed()
            if scenario == .pin || scenario == .pinError {
                askPIN?(PinRequest(holder: certificate?.holder ?? "POPESCU ION · DEMO",
                    purpose: (certificate?.holder ?? "POPESCU ION · DEMO") + "\n" +
                        signItems.map { "\($0.url.lastPathComponent) → \($0.format.label)" }.joined(separator: "\n"), attemptsLeft: lastAttemptsLeft,
                    canRemember: false, vaultProblem: DemoMode.screenshotCapture ? nil : L10n.text(.ui_demo_data_no_real_card_pin_or_signatures))) { _ in }
            } else if scenario == .settings {
                showDemoPreferences?()
            }
            demoPrepared = true
        } catch {
            lastError = (L10n.text(.ui_demo_data_could_not_be_prepared), error.localizedDescription)
            changed()
            // Do not emit the ready marker: the capture driver must fail instead of taking a stale page.
        }
    }
    #endif

    func shutdown() {
        readers.stop()
        stopBridge()
    }

    func rereadCards() { readers.rereadCards() }
    func rereadCard(reader: String) { readers.rereadCard(reader: reader) }
    func retryCard() { readers.retryCard() }
    func selectCard(_ reader: String) { readers.selectCard(reader) }
    private func setStoredPIN(_ stored: Bool, certID: String) { readers.setStoredPIN(stored, certID: certID) }

    // MARK: - Signing

    func addFiles(_ paths: [String]) {
        let known = Set(signItems.map(\.url.path))
        var isDir: ObjCBool = false
        let fresh = paths.filter { path in
            !known.contains(path) && FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && !isDir.boolValue
        }
        guard !fresh.isEmpty else { return }
        signItems += fresh.map { SignItem(url: URL(fileURLWithPath: $0)) }
        lastSigned = []
        lastError = nil
        changed()
    }

    func remove(_ id: UUID) {
        signItems.removeAll { $0.id == id }
        changed()
    }

    func setFormat(_ format: SignFormat, for id: UUID) {
        guard let index = signItems.firstIndex(where: { $0.id == id }) else { return }
        signItems[index].format = format
        changed()
    }

    var canSign: Bool { status.canSign && !signItems.isEmpty && !isSigning }

    /// Signs every queued file with one PIN entry. Wrong PIN: stop, drop the stored PIN, never retry (MAC-05).
    func signAll() {
        guard canSign, let card = selectedCard, let cert = card.certificate else { return }
        if isDemo {
            toast?(L10n.text(.ui_demo_mode_signing_is_disabled))
            return
        }
        isSigning = true
        lastError = nil
        lastSigned = []
        changed()
        let items = signItems
        let what = items.count == 1 ? items[0].url.lastPathComponent : localized(.ui_value_documents, String(items.count))
        obtainPIN(certID: cert.sha1Hex, holder: cert.holder,
                  purpose: cert.holder + "\n" + items.map { "\($0.url.lastPathComponent) → \($0.format.label)" }.joined(separator: "\n"),
                  confirmStored: (heading: localized(.ui_sign_value, what),
                                  body: localized(.ui_using_the_certificate_of_value_mdqsign_and_the_saved_pin_value, cert.holder,
                                        items.map { "\($0.url.lastPathComponent) → \($0.format.label)" }.joined(separator: ", "))),
                  allowRemember: true) { [weak self] entry in
            guard let self else { return }
            guard let entry else {
                self.isSigning = false
                self.changed()
                return
            }
            self.runSigning(items, pin: entry.pin, remember: entry.remember, cert: cert, reader: card.reader)
        }
    }

    private func runSigning(_ items: [SignItem], pin: String, remember: Bool, cert: SigningService.CertificateSummary,
                            reader: String) {
        status = .busy(reader: reader, holder: cert.holder)
        currentStep = .card
        changed()
        let batch = batchSigner
        cardQueue.async { [weak self] in
            let failure = batch.sign(items, pin: pin, remember: remember, cert: cert, reader: reader,
                progress: { [weak self] step in
                    onMain { self?.currentStep = UIStep(step); self?.changed() }
                }, completed: { [weak self] item, result, stored in
                    onMain {
                        guard let self else { return }
                        switch result {
                        case .success(let output):
                            self.lastSigned.append(output)
                            if stored { self.setStoredPIN(true, certID: cert.sha1Hex) }
                            self.signItems.removeAll { $0.id == item.id }
                            self.log(ActivityItem(kind: .signed, title: output.lastPathComponent,
                                subtitle: localized(.ui_signed_value, item.format.label), ok: true, filePath: output.path))
                        case .failure(let error):
                            self.log(ActivityItem(kind: .failed, title: item.url.lastPathComponent,
                                subtitle: Self.describe(error).message, ok: false, filePath: item.url.path))
                        }
                        self.changed()
                    }
                })
            onMain { [weak self] in self?.finishSigning(failure: failure, certID: cert.sha1Hex) }
        }
    }

    private func finishSigning(failure: Error?, certID: String) {
        isSigning = false
        currentStep = nil
        readers.refreshSnapshot()   // the reader/card may have changed while signing
        if let failure {
            switch failure {
            case CardError.wrongPIN(let remaining):
                lastAttemptsLeft = remaining
                setStoredPIN(false, certID: certID)
            case CardError.pinBlocked:
                setStoredPIN(false, certID: certID)
            case CardError.apduError(0x6985):
                // card stuck: a re-insert gives it a new generation and a fresh read
                if let index = cards.firstIndex(where: { $0.certificate?.sha1Hex == certID }) {
                    cards[index].certificate = nil
                    cards[index].problem = Self.describe(failure).message
                }
            case CardError.cardChanged:
                rereadCards()
            default:
                break
            }
            lastError = Self.describe(failure)
            if case CardError.apduError(0x6985) = failure, let error = lastError {
                status = .error(message: error.message, recovery: error.recovery)
            }
            toast?(lastError.map { "\($0.message). \($0.recovery)" } ?? L10n.text(.ui_signing_failed))
        } else {
            lastAttemptsLeft = nil
            if lastSigned.count == 1, let file = lastSigned.first, let toastWithAction {
                toastWithAction(localized(.ui_document_signed_value, file.lastPathComponent), L10n.text(.ui_show)) { [weak self] in self?.reveal?(file) }
            } else {
                toast?(localized(.ui_documents_signed_value, String(lastSigned.count)))
            }
        }
        changed()
    }

    // MARK: - PIN (LNX-10)

    /// Stored PIN (after a confirmation when `confirmStored` is set) or the PIN dialog.
    private func obtainPIN(certID: String, holder: String, purpose: String,
                           confirmStored: (heading: String, body: String)?, allowRemember: Bool,
                           completion: @escaping (PinEntry?) -> Void) {
        let vault = self.vault
        vaultQueue.async { [weak self] in
            let lookup = vault.load(certID: certID)
            onMain { [weak self] in
                guard let self else { return completion(nil) }
                if case .unavailable = lookup {} else { self.vaultProblem = nil }   // the service answered
                switch lookup {
                case .found(let pin):
                    guard let confirm = confirmStored else { return completion(PinEntry(pin: pin, remember: false)) }
                    self.presentWindow?()
                    guard let ask = self.askConfirm else { return completion(nil) }
                    ask(confirm.heading, confirm.body, L10n.text(.ui_sign)) { ok in
                        completion(ok ? PinEntry(pin: pin, remember: false) : nil)
                    }
                case .missing, .unavailable:
                    if case .unavailable = lookup {
                        self.vaultProblem = self.vaultProblem ?? L10n.text(.linux_keyring_unavailable)
                    }
                    let request = PinRequest(holder: holder, purpose: purpose, attemptsLeft: self.lastAttemptsLeft,
                                             canRemember: allowRemember && self.vaultProblem == nil,
                                             vaultProblem: allowRemember ? self.vaultProblem : nil)
                    self.presentWindow?()
                    guard let ask = self.askPIN else { return completion(nil) }
                    ask(request, completion)
                }
            }
        }
    }

    func forgetPIN() {
        guard let cert = certificate else { return }
        let vault = self.vault
        vaultQueue.async { [weak self] in
            vault.delete(certID: cert.sha1Hex)
            onMain { [weak self] in
                self?.setStoredPIN(false, certID: cert.sha1Hex)
                self?.toast?(L10n.text(.ui_the_saved_pin_was_deleted))
                self?.changed()
            }
        }
    }

    func forgetAllPINs() {
        guard !isDemo else { return }
        let vault = self.vault
        vaultQueue.async { [weak self] in
            let cleared = vault.deleteAll()
            onMain { [weak self] in
                guard let self else { return }
                if cleared {
                    for index in self.cards.indices { self.cards[index].hasStoredPIN = false }
                }
                self.toast?(cleared ? L10n.text(.ui_the_saved_pins_were_deleted) : L10n.text(.ui_the_pins_could_not_be_deleted))
                self.changed()
            }
        }
    }

    // MARK: - Verify

    func verify(path: String) {
        let url = URL(fileURLWithPath: path)
        verifyFile = url
        verifyReports = nil
        changed()
        let verifier = documentVerifier
        verifyQueue.async { [weak self] in
            let reports = verifier.verify(url)
            onMain { [weak self] in
                guard let self, self.verifyFile == url else { return }
                self.verifyReports = reports
                self.log(ActivityItem(kind: .verified, title: url.lastPathComponent, subtitle: localized(.linux_verified_result, Verdict(reports).title),
                                      ok: Verdict(reports).isValid, filePath: url.path))
                self.changed()
            }
        }
    }

    func resetVerify() {
        verifyFile = nil
        verifyReports = nil
        changed()
    }

    // MARK: - Bridge (LNX-11)

    func setBridgeEnabled(_ on: Bool) {
        preferences.update { $0.bridgeEnabled = on }
        on ? startBridge() : stopBridge()
        changed()
    }

    func setRunInBackground(_ on: Bool) {
        preferences.update { $0.runInBackground = on }
        changed()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        guard !isDemo, !configuringLoginStartup, let configureLoginStartup else { return }
        configuringLoginStartup = true
        changed()
        configureLoginStartup(enabled) { [weak self] accepted in
            guard let self else { return }
            self.configuringLoginStartup = false
            if accepted {
                self.preferences.setLaunchAtLogin(enabled)
            } else {
                self.toast?(L10n.text(.ui_could_not_configure_start_at_login))
            }
            self.changed()
        }
    }

    func setShowOnCardInsertion(_ on: Bool) {
        preferences.setShowOnCardInsertion(on)
        changed()
    }

    func setTheme(_ value: String) {
        preferences.update { $0.theme = value }
        applyAppearance()
        changed()
    }

    func setLanguage(_ value: String) {
        preferences.update { $0.language = value }
        L10n.language = value == "system" ? nil : value
        toast?(L10n.text(.ui_restart_the_app_to_apply_the_language))
        changed()
    }

    func applyAppearance() {
        L10n.language = settings.language == "system" ? nil : settings.language
        if isDemo, let language = ProcessInfo.processInfo.environment["MSIGN_DEMO_LANGUAGE"],
           ["ro", "en", "ru"].contains(language) { L10n.language = language }
        if let manager = adw_style_manager_get_default() {
            let mode = (ProcessInfo.processInfo.environment["MSIGN_DEMO_DARK"] == "1" && isDemo) || settings.theme == "dark" ? ADW_COLOR_SCHEME_FORCE_DARK :
                settings.theme == "light" ? ADW_COLOR_SCHEME_FORCE_LIGHT : ADW_COLOR_SCHEME_DEFAULT
            adw_style_manager_set_color_scheme(manager, mode)
        }
    }

    /// The window may close into the background while card monitoring or the bridge is enabled.
    var shouldRunInBackground: Bool {
        settings.runInBackground && (settings.launchAtLogin || settings.showOnCardInsertion || (settings.bridgeEnabled && bridgeState == .running))
    }

    func restartBridge() {
        stopBridge()
        startBridge()
        changed()
    }

    func importBridgeIdentity(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            try MoldSignServer.validateTLSP12(data)
            let destination = Store.bridgeIdentityURL
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            try data.write(to: destination, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: destination.path)
            if settings.bridgeEnabled { restartBridge() }
            toast?(L10n.text(.ui_the_https_identity_was_imported))
        } catch is MoldSignServer.TLSIdentityError {
            toast?(L10n.text(.ui_the_file_does_not_contain_the_moldsign_https_identity_choose_localhost_p12_from_moldsign))
        } catch {
            toast?(localized(.ui_the_https_identity_could_not_be_imported_value, error.localizedDescription))
        }
    }

    private func startBridge() {
        guard !isDemo else { return }
        bridge.onStateChange = { [weak self] in self?.changed() }
        bridge.authorize = { [weak self] request, completion in
            guard let self else { return completion(.deny) }
            self.authorize(request, completion: completion)
        }
        bridge.onSignResult = { [weak self] request, error in
            guard let self else { return }
            self.bridgeSigning = false
            self.log(Self.bridgeActivity(request, error))
            guard let error else { return }
            switch error {
            case CardError.wrongPIN(let remaining): self.forgetRejectedPIN(remaining: remaining, certID: request.certificateSHA1)
            case CardError.pinBlocked: self.forgetRejectedPIN(remaining: 0, certID: request.certificateSHA1)
            case CardError.cardChanged: self.rereadCards()
            default: break
            }
        }
        bridge.start()
    }

    private func stopBridge() { bridge.stop() }

    /// `certID`: the card the page picked (nil → the selected card, the one the bridge signed with).
    private func forgetRejectedPIN(remaining: Int, certID: String?) {
        if let certID = certID ?? certificate?.sha1Hex {
            vault.delete(certID: certID)
            setStoredPIN(false, certID: certID)
        }
        lastAttemptsLeft = remaining
        toast?(remaining > 0 ? localized(.ui_incorrect_pin_attempts_remaining_value, String(remaining)) : L10n.text(.ui_pin_blocked_unblock_it_at_cev))
        changed()
    }

    /// Consent (unless the origin is trusted for 10 minutes), then the PIN unless the page sent one.
    private func authorize(_ request: BridgeRequest, completion: @escaping (BridgeDecision) -> Void) {
        let origin = request.origin ?? "local"
        // the page picked a certificate from /certificates (several cards may be connected): consent + PIN for THAT card
        let target: CardSlot? = request.certificateSHA1.map { sha in cards.first { $0.certificate?.sha1Hex == sha } }
            ?? selectedCard
        let certID = request.certificateSHA1 ?? target?.certificate?.sha1Hex
        let holder = target?.certificate?.holder ?? request.certificateHolder ?? "—"
        let proceed: () -> Void = { [weak self] in
            guard let self else { return completion(.deny) }
            if request.pinIncluded {
                self.markBridgeSigning()
                return completion(.allow(pin: nil, certificateSHA1: certID))
            }
            guard let certID else {
                self.toast?(L10n.text(.ui_insert_the_card_into_the_reader_and_try_again))
                return completion(.deny)
            }
            let host = ConsentRequest(request: request, holder: holder, hasStoredPIN: false).originHost
            let purpose = request.documentName.map { "\(host) · \($0)" } ?? localized(.ui_value_document, host)
            self.obtainPIN(certID: certID, holder: holder, purpose: purpose,
                           confirmStored: nil, allowRemember: false) { [weak self] entry in
                guard let entry else { return completion(.deny) }
                self?.markBridgeSigning()
                completion(.allow(pin: entry.pin, certificateSHA1: certID))
            }
        }
        if (trustedUntil[origin] ?? .distantPast) > Date() { return proceed() }
        let consent = ConsentRequest(request: request, holder: holder, hasStoredPIN: target?.hasStoredPIN ?? false)
        presentWindow?()
        guard let ask = askConsent else { return completion(.deny) }
        ask(consent) { [weak self] approved, trust in
            guard approved else { return completion(.deny) }
            if trust { self?.trustedUntil[origin] = Date().addingTimeInterval(600) }
            proceed()
        }
    }

    /// Approved browser request: the card is about to sign (cleared by `onSignResult`).
    private func markBridgeSigning() {
        bridgeSigning = true
        changed()
    }

    // MARK: - Activity

    /// "msign.gov.md · Semnat · XAdES-T (SHA-1) · lot" or the failure reason.
    static func bridgeActivity(_ request: BridgeRequest, _ error: Error?) -> ActivityItem {
        let host = request.origin.flatMap { URL(string: $0)?.host } ?? "localhost"
        var what = request.format ?? "?"
        if XAdESSigner.DigestAlgorithm(requested: request.algorithm) == .sha1, request.format?.hasPrefix("XAdES") == true {
            what += " (SHA-1)"
        }
        if let document = request.documentName { what += " · \(document)" }
        if request.batchSession != nil { what = localized(.ui_value_batch, what) }
        guard let error else { return ActivityItem(kind: .bridge, title: host, subtitle: localized(.ui_signed_value, what), ok: true) }
        return ActivityItem(kind: .failed, title: host, subtitle: localized(.ui_failed_value_value, what, describe(error).message), ok: false)
    }

    private func log(_ item: ActivityItem) {
        activity.insert(item, at: 0)
        if activity.count > Store.activityLimit { activity.removeLast(activity.count - Store.activityLimit) }
        Store.save(activity)
        changed()
    }

    func clearActivity() {
        activity.removeAll()
        Store.save(activity)
        changed()
    }

    static func describe(_ error: Error) -> (message: String, recovery: String) {
        UserFacingError.describe(error)
    }

}

/// `~/Documents` (XDG user dir), falling back to `$HOME/Documents`.
var documentsDir: String {
    if let dir = g_get_user_special_dir(G_USER_DIRECTORY_DOCUMENTS) { return String(cString: dir) }
    return String(cString: g_get_home_dir()) + "/Documents"
}
