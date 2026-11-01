import XCTest
@testable import AppBatch

final class UpdateManifestTests: XCTestCase {
    func testNumericReleaseComparison() throws {
        let manifest = try JSONDecoder().decode(UpdateManifest.self, from: Data(#"{"version":"1.10.0","downloadURL":"https://esemnbun.md/#downloads"}"#.utf8))
        XCTAssertTrue(manifest.isNewer(than: "1.9.9"))
        XCTAssertFalse(manifest.isNewer(than: "1.10.0"))
        XCTAssertFalse(manifest.isNewer(than: "2.0.0"))
    }
    func testUntrustedURLsAndMalformedVersionsAreRejected() throws {
        for (version, url) in [("1.0", "https://esemnbun.md"), ("1.2.3-beta", "https://esemnbun.md"), ("1.2.3", "https://example.org"), ("1.2.3", "http://esemnbun.md"), ("1.2.3", "https://esemnbun.md@evil.example")] {
            let data = try JSONSerialization.data(withJSONObject: ["version": version, "downloadURL": url])
            let manifest = try JSONDecoder().decode(UpdateManifest.self, from: data)
            XCTAssertFalse(manifest.isValid)
            XCTAssertFalse(manifest.isNewer(than: "0.0.1"))
        }
    }
}
