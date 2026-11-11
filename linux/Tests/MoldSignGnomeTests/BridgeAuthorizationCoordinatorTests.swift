import XCTest
import MoldSignKit
@testable import MoldSignGnome

final class BridgeAuthorizationCoordinatorTests: XCTestCase {
    func testStoppedSessionIgnoresLateConsentAndNeverRequestsPin() {
        let coordinator = BridgeAuthorizationCoordinator()
        var reply: ((Bool, Bool) -> Void)?
        var completions = 0
        coordinator.authorize(BridgeRequest(origin: "https://msign.gov.md", operation: .signPDF, documentName: "fixture.pdf", format: "PAdES-T", pinIncluded: false),
            certID: "fixture", holder: "Fictional", hasStoredPIN: false,
            ask: { _, answer in reply = answer },
            obtainPIN: { _, _, _, _ in XCTFail("Cancelled consent must not request PIN") },
            completion: { decision in
                completions += 1
                if case .deny = decision {} else { XCTFail("Expected denial") }
            })
        coordinator.cancel()
        reply?(true, true)
        XCTAssertEqual(completions, 1)
    }

    func testDuplicatePinCallbackCompletesOnlyOnce() {
        let coordinator = BridgeAuthorizationCoordinator()
        var completions = 0
        coordinator.authorize(BridgeRequest(origin: nil, operation: .signPDF, documentName: "fixture.pdf", format: "PAdES-T", pinIncluded: false),
            certID: "fixture", holder: "Fictional", hasStoredPIN: false,
            ask: { _, answer in answer(true, false) },
            obtainPIN: { _, _, _, answer in answer(nil); answer(nil) },
            completion: { _ in completions += 1 })
        XCTAssertEqual(completions, 1)
    }
    func testDuplicateConsentDoesNotStartTwoPinReadsAndStopInvalidatesLookup() {
        let coordinator = BridgeAuthorizationCoordinator()
        var consent: ((Bool, Bool) -> Void)?
        var current: (() -> Bool)?
        var pin: ((String?) -> Void)?
        var reads = 0
        var decisions = 0
        coordinator.authorize(BridgeRequest(origin: nil, operation: .signPDF, documentName: "fixture.pdf", format: "PAdES-T", pinIncluded: false),
            certID: "fixture", holder: "Fictional", hasStoredPIN: true,
            ask: { _, answer in consent = answer },
            obtainPIN: { _, _, isCurrent, answer in reads += 1; current = isCurrent; pin = answer },
            completion: { decision in
                decisions += 1
                if case .deny = decision {} else { XCTFail("Stopped request authorized") }
            })
        consent?(true, false)
        consent?(true, false)
        XCTAssertEqual(reads, 1)
        XCTAssertEqual(current?(), true)
        coordinator.cancel()
        XCTAssertEqual(current?(), false)
        pin?(nil)
        XCTAssertEqual(decisions, 1)
    }
}
