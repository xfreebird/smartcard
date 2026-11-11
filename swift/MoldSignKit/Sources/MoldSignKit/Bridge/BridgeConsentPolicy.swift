import Foundation

/// Host-owned, in-memory origin trust. UI presentation and credential retrieval remain separate ports.
/// Confine each value to the host's UI thread; never persist it or share it between hosts.
public struct BridgeConsentPolicy {
    private var trustedUntil: [String: Date] = [:]
    private let duration: TimeInterval

    public init(duration: TimeInterval = 600) { self.duration = duration }

    public func requiresConsent(origin: String?, now: Date = Date()) -> Bool {
        (trustedUntil[origin ?? "local"] ?? .distantPast) <= now
    }

    public mutating func trust(origin: String?, now: Date = Date()) {
        trustedUntil = trustedUntil.filter { $0.value > now }
        trustedUntil[origin ?? "local"] = now.addingTimeInterval(duration)
    }

    public mutating func reset() { trustedUntil.removeAll() }
}
