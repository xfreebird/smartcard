import XCTest
@testable import AppBatch

final class BlockingCardCommandTests: XCTestCase {
    private enum Failure: Error { case timeout, disconnected }

    func testCallbackBeforeWaitIsRetained() throws {
        let command = BlockingCardCommand()
        command.complete(.success(Data([0x90, 0])))
        XCTAssertEqual(try command.wait(until: .now(), timeoutError: Failure.timeout), Data([0x90, 0]))
    }

    func testTimeoutCannotBecomeSuccessAfterLateCallback() {
        let command = BlockingCardCommand()
        XCTAssertThrowsError(try command.wait(until: .now(), timeoutError: Failure.timeout)) {
            guard case Failure.timeout = $0 else { return XCTFail("Unexpected error: \($0)") }
        }
        command.complete(.success(Data([0x90, 0])))
        XCTAssertThrowsError(try command.wait(until: .now(), timeoutError: Failure.timeout)) {
            guard case Failure.timeout = $0 else { return XCTFail("Late callback replaced failure") }
        }
    }

    func testInvalidationReleasesBlockedCommandAndIgnoresLateResponse() async {
        let command = BlockingCardCommand()
        let waiting = expectation(description: "waiter released")
        DispatchQueue.global().async {
            do {
                _ = try command.wait(until: .now() + 2, timeoutError: Failure.timeout)
                XCTFail("Invalidation must fail the command")
            } catch Failure.disconnected {
                // Expected cancellation of the blocked command.
            } catch { XCTFail("Unexpected error: \(error)") }
            waiting.fulfill()
        }
        command.complete(.failure(Failure.disconnected))
        command.complete(.success(Data([0x90, 0])))
        await fulfillment(of: [waiting], timeout: 3)
    }
}
