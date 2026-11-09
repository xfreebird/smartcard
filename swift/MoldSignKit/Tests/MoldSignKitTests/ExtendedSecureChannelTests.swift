import XCTest
@testable import MoldSignKit

final class ExtendedSecureChannelTests: XCTestCase {
    func testIndependentExtendedVectors() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("spec/vectors/encryption/extended-sm.json"))
        let fixture = try JSONDecoder().decode(Fixture.self, from: data)
        for vector in fixture.vectors {
            var channel = SecureChannel(sessENC: Data(hex: fixture.enc), sessMAC: Data(hex: fixture.mac), ssc: Data(hex: fixture.ssc))
            XCTAssertEqual(try channel.wrap(Data(hex: vector.command)), Data(hex: vector.wrapped))
        }
    }
    func testMalformedCommandDoesNotAdvanceCounter() throws {
        for command in [Data(hex: "002a80860001"), Data(hex: "002a808600000301020000"), Data(hex: "002a80860201"),
                        Data(hex: "002a808600ffff") + Data(repeating: 0, count: 65535)] {
            var channel = SecureChannel(sessENC: Data(repeating: 1,count: 32), sessMAC: Data(repeating: 2,count: 32), ssc: Data(repeating: 0,count: 16))
            XCTAssertThrowsError(try channel.wrap(command))
            XCTAssertEqual(channel.ssc, Data(repeating: 0,count: 16))
        }
    }
    private struct Fixture: Decodable {
        let enc: String, mac: String, ssc: String
        let vectors: [Vector]
        struct Vector: Decodable { let command: String, wrapped: String }
    }
}
