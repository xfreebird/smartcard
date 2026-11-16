import XCTest
@testable import AppBatch

final class SavedCardIdentityStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!

    override func setUp() {
        suite = "md.esemnbun.qa.saved-card-tests.\(UUID())"
        defaults = UserDefaults(suiteName: suite)!
    }
    override func tearDown() { defaults.removePersistentDomain(forName: suite) }

    func testSameCertificateFromEitherTransportRestoresAsOneSavedIdentity() {
        let der = Data([0x30, 0x03, 1, 2, 3])
        let account = SavedCardIdentityStore.account(for: der)
        let store = SavedCardIdentityStore(defaults: defaults)
        store.remember(der) // Reader encounter.
        store.remember(der) // NFC encounter of the same certificate.
        let restored = SavedCardIdentityStore(defaults: defaults)
        XCTAssertEqual(restored.certificates { $0 == account }, [der])
        XCTAssertTrue(restored.certificates { _ in false }.isEmpty, "Certificate metadata must not revive a deleted PIN account.")
    }

    func testDeletingOneAccountRemovesItsMetadataWithoutAffectingAnotherCard() {
        let first = Data([0x30, 1, 1]), second = Data([0x30, 1, 2])
        let store = SavedCardIdentityStore(defaults: defaults)
        store.remember(first); store.remember(second)
        store.remove(account: SavedCardIdentityStore.account(for: first))
        XCTAssertEqual(store.certificates { _ in true }, [second])
    }

    func testMismatchedCertificateMetadataCannotSelectAnotherAccountsPIN() {
        let first = Data([0x30, 1, 1]), second = Data([0x30, 1, 2])
        let account = SavedCardIdentityStore.account(for: first)
        defaults.set([account: second], forKey: "savedPINCardCertificates")
        XCTAssertTrue(SavedCardIdentityStore(defaults: defaults).certificates { _ in true }.isEmpty)
    }

    func testOldPINWithoutCertificateMetadataStillRequiresCardIdentification() {
        XCTAssertTrue(SavedCardIdentityStore(defaults: defaults).certificates { _ in true }.isEmpty)
    }
}
