import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Adapters around PC/SC, files, the update feed, the keyring and the bridge, with their I/O replaced.
final class InfrastructureTests: GnomeTestCase {
    private var folder: URL!
    override func setUp() { super.setUp(); folder = TestEnvironment.directory(); L10n.language = "en" }
    override func tearDown() { L10n.language = nil; super.tearDown() }

    // MARK: - Reader monitor (LNX-08)

    func testReaderMonitorCountsInsertionsAndReportsOnlyChanges() {
        var states: [ReaderMonitor.Observation] = []
        var service = true
        let lock = NSLock()
        let monitor = ReaderMonitor(readerStates: { lock.lock(); defer { lock.unlock() }; return states },
                                    serviceAvailable: { lock.lock(); defer { lock.unlock() }; return service })
        var snapshots: [ReaderSnapshot] = []
        monitor.onChange = { snapshots.append($0) }
        func set(_ value: [ReaderMonitor.Observation]) { lock.lock(); states = value; lock.unlock() }
        func poll(expect count: Int) {
            monitor.refresh()
            XCTAssertTrue(GTKTest.pump(until: { snapshots.count == count }, timeout: 3), "snapshot \(count)")
        }
        poll(expect: 1)
        XCTAssertEqual(snapshots.last, ReaderSnapshot(slots: [], serviceAvailable: true))
        lock.lock(); service = false; lock.unlock()
        poll(expect: 2)
        XCTAssertFalse(snapshots.last!.serviceAvailable)
        set([.init(name: "R", cardPresent: false, mute: false, eventCount: 0)])
        poll(expect: 3)
        XCTAssertEqual(snapshots.last?.slots, [ReaderSlot(name: "R", state: .empty, generation: 0)])
        set([.init(name: "R", cardPresent: true, mute: false, eventCount: 1)])
        poll(expect: 4)
        XCTAssertEqual(snapshots.last?.slots, [ReaderSlot(name: "R", state: .card, generation: 1)])
        // Removed and reinserted between two polls: only the event counter moved.
        set([.init(name: "R", cardPresent: true, mute: false, eventCount: 3)])
        poll(expect: 5)
        XCTAssertEqual(snapshots.last?.slots.first?.generation, 2)
        set([.init(name: "R", cardPresent: true, mute: true, eventCount: 3), .init(name: "S", cardPresent: true, mute: false, eventCount: 0)])
        poll(expect: 6)
        XCTAssertEqual(snapshots.last?.slots.map(\.state), [.mute, .card])
        set([])
        poll(expect: 7)
        monitor.start(interval: .milliseconds(50))
        monitor.start(interval: .milliseconds(50))
        GTKTest.pump(0.2)
        XCTAssertEqual(snapshots.count, 7, "Unchanged state is not reported again")
        monitor.stop()
    }

    // MARK: - Update feed

    private func checker(status: Int = 200, body: String, installed: String = "0.2.0", fails: Bool = false) -> UpdateChecker {
        UpdateChecker(stamp: folder.appendingPathComponent("stamp-\(UUID().uuidString).txt"), installedVersion: { installed }) { request in
            if fails { throw URLError(.notConnectedToInternet) }
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            return (Data(body.utf8), response)
        }
    }

    private final class ResultBox: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: UpdateChecker.Result?
        var value: UpdateChecker.Result? {
            get { lock.lock(); defer { lock.unlock() }; return stored }
            set { lock.lock(); stored = newValue; lock.unlock() }
        }
    }

    private func check(_ checker: UpdateChecker, automatic: Bool = false, now: Date = Date()) -> UpdateChecker.Result {
        let box = ResultBox()
        Task { box.value = await checker.check(automatic: automatic, now: now) }
        XCTAssertTrue(GTKTest.pump(until: { box.value != nil }, timeout: 5))
        return box.value ?? .failed
    }

    func testUpdateFeedAcceptsOnlyNewerVersionsFromTheProductSite() {
        let newer = #"{"version":"0.3.0","downloadURL":"https://esemnbun.md/download/linux/"}"#
        guard case .available(let url) = check(checker(body: newer)) else { return XCTFail("Expected an update") }
        XCTAssertEqual(url.host, "esemnbun.md")
        guard case .current = check(checker(body: newer, installed: "0.3.0")) else { return XCTFail("Expected current") }
        for body in [#"{"version":"9.0.0","downloadURL":"https://evil.example/x"}"#,
                     #"{"version":"9.0.0","downloadURL":"http://esemnbun.md/x"}"#,
                     #"{"version":"9.0","downloadURL":"https://esemnbun.md/x"}"#, "not json"] {
            guard case .failed = check(checker(body: body)) else { return XCTFail("Must reject \(body)") }
        }
        guard case .failed = check(checker(status: 404, body: newer)) else { return XCTFail("HTTP errors fail") }
        guard case .failed = check(checker(body: newer, fails: true)) else { return XCTFail("Network errors fail") }
    }

    func testAutomaticChecksRunAtMostWeekly() {
        let feed = checker(body: #"{"version":"0.2.0","downloadURL":"https://esemnbun.md/d"}"#)
        let now = Date()
        guard case .current = check(feed, automatic: true, now: now) else { return XCTFail("First automatic check runs") }
        guard case .skipped = check(feed, automatic: true, now: now.addingTimeInterval(3600)) else { return XCTFail("Within a week: skipped") }
        guard case .current = check(feed, automatic: false, now: now.addingTimeInterval(3600)) else { return XCTFail("Manual checks always run") }
        guard case .current = check(feed, automatic: true, now: now.addingTimeInterval(8 * 86_400)) else { return XCTFail("After a week it runs again") }
        XCTAssertFalse(UpdateChecker.currentVersion.isEmpty)
    }

    // MARK: - Document signer / verifier / card reads

    private struct Producer: SignatureProducing {
        var error: Error?
        func signature(for item: SignItem, pin: String, reader: String, certificateSHA1: String,
                       progress: @escaping (SigningService.Step) -> Void) throws -> Data {
            progress(.signing)
            if let error { throw error }
            return Data("signature for \(item.url.lastPathComponent)".utf8)
        }
    }

    func testDocumentSignerWritesNextToTheOriginalAndNeverOverwrites() throws {
        let input = try Fixtures.file(in: folder, name: "contract.pdf")
        var steps: [SigningService.Step] = []
        let signer = DocumentSigner(producer: Producer(), fallbackFolder: { self.folder.appendingPathComponent("fallback") })
        let first = try signer.sign(SignItem(url: input), pin: "1234", reader: "R", certificateSHA1: "aa") { steps.append($0) }
        XCTAssertEqual(first.lastPathComponent, "contract-semnat.pdf")
        XCTAssertEqual(steps, [.signing, .writing])
        let second = try signer.sign(SignItem(url: input), pin: "1234", reader: "R", certificateSHA1: "aa") { _ in }
        XCTAssertNotEqual(second, first)
        XCTAssertEqual(try String(contentsOf: first, encoding: .utf8), "signature for contract.pdf")
        var xml = SignItem(url: input)
        xml.format = .xadesBES
        XCTAssertEqual(try signer.sign(xml, pin: "1", reader: "R", certificateSHA1: "aa") { _ in }.pathExtension, "xml")
        XCTAssertThrowsError(try DocumentSigner(producer: Producer(error: CardError.noCard))
            .sign(SignItem(url: input), pin: "1", reader: "R", certificateSHA1: "aa") { _ in })
    }

    func testDocumentSignerFallsBackWhenTheOriginalsFolderIsNotWritable() throws {
        // A folder that cannot take the output (here: not exposed at all, like a portal file's folder). Unlike a
        // read-only folder this also holds for root, which CI containers run as.
        let input = folder.appendingPathComponent("not-exposed/note.txt")
        let fallback = folder.appendingPathComponent("Documents/MoldSign")
        let output = try DocumentSigner(producer: Producer(), fallbackFolder: { fallback })
            .sign(SignItem(url: input), pin: "1", reader: "R", certificateSHA1: "aa") { _ in }
        XCTAssertEqual(output.deletingLastPathComponent().path, fallback.path)
        XCTAssertEqual(output.pathExtension, "xml")
    }

    func testCardBackedAdaptersReportCardErrors() throws {
        let service = SigningService()
        service.transportFactory = { _ in throw CardError.noCard }
        let input = try Fixtures.file(in: folder, name: "a.pdf", contents: "%PDF-1.4")
        for format in [SignFormat.padesT, .xadesT] {
            var item = SignItem(url: input)
            item.format = format
            XCTAssertThrowsError(try DocumentSigner(service: service).sign(item, pin: "1", reader: "R", certificateSHA1: "aa") { _ in })
        }
        var result: CardReadResult?
        LiveCardDataProvider(service: service, vault: FakeVault()).read(reader: "R") { result = $0 }
        XCTAssertTrue(GTKTest.pump(until: { result != nil }, timeout: 3))
        XCTAssertNil(result?.certificate)
        XCTAssertEqual(result?.problem, L10n.text(.ui_insert_the_card))
    }

    func testVerifierReadsPDFsAndLooksForDetachedOriginals() throws {
        let verifier = DocumentVerifier(service: SigningService())
        let pdf = try Fixtures.pdf(in: folder)
        XCTAssertTrue(verifier.verify(pdf).isEmpty, "An unsigned PDF has no signatures")
        let xml = try Fixtures.file(in: folder, name: "sig.xml", contents: "<root/>")
        XCTAssertTrue(verifier.verify(xml, companions: [pdf]).isEmpty)
        XCTAssertTrue(verifier.verify(folder.appendingPathComponent("missing.pdf")).isEmpty)
    }

    // MARK: - Stores

    func testJSONStoresRoundTripThroughTheXDGDirectories() throws {
        var settings = AppSettings()
        settings.theme = "dark"
        JSONSettingsStore().save(settings)
        XCTAssertEqual(JSONSettingsStore().load().theme, "dark")
        XCTAssertTrue(Store.settingsURL.path.hasPrefix(TestEnvironment.root.path))
        let item = ActivityItem(kind: .bridge, title: "msign.gov.md", subtitle: "", ok: true)
        let store = JSONActivityStore()
        store.saveActivity(Array(repeating: item, count: Store.activityLimit + 5))
        XCTAssertEqual(store.loadActivity().count, Store.activityLimit)
        let file = try Fixtures.file(in: folder, name: "x-semnat.pdf")
        let document = ActivityItem(kind: .signed, title: "x", subtitle: "", ok: true, filePath: file.path)
        XCTAssertTrue(store.saveDocuments([document]))
        XCTAssertEqual(store.loadDocuments().map(\.id), [document.id])
        XCTAssertEqual(store.loadDocuments().map(\.filePath), [document.filePath])
        try Data("{".utf8).write(to: Store.settingsURL)
        XCTAssertEqual(Store.loadSettings(), AppSettings())
        XCTAssertFalse(Store.saveSignedDocuments([document], to: URL(fileURLWithPath: "/proc/esemnbun/documents.json")))
        let memory = MemorySettingsStore(settings)
        memory.save(settings)
        XCTAssertEqual(memory.load(), settings)
        try? FileManager.default.removeItem(at: Store.settingsURL)
    }

    // MARK: - Secret Service (no session bus in tests)

    func testPinVaultReportsAMissingSecretServiceInsteadOfFailingSilently() {
        let vault = PinVault()
        XCTAssertEqual(vault.availabilityProblem(), L10n.text(.linux_keyring_unavailable))
        if case .unavailable(let message) = vault.load(certID: "ABC") { XCTAssertFalse(message.isEmpty) } else { XCTFail("Expected unavailable") }
        XCTAssertFalse(vault.hasPIN(certID: "abc"))
        XCTAssertThrowsError(try vault.save("1234", certID: "abc", holder: "Test")) { error in
            XCTAssertFalse(String(describing: error).isEmpty)
        }
        XCTAssertFalse(vault.delete(certID: "abc"))
        XCTAssertFalse(vault.deleteAll())
    }

    // MARK: - Login startup (XDG autostart)

    func testLoginStartupWritesAndRemovesOnlyTheUserAutostartEntry() throws {
        try GTKTest.require()
        let portal = BackgroundPortal(application: GTKTest.application)
        let entry = URL(fileURLWithPath: userConfigDir).appendingPathComponent("autostart/md.moldsign.MoldSign.desktop")
        var answers: [Bool] = []
        LoginStartup.configure(true, portal: portal) { answers.append($0) }
        let text = try String(contentsOf: entry, encoding: .utf8)
        XCTAssertTrue(text.contains("Exec=\""))
        XCTAssertTrue(text.contains("\" --background"))
        XCTAssertTrue(text.contains("NoDisplay=true"))
        LoginStartup.configure(false, portal: portal) { answers.append($0) }
        XCTAssertFalse(FileManager.default.fileExists(atPath: entry.path))
        LoginStartup.configure(false, portal: portal) { answers.append($0) }
        XCTAssertEqual(answers, [true, true, true])
        setenv("FLATPAK_ID", "md.moldsign.MoldSign", 1)
        defer { unsetenv("FLATPAK_ID") }
        XCTAssertTrue(LoginStartup.sandboxed)
        LoginStartup.configure(true, portal: portal) { answers.append($0) }
        XCTAssertEqual(answers.last, false, "Without a portal the sandboxed request is refused")
        portal.setStatus(String(repeating: "x", count: 200))
        portal.requestBackground(reason: "test")
    }
}
