import Dispatch
import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome

final class CardDataProviderTests: GnomeTestCase {
    func testLateReadCannotOverwriteAReplacementCard() {
        let source = DeferredCardData()
        let session = ReaderSession(service: SigningService(), vault: UnusedVault(), monitor: UnusedMonitor(),
                                    transportFactory: nil, cardData: source)
        session.apply(ReaderSnapshot(slots: [.init(name: "reader", state: .card, generation: 1)]))
        session.apply(ReaderSnapshot(slots: [.init(name: "reader", state: .card, generation: 2)]))
        XCTAssertEqual(source.completions.count, 2)
        source.completions[0](CardReadResult(problem: "stale error"))
        XCTAssertNil(session.cards.first?.problem)
        source.completions[1](CardReadResult(problem: "current error"))
        XCTAssertEqual(session.cards.first?.problem, "current error")
    }

    func testMemoryStoresDoNotShareDocumentHistory() {
        let first = MemoryActivityStore()
        let second = MemoryActivityStore()
        let item = ActivityItem(kind: .signed, title: "demo", subtitle: "", ok: true, filePath: "/demo.pdf")
        first.saveActivity([item])
        first.saveDocuments([item])
        first.saveActivity([])
        XCTAssertEqual(first.loadDocuments(), [item])
        XCTAssertTrue(second.loadActivity().isEmpty)
        XCTAssertTrue(second.loadDocuments().isEmpty)
    }
}

private final class DeferredCardData: CardDataProviding {
    var completions: [(CardReadResult) -> Void] = []
    func read(reader: String, completion: @escaping (CardReadResult) -> Void) { completions.append(completion) }
}

private final class UnusedMonitor: CardMonitoring {
    var onChange: ((ReaderSnapshot) -> Void)?
    func start(interval: DispatchTimeInterval) { XCTFail("Unexpected monitoring") }
    func stop() {}
    func refresh() { XCTFail("Unexpected hardware refresh") }
}

private final class UnusedVault: PINStoring {
    func save(_ pin: String, certID: String, holder: String) throws { XCTFail("Unexpected vault write") }
    func load(certID: String) -> PINLookup { XCTFail("Unexpected vault read"); return .missing }
    func hasPIN(certID: String) -> Bool { XCTFail("Provider must own vault access"); return false }
    func delete(certID: String) -> Bool { XCTFail("Unexpected vault delete"); return false }
    func deleteAll() -> Bool { XCTFail("Unexpected vault delete"); return false }
    func availabilityProblem() -> String? { nil }
}
