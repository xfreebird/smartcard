import Foundation
import Observation
import MoldSignKit

/// Browser consent and origin trust, separate from listener ownership and document workflows.
@MainActor @Observable
final class BridgeAuthorizationCoordinator {
    var request: ConsentRequest?
    @ObservationIgnored private var policy = BridgeConsentPolicy()
    @ObservationIgnored private let decision = DecisionChannel<(approved: Bool, trust: Bool)>()

    func resetTrust() { policy.reset() }
    func answer(approved: Bool, trust: Bool) {
        request = nil
        decision.resolve((approved, trust))
    }

    func authorize(_ incoming: BridgeRequest, target: SigningService.CertificateSummary?,
                   vault: any PinStoring, present: () -> Void,
                   obtainPIN: (String, String) async -> String?) async -> BridgeDecision {
        guard !decision.isPending else { return .deny }
        let certID = incoming.certificateSHA1 ?? target?.sha1Hex
        let holder = target?.holder ?? incoming.certificateHolder ?? "—"
        if policy.requiresConsent(origin: incoming.origin) {
            let answer = await decision.request(fallback: (false, false), present: {
                request = ConsentRequest(request: incoming, holder: holder,
                                         hasStoredPIN: certID.map { vault.hasPIN(certID: $0) } ?? false)
                present()
            }, dismiss: { [weak self] in self?.request = nil })
            guard answer.approved, !Task.isCancelled else { return .deny }
            if answer.trust { policy.trust(origin: incoming.origin) }
        }
        guard !Task.isCancelled else { return .deny }
        if incoming.pinIncluded { return .allow(pin: nil, certificateSHA1: certID) }
        guard let certID, let pin = await obtainPIN(certID, holder), !Task.isCancelled else { return .deny }
        return .allow(pin: pin, certificateSHA1: certID)
    }
}
