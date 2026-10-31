import Foundation

/// An atomic boundary prevents a mode switch while a live card transport is connected.
final class DemoHardwareGate: @unchecked Sendable {
    private let lock = NSLock()
    private var demo: Bool
    private var active = 0
    init(demo: Bool) { self.demo = demo }
    var isBusy: Bool { lock.lock(); defer { lock.unlock() }; return active > 0 }
    func changeMode(demo: Bool) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard active == 0 else { return false }
        self.demo = demo
        return true
    }
    func begin() -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard !demo else { return false }
        active += 1
        return true
    }
    func end() { lock.lock(); defer { lock.unlock() }; active = max(0, active - 1) }
}
