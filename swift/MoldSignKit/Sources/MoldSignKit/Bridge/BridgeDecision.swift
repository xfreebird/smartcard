import Foundation

public enum BridgeDecision: Sendable {
    case deny
    /// `pin`: the PIN to use when the request carries none (nil → host fallback: env / dialog / tty).
    /// `certificateSHA1`: the card that PIN belongs to; the server refuses a different card before VERIFY.
    case allow(pin: String?, certificateSHA1: String? = nil)
}
