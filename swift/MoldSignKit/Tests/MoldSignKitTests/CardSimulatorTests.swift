import XCTest
@testable import MoldSignKit

/// Card side of the SM channel: answers READ BINARY from a file image, like the CosmoX does.
private final class SimulatedCard: CardTransport {
    let readerName = "Simulated reader"
    private let enc: AES
    private let mac: Data
    private var ssc: Data
    private let file: Data

    init(sessENC: Data, sessMAC: Data, ssc: Data, file: Data) {
        enc = AES(key: sessENC)
        mac = sessMAC
        self.ssc = ssc
        self.file = file
    }

    func transmit(_ apdu: Data) throws -> Data {
        bump()                                   // command MAC used SSC+1
        let bytes = [UInt8](apdu)
        bump()                                   // response uses SSC+2
        guard bytes[1] == 0xB0 else { return respond(Data()) }
        // SM READ BINARY: 0C B0 P1 P2 Lc 97 01 Le 8E 08 … 00
        let offset = Int(bytes[2]) << 8 | Int(bytes[3])
        let le = Int(bytes[7])
        return respond(file.subdata(in: offset..<min(file.count, offset + le)))
    }

    func disconnect() {}

    private func bump() {
        var s = [UInt8](ssc)
        for i in stride(from: 15, through: 0, by: -1) { s[i] &+= 1; if s[i] != 0 { break } }
        ssc = Data(s)
    }

    private func respond(_ data: Data) -> Data {
        var body = Data()
        if !data.isEmpty {
            let ct = try! enc.cbcEncrypt(AES.iso9797Pad(data), iv: enc.ecbEncrypt(ssc))
            body += Data([0x87, 0x81, UInt8(ct.count + 1), 0x01]) + ct
        }
        body += Data([0x99, 0x02, 0x90, 0x00])
        let tag = try! AES.cmac(key: mac, message: AES.iso9797Pad(ssc + body)).prefix(8)
        return body + Data([0x8E, 0x08]) + tag + Data([0x90, 0x00])
    }
}

final class CardSimulatorTests: XCTestCase {
    func testReadBinaryKeepsChunksEndingInPaddingBytes() throws {
        let enc = Data(hex: "7C0749D47D8591E071A2C07788359A01AD12F94CAB3D2CA74F97FFD088CDCEDE")
        let mac = Data(hex: "A6C8773EFCA56A978389E6D9E1D4D19F6A6E54B05DCE27A84943B7FDB3A3F530")
        let ssc = Data(hex: "62AB2DF56EFCB9D384C6CE4CE785CB7B")
        // 300 bytes: first chunk ends in 0x00, second in 0x80 (both used to be truncated)
        var file = Data((0..<300).map { UInt8($0 % 251) })
        file[127] = 0x00; file[126] = 0x00
        file[255] = 0x80
        let card = CosmoXCard(transport: SimulatedCard(sessENC: enc, sessMAC: mac, ssc: ssc, file: file))
        card.installSecureChannel(SecureChannel(sessENC: enc, sessMAC: mac, ssc: ssc))
        XCTAssertEqual(try card.readBinary(offset: 0, length: 300), file)
    }
}
