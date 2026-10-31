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

/// Isolated credential dependency: demo PINs remain in memory and never reach the system keychain.
final class MemoryPinVault: PinStoring {
    private var pins: [String: String] = [:]
    func savedAccounts() -> [String] { pins.keys.sorted() }
    func hasPIN(certID: String) -> Bool { pins[certID] != nil }
    func save(_ pin: String, certID: String) throws { pins[certID] = pin }
    func load(certID: String, reason: String) async -> String? { pins[certID] }
    func delete(certID: String) { pins[certID] = nil }
}
