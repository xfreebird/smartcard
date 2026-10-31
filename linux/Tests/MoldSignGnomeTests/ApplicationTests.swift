import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome

final class ApplicationTests: XCTestCase {
    func testBackgroundCannotSuppressFirstPresentation() {
        let store = LaunchMemory()
        let policy = ActivationPolicy(store: store)
        XCTAssertEqual(policy.destination(backgroundRequested: true, backgroundAllowed: true), .mainWindow)
        XCTAssertFalse(store.hasPresentedMainWindow)
        policy.mainWindowDidPresent()
        XCTAssertTrue(store.hasPresentedMainWindow)
        XCTAssertEqual(ActivationPolicy(store: store).destination(backgroundRequested: true, backgroundAllowed: true), .background)
    }

    func testExplicitLaunchAlwaysPresentsWindow() {
        let store = LaunchMemory(); store.hasPresentedMainWindow = true
        XCTAssertEqual(ActivationPolicy(store: store).destination(backgroundRequested: false, backgroundAllowed: true), .mainWindow)
        XCTAssertEqual(ActivationPolicy(store: store).destination(backgroundRequested: true, backgroundAllowed: false), .mainWindow)
    }

    func testMissingCorruptAndRecordedLaunchState() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = JSONLaunchStateStore(url: directory.appendingPathComponent("launch.json"))
        XCTAssertFalse(store.hasPresentedMainWindow)
        store.recordMainWindowPresentation()
        XCTAssertTrue(store.hasPresentedMainWindow)
        try Data("broken".utf8).write(to: store.url)
        XCTAssertFalse(store.hasPresentedMainWindow)
    }

    func testSettingsEnableRequiredBackgroundAndPersist() {
        let store = SettingsMemory()
        let settings = SettingsCoordinator(store: store)
        settings.update { $0.runInBackground = false }
        settings.setLaunchAtLogin(true)
        XCTAssertTrue(store.value.launchAtLogin)
        XCTAssertTrue(store.value.runInBackground)
        settings.setLaunchAtLogin(false)
        settings.update { $0.runInBackground = false }
        settings.setShowOnCardInsertion(true)
        XCTAssertTrue(store.value.showOnCardInsertion)
        XCTAssertTrue(store.value.runInBackground)
    }

    func testBatchUsesFrozenIdentityAndStoresOnceAfterSuccess() {
        let signer = SignerSpy(); let vault = VaultSpy()
        let batch = BatchSigningService(signer: signer, vault: vault)
        var completed = 0
        let failure = batch.sign(items, pin: "0000", remember: true, cert: certificate, reader: "frozen-reader", progress: { _ in }) { _, result, stored in
            if case .failure(let error) = result { XCTFail("Unexpected error: \(error)") }
            XCTAssertTrue(stored)
            completed += 1
        }
        XCTAssertNil(failure)
        XCTAssertEqual(completed, 3)
        XCTAssertEqual(vault.saves, 1)
        XCTAssertEqual(signer.readers, Array(repeating: "frozen-reader", count: 3))
        XCTAssertEqual(signer.certificates, Array(repeating: "test-certificate", count: 3))
    }

    func testWrongPINStopsBatchDeletesStoredPINAndNeverRetries() {
        let signer = SignerSpy(); signer.failure = CardError.wrongPIN(remaining: 2)
        let vault = VaultSpy()
        let result = BatchSigningService(signer: signer, vault: vault).sign(items, pin: "0000", remember: true,
            cert: certificate, reader: "test", progress: { _ in }, completed: { _, _, _ in })
        XCTAssertNotNil(result)
        XCTAssertEqual(signer.readers.count, 1)
        XCTAssertEqual(vault.saves, 0)
        XCTAssertEqual(vault.deleted, ["test-certificate"])
    }

    func testUnavailableVaultDoesNotRepeatSaveOrStopAcceptedBatch() {
        let signer = SignerSpy(); let vault = VaultSpy(); vault.saveFails = true
        let result = BatchSigningService(signer: signer, vault: vault).sign(items, pin: "0000", remember: true,
            cert: certificate, reader: "test", progress: { _ in }) { _, _, stored in XCTAssertFalse(stored) }
        XCTAssertNil(result)
        XCTAssertEqual(signer.readers.count, 3)
        XCTAssertEqual(vault.saves, 1)
    }

    func testKeyedTranslationsKeepUserDataLiteral() {
        defer { L10n.language = nil }
        for language in ["ro", "en", "ru"] {
            L10n.language = language
            let filename = "report-%1$s.pdf"
            XCTAssertTrue(localized(.ui_document_signed_value, filename).contains(filename))
            XCTAssertFalse(localized(.linux_bridge_active, "18480", "18443").contains("%"))
        }
    }

    func testCertificateDateFollowsSelectedLanguage() {
        defer { L10n.language = nil }
        let date = Date(timeIntervalSince1970: 1_793_404_800)
        var rendered = Set<String>()
        for language in ["ro", "en", "ru"] {
            L10n.language = language
            rendered.insert(Format.longDate(date))
        }
        XCTAssertEqual(rendered.count, 3)
    }

    private var items: [SignItem] { (1...3).map { SignItem(url: URL(fileURLWithPath: "/tmp/test-\($0).pdf")) } }
    private var certificate: SigningService.CertificateSummary {
        .init(der: Data(), holder: "TEST", subjectDN: "", issuer: "", issuerName: "", serialDecimal: "", sha1Hex: "test-certificate", notAfter: nil)
    }
}

private final class LaunchMemory: LaunchStateStoring {
    var hasPresentedMainWindow = false
    func recordMainWindowPresentation() { hasPresentedMainWindow = true }
}
private final class SettingsMemory: SettingsStoring {
    var value = AppSettings()
    func load() -> AppSettings { value }
    func save(_ settings: AppSettings) { value = settings }
}
private final class SignerSpy: DocumentSigning {
    var failure: Error?
    var readers: [String] = []
    var certificates: [String] = []
    func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String,
              progress: @escaping (SigningService.Step) -> Void) throws -> URL {
        readers.append(reader); certificates.append(certificateSHA1)
        if let failure { throw failure }
        return item.url.appendingPathExtension("signed")
    }
}
private final class VaultSpy: PINStoring {
    var saves = 0
    var deleted: [String] = []
    var saveFails = false
    func save(_ pin: String, certID: String, holder: String) throws {
        saves += 1
        if saveFails { throw NSError(domain: "test", code: 1) }
    }
    func load(certID: String) -> PINLookup { .missing }
    func hasPIN(certID: String) -> Bool { false }
    func delete(certID: String) -> Bool { deleted.append(certID); return true }
    func deleteAll() -> Bool { true }
    func availabilityProblem() -> String? { nil }
}
