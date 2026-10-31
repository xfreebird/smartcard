import Foundation
import MoldSignKit

final class GatedCardTransport: CardTransport {
    private let base: CardTransport
    private let gate: DemoHardwareGate
    private var connected = true
    var readerName: String { base.readerName }
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

struct DemoDocumentSigner: DocumentSigning {
    let files: DemoDocumentFiles
    func sign(_ item: SignItem, pin: String, reader: String, certificateSHA1: String,
              progress: @escaping @Sendable (SigningService.Step) -> Void) async throws -> URL {
        // Do not inspect the source URL, bytes, credential, certificate or reader.
        for step in [SigningService.Step.connecting, .signing, .writing] {
            progress(step)
            try await Task.sleep(for: .milliseconds(100))
        }
        return try files.output()
    }
}

struct DemoDocumentVerifier: DocumentVerifying {
    func verify(_ url: URL) async -> [Validator.Report] { [] }
}
