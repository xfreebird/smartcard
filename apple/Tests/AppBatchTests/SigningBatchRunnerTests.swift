import XCTest
@testable import AppBatch

@MainActor
final class SigningBatchRunnerTests: XCTestCase {
    struct Context: Equatable { let reader: String; let certificate: String }
    enum Failure: Error { case rejectedPIN, disconnected }

    func testDocumentFailureContinuesWithoutRepeatingAuthorization() async {
        let runner = SigningBatchRunner()
        var prompts = 0
        var completed: [Int] = []
        var failures: [Int] = []
        _ = await runner.run(items: [1, 2, 3], context: (), authorize: { _, _ in
            prompts += 1
            return "mock-credential"
        }, sign: { item, _, _ in
            if item == 2 { throw Failure.disconnected }
            return item
        }, didSign: { item, _, _ in completed.append(item) },
        didFail: { item, _ in failures.append(item) }, shouldContinue: { _ in true })
        XCTAssertEqual(prompts, 1)
        XCTAssertEqual(completed, [1, 3])
        XCTAssertEqual(failures, [2])
    }

    func testSuspendedAuthorizationFreezesFilesAndCardAndRejectsSecondStart() async {
        let runner = SigningBatchRunner()
        var queue = [1, 2]
        var context = Context(reader: "original-reader", certificate: "original-cert")
        var prompt: CheckedContinuation<String?, Never>?
        let entered = expectation(description: "authorization pending")
        var authorizationCount = 0
        var signed: [(Int, Context)] = []
        let first = Task {
            await runner.run(items: queue, context: context, authorize: { _, items in
                authorizationCount += 1
                XCTAssertEqual(items, [1, 2])
                return await withCheckedContinuation { prompt = $0; entered.fulfill() }
            }, sign: { item, snapshot, credential in
                XCTAssertEqual(credential, "mock-credential")
                signed.append((item, snapshot))
                return item
            }, didSign: { _, _, _ in }, didFail: { _, _ in XCTFail("Unexpected error") })
        }
        await fulfillment(of: [entered], timeout: 2)
        queue = [99]
        context = Context(reader: "replacement-reader", certificate: "replacement-cert")
        let second = await runner.run(items: queue, context: context, authorize: { _, _ in
            authorizationCount += 1
            return "other-credential"
        }, sign: { item, _, _ in item }, didSign: { _, _, _ in XCTFail("Second batch must not sign") }, didFail: { _, _ in })
        XCTAssertEqual(second, .alreadyRunning)
        XCTAssertTrue(runner.isRunning)
        prompt?.resume(returning: "mock-credential")
        let firstOutcome = await first.value
        XCTAssertEqual(firstOutcome, .completed)
        XCTAssertEqual(authorizationCount, 1)
        XCTAssertEqual(signed.map(\.0), [1, 2])
        XCTAssertEqual(signed.map(\.1), Array(repeating: Context(reader: "original-reader", certificate: "original-cert"), count: 2))
        XCTAssertFalse(runner.isRunning)
    }

    func testCancellationReleasesScopeAndNextBatchRequiresNewAuthorization() async {
        let runner = SigningBatchRunner()
        var prompts = 0
        var signed: [Int] = []
        let cancelled = await runner.run(items: [1, 2], context: (), authorize: { _, _ -> String? in
            prompts += 1
            return nil
        }, sign: { item, _, _ in item }, didSign: { item, _, _ in signed.append(item) }, didFail: { _, _ in })
        XCTAssertEqual(cancelled, .cancelled)
        XCTAssertFalse(runner.isRunning)
        XCTAssertTrue(signed.isEmpty)
        let completed = await runner.run(items: [3, 4], context: (), authorize: { _, _ in
            prompts += 1
            return "new-mock-credential"
        }, sign: { item, _, _ in item }, didSign: { item, _, _ in signed.append(item) }, didFail: { _, _ in })
        XCTAssertEqual(completed, .completed)
        XCTAssertEqual(prompts, 2)
        XCTAssertEqual(signed, [3, 4])
    }

    func testRejectedPINStopsAtFirstFileWithoutRetryAndRequiresFreshAuthorization() async {
        let runner = SigningBatchRunner()
        var prompts = 0
        var attempts: [Int] = []
        var failures: [Int] = []
        let failed = await runner.run(items: [1, 2, 3], context: (), authorize: { _, _ in
            prompts += 1
            return "mock-credential"
        }, sign: { item, _, _ -> Int in
            attempts.append(item)
            throw Failure.rejectedPIN
        }, didSign: { _, _, _ in XCTFail("Rejected credential must never succeed") }, didFail: { item, _ in failures.append(item) })
        XCTAssertEqual(failed, .failed)
        XCTAssertEqual(attempts, [1])
        XCTAssertEqual(failures, [1])
        XCTAssertFalse(runner.isRunning)
        let next = await runner.run(items: [4], context: (), authorize: { _, _ in
            prompts += 1
            return "fresh-mock-credential"
        }, sign: { item, _, _ in item }, didSign: { _, _, _ in }, didFail: { _, _ in })
        XCTAssertEqual(next, .completed)
        XCTAssertEqual(prompts, 2)
    }

    func testPartialFailureKeepsCompletedItemsDistinctFromUnprocessedQueue() async {
        let runner = SigningBatchRunner()
        var queue = [1, 2, 3]
        var signed: [Int] = []
        let outcome = await runner.run(items: queue, context: (), authorize: { _, _ in
            queue.append(99) // Added after the user began this batch.
            return "mock-credential"
        }, sign: { item, _, _ in
            if item == 2 { throw Failure.disconnected }
            return item
        }, didSign: { item, _, _ in signed.append(item); queue.removeAll { $0 == item } }, didFail: { _, _ in })
        XCTAssertEqual(outcome, .failed)
        XCTAssertEqual(signed, [1])
        XCTAssertEqual(queue, [2, 3, 99])
    }
}
