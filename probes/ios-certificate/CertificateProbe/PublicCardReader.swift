import Foundation
import MoldSignKit
import Security

/// Only public SELECT/READ/GET RESPONSE commands. No authentication or PIN commands.
struct PublicCardReader {
    let transport: CardTransport
    let log: (String) -> Void
    let save: (String, Data) throws -> Void

    func run() throws {
        try selectApplication()
        // These are the three files read by production encryption discovery, plus
        // the known signing certificate. No key-reference guessing or EF scanning.
        for file: UInt16 in [0x7001, 0x7002, 0x7005, 0x0001] {
            try selectApplication()
            let selected = try exchange(Data([0, 0xa4, 2, 4, 2, UInt8(file >> 8), UInt8(file & 255), 0]))
            if selected.status == 0x6a82 {
                log(String(format: "EF %04X: not found (6A82)", file))
                continue
            }
            try requireSuccess(selected.status)
            let bytes = try readFile()
            let name = String(format: "EF-%04X", file)
            try save(name + ".bin", bytes)
            log("\(name): \(bytes.count) bytes saved privately")
            if let certificate = exactCertificate(bytes) {
                try save(name + ".cer", certificate)
                let usable = (try? CertificateFileProtection.validateRecipient(certificate)) != nil
                log("\(name): parsed X.509; RSA recipient validation \(usable ? "accepted" : "rejected")")
            }
        }
    }

    private func selectApplication() throws {
        let aid: [UInt8] = [0xe8,0x28,0xbd,8,0x0f,0xd2,0x50,0x47,0x65,0x6e,0x65,0x72,0x69,0x63]
        try requireSuccess(exchange(Data([0,0xa4,4,4,UInt8(aid.count)] + aid + [0])).status)
    }

    private func readFile() throws -> Data {
        var output = Data()
        while output.count < 32768 {
            let offset = output.count
            let response = try exchange(Data([0,0xb0,UInt8(offset >> 8),UInt8(offset & 255),0x80]))
            if [0x6b00, 0x6a86].contains(response.status), !output.isEmpty { return output }
            guard response.status == 0x9000 || response.status == 0x6282 else {
                try requireSuccess(response.status)
                throw ProbeFailure.message("Unexpected read status")
            }
            guard response.data.count <= 128 else { throw ProbeFailure.message("Oversized READ reply") }
            output += response.data
            if response.data.count < 128 || response.status == 0x6282 { return output }
        }
        throw ProbeFailure.message("File reached 32768-byte limit")
    }

    private func exchange(_ command: Data) throws -> (data: Data, status: UInt16) {
        // This boundary deliberately accepts no arbitrary command input from the UI.
        guard command.first == 0, command.count >= 5, [0xa4,0xb0].contains(command[1]) else {
            throw ProbeFailure.message("Command blocked")
        }
        var request = command, output = Data(), corrected = false
        for _ in 0..<8 {
            let reply = try transport.transmit(request)
            guard reply.count >= 2 else { throw ProbeFailure.message("Truncated response") }
            let bytes = [UInt8](reply), sw1 = bytes[bytes.count-2], sw2 = bytes[bytes.count-1]
            let status = UInt16(sw1) << 8 | UInt16(sw2)
            log(String(format: "INS %02X: SW %04X, %d bytes", request[1], status, bytes.count-2))
            if sw1 == 0x63 || [0x6983,0x6985,0x6988].contains(status) {
                throw ProbeFailure.message(String(format: "Security-state stop %04X; do not repeat", status))
            }
            if sw1 == 0x6c, [0xb0,0xc0].contains(request[1]), !corrected, reply.count == 2 {
                corrected = true
                request[request.count-1] = sw2
                continue
            }
            output += Data(reply.dropLast(2))
            guard output.count <= 4096 else { throw ProbeFailure.message("Response limit exceeded") }
            if sw1 == 0x61 {
                request = Data([0,0xc0,0,0,sw2])
                corrected = false
                continue
            }
            return (output,status)
        }
        throw ProbeFailure.message("Response exchange limit exceeded")
    }

    private func requireSuccess(_ status: UInt16) throws {
        guard status == 0x9000 else {
            throw ProbeFailure.message(String(format: "Card returned %04X", status))
        }
    }

    private func exactCertificate(_ bytes: Data) -> Data? {
        let b = [UInt8](bytes)
        guard b.count >= 2, b[0] == 0x30 else { return nil }
        var header = 2, length = Int(b[1])
        if b[1] & 0x80 != 0 {
            let count = Int(b[1] & 0x7f)
            guard (1...3).contains(count), b.count >= 2 + count else { return nil }
            header += count
            length = b[2..<header].reduce(0) { $0 * 256 + Int($1) }
        }
        guard length > 0, header + length <= bytes.count,
              b[(header+length)...].allSatisfy({ $0 == 0 }) else { return nil }
        let certificate = Data(bytes.prefix(header+length))
        return SecCertificateCreateWithData(nil, certificate as CFData) == nil ? nil : certificate
    }
}

enum ProbeFailure: LocalizedError {
    case message(String)
    var errorDescription: String? {
        switch self { case .message(let value): return value }
    }
}
