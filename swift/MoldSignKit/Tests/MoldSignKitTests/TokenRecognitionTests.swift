import XCTest
@testable import MoldSignKit

/// Phase TOK: ATR recognition of USB tokens against spec/tokens/token-families.json, and the experimental gate.
final class TokenRecognitionTests: XCTestCase {
    private func spec() throws -> [String: Any] {
        let url = VectorTests.repoRoot.appendingPathComponent("spec/tokens/token-families.json")
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }

    func testTableMatchesSpec() throws {
        let families = try XCTUnwrap(try spec()["families"] as? [[String: Any]])
        var fromSpec: [String] = []
        for family in families {
            let id = try XCTUnwrap(family["id"] as? String)
            XCTAssertEqual(TokenFamily(rawValue: id)?.displayName, family["name"] as? String, id)
            for pattern in try XCTUnwrap(family["patterns"] as? [[String: Any]]) {
                fromSpec.append("\(id) \(try XCTUnwrap(pattern["atr"] as? String)) \(try XCTUnwrap(pattern["mask"] as? String))")
            }
        }
        let table = TokenRecognizer.patterns.map { "\($0.family.rawValue) \($0.pattern.atr.hexString) \($0.pattern.mask.hexString)" }
        XCTAssertEqual(table, fromSpec, "regenerate TokenRecognizer.patterns from spec/tokens/token-families.json")
        XCTAssertEqual(Set(TokenFamily.allCases.map(\.rawValue)), Set(families.compactMap { $0["id"] as? String }))
    }

    func testVectors() throws {
        let vectors = try XCTUnwrap(try spec()["vectors"] as? [[String: Any]])
        XCTAssertFalse(vectors.isEmpty)
        for vector in vectors {
            let atr = try XCTUnwrap(vector["atr"] as? String)
            let expected = vector["family"] as? String
            XCTAssertEqual(TokenRecognizer.family(atr: Data(hex: atr))?.rawValue, expected, vector["comment"] as? String ?? atr)
        }
        XCTAssertNil(TokenRecognizer.family(atr: nil))
    }

    func testRecognizedTokenGetsNoAPDUWhenEnabled() throws {
        let token = RecordingTransport(atr: Data(hex: "3B9F958131FE9F006646530500000071DF000000000000"))
        let service = SigningService()
        service.transportFactory = { _ in token }
        service.experimentalTokens = true
        XCTAssertThrowsError(try service.readCertificate(reader: "token")) { error in
            XCTAssertEqual(error as? UnsupportedTokenError, UnsupportedTokenError(family: .ePass2003))
        }
        XCTAssertEqual(token.sent, [], "a recognized token must not receive IAS/ECC commands")
        XCTAssertTrue(token.disconnected)
    }

    func testDisabledKeepsTheEIDPath() {
        let token = RecordingTransport(atr: Data(hex: "3B9F958131FE9F006646530500000071DF000000000000"))
        let service = SigningService()
        service.transportFactory = { _ in token }
        XCTAssertFalse(service.experimentalTokens, "off by default")
        XCTAssertThrowsError(try service.readCertificate(reader: "token")) { error in
            XCTAssertNil(error as? UnsupportedTokenError)
        }
        XCTAssertFalse(token.sent.isEmpty, "off: the card is treated as an eID, as before")
    }

    func testEIDIsNotATokenWhenEnabled() {
        let eid = RecordingTransport(atr: Data(hex: "3BDF96008131FE4580738421E0574D44415F415350810F78"))
        let service = SigningService()
        service.transportFactory = { _ in eid }
        service.experimentalTokens = true
        XCTAssertThrowsError(try service.readCertificate(reader: "eid")) { error in
            XCTAssertNil(error as? UnsupportedTokenError)
        }
        XCTAssertFalse(eid.sent.isEmpty)
    }
}

/// Answers every APDU with 6A82 (file not found), like a token asked for the IAS/ECC application.
private final class RecordingTransport: CardTransport {
    let readerName = "Recording reader"
    let atr: Data?
    private(set) var sent: [Data] = []
    private(set) var disconnected = false

    init(atr: Data?) { self.atr = atr }

    func transmit(_ apdu: Data) throws -> Data {
        sent.append(apdu)
        return Data([0x6A, 0x82])
    }

    func disconnect() { disconnected = true }
}
