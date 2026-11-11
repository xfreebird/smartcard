import XCTest
@testable import AppBatch

final class CancellableRequestScopeTests: XCTestCase {
    @MainActor
    func testShutdownReleasesDecisionAndNewLifetimeCanAuthorize() async {
        let scope = CancellableRequestScope()
        let channel = DecisionChannel<Bool>()
        let presented = expectation(description: "presented")
        let first = Task {
            await scope.run(fallback: false) {
                await channel.request(fallback: false, present: { presented.fulfill() })
            }
        }
        await fulfillment(of: [presented], timeout: 2)
        scope.cancelAll()
        let rejected = await first.value
        XCTAssertFalse(rejected)
        XCTAssertFalse(channel.isPending)
        let next = await scope.run(fallback: false) { true }
        XCTAssertTrue(next)
    }

    @MainActor
    func testNonCooperativeLateResultCannotAuthorizeAfterShutdown() async {
        let scope = CancellableRequestScope()
        let started = expectation(description: "started")
        var continuation: CheckedContinuation<Bool, Never>?
        let first = Task {
            await scope.run(fallback: false) {
                await withCheckedContinuation { continuation = $0; started.fulfill() }
            }
        }
        await fulfillment(of: [started], timeout: 2)
        scope.cancelAll()
        continuation?.resume(returning: true)
        let rejected = await first.value
        XCTAssertFalse(rejected)
    }
}
