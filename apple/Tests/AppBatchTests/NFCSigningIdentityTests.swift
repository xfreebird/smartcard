import XCTest
@testable import AppBatch

final class NFCSigningIdentityTests: XCTestCase {
    func testNewCardBindsOnceAndCannotChangeBetweenBatchDocuments() {
        let identity = NFCSigningIdentity(expectedCertificate: nil)
        XCTAssertNil(identity.certificateDER)
        XCTAssertTrue(identity.bind(Data([1, 2, 3])))
        XCTAssertTrue(identity.bind(Data([1, 2, 3])))
        XCTAssertFalse(identity.bind(Data([4, 5, 6])))
        XCTAssertEqual(identity.certificateDER, Data([1, 2, 3]))
    }

    func testRememberedCardRejectsDifferentCertificateWithoutReplacingIt() {
        let identity = NFCSigningIdentity(expectedCertificate: Data([1, 2, 3]))
        XCTAssertFalse(identity.bind(Data([1, 2, 4])))
        XCTAssertEqual(identity.certificateDER, Data([1, 2, 3]))
        XCTAssertTrue(identity.bind(Data([1, 2, 3])))
    }
}
