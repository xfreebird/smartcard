import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome

/// AppController flows with fake readers, vault, signer, verifier and bridge. Needs only the GLib main loop.
final class AppControllerTests: GnomeTestCase {
    private var harness: ControllerHarness!
    private var folder: URL!

    override func setUp() {
        super.setUp()
        L10n.language = "en"
        folder = TestEnvironment.directory()
    }

    override func tearDown() {
        harness?.controller.shutdown()
        harness = nil
        L10n.language = nil
        super.tearDown()
    }

    private func make(cards: Int = 1, settings: AppSettings = TestSettings.defaults, service: SigningService = SigningService(),
                      activity: [ActivityItem] = [], documents: [ActivityItem] = [], vaultProblem: String? = nil,
                      transport: @escaping (String?) throws -> CardTransport = { _ in throw CardError.noReader }) -> ControllerHarness {
        harness = ControllerHarness(cards: cards, settings: settings, service: service, activity: activity,
                                    documents: documents, vaultProblem: vaultProblem, transport: transport)
        return harness
    }

    private func pdf(_ name: String = "contract.pdf") throws -> URL { try Fixtures.file(in: folder, name: name, contents: "%PDF-1.4") }

    // MARK: - Readers and cards

    func testStartMonitorsReadersAndReportsKeyringProblem() {
        let h = make(cards: 2, vaultProblem: "Keyring locked")
        XCTAssertEqual(h.monitor.started, 1)
        XCTAssertTrue(h.settle(until: { h.controller.vaultProblem == "Keyring locked" }))
        XCTAssertEqual(h.controller.cards.count, 2)
        XCTAssertEqual(h.controller.selectedCard?.reader, Fixtures.readers[0])
        XCTAssertEqual(h.controller.certificate?.holder, "POPESCU ION")
        XCTAssertTrue(h.controller.status.canSign)
        XCTAssertEqual(h.controller.statusLight.light, .ready)
        XCTAssertTrue(h.controller.trayStatus.connected)
        XCTAssertEqual(h.controller.backgroundStatusText, h.controller.trayStatus.text)
        XCTAssertEqual(h.bridge.starts, 0, "The bridge stays off when the setting is off")
    }

    func testSelectingAnotherCardChangesTheSigningIdentityOnly() {
        let h = make(cards: 2)
        h.controller.selectCard(Fixtures.readers[1])
        XCTAssertEqual(h.controller.selectedReaderName, Fixtures.readers[1])
        XCTAssertEqual(h.controller.certificate?.holder, "CIOBANU MARIA")
        h.controller.selectCard("missing reader")
        XCTAssertEqual(h.controller.selectedReaderName, Fixtures.readers[1])
        let reads = h.cardData.reads.count
        h.controller.rereadCard(reader: Fixtures.readers[0])
        XCTAssertEqual(h.cardData.reads.count, reads + 1)
        h.controller.rereadCards()
        XCTAssertEqual(h.cardData.reads.count, reads + 3)
        h.controller.retryCard()
        XCTAssertEqual(h.cardData.reads.count, reads + 5)
    }

    func testEmptyReaderRetryPollsAndInsertionCanPresentTheWindow() {
        var settings = TestSettings.defaults
        settings.showOnCardInsertion = true
        let h = make(cards: 0, settings: settings)
        h.monitor.emit(ReaderSnapshot(slots: [.init(name: "Reader A 00 00", state: .empty, generation: 0)]))
        XCTAssertEqual(h.controller.status, .empty(reader: "Reader A 00 00"))
        h.controller.retryCard()
        XCTAssertEqual(h.monitor.refreshed, 1)
        h.insert(1)
        XCTAssertEqual(h.presented, 1)
        h.monitor.emit(ReaderSnapshot(slots: [], serviceAvailable: false))
        if case .error = h.controller.status {} else { XCTFail("PC/SC down must be an error") }
        h.monitor.emit(ReaderSnapshot(slots: [.init(name: "Reader A 00 00", state: .mute, generation: 1)]))
        if case .error = h.controller.status {} else { XCTFail("A mute card must be an error") }
        h.monitor.emit(ReaderSnapshot())
        XCTAssertEqual(h.controller.status, .noReader)
        XCTAssertFalse(h.controller.trayStatus.connected)
    }

    func testCardWithoutCertificateShowsTheReadProblem() {
        let h = make(cards: 0)
        h.cardData.certificates = [:]
        h.insert(1)
        XCTAssertEqual(h.controller.cards.first?.problem, "Card unavailable")
        if case .error(let message, _) = h.controller.status { XCTAssertEqual(message, "Card unavailable") } else { XCTFail() }
    }

    // MARK: - Document queue

    func testAddFilesSkipsMissingDuplicateAndFolderEntries() throws {
        let h = make()
        let first = try pdf(), second = try Fixtures.file(in: folder, name: "note.txt")
        h.controller.addFiles([first.path, second.path, first.path, folder.path, folder.appendingPathComponent("gone.pdf").path])
        XCTAssertEqual(h.controller.signItems.map(\.url.lastPathComponent), ["contract.pdf", "note.txt"])
        XCTAssertEqual(h.controller.signItems.map(\.format), [.padesT, .xadesT])
        h.controller.addFiles([first.path])
        XCTAssertEqual(h.controller.signItems.count, 2)
        let note = h.controller.signItems[1].id
        h.controller.setFormat(.xadesC, for: note)
        XCTAssertEqual(h.controller.signItems[1].format, .xadesC)
        h.controller.setStamp(PDFStampPlacement(page: 0), for: h.controller.signItems[0].id)
        XCTAssertNotNil(h.controller.signItems[0].stamp)
        h.controller.setFormat(.xadesBES, for: UUID())
        h.controller.remove(note)
        XCTAssertEqual(h.controller.signItems.count, 1)
        XCTAssertTrue(h.controller.canSign)
    }

    // MARK: - Signing

    func testSigningAsksForThePINAndRecordsEachResult() throws {
        let h = make()
        h.controller.addFiles([try pdf().path])
        h.controller.signAll()
        XCTAssertTrue(h.settle(until: { h.pinRequests.count == 1 }))
        let request = h.pinRequests[0].request
        XCTAssertEqual(request.holder, "POPESCU ION")
        XCTAssertTrue(request.purpose.contains("contract.pdf"))
        XCTAssertTrue(request.canRemember)
        XCTAssertNil(request.vaultProblem)
        XCTAssertEqual(h.presented, 1)
        XCTAssertFalse(h.controller.canSign)
        h.pinRequests[0].answer(PinEntry(pin: "1234", remember: true))
        XCTAssertTrue(h.settle(until: { !h.controller.isSigning }, timeout: 3))
        XCTAssertEqual(h.signer.signed.map(\.pin), ["1234"])
        XCTAssertEqual(h.controller.lastSigned.map(\.lastPathComponent), ["contract-semnat.pdf"])
        XCTAssertTrue(h.controller.signItems.isEmpty)
        XCTAssertEqual(h.vault.saves.map(\.certID), ["cert0"])
        XCTAssertTrue(h.controller.hasStoredPIN)
        XCTAssertNil(h.controller.currentStep)
        XCTAssertEqual(h.controller.activity.first?.kind, .signed)
        XCTAssertEqual(h.controller.signedDocuments.count, 1)
        XCTAssertEqual(h.activity.documents.count, 1)
        XCTAssertEqual(h.actionToasts.count, 1)
        h.actionToasts[0].action()
        XCTAssertEqual(h.revealed.map(\.lastPathComponent), ["contract-semnat.pdf"])
    }

    func testStoredPINIsUsedOnlyAfterConfirmation() throws {
        let h = make()
        h.vault.stored["cert0"] = "4321"
        h.controller.addFiles([try pdf().path, try pdf("second.pdf").path])
        h.controller.signAll()
        XCTAssertTrue(h.settle(until: { h.confirmations.count == 1 }))
        XCTAssertTrue(h.confirmations[0].body.contains("POPESCU ION"))
        XCTAssertTrue(h.pinRequests.isEmpty)
        h.confirmations[0].answer(true)
        XCTAssertTrue(h.settle(until: { !h.controller.isSigning }, timeout: 3))
        XCTAssertEqual(h.signer.signed.map(\.pin), ["4321", "4321"])
        XCTAssertTrue(h.vault.saves.isEmpty, "A stored PIN is not saved again")
        XCTAssertTrue(h.toasts.contains { $0.contains("2") })
    }

    func testDecliningThePINOrConfirmationLeavesTheQueue() throws {
        let h = make()
        h.controller.addFiles([try pdf().path])
        h.controller.signAll()
        XCTAssertTrue(h.settle(until: { h.pinRequests.count == 1 }))
        h.pinRequests[0].answer(nil)
        h.settle()
        XCTAssertFalse(h.controller.isSigning)
        XCTAssertEqual(h.controller.signItems.count, 1)
        h.vault.stored["cert0"] = "4321"
        h.controller.signAll()
        XCTAssertTrue(h.settle(until: { h.confirmations.count == 1 }))
        h.confirmations[0].answer(false)
        h.settle()
        XCTAssertTrue(h.signer.signed.isEmpty)
    }

    func testWrongPINStopsDeletesTheStoredPINAndShowsAttempts() throws {
        let h = make()
        h.signer.failures["contract.pdf"] = CardError.wrongPIN(remaining: 2)
        h.controller.addFiles([try pdf().path, try pdf("second.pdf").path])
        h.controller.signAll()
        XCTAssertTrue(h.settle(until: { h.pinRequests.count == 1 }))
        h.pinRequests[0].answer(PinEntry(pin: "0000", remember: true))
        XCTAssertTrue(h.settle(until: { !h.controller.isSigning }, timeout: 3))
        XCTAssertEqual(h.signer.signed.count, 1, "A wrong PIN is never retried")
        XCTAssertEqual(h.controller.lastAttemptsLeft, 2)
        XCTAssertEqual(h.vault.deleted, ["cert0"])
        XCTAssertEqual(h.controller.lastError?.message, L10n.text(.ui_incorrect_pin))
        XCTAssertEqual(h.controller.signItems.first?.error, L10n.text(.ui_incorrect_pin))
        XCTAssertEqual(h.controller.activity.first?.kind, .failed)
        XCTAssertFalse(h.toasts.isEmpty)
        h.controller.signAll()
        XCTAssertTrue(h.settle(until: { h.pinRequests.count == 2 }))
        XCTAssertEqual(h.pinRequests[1].request.attemptsLeft, 2)
        h.pinRequests[1].answer(nil)
        h.controller.selectCard(Fixtures.readers[0])
        h.settle()
    }

    func testDocumentFailureContinuesTheBatchAndRetryTargetsOneItem() throws {
        let h = make()
        h.signer.failures["broken.pdf"] = CardError.signFailed("bad PDF")
        h.controller.addFiles([try pdf("broken.pdf").path, try pdf().path])
        h.controller.signAll()
        XCTAssertTrue(h.settle(until: { h.pinRequests.count == 1 }))
        h.pinRequests[0].answer(PinEntry(pin: "1234", remember: false))
        XCTAssertTrue(h.settle(until: { !h.controller.isSigning }, timeout: 3))
        XCTAssertEqual(h.signer.signed.count, 2)
        XCTAssertEqual(h.controller.signItems.map(\.url.lastPathComponent), ["broken.pdf"])
        XCTAssertNotNil(h.controller.signItems[0].error)
        h.signer.failures = [:]
        h.controller.retry(h.controller.signItems[0].id)
        XCTAssertTrue(h.settle(until: { h.pinRequests.count == 2 }))
        h.pinRequests[1].answer(PinEntry(pin: "1234", remember: false))
        XCTAssertTrue(h.settle(until: { h.controller.signItems.isEmpty }, timeout: 3))
        h.controller.retry(UUID())
    }

    func testBlockedStuckAndChangedCardsHaveTheirRecovery() throws {
        for (error, check) in [
            (CardError.pinBlocked as Error, { (h: ControllerHarness) in XCTAssertEqual(h.vault.deleted, ["cert0"]) }),
            (CardError.apduError(0x6985), { h in
                XCTAssertNil(h.controller.cards.first?.certificate)
                if case .error = h.controller.status {} else { XCTFail("A stuck card must show an error") }
            }),
            (CardError.cardChanged, { h in XCTAssertGreaterThan(h.cardData.reads.count, 1) }),
        ] {
            let h = make()
            h.signer.failures["contract.pdf"] = error
            h.controller.addFiles([try pdf().path])
            h.controller.signAll()
            XCTAssertTrue(h.settle(until: { h.pinRequests.count == 1 }))
            h.pinRequests[0].answer(PinEntry(pin: "1234", remember: false))
            XCTAssertTrue(h.settle(until: { !h.controller.isSigning }, timeout: 3))
            check(h)
            XCTAssertNotNil(h.controller.lastError)
            h.controller.shutdown()
        }
    }

    func testUnavailableKeyringDisablesRememberingAndIsReported() throws {
        let h = make()
        h.vault.unavailable = "No Secret Service"
        h.controller.addFiles([try pdf().path])
        h.controller.signAll()
        XCTAssertTrue(h.settle(until: { h.pinRequests.count == 1 }))
        XCTAssertFalse(h.pinRequests[0].request.canRemember)
        XCTAssertEqual(h.pinRequests[0].request.vaultProblem, L10n.text(.linux_keyring_unavailable))
        XCTAssertEqual(h.controller.vaultProblem, L10n.text(.linux_keyring_unavailable))
        h.pinRequests[0].answer(nil)
    }

    func testSigningWithoutUIHooksEndsCleanly() throws {
        let h = make()
        h.controller.askPIN = nil
        h.controller.addFiles([try pdf().path])
        h.controller.signAll()
        XCTAssertTrue(h.settle(until: { !h.controller.isSigning }))
        h.vault.stored["cert0"] = "1234"
        h.controller.askConfirm = nil
        h.controller.signAll()
        XCTAssertTrue(h.settle(until: { !h.controller.isSigning }))
        XCTAssertTrue(h.signer.signed.isEmpty)
    }

    // MARK: - Saved PINs

    func testForgettingPINsUpdatesCardsAndReportsFailures() {
        let h = make(cards: 2)
        h.vault.stored = ["cert0": "1", "cert1": "2"]
        h.controller.forgetPIN()
        XCTAssertTrue(h.settle(until: { h.vault.deleted == ["cert0"] && !h.toasts.isEmpty }))
        h.controller.forgetPIN(forCertificateID: "cert1")
        XCTAssertTrue(h.settle(until: { h.vault.deleted.count == 2 }))
        XCTAssertEqual(h.controller.selectedReaderName, Fixtures.readers[0], "Deleting another card's PIN keeps the selection")
        h.controller.forgetAllPINs()
        XCTAssertTrue(h.settle(until: { h.toasts.contains(L10n.text(.ui_the_saved_pins_were_deleted)) }))
        h.vault.deleteAllResult = false
        h.controller.forgetAllPINs()
        XCTAssertTrue(h.settle(until: { h.toasts.contains(L10n.text(.ui_the_pins_could_not_be_deleted)) }))
        XCTAssertFalse(h.controller.cards.contains(where: \.hasStoredPIN))
    }

    // MARK: - Verification

    func testVerifyRecordsTheVerdictAndOriginalsCanBeAdded() throws {
        let h = make()
        let signed = try pdf("signed.pdf"), detached = try Fixtures.file(in: folder, name: "sig.xml")
        h.verifier.reports["signed.pdf"] = [Fixtures.report()]
        var incomplete = Fixtures.report(kind: "XAdES")
        incomplete.missingDetachedReferences = ["original.txt"]
        h.verifier.reports["sig.xml"] = [incomplete]
        h.controller.verify(path: signed.path)
        XCTAssertEqual(h.controller.verifyFile, signed)
        XCTAssertTrue(h.settle(until: { h.controller.verifyReports != nil }))
        XCTAssertEqual(h.controller.verifyReports?.count, 1)
        XCTAssertEqual(h.controller.activity.first?.kind, .verified)
        XCTAssertEqual(h.controller.activity.first?.ok, true)
        h.controller.verify(paths: [signed.path, detached.path])
        XCTAssertTrue(h.settle(until: { h.controller.verifiedDocuments.count == 2 }))
        h.controller.verifyOriginals(path: detached.path, companions: [signed])
        XCTAssertTrue(h.settle(until: { h.verifier.requests.last?.companions == ["signed.pdf"] && h.controller.verifyReports != nil }))
        XCTAssertEqual(h.controller.activity.first?.ok, false)
        h.controller.resetVerify()
        XCTAssertNil(h.controller.verifyFile)
        XCTAssertTrue(h.controller.verifiedDocuments.isEmpty)
    }

    func testInspectingADocumentNeedsAReadableFileAndCreatesNoHistory() throws {
        let h = make()
        let signed = try pdf("signed.pdf")
        h.verifier.reports["signed.pdf"] = [Fixtures.report()]
        var result: [SignatureReport]?? = .none
        h.controller.inspectDocument(path: signed.path) { result = .some($0) }
        XCTAssertTrue(h.settle(until: { result != nil }))
        XCTAssertEqual(result??.count, 1)
        result = .none
        h.controller.inspectDocument(path: folder.appendingPathComponent("gone.pdf").path) { result = .some($0) }
        XCTAssertTrue(h.settle(until: { result != nil }))
        XCTAssertNil(result!)
        XCTAssertTrue(h.controller.activity.isEmpty)
    }

    // MARK: - Browser bridge

    func testBridgeLifecycleFollowsTheSetting() {
        let h = make()
        h.controller.setBridgeEnabled(true)
        XCTAssertEqual(h.bridge.starts, 1)
        XCTAssertTrue(h.controller.settings.bridgeEnabled)
        XCTAssertEqual(h.controller.bridgeState, .running)
        XCTAssertNotNil(h.bridge.authorize)
        h.controller.setLegacyDesktopClientEnabled(true)
        XCTAssertTrue(h.bridge.allowsLegacyDesktopClient)
        XCTAssertEqual(h.bridge.starts, 2)
        h.controller.setBrowserStampsEnabled(true)
        XCTAssertEqual(h.bridge.previewPDFEnabled?(), true)
        h.controller.setBridgeEnabled(false)
        XCTAssertEqual(h.controller.bridgeState, .stopped)
        h.controller.setLegacyDesktopClientEnabled(false)
        XCTAssertEqual(h.bridge.starts, 2)
    }

    func testExperimentalTokensFollowTheSetting() {
        let service = SigningService()
        let h = make(service: service)
        XCTAssertFalse(h.controller.settings.experimentalTokensEnabled)
        XCTAssertFalse(service.experimentalTokens, "off by default")
        h.controller.setExperimentalTokensEnabled(true)
        XCTAssertTrue(h.controller.settings.experimentalTokensEnabled)
        XCTAssertTrue(service.experimentalTokens)
        h.controller.setExperimentalTokensEnabled(false)
        XCTAssertFalse(service.experimentalTokens)
    }

    func testBrowserRequestNeedsConsentThenAPINAndMarksSigning() {
        let h = make()
        h.controller.setBridgeEnabled(true)
        var decision: BridgeDecision?
        let request = BridgeRequest(origin: "https://msign.gov.md", operation: .signPDF, documentName: "cerere.pdf",
                                    format: "PAdES", pinIncluded: false)
        h.bridge.authorize?(request) { decision = $0 }
        XCTAssertEqual(h.consents.count, 1)
        XCTAssertEqual(h.consents[0].request.originHost, "msign.gov.md")
        XCTAssertEqual(h.consents[0].request.holder, "POPESCU ION")
        h.consents[0].answer(true, true)
        XCTAssertTrue(h.settle(until: { h.pinRequests.count == 1 }))
        XCTAssertTrue(h.pinRequests[0].request.purpose.contains("msign.gov.md · cerere.pdf"))
        XCTAssertFalse(h.pinRequests[0].request.canRemember)
        h.pinRequests[0].answer(PinEntry(pin: "1234", remember: false))
        guard case .allow(let pin, let certificate)? = decision else { return XCTFail("Expected allow") }
        XCTAssertEqual(pin, "1234")
        XCTAssertEqual(certificate, "cert0")
        XCTAssertTrue(h.controller.bridgeSigning)
        XCTAssertEqual(h.controller.statusLight.light, .busy)
        h.bridge.onSignResult?(request, nil)
        XCTAssertFalse(h.controller.bridgeSigning)
        XCTAssertEqual(h.controller.activity.first?.kind, .bridge)
        // Trusted for 10 minutes: no second consent, the page's PIN is used directly.
        decision = nil
        h.bridge.authorize?(BridgeRequest(origin: "https://msign.gov.md", operation: .signData, documentName: nil,
                                          format: "XAdES-T", pinIncluded: true)) { decision = $0 }
        XCTAssertEqual(h.consents.count, 1)
        guard case .allow(nil, _)? = decision else { return XCTFail("Expected allow without a PIN") }
    }

    func testBrowserRequestIsDeniedWhileSigningOrWhenRefused() throws {
        let h = make()
        h.controller.setBridgeEnabled(true)
        var decisions: [BridgeDecision] = []
        let request = BridgeRequest(origin: "https://example.org", operation: .signFile, documentName: nil, format: nil, pinIncluded: false)
        h.bridge.authorize?(request) { decisions.append($0) }
        h.consents.last?.answer(false, false)
        h.controller.askConsent = nil
        h.bridge.authorize?(request) { decisions.append($0) }
        h.controller.addFiles([try pdf().path])
        h.controller.signAll()
        h.bridge.authorize?(request) { decisions.append($0) }
        XCTAssertEqual(decisions.count, 3)
        for decision in decisions { if case .allow = decision { XCTFail("Expected deny") } }
        XCTAssertTrue(h.settle(until: { h.pinRequests.count == 1 }))
        h.pinRequests[0].answer(nil)
    }

    func testRejectedBrowserPINsAreForgottenAndChangedCardsReread() {
        let h = make()
        h.controller.setBridgeEnabled(true)
        h.vault.stored["cert0"] = "1111"
        let request = BridgeRequest(origin: "https://msign.gov.md", operation: .signPDF, documentName: "a.pdf", format: "PAdES", pinIncluded: true)
        h.bridge.onSignResult?(request, CardError.wrongPIN(remaining: 1))
        XCTAssertEqual(h.vault.deleted, ["cert0"])
        XCTAssertEqual(h.controller.lastAttemptsLeft, 1)
        XCTAssertTrue(h.toasts.last?.contains("1") == true)
        h.bridge.onSignResult?(request, CardError.pinBlocked)
        XCTAssertEqual(h.toasts.last, L10n.text(.ui_pin_blocked_unblock_it_at_cev))
        let reads = h.cardData.reads.count
        h.bridge.onSignResult?(request, CardError.cardChanged)
        XCTAssertGreaterThan(h.cardData.reads.count, reads)
        h.bridge.onSignResult?(request, CardError.noCard)
        XCTAssertEqual(h.controller.activity.first?.kind, .failed)
        XCTAssertEqual(h.controller.activity.count, 4)
    }

    func testBrowserStampPreviewUsesAPrivateCopyAndHonoursTheSetting() {
        let h = make()
        h.controller.setBridgeEnabled(true)
        let request = BridgeRequest(origin: "https://msign.gov.md", operation: .signPDF, documentName: "a.pdf", format: "PAdES", pinIncluded: false)
        var answers: [PDFStampDecision] = []
        h.bridge.previewPDF?(request, Data("%PDF-1.4".utf8)) { answers.append($0) }
        guard case .proceed(nil)? = answers.last else { return XCTFail("Disabled stamps proceed without a stamp") }
        h.controller.setBrowserStampsEnabled(true)
        h.bridge.previewPDF?(request, Data("%PDF-1.4".utf8)) { answers.append($0) }
        XCTAssertEqual(h.stamps.count, 1)
        let staged = h.stamps[0].item.url
        XCTAssertTrue(FileManager.default.fileExists(atPath: staged.path))
        XCTAssertEqual(h.stamps[0].origin, "https://msign.gov.md")
        XCTAssertNotNil(h.stamps[0].item.stamp)
        XCTAssertTrue(h.controller.bridgeSigning)
        h.stamps[0].answer(.proceed(PDFStampPlacement()))
        XCTAssertFalse(FileManager.default.fileExists(atPath: staged.path), "The staged copy is removed after the answer")
        guard case .proceed(.some)? = answers.last else { return XCTFail("Expected the chosen stamp") }
        h.controller.askStamp = nil
        h.bridge.previewPDF?(request, Data()) { answers.append($0) }
        guard case .cancel? = answers.last else { return XCTFail("Without an editor the request is cancelled") }
        XCTAssertEqual(answers.count, 3)
    }

    func testStoppingTheBridgeCancelsAPendingConsentAndOpenPreview() {
        let h = make()
        h.controller.setBridgeEnabled(true)
        h.controller.setBrowserStampsEnabled(true)
        let request = BridgeRequest(origin: "https://msign.gov.md", operation: .signPDF, documentName: "a.pdf", format: "PAdES", pinIncluded: false)
        var decision: BridgeDecision?
        h.bridge.authorize?(request) { decision = $0 }
        h.bridge.previewPDF?(request, Data("%PDF".utf8)) { _ in }
        h.controller.restartBridge()
        guard case .deny? = decision else { return XCTFail("Restart must deny the pending request") }
        XCTAssertEqual(h.stampCancelled, 1)
        XCTAssertEqual(h.bridge.stops, 1)
    }

    func testBridgeActivityDescribesOriginFormatAndBatch() {
        let sha1 = BridgeRequest(origin: "https://msign.gov.md/x", operation: .signData, documentName: "lot.xml",
                                 format: "XAdES-T", pinIncluded: false, algorithm: "SHA-1", batchSession: "s1")
        let item = AppController.bridgeActivity(sha1, nil)
        XCTAssertEqual(item.kind, .bridge)
        XCTAssertEqual(item.title, "msign.gov.md")
        XCTAssertTrue(item.subtitle.contains("SHA-1"))
        XCTAssertTrue(item.subtitle.contains("lot.xml"))
        let failed = AppController.bridgeActivity(BridgeRequest(origin: nil, operation: .signPDF, documentName: nil, format: nil, pinIncluded: false),
                                                  CardError.noCard)
        XCTAssertEqual(failed.title, "localhost")
        XCTAssertFalse(failed.ok)
        XCTAssertTrue(failed.subtitle.contains(L10n.text(.ui_insert_the_card)))
    }

    func testImportingTheHTTPSIdentityValidatesAndRestarts() throws {
        let h = make()
        h.controller.setBridgeEnabled(true)
        let invalid = try Fixtures.file(in: folder, name: "personal.p12", contents: "not pkcs12")
        h.controller.importBridgeIdentity(from: invalid)
        XCTAssertEqual(h.toasts.last, L10n.text(.ui_the_file_does_not_contain_the_moldsign_https_identity_choose_localhost_p12_from_moldsign))
        h.controller.importBridgeIdentity(from: folder.appendingPathComponent("missing.p12"))
        XCTAssertNotEqual(h.toasts.last, L10n.text(.ui_the_https_identity_was_imported))
        let identity = try XCTUnwrap(TestEnvironment.bridgeIdentity)
        let source = folder.appendingPathComponent("localhost.p12")
        try identity.write(to: source)
        h.controller.importBridgeIdentity(from: source)
        XCTAssertEqual(h.toasts.last, L10n.text(.ui_the_https_identity_was_imported))
        XCTAssertEqual(try Data(contentsOf: Store.bridgeIdentityURL), identity)
        let mode = try FileManager.default.attributesOfItem(atPath: Store.bridgeIdentityURL.path)[.posixPermissions] as? NSNumber
        XCTAssertEqual(mode?.intValue, 0o600)
        XCTAssertEqual(h.bridge.starts, 2)
        try? FileManager.default.removeItem(at: Store.bridgeIdentityURL)
    }

    // MARK: - Settings

    func testPreferencesPersistAndBackgroundNeedsAReason() {
        let h = make()
        XCTAssertFalse(h.controller.shouldRunInBackground)
        h.controller.setShowOnCardInsertion(true)
        XCTAssertTrue(h.settings.value.showOnCardInsertion)
        XCTAssertTrue(h.controller.shouldRunInBackground)
        h.controller.setRunInBackground(false)
        XCTAssertFalse(h.controller.shouldRunInBackground)
        h.controller.setRunInBackground(true)
        h.controller.setShowOnCardInsertion(false)
        h.controller.setBridgeEnabled(true)
        XCTAssertTrue(h.controller.shouldRunInBackground)
        h.controller.completeOnboarding()
        XCTAssertTrue(h.settings.value.onboardingCompleted)
        h.controller.setLanguage("ro")
        XCTAssertEqual(L10n.language, "ro")
        XCTAssertEqual(h.settings.value.language, "ro")
        h.controller.setLanguage("system")
        XCTAssertNil(L10n.language)
        XCTAssertEqual(h.toasts.count, 2)
    }

    func testStartAtLoginWaitsForTheRegistrationAnswer() {
        let h = make()
        h.controller.setLaunchAtLogin(true)
        XCTAssertTrue(h.controller.configuringLoginStartup)
        h.controller.setLaunchAtLogin(false)
        XCTAssertEqual(h.loginRequests.count, 1, "One registration at a time")
        h.loginRequests[0].answer(true)
        XCTAssertFalse(h.controller.configuringLoginStartup)
        XCTAssertTrue(h.settings.value.launchAtLogin)
        XCTAssertTrue(h.settings.value.runInBackground)
        h.controller.setLaunchAtLogin(false)
        h.loginRequests[1].answer(false)
        XCTAssertTrue(h.settings.value.launchAtLogin, "A refused change keeps the old value")
        XCTAssertEqual(h.toasts.last, L10n.text(.ui_could_not_configure_start_at_login))
    }

    func testAutomationApprovalPreparesItsPrivateSpool() {
        let h = make()
        h.controller.setAgentApprovalEnabled(true)
        XCTAssertTrue(h.settings.value.agentApprovalEnabled)
        XCTAssertTrue(FileManager.default.fileExists(atPath: AgentApprovalBroker.directory.appendingPathComponent("requests").path))
        XCTAssertTrue(h.controller.shouldRunInBackground)
        h.controller.setAgentApprovalEnabled(false)
        XCTAssertFalse(h.settings.value.agentApprovalEnabled)
    }

    // MARK: - Documents and history

    func testHistoryIsBoundedAndProtectionOutputsAreSaved() throws {
        let seed = (0..<Store.activityLimit).map { ActivityItem(kind: .bridge, title: "\($0)", subtitle: "", ok: true) }
        let h = make(activity: seed)
        let output = try Fixtures.file(in: folder, name: "a.pdf.symmetric.p7m")
        h.controller.recordProtectionOutput(path: output.path, encrypted: true)
        XCTAssertEqual(h.controller.activity.count, Store.activityLimit)
        XCTAssertEqual(h.controller.activity.first?.kind, .encrypted)
        XCTAssertEqual(h.controller.signedDocuments.first?.filePath, output.path)
        h.controller.recordProtectionOutput(path: output.path, encrypted: false)
        XCTAssertEqual(h.controller.signedDocuments.count, 1, "The same file appears once in the library")
        XCTAssertEqual(h.controller.signedDocuments.first?.kind, .decrypted)
    }

    func testDeletingSavedDocumentsAndClearingHistoryReportFailures() throws {
        let kept = try Fixtures.file(in: folder, name: "kept-semnat.pdf")
        let item = ActivityItem(kind: .signed, title: kept.lastPathComponent, subtitle: "", ok: true, filePath: kept.path)
        let h = make(activity: [item], documents: [item])
        h.activity.documentsSaveSucceeds = false
        h.controller.clearActivity()
        XCTAssertEqual(h.toasts.last, L10n.text(.saved_library_save_failed))
        XCTAssertEqual(h.controller.activity.count, 1, "History is kept when the library cannot be saved")
        h.controller.deleteSignedDocuments([item])
        XCTAssertEqual(h.toasts.last, L10n.text(.saved_library_save_failed))
        h.activity.documentsSaveSucceeds = true
        h.controller.clearActivity()
        XCTAssertTrue(h.controller.activity.isEmpty)
        let foreign = ActivityItem(kind: .signed, title: "x", subtitle: "", ok: true, filePath: "/etc/hostname")
        h.controller.deleteSignedDocuments([foreign])
        XCTAssertTrue(FileManager.default.fileExists(atPath: "/etc/hostname"))
        h.controller.deleteSignedDocuments([item])
        XCTAssertTrue(h.controller.signedDocuments.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: kept.path))
    }

    // MARK: - Automation (agent) signing

    func testAgentSigningIsRefusedWithoutApprovalUIOrCard() {
        let h = make(cards: 0)
        var results: [Result<Data, Error>] = []
        h.controller.signAgentPDF(Data("%PDF".utf8), name: "a.pdf", stagingURL: folder.appendingPathComponent("a.pdf"),
                                  authorized: { true }, willSign: {}, completion: { results.append($0) })
        h.controller.askAgentApproval = nil
        h.controller.signAgentPDF(Data("%PDF".utf8), name: "a.pdf", stagingURL: folder.appendingPathComponent("a.pdf"),
                                  authorized: { true }, willSign: {}, completion: { results.append($0) })
        XCTAssertEqual(results.count, 2)
        if case .failure(AppController.AgentSigningError.noCard) = results[0] {} else { XCTFail("Expected no card") }
        if case .failure(AppController.AgentSigningError.unavailable) = results[1] {} else { XCTFail("Expected unavailable") }
    }

    func testAgentSigningShowsPreviewApprovalAndPINAndForgetsARejectedPIN() {
        let h = make(transport: { _ in throw CardError.wrongPIN(remaining: 1) })
        h.vault.stored["cert0"] = "9999"
        var result: Result<Data, Error>?
        var started = false
        h.controller.signAgentPDF(Data("%PDF-1.4".utf8), name: "agent.pdf", stagingURL: folder.appendingPathComponent("agent.pdf"),
                                  authorized: { true }, willSign: { started = true }, completion: { result = $0 })
        XCTAssertTrue(h.controller.isSigning)
        XCTAssertEqual(h.stamps.count, 1)
        h.stamps[0].answer(.proceed(nil))
        XCTAssertEqual(h.approvals.count, 1)
        XCTAssertTrue(h.approvals[0].body.contains("agent.pdf"))
        h.approvals[0].answer(true)
        XCTAssertTrue(h.settle(until: { result != nil }, timeout: 3), "A stored PIN is used without a dialog")
        XCTAssertTrue(started)
        guard case .failure(CardError.wrongPIN)? = result else { return XCTFail("Expected the card error") }
        XCTAssertEqual(h.vault.deleted, ["cert0"])
        XCTAssertFalse(h.controller.isSigning)
    }

    func testAgentSigningCancellationsAtEachStep() {
        let h = make()
        var results: [Result<Data, Error>] = []
        func start() {
            h.controller.signAgentPDF(Data("%PDF".utf8), name: "a.pdf", stagingURL: folder.appendingPathComponent("a.pdf"),
                                      authorized: { true }, willSign: {}, completion: { results.append($0) })
        }
        start(); h.stamps.last?.answer(.cancel)
        start(); h.stamps.last?.answer(.proceed(nil)); h.approvals.last?.answer(false)
        start(); h.stamps.last?.answer(.proceed(nil)); h.approvals.last?.answer(true)
        XCTAssertTrue(h.settle(until: { h.pinRequests.count == 1 }))
        h.pinRequests[0].answer(nil)
        start(); h.controller.cancelAgentPreview()
        XCTAssertEqual(h.stampCancelled, 1)
        XCTAssertEqual(results.count, 3)
        for result in results {
            if case .failure(AppController.AgentSigningError.cancelled) = result {} else { XCTFail("Expected cancelled") }
        }
    }

    // MARK: - Demo session

    func testDemoSessionUsesFictionalCardsAndNoExternalServices() {
        let demo = DemoMode("2")
        let monitor = FakeMonitor(), bridge = FakeBridge(), settings = TestSettings(), vault = FakeVault()
        settings.value.bridgeEnabled = true
        let controller = AppController(vault: vault, monitor: monitor, settingsStore: settings, bridge: bridge, demo: demo)
        var toasts: [String] = []
        controller.toast = { toasts.append($0) }
        controller.start()
        defer { controller.shutdown() }
        XCTAssertTrue(controller.isDemo)
        XCTAssertEqual(monitor.started, 0)
        XCTAssertEqual(bridge.starts, 0)
        XCTAssertFalse(controller.settings.bridgeEnabled)
        XCTAssertTrue(settings.value.bridgeEnabled, "The real settings are untouched")
        XCTAssertNil(controller.backgroundStatusText, "A preview never publishes fictional cards to the Background portal")
        XCTAssertTrue(GTKTest.pump(until: { controller.cards.allSatisfy { $0.certificate != nil } && controller.cards.count == 2 }, timeout: 3))
        XCTAssertEqual(controller.certificate?.holder, "POPESCU ION")
        controller.setAgentApprovalEnabled(true)
        XCTAssertFalse(controller.settings.agentApprovalEnabled)
        controller.setBridgeEnabled(true)
        XCTAssertEqual(bridge.starts, 0)
        controller.forgetAllPINs()
        XCTAssertEqual(vault.deletedAll, 0)
        controller.retryCard()
        XCTAssertEqual(monitor.refreshed, 0)
        for value in ["noreader", "pcscd", "empty", "error", "4"] {
            let session = DemoMode(value)
            XCTAssertEqual(session.snapshot.slots.count, ["4": 4, "empty": 1, "error": 1][value] ?? 0, value)
        }
    }

    func testDemoSigningIsDisabledUnlessAScenarioRuns() throws {
        let controller = AppController(vault: FakeVault(), monitor: FakeMonitor(), settingsStore: TestSettings(), bridge: FakeBridge(),
                                       demo: DemoMode("1"))
        var toasts: [String] = []
        controller.toast = { toasts.append($0) }
        controller.start()
        defer { controller.shutdown() }
        XCTAssertTrue(GTKTest.pump(until: { controller.status.canSign }, timeout: 3))
        controller.addFiles([try pdf().path])
        controller.signAll()
        XCTAssertEqual(toasts, [L10n.text(.ui_demo_mode_signing_is_disabled)])
        XCTAssertFalse(controller.isSigning)
    }
}
