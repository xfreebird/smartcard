import XCTest
@testable import MoldSignKit

final class ContactlessCertificateReaderTests: XCTestCase {
    func testCompleteReadIsBoundedAndNeverAuthenticates() throws {
        let bytes = DER.seq(Data(repeating: 0x5A, count: 1795))
        let transport = CertificateTransport(file: bytes)
        XCTAssertEqual(try ContactlessCertificateReader.read(using: transport), bytes)
        XCTAssertEqual(transport.commands.first, Data([0, 0xA4, 4, 4, UInt8(CosmoXCard.genericADF.count)]) + CosmoXCard.genericADF + Data([0]))
        XCTAssertTrue(transport.commands.allSatisfy { [0xA4, 0xB0].contains($0[1]) })
        XCTAssertTrue(transport.commands.filter { $0[1] == 0xB0 }.allSatisfy { $0[4] <= 128 })
        XCTAssertFalse(transport.disconnected, "Reader does not own transport lifetime")
    }

    func testMalformedOrTruncatedFileStopsWithoutAuthentication() {
        for file in [Data(hex: "31800000"), Data(hex: "30800000"), Data(hex: "3082007F"),
                     Data(hex: "30822000"), Data(hex: "308101"), Data(hex: "30820100") + Data(count: 10)] {
            let transport = CertificateTransport(file: file)
            XCTAssertThrowsError(try ContactlessCertificateReader.read(using: transport))
            XCTAssertTrue(transport.commands.allSatisfy { [0xA4, 0xB0].contains($0[1]) })
        }
    }

    func testSelectionFailureDoesNotReadOrRetry() {
        let transport = CertificateTransport(file: Data(), response: { _ in Data(hex: "6982") })
        XCTAssertThrowsError(try ContactlessCertificateReader.read(using: transport))
        XCTAssertEqual(transport.commands.count, 1)
    }

    func testEndlessContinuationIsBounded() {
        let transport = CertificateTransport(file: Data(), response: { _ in Data(hex: "6100") })
        XCTAssertThrowsError(try ContactlessCertificateReader.read(using: transport))
        XCTAssertEqual(transport.commands.count, 8)
        XCTAssertTrue(transport.commands.dropFirst().allSatisfy { $0 == Data(hex: "00C0000000") })
    }
}

private final class CertificateTransport: CardTransport {
    let readerName = "Synthetic contactless certificate"
    let file: Data
    let response: ((Data) -> Data)?
    var commands: [Data] = []
    var disconnected = false
    init(file: Data, response: ((Data) -> Data)? = nil) { self.file = file; self.response = response }
    func disconnect() { disconnected = true }
    func transmit(_ command: Data) throws -> Data {
        commands.append(command)
        if let response { return response(command) }
        if command[1] == 0xA4 { return Data(hex: "9000") }
        guard command[1] == 0xB0 else { return Data(hex: "6D00") }
        let offset = Int(command[2]) * 256 + Int(command[3])
        guard offset <= file.count else { return Data(hex: "6B00") }
        return file.subdata(in: offset..<min(file.count, offset + Int(command[4]))) + Data(hex: "9000")
    }
}
