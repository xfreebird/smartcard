import XCTest
import MoldSignKit
@testable import VerificationPolicies

final class DocumentVerificationModelTests: XCTestCase {
    @MainActor
    func testClearRejectsLateNonCooperativeVerifierResultAndHistory() async {
        let started = expectation(description: "verification started")
        let verifier = DeferredVerifier { started.fulfill() }
        let model = DocumentVerificationModel()
        var logged = 0
        let file = URL(fileURLWithPath: "/fixture.pdf")
        let work = Task { await model.verify([file], using: verifier) { _, _ in logged += 1 } }
        await fulfillment(of: [started], timeout: 2)
        model.clear()
        await verifier.finish(file)
        await work.value
        XCTAssertNil(model.file)
        XCTAssertNil(model.reports)
        XCTAssertTrue(model.documents.isEmpty)
        XCTAssertFalse(model.isVerifying)
        XCTAssertEqual(logged, 0)
    }

    @MainActor
    func testReplacementResultCannotBeOverwrittenByOlderRequest() async {
        let oldStarted = expectation(description: "old started")
        let newStarted = expectation(description: "new started")
        let old = DeferredVerifier { oldStarted.fulfill() }
        let new = DeferredVerifier { newStarted.fulfill() }
        let oldFile = URL(fileURLWithPath: "/old.pdf")
        let newFile = URL(fileURLWithPath: "/new.pdf")
        let model = DocumentVerificationModel()
        var logged: [URL] = []
        let first = Task { await model.verify([oldFile], using: old) { url, _ in logged.append(url) } }
        await fulfillment(of: [oldStarted], timeout: 2)
        let second = Task { await model.verify([newFile], using: new) { url, _ in logged.append(url) } }
        await fulfillment(of: [newStarted], timeout: 2)
        await new.finish(newFile)
        await second.value
        await old.finish(oldFile)
        await first.value
        XCTAssertEqual(model.file, newFile)
        XCTAssertEqual(model.documents.map(\.url), [newFile])
        XCTAssertEqual(logged, [newFile])
    }

    @MainActor
    func testCancelledBatchStopsBeforeNextFileAndDoesNotLogLateCompletion() async {
        let started = expectation(description: "started")
        let verifier = DeferredVerifier { started.fulfill() }
        let first = URL(fileURLWithPath: "/first.pdf")
        let model = DocumentVerificationModel()
        let work = Task {
            await model.verify([first, URL(fileURLWithPath: "/never.pdf")], using: verifier) { _, _ in XCTFail("Cancelled result logged") }
        }
        await fulfillment(of: [started], timeout: 2)
        work.cancel()
        await verifier.finish(first)
        await work.value
        XCTAssertTrue(model.documents.isEmpty)
        XCTAssertFalse(model.isVerifying)
        let reads = await verifier.reads
        XCTAssertEqual(reads, [first])
    }
}

private actor DeferredVerifier: DocumentVerifying {
    let started: @Sendable () -> Void
    var reads: [URL] = []
    var pending: [URL: CheckedContinuation<[Validator.Report], Never>] = [:]
    init(started: @escaping @Sendable () -> Void) { self.started = started }
    func verify(_ url: URL) async -> [Validator.Report] {
        reads.append(url)
        return await withCheckedContinuation { continuation in
            pending[url] = continuation
            started()
        }
    }
    func finish(_ url: URL) { pending.removeValue(forKey: url)?.resume(returning: []) }
}
