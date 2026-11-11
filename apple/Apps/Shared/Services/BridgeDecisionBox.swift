import MoldSignKit

// Written before signaling the bridge semaphore; read only after its wait completes.
final class BridgeDecisionBox: @unchecked Sendable {
    var value: BridgeDecision = .deny
}
