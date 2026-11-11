import Foundation
import MoldSignKit

/// What the PIN dialog shows. `attemptsLeft` comes from the last 63Cx.
struct PinRequest {
    let holder: String
    /// One line about what is being signed ("2 documente", "msign.gov.md · cerere.pdf").
    let purpose: String
    let attemptsLeft: Int?
    let canRemember: Bool
    /// nil when the vault works; otherwise why "remember" is unavailable.
    let vaultProblem: String?
}
