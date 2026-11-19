import XCTest
import MoldSignKit
@testable import CertificateProbeSupport

final class PublicCardReaderTests: XCTestCase {
    private final class Transport: CardTransport {
        let readerName = "Synthetic reader"
        var commands: [Data] = []
        var respond: (Data) throws -> Data = { _ in Data([0x90, 0]) }
        func transmit(_ apdu: Data) throws -> Data { commands.append(apdu); return try respond(apdu) }
        func disconnect() {}
    }

    func testPINPrivateKeyAndMutationCommandsNeverReachTransport() {
        let underlying = Transport(), transport = ReadOnlyProbeTransport(Transport())
        // Both clear and secure-message CLA values retain the operation INS.
        let guarded = ReadOnlyProbeTransport(underlying)
        for cla: UInt8 in [0, 0x0c] {
            for instruction: UInt8 in [0x20, 0x24, 0x2c, 0x2a, 0x88, 0xd6, 0xe0, 0xe4, 0x46] {
                XCTAssertThrowsError(try guarded.transmit(Data([cla,instruction,0,0,0])))
            }
        }
        XCTAssertThrowsError(try transport.transmit(Data([0,0x22,0x41,0xb8,0])))
        XCTAssertTrue(underlying.commands.isEmpty)
    }

    func testSecurityStatusStopsWithoutSendingAnotherCommand() {
        for status: UInt16 in [0x6983,0x6985,0x6988,0x63c2] {
            let transport = Transport()
            transport.respond = { _ in Data([UInt8(status >> 8), UInt8(status & 255)]) }
            XCTAssertThrowsError(try PublicCardReader(transport: transport, log: { _ in }, save: { _,_ in XCTFail("No file should be saved") }).run())
            XCTAssertEqual(transport.commands.count,1)
        }
    }

    func testMissingPublicFilesAreReportedWithoutAuthentication() throws {
        let transport = Transport()
        transport.respond = { command in command[2] == 2 ? Data([0x6a,0x82]) : Data([0x90,0]) }
        var reports: [String] = []
        try PublicCardReader(transport: transport, log: { reports.append($0) }, save: { _,_ in XCTFail("Missing file") }).run()
        XCTAssertEqual(reports.filter { $0.contains("not found") }.count,4)
        XCTAssertTrue(transport.commands.allSatisfy { $0[1] == 0xa4 })
    }

    func testLengthCorrectionDoesNotLoopOnRepeated6C() {
        let transport = Transport()
        transport.respond = { command in command[1] == 0xb0 ? Data([0x6c,0x20]) : Data([0x90,0]) }
        XCTAssertThrowsError(try PublicCardReader(transport: transport, log: { _ in }, save: { _,_ in XCTFail("No complete file") }).run())
        let reads = transport.commands.filter { $0[1] == 0xb0 }
        XCTAssertEqual(reads.count,2)
        XCTAssertEqual(reads.last?.last,0x20)
    }

    func testShortSuccessfulReadSavesOnlyReturnedBytes() throws {
        let transport = Transport()
        transport.respond = { command in command[1] == 0xb0 ? Data([1,2,3,0x90,0]) : Data([0x90,0]) }
        var files: [String:Data] = [:]
        try PublicCardReader(transport: transport, log: { _ in }, save: { files[$0] = $1 }).run()
        XCTAssertEqual(files.count,4)
        XCTAssertTrue(files.values.allSatisfy { $0 == Data([1,2,3]) })
        XCTAssertEqual(transport.commands.filter { $0[1] == 0xb0 }.count,4)
    }
    func testExplicitDecipherModeAllowsOnlyOneOrderedPrivateOperation() throws {
        let underlying = Transport()
        let transport = ReadOnlyProbeTransport(underlying, allowDecipher: true)
        let verify = Data([0x0c,0x20,0,3,0])
        let mse = Data([0x0c,0x22,0x41,0xb8,0])
        let decipher = Data([0x0c,0x2a,0x80,0x86,0])
        XCTAssertThrowsError(try transport.transmit(mse))
        XCTAssertThrowsError(try transport.transmit(decipher))
        XCTAssertThrowsError(try transport.transmit(Data([0x0c,0x20,0,4,0])))
        _ = try transport.transmit(verify)
        XCTAssertThrowsError(try transport.transmit(verify))
        _ = try transport.transmit(mse)
        XCTAssertThrowsError(try transport.transmit(mse))
        _ = try transport.transmit(decipher)
        XCTAssertThrowsError(try transport.transmit(decipher))
        XCTAssertThrowsError(try transport.transmit(Data([0x0c,0x88,0,0,0])))
        XCTAssertEqual(underlying.commands,[verify,mse,decipher])
    }
}
