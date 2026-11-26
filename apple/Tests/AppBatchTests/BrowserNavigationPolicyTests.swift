import XCTest
@testable import AppBatch

final class BrowserNavigationPolicyTests: XCTestCase {
    func testOpenWebAndBlankPagesRemainAvailable() {
        for address in ["https://msign.gov.md/#/", "https://example.org/path", "http://example.org/", "about:blank"] {
            XCTAssertTrue(BrowserNavigationPolicy.allows(URL(string: address)), address)
        }
    }

    func testRedirectsCannotReachLocalOrExecutableSchemesOrHideCredentials() {
        for address in ["file:///etc/passwd", "data:text/html,example", "javascript:alert(1)",
                        "about:config", "mailto:example@example.org", "https://example.org@evil.example/"] {
            XCTAssertFalse(BrowserNavigationPolicy.allows(URL(string: address)), address)
        }
        XCTAssertFalse(BrowserNavigationPolicy.allows(nil))
    }
}
