import Foundation

/// Reads only the public certificate through the plaintext NFC path proven by the physical probe.
/// No authentication or PIN command is sent. The caller owns the transport/session lifetime.
public enum ContactlessCertificateReader {
    public static func read(using transport: CardTransport) throws -> Data {
        func exchange(_ command: Data) throws -> Data {
            var result = Data()
            var request = command
            for _ in 0..<8 {
                let response = try transport.transmit(request)
                guard response.count >= 2 else { throw CardError.cardNotResponding }
                let status = [UInt8](response.suffix(2))
                result += response.dropLast(2)
                guard result.count <= 4096 else { throw CardError.cardNotResponding }
                if status[0] == 0x61 { request = Data([0, 0xC0, 0, 0, status[1]]); continue }
                guard status == [0x90, 0] else { throw CardError.apduError(UInt16(status[0]) << 8 | UInt16(status[1])) }
                return result
            }
            throw CardError.cardNotResponding
        }
        _ = try exchange(Data([0, 0xA4, 4, 4, UInt8(CosmoXCard.genericADF.count)]) + CosmoXCard.genericADF + Data([0]))
        _ = try exchange(Data([0, 0xA4, 2, 4, 2, 0, 1, 0]))
        var certificate = Data()
        func read(_ count: Int) throws {
            let offset = certificate.count
            let part = try exchange(Data([0, 0xB0, UInt8(offset >> 8), UInt8(offset & 255), UInt8(count)]))
            guard part.count == count else { throw CardError.cardNotResponding }
            certificate += part
        }
        try read(2)
        let header = [UInt8](certificate)
        guard header[0] == 0x30 else { throw CardError.cardNotResponding }
        let payload: Int
        if header[1] < 128 { payload = Int(header[1]) }
        else {
            let count = Int(header[1] & 127)
            guard (1...2).contains(count) else { throw CardError.cardNotResponding }
            try read(count)
            let bytes = [UInt8](certificate.dropFirst(2))
            guard bytes[0] != 0 else { throw CardError.cardNotResponding }
            payload = bytes.reduce(0) { $0 * 256 + Int($1) }
            guard payload >= 128 else { throw CardError.cardNotResponding }
        }
        let total = certificate.count + payload
        guard total <= 4096 else { throw CardError.cardNotResponding }
        while certificate.count < total { try read(min(128, total - certificate.count)) }
        return certificate
    }
}
