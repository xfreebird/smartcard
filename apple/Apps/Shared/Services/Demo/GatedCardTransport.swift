import Foundation
import MoldSignKit

final class GatedCardTransport: CardTransport {
    private let base: CardTransport
    private let gate: DemoHardwareGate
    private var connected = true
    var readerName: String { base.readerName }
    var atr: Data? { connected ? base.atr : nil }
    init(base: CardTransport, gate: DemoHardwareGate) { self.base = base; self.gate = gate }
    func transmit(_ apdu: Data) throws -> Data {
        guard connected else { throw CardError.noCard }
        return try base.transmit(apdu)
    }
    func disconnect() {
        guard connected else { return }
        connected = false
        base.disconnect()
        gate.end()
    }
    deinit { disconnect() }
}
