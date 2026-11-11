import Foundation

/// Explicitly injected reader source for host tests and previews; no CryptoTokenKit observer is started.
final class MockReaderMonitor: ReaderMonitoring {
    var onChange: ((ReaderMonitor.Snapshot) -> Void)?
    var snapshot: ReaderMonitor.Snapshot
    init(snapshot: ReaderMonitor.Snapshot = .init()) { self.snapshot = snapshot }
    func start() { onChange?(snapshot) }
    func stop() {}
    func send(_ snapshot: ReaderMonitor.Snapshot) { self.snapshot = snapshot; onChange?(snapshot) }
}
