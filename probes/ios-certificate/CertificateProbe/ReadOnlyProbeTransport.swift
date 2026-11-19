import Foundation
import MoldSignKit

/// A second boundary protects the production-path probe if that code changes.
/// Secure messaging retains INS, so the default metadata mode blocks PIN/private
/// operations even when encrypted. The explicit synthetic-decipher mode permits
/// exactly one VERIFY(ref03), one decipher MSE and one PSO; signing stays blocked.
/// Never log raw requests or responses.
final class ReadOnlyProbeTransport: CardTransport {
    private let underlying: CardTransport
    private let log: (String) -> Void
    private let allowDecipher: Bool
    private let beforeVerify: () throws -> Void
    private var verified = false
    private var decipherSelected = false
    private var deciphered = false
    var readerName: String { underlying.readerName }
    init(_ underlying: CardTransport, log: @escaping (String) -> Void = { _ in }, allowDecipher: Bool = false,
         beforeVerify: @escaping () throws -> Void = {}) {
        self.underlying = underlying
        self.log = log
        self.allowDecipher = allowDecipher
        self.beforeVerify = beforeVerify
    }
    func transmit(_ apdu: Data) throws -> Data {
        guard apdu.count >= 5 else { throw ProbeFailure.message("Short command blocked") }
        let allowed: Bool
        switch (apdu[0], apdu[1]) {
        case (0,0xa4), (0,0xb0), (0,0xc0), (0x0c,0xa4), (0x0c,0xb0), (0x0c,0xcb):
            allowed = true
        case (0,0x22):
            allowed = apdu == Data([0,0x22,0xc1,0xa4,9,0x80,4,0xff,0x40,0x10,0x8c,0x83,1,4])
        case (0,0x84): allowed = apdu == Data([0,0x84,0,0,0x10])
        case (0,0x82): allowed = apdu.count == 101 && apdu[2] == 0 && apdu[3] == 0 && apdu[4] == 96
        case (0x0c,0x20):
            allowed = allowDecipher && !verified && apdu[2] == 0 && apdu[3] == 3
            if allowed { verified = true }
        case (0x0c,0x22):
            allowed = allowDecipher && verified && !decipherSelected && apdu[2] == 0x41 && apdu[3] == 0xb8
            if allowed { decipherSelected = true }
        case (0x0c,0x2a):
            allowed = allowDecipher && decipherSelected && !deciphered && apdu[2] == 0x80 && apdu[3] == 0x86
            if allowed { deciphered = true }
        default: allowed = false
        }
        guard allowed else { throw ProbeFailure.message("Non-discovery command blocked") }
        if apdu[0] == 0x0c && apdu[1] == 0x20 { try beforeVerify() }
        // Describe operation/result only, never command/response payloads.
        let operation: String
        switch apdu[1] {
        case 0xa4: operation = "SELECT"
        case 0xb0: operation = "READ"
        case 0xc0: operation = "GET RESPONSE"
        case 0xcb: operation = "GET DATA control parameters"
        case 0x22: operation = apdu[0] == 0x0c ? "decipher environment" : "secure-channel setup"
        case 0x20: operation = "single PIN verification"
        case 0x2a: operation = "single synthetic RSA decipher"
        case 0x84: operation = "challenge"
        default: operation = "mutual authentication"
        }
        let mode = apdu[0] == 0x0c ? "protected" : "plain"
        log("Sending \(mode) \(operation)")
        do {
            let reply = try underlying.transmit(apdu)
            let bytes = [UInt8](reply)
            if bytes.count >= 2 {
                log(String(format: "Reply: %d bytes; outer SW %02X%02X", bytes.count-2, bytes[bytes.count-2], bytes[bytes.count-1]))
            }
            return reply
        } catch {
            log("Transport stopped during \(mode) \(operation)")
            throw error
        }
    }
    func disconnect() { underlying.disconnect() }
}
