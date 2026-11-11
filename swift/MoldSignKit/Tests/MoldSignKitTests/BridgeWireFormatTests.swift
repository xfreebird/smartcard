import XCTest
@testable import MoldSignKit

final class BridgeWireFormatTests: XCTestCase {
    func testFragmentedBodyWaitsForAllUtf8Bytes() {
        let body = Data("șț🔐".utf8)
        let header = Data("POST /sign/data HTTP/1.1\r\nContent-Length: \(body.count)\r\n\r\n".utf8)
        for count in 0..<body.count {
            XCTAssertFalse(BridgeWireFormat.httpComplete(header + body.prefix(count)))
        }
        XCTAssertTrue(BridgeWireFormat.httpComplete(header + body))
    }

    func testResponseLengthIsBytesAndDeniedOriginsHaveNoCors() {
        let response = BridgeWireFormat.respond(403, "șț🔐", contentType: "text/plain", origin: nil)
        let text = String(decoding: response, as: UTF8.self)
        XCTAssertTrue(text.contains("Content-Length: 8\r\n"))
        XCTAssertFalse(text.contains("Access-Control-Allow-Origin"))
    }

    func testCreatedResponseKeepsAbsoluteLocationAndEmptyBody() {
        let response = BridgeWireFormat.respondCreated(sessionId: "session", origin: "https://msign.gov.md",
                                                       location: "https://localhost.cts.md:18443/result/session")
        let text = String(decoding: response, as: UTF8.self)
        XCTAssertTrue(text.contains("Location: https://localhost.cts.md:18443/result/session\r\n"))
        XCTAssertTrue(text.contains("Content-Length: 0\r\n"))
        XCTAssertTrue(text.hasSuffix("\r\n\r\n"))
    }

    func testErrorStringsRoundTripControlCharactersAndUnicode() throws {
        for value in ["line\nnext", "tab\tvalue", "quote\"slash\\", "nul\u{0}end", "șț🔐"] {
            let json = Data(("{\"error\":\"" + BridgeWireFormat.jsonEsc(value) + "\"}").utf8)
            let decoded = try XCTUnwrap(JSONSerialization.jsonObject(with: json) as? [String: String])
            XCTAssertEqual(decoded["error"], value)
        }
    }

    func testJerseyNestedListReadsLeavesOnly() {
        let body = Data("<filesToSign><filesToSign>a.pdf</filesToSign><filesToSign>b.pdf</filesToSign></filesToSign>".utf8)
        XCTAssertEqual(BridgeWireFormat.xmlFields(body, "filesToSign"), ["a.pdf", "b.pdf"])
    }
    func testHostileLengthsCannotOverflowAndAmbiguousFramingIsRejected() {
        let huge = "POST / HTTP/1.1\r\nContent-Length: \(Int.max)\r\n\r\n"
        XCTAssertFalse(BridgeWireFormat.httpComplete(Data(huge.utf8)))
        for headers in ["Content-Length: -1", "Content-Length: +1", "Content-Length: nope",
                        "Content-Length: 1\r\nContent-Length: 1", "Transfer-Encoding: chunked",
                        "Content-Length: 99999999999999999999999999999"] {
            let head = "POST / HTTP/1.1\r\n" + headers
            XCTAssertNil(BridgeWireFormat.contentLength(head), headers)
            XCTAssertTrue(BridgeWireFormat.httpComplete(Data((head + "\r\n\r\n").utf8)))
        }
    }

    func testQueryEmptyNamesAndValuesCannotTrapOrShiftKeys() {
        XCTAssertEqual(BridgeWireFormat.queryItems("/result?=&=ignored&empty=&flag&name=a%3Db"),
                       ["empty": "", "flag": "", "name": "a=b"])
    }
}
