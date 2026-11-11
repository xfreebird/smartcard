import Foundation
import Observation

/// PIN presentation and saved-credential acquisition, independent of signing and bridge routing.
@MainActor @Observable
final class PINCoordinator {
    var request: PinRequest?
    private(set) var isObtaining = false
    @ObservationIgnored private let pinDecision = DecisionChannel<(pin: String, remember: Bool)?>()

    func obtain(certID: String, holder: String, allowRemember: Bool,
                           documentNames: [String] = [], vault: any PinStoring,
                attemptsLeft: Int?, present: () -> Void) async -> (pin: String, remember: Bool)? {
        // A browser request may arrive while the manual batch is authorizing. Never replace its continuation.
        guard !isObtaining else { return nil }
        isObtaining = true
        defer { isObtaining = false }
        let reason: String
        if documentNames.isEmpty {
            reason = L10n.text(.ui_signing_with_certificate_value, holder)
        } else {
            let action = documentNames.count == 1 ? L10n.text(.ui_sign)
                : L10n.text(.ui_sign_count_documents, documentNames.count)
            reason = [action, documentNames.joined(separator: ", "), holder].joined(separator: " · ")
        }
        if vault.hasPIN(certID: certID) {
            // Cancelling device-owner authentication cancels this batch instead of opening another prompt.
            guard let stored = await vault.load(certID: certID, reason: reason), !Task.isCancelled else { return nil }
            return (stored, false)
        }
        return await pinDecision.request(fallback: nil, present: {
            request = PinRequest(holder: holder, attemptsLeft: attemptsLeft,
                                    canRemember: allowRemember, documentNames: documentNames)
            present()
        }, dismiss: { [weak self] in self?.request = nil })
    }

    func submitPIN(_ pin: String, remember: Bool) {
        request = nil
        pinDecision.resolve((pin, remember))
    }

    func cancelPIN() {
        request = nil
        pinDecision.resolve(nil)
    }

}
