import Foundation

/// Absence of a persisted choice is distinct from a recorded refusal.
struct MonitoringConsent: Codable, Equatable {
    var crashes: Bool
    var metrics: Bool
    var enabled: Bool { crashes || metrics }
}

protocol MonitoringConsentStoring {
    func load() -> MonitoringConsent?
    func save(_ consent: MonitoringConsent) throws
}

/// The SDK cannot be initialized before a durable explicit choice. On any consent change,
/// revoke and discard the old session/queue before starting the newly allowed signals.
final class MonitoringCoordinator {
    private let store: any MonitoringConsentStoring
    private let start: (MonitoringConsent) -> Void
    private let revoke: () -> Void
    private(set) var consent: MonitoringConsent?
    init(store: any MonitoringConsentStoring, start: @escaping (MonitoringConsent) -> Void,
         revoke: @escaping () -> Void) {
        self.store = store; self.start = start; self.revoke = revoke
        consent = store.load()
    }
    func restore() { if let consent, consent.enabled { start(consent) } }
    func choose(_ value: MonitoringConsent) throws {
        // Always stop first: even failed persistence must not leave the old signal active.
        revoke()
        consent = nil
        try store.save(value)
        consent = value
        if value.enabled { start(value) }
    }
}
