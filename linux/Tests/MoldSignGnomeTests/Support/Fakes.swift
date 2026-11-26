import Dispatch
import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome

// Hardware-free adapters for AppController and the views. Nothing here touches PC/SC, the keyring or the network.

final class FakeMonitor: CardMonitoring {
    var onChange: ((ReaderSnapshot) -> Void)?
    private(set) var started = 0
    private(set) var stopped = 0
    private(set) var refreshed = 0
    func start(interval: DispatchTimeInterval) { started += 1 }
    func stop() { stopped += 1 }
    func refresh() { refreshed += 1 }
    func emit(_ snapshot: ReaderSnapshot) { onChange?(snapshot) }
}

final class FakeVault: PINStoring {
    var stored: [String: String] = [:]
    var unavailable: String?
    var problem: String?
    var saveFails = false
    var deleteAllResult = true
    private(set) var saves: [(pin: String, certID: String)] = []
    private(set) var deleted: [String] = []
    private(set) var deletedAll = 0
    private let lock = NSLock()

    func save(_ pin: String, certID: String, holder: String) throws {
        lock.lock(); defer { lock.unlock() }
        saves.append((pin, certID))
        if saveFails { throw NSError(domain: "FakeVault", code: 1) }
        stored[certID] = pin
    }
    func load(certID: String) -> PINLookup {
        lock.lock(); defer { lock.unlock() }
        if let unavailable { return .unavailable(unavailable) }
        return stored[certID].map { .found($0) } ?? .missing
    }
    func hasPIN(certID: String) -> Bool { lock.lock(); defer { lock.unlock() }; return stored[certID] != nil }
    @discardableResult func delete(certID: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        deleted.append(certID)
        return stored.removeValue(forKey: certID) != nil
    }
    func deleteAll() -> Bool {
        lock.lock(); defer { lock.unlock() }
        deletedAll += 1
        if deleteAllResult { stored.removeAll() }
        return deleteAllResult
    }
    func availabilityProblem() -> String? { problem }
}

final class FakeBridge: BridgeHosting {
    var allowsLegacyDesktopClient = false
    var state: BridgeState = .stopped { didSet { onStateChange?() } }
    var previewPDFEnabled: (() -> Bool)?
    var previewPDF: ((BridgeRequest, Data, @escaping (PDFStampDecision) -> Void) -> Void)?
    var authorize: ((BridgeRequest, @escaping (BridgeDecision) -> Void) -> Void)?
    var onSignResult: ((BridgeRequest, Error?) -> Void)?
    var onStateChange: (() -> Void)?
    var stateOnStart: BridgeState = .running
    private(set) var starts = 0
    private(set) var stops = 0
    func start() { starts += 1; state = stateOnStart }
    func stop() { stops += 1; state = .stopped }
}

/// Answers certificate reads from a table: a certificate, or a problem when the reader is missing.
final class FakeCardData: CardDataProviding {
    var certificates: [String: SigningService.CertificateSummary] = [:]
    var stored: Set<String> = []
    var deferred = false
    private(set) var reads: [String] = []
    private(set) var pending: [(CardReadResult) -> Void] = []

    func read(reader: String, completion: @escaping (CardReadResult) -> Void) {
        reads.append(reader)
        let certificate = certificates[reader]
        let result = CardReadResult(certificate: certificate, problem: certificate == nil ? "Card unavailable" : nil,
                                    hasStoredPIN: certificate.map { stored.contains($0.sha1Hex) } ?? false)
        if deferred { pending.append { _ in completion(result) } } else { completion(result) }
    }

    func flush() {
        let calls = pending
        pending.removeAll()
        calls.forEach { $0(CardReadResult()) }
    }
}

final class FakeSigner: DocumentSigning {
    var failures: [String: Error] = [:]
    var outputDirectory: URL?
    private(set) var signed: [(file: String, pin: String, reader: String)] = []
    private let lock = NSLock()

    func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String,
              progress: @escaping (SigningService.Step) -> Void) throws -> URL {
        lock.lock(); signed.append((item.url.lastPathComponent, pin, reader)); lock.unlock()
        progress(.signing)
        progress(.timestamping)
        if let failure = failures[item.url.lastPathComponent] { throw failure }
        progress(.writing)
        let folder = outputDirectory ?? item.url.deletingLastPathComponent()
        let output = folder.appendingPathComponent(item.url.deletingPathExtension().lastPathComponent + "-semnat." + item.format.outputExtension)
        try Data("signed".utf8).write(to: output)
        return output
    }
}

final class FakeVerifier: DocumentVerifying {
    var reports: [String: [SignatureReport]] = [:]
    private(set) var requests: [(file: String, companions: [String])] = []
    private let lock = NSLock()
    func verify(_ url: URL) -> [SignatureReport] { verify(url, companions: []) }
    func verify(_ url: URL, companions: [URL]) -> [SignatureReport] {
        lock.lock(); defer { lock.unlock() }
        requests.append((url.lastPathComponent, companions.map(\.lastPathComponent)))
        return reports[url.lastPathComponent] ?? []
    }
}

final class TestSettings: SettingsStoring {
    var value: AppSettings
    private(set) var saves = 0
    init(_ value: AppSettings = TestSettings.defaults) { self.value = value }
    static var defaults: AppSettings {
        var settings = AppSettings()
        settings.bridgeEnabled = false
        settings.onboardingCompleted = true
        return settings
    }
    func load() -> AppSettings { value }
    func save(_ settings: AppSettings) { value = settings; saves += 1 }
}

final class TestActivityStore: ActivityStoring {
    var activity: [ActivityItem] = []
    var documents: [ActivityItem] = []
    var documentsSaveSucceeds = true
    func loadActivity() -> [ActivityItem] { activity }
    func loadDocuments() -> [ActivityItem] { documents }
    func saveActivity(_ items: [ActivityItem]) { activity = items }
    func saveDocuments(_ items: [ActivityItem]) -> Bool {
        guard documentsSaveSucceeds else { return false }
        documents = items
        return true
    }
}

/// The four fictional demo certificates as real parsed X.509 summaries, plus a minimal explicit one.
enum Fixtures {
    static func certificate(_ holder: String = "POPESCU ION", sha1: String = "aa11", notAfter: Date? = Date(timeIntervalSince1970: 1_900_000_000)) -> SigningService.CertificateSummary {
        .init(der: Data(holder.utf8), holder: holder, subjectDN: "CN=\(holder)", issuer: "CN=MDQSign", issuerName: "MDQSign",
              serialDecimal: "123456", sha1Hex: sha1, notAfter: notAfter)
    }

    static let readers = ["Reader A 00 00", "Reader B 01 00", "Reader C 02 00"]

    static func snapshot(cards: Int, generation: Int = 1) -> ReaderSnapshot {
        ReaderSnapshot(slots: readers.prefix(cards).map { .init(name: $0, state: .card, generation: generation) })
    }

    static func cardData(_ count: Int = 2) -> FakeCardData {
        let data = FakeCardData()
        let holders = ["POPESCU ION", "CIOBANU MARIA", "ROTARU ANDREI"]
        for index in 0..<count { data.certificates[readers[index]] = certificate(holders[index], sha1: "cert\(index)") }
        return data
    }

    static func report(valid: Bool = true, intact: Bool = true, trusted: Bool = true, kind: String = "PAdES") -> SignatureReport {
        var report = SignatureReport()
        report.kind = kind
        report.name = "Signature1"
        report.signer = "POPESCU ION"
        report.contentIntact = intact
        report.signatureValid = valid
        report.chainTrusted = trusted
        report.signingTime = "2026-10-30T12:00:00Z"
        report.timestampTime = "2026-10-30T12:00:02Z"
        report.level = "PAdES-B-T"
        report.summary = "Summary"
        report.certificateDetails = ["Subject · Name": "POPESCU ION", "Subject · Personal identifier": "2000000000000",
                                     "Issuer · Name": "MDQSign"]
        return report
    }

    /// A one-page unsigned PDF (the demo fixture generator), written to `folder`.
    static func pdf(in folder: URL, name: String = "document.pdf") throws -> URL {
        let documents = try DemoDocuments()
        let url = folder.appendingPathComponent(name)
        try FileManager.default.copyItem(at: documents.input, to: url)
        return url
    }

    static func file(in folder: URL, name: String, contents: String = "text") throws -> URL {
        let url = folder.appendingPathComponent(name)
        try Data(contents.utf8).write(to: url)
        return url
    }
}

/// AppController wired to fakes, with every UI hook recorded.
final class ControllerHarness {
    let monitor = FakeMonitor()
    let vault = FakeVault()
    let bridge = FakeBridge()
    let cardData: FakeCardData
    let signer = FakeSigner()
    let verifier = FakeVerifier()
    let settings: TestSettings
    let activity = TestActivityStore()
    let controller: AppController
    var toasts: [String] = []
    var actionToasts: [(text: String, button: String, action: () -> Void)] = []
    var pinRequests: [(request: PinRequest, answer: (PinEntry?) -> Void)] = []
    var confirmations: [(heading: String, body: String, answer: (Bool) -> Void)] = []
    var consents: [(request: ConsentRequest, answer: (Bool, Bool) -> Void)] = []
    var stamps: [(item: SignItem, holder: String, origin: String?, answer: (PDFStampDecision) -> Void)] = []
    var approvals: [(heading: String, body: String, answer: (Bool) -> Void)] = []
    var presented = 0
    var revealed: [URL] = []
    var loginRequests: [(enabled: Bool, answer: (Bool) -> Void)] = []
    var stampCancelled = 0

    init(cards: Int = 1, settings: AppSettings = TestSettings.defaults, service: SigningService = SigningService(),
         activity seed: [ActivityItem] = [], documents: [ActivityItem] = [], vaultProblem: String? = nil,
         hooks: Bool = true, start: Bool = true,
         transport: @escaping (String?) throws -> CardTransport = { _ in throw CardError.noReader }) {
        cardData = Fixtures.cardData(max(cards, 1))
        self.settings = TestSettings(settings)
        activity.activity = seed
        activity.documents = documents
        vault.problem = vaultProblem
        controller = AppController(service: service, vault: vault, monitor: monitor, transportFactory: transport,
                                   batchSigner: BatchSigningService(signer: signer, vault: vault),
                                   documentVerifier: verifier, cardData: cardData, activityStore: activity,
                                   settingsStore: self.settings, bridge: bridge)
        if hooks { installHooks() }
        guard start else { return }
        controller.start()
        if cards > 0 { insert(cards) }
    }

    /// Records every UI request instead of presenting dialogs (views install their own when `hooks` is false).
    func installHooks() {
        controller.toast = { [unowned self] in toasts.append($0) }
        controller.toastWithAction = { [unowned self] text, button, action in actionToasts.append((text, button, action)) }
        controller.askPIN = { [unowned self] request, answer in pinRequests.append((request, answer)) }
        controller.askConfirm = { [unowned self] heading, body, _, answer in confirmations.append((heading, body, answer)) }
        controller.askConsent = { [unowned self] request, answer in consents.append((request, answer)) }
        controller.askAgentApproval = { [unowned self] heading, body, _, answer in approvals.append((heading, body, answer)) }
        controller.askStamp = { [unowned self] item, holder, origin, answer in
            stamps.append((item, holder, origin, answer))
            return { [unowned self] in stampCancelled += 1 }
        }
        controller.presentWindow = { [unowned self] in presented += 1 }
        controller.reveal = { [unowned self] in revealed.append($0) }
        controller.configureLoginStartup = { [unowned self] enabled, answer in loginRequests.append((enabled, answer)) }
    }

    /// Starts monitoring and inserts the fixture cards.
    func start(cards: Int) {
        controller.start()
        if cards > 0 { insert(cards) }
    }

    func insert(_ count: Int, generation: Int = 1) {
        monitor.emit(Fixtures.snapshot(cards: count, generation: generation))
        GTKTest.pump()
    }

    /// Main-loop work from the controller's worker queues (vault, card, verification).
    @discardableResult
    func settle(until condition: () -> Bool = { false }, timeout: Double = 0.3) -> Bool {
        GTKTest.pump(until: condition, timeout: timeout)
    }
}
