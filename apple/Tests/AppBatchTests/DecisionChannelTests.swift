import XCTest
@testable import AppBatch

final class DecisionChannelTests: XCTestCase {
    @MainActor
    func testSynchronousPresentationResponseCannotBeLost() async {
        let channel = DecisionChannel<Bool>()
        let answer = await channel.request(fallback: false, present: { channel.resolve(true) })
        XCTAssertTrue(answer)
        XCTAssertFalse(channel.isPending)
    }

    @MainActor
    func testCancellationDismissesPromptAndAllowsNextRequest() async {
        let channel = DecisionChannel<Bool>()
        let presented = expectation(description: "presented")
        var dismissals = 0
        let pending = Task { await channel.request(fallback: false, present: { presented.fulfill() }, dismiss: { dismissals += 1 }) }
        await fulfillment(of: [presented], timeout: 2)
        pending.cancel()
        let answer = await pending.value
        XCTAssertFalse(answer)
        XCTAssertEqual(dismissals, 1)
        let next = await channel.request(fallback: false, present: { channel.resolve(true) })
        XCTAssertTrue(next)
    }

    @MainActor
    func testSecondRequestCannotReplaceFirstContinuation() async {
        let channel = DecisionChannel<Int>()
        let presented = expectation(description: "presented")
        let first = Task { await channel.request(fallback: -1, present: { presented.fulfill() }) }
        await fulfillment(of: [presented], timeout: 2)
        let second = await channel.request(fallback: -2, present: { XCTFail("Overlapping prompt") })
        XCTAssertEqual(second, -2)
        channel.resolve(42)
        let answer = await first.value
        XCTAssertEqual(answer, 42)
    }
}
