import XCTest
@testable import MoldSignKit

final class BridgeConsentPolicyTests: XCTestCase {
    func testOriginTrustExpiresAtBoundaryAndDoesNotCrossHosts() {
        let now = Date(timeIntervalSince1970: 1000)
        var policy = BridgeConsentPolicy(duration: 600)
        policy.trust(origin: "https://msign.gov.md", now: now)
        XCTAssertFalse(policy.requiresConsent(origin: "https://msign.gov.md", now: now.addingTimeInterval(599)))
        XCTAssertTrue(policy.requiresConsent(origin: "https://msign.gov.md", now: now.addingTimeInterval(600)))
        XCTAssertTrue(policy.requiresConsent(origin: "https://mpass.gov.md", now: now))
        XCTAssertTrue(policy.requiresConsent(origin: nil, now: now))
        XCTAssertTrue(BridgeConsentPolicy().requiresConsent(origin: "https://msign.gov.md", now: now))
        policy.reset()
        XCTAssertTrue(policy.requiresConsent(origin: "https://msign.gov.md", now: now))
    }
}
