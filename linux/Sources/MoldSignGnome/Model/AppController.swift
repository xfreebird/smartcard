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
    private(set) var status: ReaderStatus = .noReader
    private(set) var cards: [CardSlot] = []
    private(set) var selectedReaderName: String?
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
    private(set) var verifyReports: [Validator.Report]?

    // Activity, settings, bridge, PIN vault
    /// Pruned on load: entries whose file was deleted or moved are dropped (browser requests stay).
    private(set) var activity: [ActivityItem] = Store.loadActivity().filter(\.isShowable)
    private(set) var settings = Store.loadSettings()
    private(set) var bridgeState: BridgeState = .stopped
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
    /// Shows a file in the file manager (OpenURI portal / FileManager1).
    var reveal: ((URL) -> Void)?

    let service = SigningService.shared
    private let vault = PinVault()
    private let monitor = ReaderMonitor()
    private let selectedReader = SelectedReader()
    private var server: MoldSignServer?
    private var trustedUntil: [String: Date] = [:]
    private var lastSnapshot = ReaderMonitor.Snapshot()
    private var observers: [Int: () -> Void] = [:]
    private var nextObserver = 0
    private var renderScheduled = false

    private let cardQueue = DispatchQueue(label: "md.moldsign.card")
    private let vaultQueue = DispatchQueue(label: "md.moldsign.vault")
    private let verifyQueue = DispatchQueue(label: "md.moldsign.verify")

    #if MOLDSIGN_DEMO
    /// `MSIGN_DEMO_CARDS` (debug builds only): fake cards, no card/keyring/bridge I/O.
    private let demo = DemoMode.current
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
            vaultProblem = "Mod demonstrativ"
            apply(demo.snapshot)
            return
        }
        #endif
        let selected = selectedReader
        // nil (no specific card asked for) → the card selected in the UI
        service.transportFactory = { reader in try CardTransports.connect(reader: reader ?? selected.name) }
        monitor.onChange = { [weak self] snapshot in self?.apply(snapshot) }
        monitor.start()
        let vault = self.vault
        vaultQueue.async {
            let problem = vault.availabilityProblem()
            onMain { [weak self] in
                self?.vaultProblem = problem
                self?.changed()
            }
        }
        if settings.bridgeEnabled { startBridge() }
    }

    func shutdown() {
        monitor.stop()
        stopBridge()
    }

    // MARK: - Reader state (LNX-08)

    private func apply(_ snapshot: ReaderMonitor.Snapshot) {
        lastSnapshot = snapshot
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
        for card in toRead { readCertificate(of: card) }
    }

    /// PIN-less certificate read so the UI can greet the holder (MAC-02 equivalent). Ignored if the card changed meanwhile.
    private func readCertificate(of card: CardSlot) {
        #if MOLDSIGN_DEMO
        if let demo {
            // a short "reading" phase, like a real PIN-less read
            after(milliseconds: 700) { [weak self] in
                guard let self,
                      let index = self.cards.firstIndex(where: { $0.reader == card.reader && $0.generation == card.generation })
                else { return }
                self.cards[index].certificate = demo.certificates[card.reader]
                self.cards[index].problem = demo.certificates[card.reader] == nil ? demo.failure : nil
                self.recomputeStatus()
            }
            return
        }
        #endif
        let service = self.service
        let vault = self.vault
        let reader = card.reader
        cardQueue.async {
            let result = Result { try service.readCertificate(reader: reader) }
            let stored = (try? result.get()).map { vault.hasPIN(certID: $0.sha1Hex) } ?? false
            onMain { [weak self] in
                guard let self,
                      let index = self.cards.firstIndex(where: { $0.reader == reader && $0.generation == card.generation })
                else { return }
                switch result {
                case .success(let cert):
                    self.cards[index].certificate = cert
                    self.cards[index].problem = nil
                    self.cards[index].hasStoredPIN = stored
                case .failure(let error):
                    self.cards[index].problem = Self.describe(error).message
                }
                self.recomputeStatus()
            }
        }
    }

    /// "Recitește cardul": forget what we know about the inserted cards and read them again.
    func rereadCards() {
        guard !isSigning else { return }
        for index in cards.indices {
            cards[index].certificate = nil
            cards[index].problem = nil
        }
        recomputeStatus()
        for card in cards { readCertificate(of: card) }
    }

    /// "Recitește cardul" on one card of the wallet (its context menu).
    func rereadCard(reader: String) {
        guard !isSigning, let index = cards.firstIndex(where: { $0.reader == reader }) else { return }
        cards[index].certificate = nil
        cards[index].problem = nil
        recomputeStatus()
        readCertificate(of: cards[index])
    }

    /// "Reîncearcă" / the header's re-read button: re-read the inserted cards, or re-poll the readers when there are none.
    func retryCard() {
        #if MOLDSIGN_DEMO
        if let demo, cards.isEmpty { return apply(demo.snapshot) }
        #endif
        if cards.isEmpty { monitor.refresh() } else { rereadCards() }
    }

    func selectCard(_ reader: String) {
        guard reader != selectedCard?.reader, cards.contains(where: { $0.reader == reader }) else { return }
        selectedReaderName = reader
        selectedReader.name = reader
        lastAttemptsLeft = nil
        recomputeStatus()
    }

    private func setStoredPIN(_ stored: Bool, certID: String) {
        for index in cards.indices where cards[index].certificate?.sha1Hex == certID {
            cards[index].hasStoredPIN = stored
        }
    }

    private func recomputeStatus() {
        guard !isSigning else { return changed() }
        let snapshot = lastSnapshot
        guard let firstReader = snapshot.readers.first else {
            status = snapshot.serviceAvailable
                ? .noReader
                : .error(message: "Serviciul PC/SC nu rulează", recovery: "Pornește-l: sudo systemctl enable --now pcscd.socket")
            return changed()
        }
        guard let card = selectedCard else {
            status = snapshot.muteCard
                ? .error(message: "Cardul nu răspunde", recovery: "Scoate și reintrodu cardul")
                : .empty(reader: firstReader)
            return changed()
        }
        if let cert = card.certificate {
            status = .ready(reader: card.reader, holder: cert.holder, validUntil: cert.notAfter)
        } else if let problem = card.problem {
            status = .error(message: problem, recovery: "Scoate și reintrodu cardul")
        } else {
            status = .reading(reader: card.reader)
        }
        changed()
    }

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
            toast?("Mod demonstrativ: semnarea este dezactivată")
            return
        }
        isSigning = true
        lastError = nil
        lastSigned = []
        changed()
        let items = signItems
        let what = items.count == 1 ? items[0].url.lastPathComponent : "\(items.count) documente"
        obtainPIN(certID: cert.sha1Hex, holder: cert.holder,
                  purpose: "Semnezi \(what) ca \(cert.holder)",
                  confirmStored: (heading: "Semnezi \(what)?",
                                  body: "Cu certificatul \(cert.holder) (MDQSign), folosind PIN-ul salvat. " +
                                        items.map { "\($0.url.lastPathComponent) → \($0.format.label)" }.joined(separator: ", ")),
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
        let service = self.service
        let vault = self.vault
        cardQueue.async {
            var savedPIN = false
            var failure: Error?
            for item in items {
                do {
                    // the expected certificate makes the core refuse a swapped card before the PIN is sent
                    let output = try Self.sign(item, pin: pin, reader: reader, certificateSHA1: cert.sha1Hex,
                                               service: service) { step in
                        onMain { [weak self] in
                            self?.currentStep = UIStep(step)
                            self?.changed()
                        }
                    }
                    // The card accepted the PIN: only now may it be remembered (LNX-10).
                    if remember && !savedPIN {
                        savedPIN = (try? vault.save(pin, certID: cert.sha1Hex, holder: cert.holder)) != nil
                    }
                    let stored = savedPIN
                    onMain { [weak self] in
                        guard let self else { return }
                        self.lastSigned.append(output)
                        if stored { self.setStoredPIN(true, certID: cert.sha1Hex) }
                        self.signItems.removeAll { $0.id == item.id }
                        self.log(ActivityItem(kind: .signed, title: output.lastPathComponent,
                                              subtitle: "Semnat · \(item.format.label)", ok: true, filePath: output.path))
                        self.changed()
                    }
                } catch {
                    failure = error
                    if case CardError.wrongPIN = error { vault.delete(certID: cert.sha1Hex) }
                    if case CardError.pinBlocked = error { vault.delete(certID: cert.sha1Hex) }
                    onMain { [weak self] in
                        self?.log(ActivityItem(kind: .failed, title: item.url.lastPathComponent,
                                               subtitle: Self.describe(error).message, ok: false, filePath: item.url.path))
                    }
                    break
                }
            }
            onMain { [weak self] in self?.finishSigning(failure: failure, certID: cert.sha1Hex) }
        }
    }

    private func finishSigning(failure: Error?, certID: String) {
        isSigning = false
        currentStep = nil
        apply(lastSnapshot)   // the reader/card may have changed while signing
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
            toast?(lastError.map { "\($0.message). \($0.recovery)" } ?? "Semnarea a eșuat")
        } else {
            lastAttemptsLeft = nil
            if lastSigned.count == 1, let file = lastSigned.first, let toastWithAction {
                toastWithAction("Document semnat: \(file.lastPathComponent)", "Arată") { [weak self] in self?.reveal?(file) }
            } else {
                toast?("Documente semnate: \(lastSigned.count)")
            }
        }
        changed()
    }

    /// One file: PAdES-T for PDF, XAdES (detached) otherwise; written next to the original.
    private static func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String,
                             service: SigningService, progress: @escaping (SigningService.Step) -> Void) throws -> URL {
        let input = item.url
        let signed: Data
        if let xades = item.format.xades {
            signed = try service.signXAdES(files: [input], format: xades, type: .detached, pin: pin, reader: reader,
                                           expectedCertificateSHA1: certificateSHA1, progress: progress)
        } else {
            signed = try service.signPDF(try Data(contentsOf: input), pin: pin, reader: reader,
                                         expectedCertificateSHA1: certificateSHA1, progress: progress)
        }
        progress(.writing)
        let preferred = SigningService.outputURL(for: input, pathExtension: item.format.outputExtension)
        do {
            try signed.write(to: preferred, options: .withoutOverwriting)
            return preferred
        } catch {
            // Read-only folder, or a Flatpak document-portal file whose folder is not exposed:
            // fall back to ~/Documents/MoldSign (granted by --filesystem=xdg-documents).
            // TODO(LNX-13): offer a GtkFileDialog save instead when the fallback also fails.
            let folder = URL(fileURLWithPath: documentsDir).appendingPathComponent("MoldSign")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let fallback = SigningService.outputURL(for: folder.appendingPathComponent(input.lastPathComponent),
                                                    pathExtension: item.format.outputExtension)
            try signed.write(to: fallback, options: .withoutOverwriting)
            return fallback
        }
    }

    // MARK: - PIN (LNX-10)

    /// Stored PIN (after a confirmation when `confirmStored` is set) or the PIN dialog.
    private func obtainPIN(certID: String, holder: String, purpose: String,
                           confirmStored: (heading: String, body: String)?, allowRemember: Bool,
                           completion: @escaping (PinEntry?) -> Void) {
        let vault = self.vault
        vaultQueue.async {
            let lookup = vault.load(certID: certID)
            onMain { [weak self] in
                guard let self else { return completion(nil) }
                if case .unavailable = lookup {} else { self.vaultProblem = nil }   // the service answered
                switch lookup {
                case .found(let pin):
                    guard let confirm = confirmStored else { return completion(PinEntry(pin: pin, remember: false)) }
                    self.presentWindow?()
                    guard let ask = self.askConfirm else { return completion(nil) }
                    ask(confirm.heading, confirm.body, "Semnează") { ok in
                        completion(ok ? PinEntry(pin: pin, remember: false) : nil)
                    }
                case .missing, .unavailable:
                    if case .unavailable = lookup {
                        self.vaultProblem = self.vaultProblem ?? "Serviciul de chei (GNOME Keyring) nu este disponibil"
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
        vaultQueue.async {
            vault.delete(certID: cert.sha1Hex)
            onMain { [weak self] in
                self?.setStoredPIN(false, certID: cert.sha1Hex)
                self?.toast?("PIN-ul salvat a fost șters")
                self?.changed()
            }
        }
    }

    // MARK: - Verify

    func verify(path: String) {
        let url = URL(fileURLWithPath: path)
        verifyFile = url
        verifyReports = nil
        changed()
        let service = self.service
        verifyQueue.async {
            let reports: [Validator.Report]
            if let data = try? Data(contentsOf: url) {
                let isPDF = url.pathExtension.lowercased() == "pdf"
                let detached = isPDF ? [:] : Self.detachedDocuments(for: data, near: url)
                reports = service.verify(data, isPDF: isPDF, detached: detached)
            } else {
                reports = []
            }
            onMain { [weak self] in
                guard let self, self.verifyFile == url else { return }
                self.verifyReports = reports
                self.log(ActivityItem(kind: .verified, title: url.lastPathComponent, subtitle: "Verificat · " + Verdict(reports).title,
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

    // MARK: - Bridge (LNX-11)

    func setBridgeEnabled(_ on: Bool) {
        settings.bridgeEnabled = on
        Store.save(settings)
        on ? startBridge() : stopBridge()
        changed()
    }

    func setRunInBackground(_ on: Bool) {
        settings.runInBackground = on
        Store.save(settings)
        changed()
    }

    /// The window may close into the background only while the bridge listens (LNX-12).
    var shouldRunInBackground: Bool {
        settings.runInBackground && settings.bridgeEnabled && bridgeState == .running
    }

    func restartBridge() {
        stopBridge()
        startBridge()
        changed()
    }

    private func startBridge() {
        guard server == nil else { return }
        if isDemo {
            logInfo("demo mode: browser bridge not started")
            return
        }
        let server = MoldSignServer()
        server.authorize = { [weak self] request in
            // Called on the server's work queue: block it (never the GTK thread) until the user answers.
            let answer = DecisionBox()
            let done = DispatchSemaphore(value: 0)
            onMain {
                guard let self else { done.signal(); return }
                self.authorize(request) { decision in
                    answer.value = decision
                    _ = done.signal()
                }
            }
            done.wait()
            return answer.value
        }
        server.onSignResult = { [weak self] request, error in
            onMain {
                self?.bridgeSigning = false
                self?.log(Self.bridgeActivity(request, error))   // MAC-10: outcome, not just "request received"
            }
            // A stored PIN the card rejected during a browser request must go, like in the UI flow (MAC-05).
            guard let error else { return }
            switch error {
            case CardError.wrongPIN(let remaining): onMain { self?.forgetRejectedPIN(remaining: remaining, certID: request.certificateSHA1) }
            case CardError.pinBlocked: onMain { self?.forgetRejectedPIN(remaining: 0, certID: request.certificateSHA1) }
            case CardError.cardChanged: onMain { self?.rereadCards() }
            default: break
            }
        }
        server.onListenerError = { [weak self, weak server] _, error in
            let busy = MoldSignServer.isAddressInUse(error)
            let message = "\(error)"
            onMain {
                guard let self, let server, self.server === server else { return }
                self.bridgeState = busy ? .portBusy : .failed(message)
                self.changed()
            }
        }
        do {
            try server.start()
            self.server = server
            if bridgeState != .portBusy { bridgeState = .running }
        } catch {
            server.stop()
            bridgeState = MoldSignServer.isAddressInUse(error) ? .portBusy : .failed("\(error)")
        }
    }

    private func stopBridge() {
        server?.stop()
        server = nil
        bridgeState = .stopped
    }

    /// `certID`: the card the page picked (nil → the selected card, the one the bridge signed with).
    private func forgetRejectedPIN(remaining: Int, certID: String?) {
        if let certID = certID ?? certificate?.sha1Hex {
            vault.delete(certID: certID)
            setStoredPIN(false, certID: certID)
        }
        lastAttemptsLeft = remaining
        toast?(remaining > 0 ? "PIN greșit. Încercări rămase: \(remaining)" : "PIN blocat. Deblochează-l la CEV")
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
                self.toast?("Introdu cardul în cititor și încearcă din nou")
                return completion(.deny)
            }
            let host = ConsentRequest(request: request, holder: holder, hasStoredPIN: false).originHost
            self.obtainPIN(certID: certID, holder: holder, purpose: "\(host) · \(request.documentName ?? "document")",
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
        if request.batchSession != nil { what += " · lot" }
        guard let error else { return ActivityItem(kind: .bridge, title: host, subtitle: "Semnat · \(what)", ok: true) }
        return ActivityItem(kind: .failed, title: host, subtitle: "Eșuat · \(what) · \(describe(error).message)", ok: false)
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

    // MARK: - Errors (docs/09 §3.3)

    static func describe(_ error: Error) -> (message: String, recovery: String) {
        switch error {
        case CardError.wrongPIN(let remaining):
            return ("PIN greșit", "Încercări rămase: \(remaining)")
        case CardError.pinBlocked:
            return ("PIN blocat", "Deblochează-l la CEV")
        case CardError.noReader:
            return ("Conectează cititorul", "Verifică dacă serviciul pcscd rulează")
        case CardError.noCard:
            return ("Introdu cardul în cititor", "")
        case CardError.cardNotResponding:
            return ("Cardul nu răspunde", "Scoate și reintrodu cardul")
        case CardError.cardChanged:
            return ("Cardul din cititor s-a schimbat", "Verifică titularul și semnează din nou")
        case CardError.apduError(0x6985):
            return ("Cardul a rămas într-o stare invalidă", "Scoate și reintrodu cardul")
        case CardError.apduError(0x6988), CardError.macVerificationFailed:
            return ("Sesiunea securizată s-a întrerupt", "Încearcă din nou")
        case CardError.signFailed(let message) where message.hasPrefix("TSA"):
            return ("Serviciul de marcă temporală nu răspunde", "Verifică conexiunea și încearcă din nou")
        case is TrustServices.NetworkError:
            return ("Serviciile PKI nu răspund", "Verifică conexiunea și încearcă din nou")
        case let error as CocoaError where error.code == .fileWriteNoPermission || error.code == .fileWriteFileExists:
            return ("Fișierul semnat nu a putut fi salvat", "Alege un dosar în care ai drept de scriere")
        default:
            return (error.localizedDescription, "Încearcă din nou")
        }
    }
}

/// `~/Documents` (XDG user dir), falling back to `$HOME/Documents`.
var documentsDir: String {
    if let dir = g_get_user_special_dir(G_USER_DIRECTORY_DOCUMENTS) { return String(cString: dir) }
    return String(cString: g_get_home_dir()) + "/Documents"
}

/// Reader of the UI-selected card, read by the transport factory on the card queue.
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
