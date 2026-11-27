import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome

final class DomainTests: GnomeTestCase {
    override func setUp() { L10n.language = "en" }
    override func tearDown() { L10n.language = nil }

    func testStatusLightFollowsTheFiveStatesAndNeverUsesColorAlone() {
        let ready = StatusLight.from(status: .ready(reader: "R", holder: "ION", validUntil: nil), cardCount: 2, busy: false)
        XCTAssertEqual(ready.light, .ready)
        XCTAssertTrue(ready.text.contains("ION"))
        XCTAssertTrue(ready.text.contains("2"))
        let single = StatusLight.from(status: .ready(reader: "R", holder: "ION", validUntil: nil), cardCount: 1, busy: false)
        XCTAssertTrue(ready.text.hasPrefix(single.text), "Several cards add their count to the same text")
        XCTAssertNotEqual(ready.text, single.text)
        XCTAssertEqual(StatusLight.from(status: .noReader, cardCount: 0, busy: true).light, .busy)
        XCTAssertEqual(StatusLight.from(status: .reading(reader: "R"), cardCount: 1, busy: false).light, .reader)
        XCTAssertEqual(StatusLight.from(status: .empty(reader: "R"), cardCount: 0, busy: false).light, .reader)
        XCTAssertEqual(StatusLight.from(status: .busy(reader: "R", holder: "ION"), cardCount: 1, busy: false).light, .busy)
        let error = StatusLight.from(status: .error(message: "Broken", recovery: "Retry"), cardCount: 0, busy: false)
        XCTAssertEqual(error, StatusLight(light: .error, text: "Broken. Retry"))
        XCTAssertEqual(StatusLight.from(status: .error(message: "Broken", recovery: ""), cardCount: 0, busy: false).text, "Broken")
        let idle = StatusLight.from(status: .noReader, cardCount: 0, busy: false)
        XCTAssertEqual(idle.light, .idle)
        XCTAssertFalse(idle.text.isEmpty)
    }

    func testTrayStatusHasTwoStatesAndPrefersTheSelectedUsableCard() {
        let ion = CardSlot(reader: "A", generation: 1, certificate: Fixtures.certificate("ION"))
        let maria = CardSlot(reader: "B", generation: 1, certificate: Fixtures.certificate("MARIA", sha1: "bb"))
        let broken = CardSlot(reader: "C", generation: 1, problem: "mute")
        let reading = CardSlot(reader: "D", generation: 1)
        XCTAssertTrue(TrayStatus.from(cards: [ion, maria], selected: maria, status: .noReader).text.contains("MARIA"))
        XCTAssertTrue(TrayStatus.from(cards: [ion, broken], selected: broken, status: .noReader).text.contains("ION"))
        let anonymous = TrayStatus.from(cards: [reading], selected: nil, status: .noReader)
        XCTAssertTrue(anonymous.connected)
        XCTAssertFalse(anonymous.text.isEmpty)
        let failed = TrayStatus.from(cards: [broken], selected: broken, status: .error(message: "PC/SC", recovery: "Start it"))
        XCTAssertEqual(failed, TrayStatus(connected: false, text: "PC/SC. Start it"))
        XCTAssertEqual(TrayStatus.from(cards: [], selected: nil, status: .error(message: "PC/SC", recovery: "")).text, "PC/SC")
        XCTAssertFalse(TrayStatus.from(cards: [], selected: nil, status: .noReader).connected)
    }

    func testReaderStatusTextAndCapabilities() {
        let until = Date(timeIntervalSince1970: 1_900_000_000)
        let statuses: [ReaderStatus] = [.noReader, .empty(reader: "R"), .reading(reader: "R"),
                                        .ready(reader: "R", holder: "ION", validUntil: until), .busy(reader: "R", holder: "ION"),
                                        .error(message: "M", recovery: "Fix")]
        XCTAssertEqual(statuses.map(\.cardPresent), [false, false, true, true, true, false])
        XCTAssertEqual(statuses.map(\.canSign), [false, false, false, true, false, false])
        XCTAssertEqual(statuses[3].title, "ION")
        XCTAssertEqual(statuses[4].title, "ION")
        XCTAssertEqual(statuses[5].title, "M")
        XCTAssertEqual(statuses[5].subtitle, "Fix")
        XCTAssertEqual(statuses[1].subtitle, "R")
        XCTAssertTrue(statuses[3].subtitle.contains("R"))
        for status in statuses { XCTAssertFalse(status.title.isEmpty); _ = status.subtitle }
        XCTAssertTrue(statuses[3].validityText?.contains(Format.monthYear(until)) == true)
        XCTAssertNil(statuses[0].validityText)
        XCTAssertNil(ReaderStatus.ready(reader: "R", holder: "ION", validUntil: nil).validityText)
    }

    func testVerdictClassifiesReportsAndHasMatchingPresentation() {
        let valid = Verdict([Fixtures.report(), Fixtures.report()])
        guard case .valid(let count) = valid else { return XCTFail("Expected valid") }
        XCTAssertEqual(count, 2)
        XCTAssertEqual(valid.styleClass, "success")
        XCTAssertEqual(valid.icon, "security-high-symbolic")
        XCTAssertTrue(valid.subtitle.contains("2"))
        let untrusted = Verdict([Fixtures.report(trusted: false)])
        guard case .unknown = untrusted else { return XCTFail("Expected unknown chain") }
        XCTAssertEqual(untrusted.styleClass, "warning")
        let invalid = Verdict([Fixtures.report(intact: false)])
        guard case .invalid = invalid else { return XCTFail("Expected invalid") }
        XCTAssertEqual(invalid.icon, "dialog-error-symbolic")
        XCTAssertEqual(invalid.styleClass, "error")
        XCTAssertFalse(invalid.title.isEmpty)
        XCTAssertFalse(invalid.subtitle.isEmpty)
        var missing = Fixtures.report(intact: false)
        missing.missingDetachedReferences = ["original.txt"]
        let incomplete = Verdict([missing])
        guard case .incomplete = incomplete else { return XCTFail("Expected incomplete") }
        XCTAssertEqual(incomplete.icon, "dialog-warning-symbolic")
        XCTAssertNotEqual(incomplete.subtitle, Verdict([]).subtitle)
        XCTAssertEqual(Verdict([]).title, incomplete.title)
        XCTAssertFalse(Verdict([]).isValid)
    }

    func testFormatterOutputs() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertEqual(Format.relative(now.addingTimeInterval(-10), now: now), L10n.text(.ui_now))
        XCTAssertTrue(Format.relative(now.addingTimeInterval(-600), now: now).contains("10"))
        XCTAssertTrue(Format.relative(now.addingTimeInterval(-3 * 86_400), now: now).contains("."))
        XCTAssertEqual(Format.relative(now.addingTimeInterval(-7200), now: now).count, Calendar.current.isDate(now.addingTimeInterval(-7200), inSameDayAs: now) ? 5 : 16)
        XCTAssertEqual(Format.bytes(512), "512 B")
        XCTAssertEqual(Format.bytes(2048), "2 KB")
        XCTAssertEqual(Format.bytes(3 * 1024 * 1024), "3.0 MB")
        let date = Date(timeIntervalSince1970: 1_894_017_600) // 2030-01-07 12:00 UTC
        XCTAssertEqual(Format.monthYear(date), "01.2030")
        XCTAssertEqual(Format.cardDate(date), "07 01 2030")
        L10n.language = "de"
        XCTAssertFalse(Format.longDate(date).isEmpty)
    }

    func testCertificateLabelsTranslateKnownKeysAndKeepUnknownOnes() {
        XCTAssertEqual(CertificateLabels.label("Subject"), L10n.text(.cert_label_subject))
        XCTAssertEqual(CertificateLabels.label("Subject · Name"), L10n.text(.cert_label_subject) + " · " + L10n.text(.cert_label_name))
        XCTAssertEqual(CertificateLabels.label("Extension 1.2.3"), L10n.text(.cert_label_extension) + " 1.2.3")
        XCTAssertEqual(CertificateLabels.label("2.5.29.99"), "2.5.29.99")
        XCTAssertEqual(signatureLabels("PAdES-B-T"), L10n.text(.format_pdf_time))
        XCTAssertEqual(signatureLabels("XAdES-C · lot"), L10n.text(.format_xml_data) + " · lot")
        XCTAssertEqual(signatureLabels("CAdES"), "CAdES")
    }

    func testSigningStepsAndFormats() {
        XCTAssertEqual(SigningService.Step.allCases.map(UIStep.init),
                       [.card, .card, .card, .pin, .signature, .timestamp, .save, .save])
        XCTAssertEqual(Set(UIStep.allCases.map(\.label)).count, UIStep.allCases.count)
        let pdf = URL(fileURLWithPath: "/tmp/a.PDF"), text = URL(fileURLWithPath: "/tmp/a.txt")
        XCTAssertEqual(SignFormat.automatic(for: pdf), .padesT)
        XCTAssertEqual(SignFormat.automatic(for: text), .xadesT)
        XCTAssertEqual(SignFormat.choices(for: pdf).count, 4)
        XCTAssertEqual(SignFormat.choices(for: text), [.xadesBES, .xadesT, .xadesC])
        XCTAssertEqual(SignFormat.allCases.compactMap(\.xades).count, 3)
        XCTAssertEqual(SignFormat.allCases.map(\.outputExtension), ["pdf", "xml", "xml", "xml"])
        XCTAssertEqual(Set(SignFormat.allCases.map(\.label)).count, 4)
    }

    func testSignItemSizeTextReadsTheFile() throws {
        let folder = TestEnvironment.directory()
        let file = try Fixtures.file(in: folder, name: "a.txt", contents: String(repeating: "x", count: 2048))
        XCTAssertEqual(SignItem(url: file).sizeText, "2 KB")
        XCTAssertEqual(SignItem(url: folder.appendingPathComponent("missing.txt")).sizeText, "")
    }

    func testUserFacingErrorsHaveRecoveryText() {
        let cases: [(Error, String)] = [
            (CardError.wrongPIN(remaining: 2), L10n.text(.ui_incorrect_pin)),
            (CardError.pinBlocked, L10n.text(.linux_pin_blocked)),
            (CardError.noReader, L10n.text(.ui_connect_the_reader)),
            (CardError.noCard, L10n.text(.ui_insert_the_card)),
            (CardError.cardNotResponding, L10n.text(.ui_the_card_does_not_respond)),
            (CardError.cardChanged, L10n.text(.linux_card_changed)),
            (CardError.apduError(0x6985), L10n.text(.ui_the_card_is_in_an_invalid_state)),
            (CardError.apduError(0x6988), L10n.text(.ui_the_secure_session_was_interrupted)),
            (CardError.macVerificationFailed, L10n.text(.ui_the_secure_session_was_interrupted)),
            (CardError.signFailed("TSA timeout"), L10n.text(.ui_the_timestamp_service_is_not_responding)),
            (TrustServices.NetworkError.http("http://tsp", 500), L10n.text(.ui_pki_services_are_not_responding)),
            (CocoaError(.fileWriteNoPermission), L10n.text(.ui_the_signed_file_could_not_be_saved)),
            (CocoaError(.fileWriteFileExists), L10n.text(.ui_the_signed_file_could_not_be_saved)),
        ]
        for (error, message) in cases { XCTAssertEqual(UserFacingError.describe(error).message, message, "\(error)") }
        XCTAssertTrue(UserFacingError.describe(CardError.wrongPIN(remaining: 2)).recovery.contains("2"))
        XCTAssertFalse(UserFacingError.describe(CardError.signFailed("bad PDF")).message.isEmpty)
        XCTAssertTrue(UserFacingError.describe(UnsupportedTokenError(family: .ePass2003)).message.contains("Feitian ePass2003"))
        XCTAssertEqual(UserFacingError.describe(NSError(domain: "x", code: 1)).recovery, L10n.text(.ui_try_again))
        XCTAssertEqual(AppController.describe(CardError.pinBlocked).recovery, L10n.text(.ui_unblock_it_at_cev))
    }

    func testBridgeStateAndConsentDescriptions() {
        let states: [BridgeState] = [.stopped, .running, .identityRequired, .portBusy, .failed("boom")]
        XCTAssertEqual(Set(states.map(\.description)).count, states.count)
        XCTAssertTrue(BridgeState.running.description.contains("18480"))
        XCTAssertTrue(BridgeState.failed("boom").description.contains("boom"))
        let request = BridgeRequest(origin: "https://msign.gov.md", operation: .signPDF, documentName: "a.pdf", format: "PAdES", pinIncluded: false)
        XCTAssertEqual(ConsentRequest(request: request, holder: "ION", hasStoredPIN: false).originHost, "msign.gov.md")
        let local = BridgeRequest(origin: nil, operation: .signData, documentName: nil, format: nil, pinIncluded: true)
        XCTAssertEqual(ConsentRequest(request: local, holder: "ION", hasStoredPIN: true).originHost, L10n.text(.ui_a_local_application))
    }

    func testActivityItemsDistinguishSavedOutputsAndMissingFiles() throws {
        let folder = TestEnvironment.directory()
        let file = try Fixtures.file(in: folder, name: "a-semnat.pdf")
        let signed = ActivityItem(kind: .signed, title: "a", subtitle: "", ok: true, filePath: file.path)
        XCTAssertTrue(signed.isSignedDocument && signed.isSavedDocument && signed.isShowable)
        XCTAssertFalse(ActivityItem(kind: .failed, title: "a", subtitle: "", ok: false, filePath: file.path).isSavedDocument)
        XCTAssertTrue(ActivityItem(kind: .bridge, title: "a", subtitle: "", ok: true).isShowable)
        XCTAssertFalse(ActivityItem(kind: .signed, title: "a", subtitle: "", ok: true, filePath: folder.appendingPathComponent("gone").path).isShowable)
    }

    func testPlaceholderAndCardContentCoverEveryState() {
        let ready = CardSlot(reader: "Reader A", generation: 1, certificate: Fixtures.certificate("POPESCU ION"))
        let collapsed = CardItemContent(card: ready, index: 0, count: 2, busy: false, selected: true, expanded: false)
        XCTAssertEqual(collapsed.face.state, .ready)
        XCTAssertEqual(collapsed.face.surname, "POPESCU")
        XCTAssertTrue(collapsed.label.contains("POPESCU ION"))
        XCTAssertTrue(collapsed.label.contains("1"))
        XCTAssertEqual(collapsed.tooltip, L10n.text(.ui_card_details_switches_cards))
        XCTAssertEqual(CardItemContent(card: ready, index: 0, count: 1, busy: true, selected: true, expanded: false).face.state, .busy)
        XCTAssertEqual(CardItemContent(card: ready, index: 0, count: 1, busy: false, selected: true, expanded: false).tooltip, L10n.text(.linux_card_details))
        let expanded = CardItemContent(card: ready, index: 0, count: 2, busy: false, selected: false, expanded: true)
        XCTAssertTrue(expanded.label.contains("POPESCU ION"))
        XCTAssertEqual(expanded.disclosureTooltip, L10n.text(.ui_close_list))
        let anonymous = CardItemContent(card: CardSlot(reader: "Reader C", generation: 1), index: 0, count: 1, busy: false, selected: false, expanded: true)
        XCTAssertTrue(anonymous.label.contains("Reader C"))
        XCTAssertEqual(anonymous.tooltip, "")
        XCTAssertEqual(PlaceholderContent(status: .reading(reader: "R")).kind, .noReader)
    }
}
