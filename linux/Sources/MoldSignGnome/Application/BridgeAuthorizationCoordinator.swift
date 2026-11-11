import Foundation
import MoldSignKit

/// Main-loop consent lifecycle. Pending callbacks cannot authorize a stopped/replaced bridge session.
final class BridgeAuthorizationCoordinator {
    private var policy = BridgeConsentPolicy()
    private var pending: (id: UUID, completion: (BridgeDecision) -> Void)?

    func cancel() {
        guard let current = pending else { return }
        pending = nil
        current.completion(.deny)
    }

    func authorize(_ request: BridgeRequest, certID: String?, holder: String, hasStoredPIN: Bool,
                   ask: (ConsentRequest, @escaping (Bool, Bool) -> Void) -> Void,
                   obtainPIN: @escaping (String, String, @escaping () -> Bool, @escaping (String?) -> Void) -> Void,
                   completion: @escaping (BridgeDecision) -> Void) {
        guard pending == nil else { completion(.deny); return }
        let id = UUID()
        pending = (id, completion)
        let proceed: () -> Void = { [weak self] in
            guard let self, self.pending?.id == id else { return }
            if request.pinIncluded { self.finish(.allow(pin: nil, certificateSHA1: certID), id: id); return }
            guard let certID else { self.finish(.deny, id: id); return }
            obtainPIN(certID, holder, { [weak self] in self?.pending?.id == id }) { [weak self] pin in
                self?.finish(pin.map { .allow(pin: $0, certificateSHA1: certID) } ?? .deny, id: id)
            }
        }
        if !policy.requiresConsent(origin: request.origin) { proceed(); return }
        var consentAnswered = false
        ask(ConsentRequest(request: request, holder: holder, hasStoredPIN: hasStoredPIN)) { [weak self] approved, trust in
            guard let self, self.pending?.id == id, !consentAnswered else { return }
            consentAnswered = true
            guard approved else { self.finish(.deny, id: id); return }
            if trust { self.policy.trust(origin: request.origin) }
            proceed()
        }
    }

    private func finish(_ answer: BridgeDecision, id: UUID) {
        guard let current = pending, current.id == id else { return }
        pending = nil
        current.completion(answer)
    }
}
