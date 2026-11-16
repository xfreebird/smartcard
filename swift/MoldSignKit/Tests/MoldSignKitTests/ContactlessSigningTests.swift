#if canImport(Security)
import XCTest
@testable import MoldSignKit

/// The production core over a simulated NFC pipe: plaintext identification, response chaining,
/// a fresh secure channel, certificate binding and one PIN verification. No physical card or PKI call.
final class ContactlessSigningTests: XCTestCase {
    func testRSA4096IdentityReadAndXAdESSigningWithChainedResponses() throws {
        let identity = try TestIdentity(keySize: 4096)
        let state = SimulatedCardState()
        let scan = ContactlessSimulator(state: state, identity: identity)
        let certificate = try ContactlessCertificateReader.read(using: scan)
        XCTAssertEqual(certificate, identity.certDER)
        XCTAssertEqual(state.verifyAttempts, 0)
        XCTAssertFalse(scan.commands.contains { $0[1] == 0x82 })

        // Keep the same connection from public identity read through the signature.
        let signing = scan
        XCTAssertEqual(signing.disconnectCount, 0)
        let service = SigningService()
        service.transportFactory = { _ in signing }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("nfc-synthetic-\(UUID()).xml")
        try Data("<document>NFC integration test</document>".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let result = try service.signXAdES(files: [url], format: .bes, type: .enveloping,
                                          pin: "1234", expectedCertificateSHA1: certificate.sha1().hexString)
        let reports = Validator.validateXAdES(result, referencedFiles: [:])
        XCTAssertEqual(reports.count, 1)
        let report = try XCTUnwrap(reports.first)
        XCTAssertTrue(report.signatureValid)
        XCTAssertTrue(report.contentIntact)
        XCTAssertEqual(state.verifyAttempts, 1)
        XCTAssertEqual(state.signedDigestInfos.count, 1)
        XCTAssertEqual(signing.commands.filter { $0[1] == 0x82 }.count, 1)
        XCTAssertEqual(signing.commands.filter { $0[1] == 0x88 }.count, 1)
        XCTAssertTrue(signing.commands.contains { $0[1] == 0xC0 })
        XCTAssertEqual(signing.disconnectCount, 1)
    }

    func testDifferentCardStopsBeforePIN() throws {
        let other = try TestIdentity(commonName: "OTHER SYNTHETIC CARD")
        let state = SimulatedCardState()
        let pipe = ContactlessSimulator(state: state, identity: other)
        let card = CosmoXCard(transport: pipe)
        try card.authenticate()
        XCTAssertThrowsError(try card.prepareForSigning(pin: "1234", expectedCertificateSHA1: TestIdentity.shared.certDER.sha1().hexString)) {
            guard case CardError.cardChanged = $0 else { return XCTFail("Unexpected error: \($0)") }
        }
        XCTAssertEqual(state.verifyAttempts, 0)
        XCTAssertTrue(state.signedDigestInfos.isEmpty)
    }

    func testWrongPINIsSentOnce() throws {
        let state = SimulatedCardState()
        let card = CosmoXCard(transport: ContactlessSimulator(state: state))
        try card.authenticate()
        XCTAssertThrowsError(try card.prepareForSigning(pin: "9999", expectedCertificateSHA1: nil)) {
            guard case CardError.wrongPIN(remaining: 2) = $0 else { return XCTFail("Unexpected error: \($0)") }
        }
        XCTAssertEqual(state.verifyAttempts, 1)
        XCTAssertTrue(state.signedDigestInfos.isEmpty)
    }

    func testEveryFailedSetupStatusStopsBeforeAuthentication() {
        for index in 0..<8 {
            let state = SimulatedCardState()
            let pipe = ContactlessSimulator(state: state)
            pipe.failCommand = index
            XCTAssertThrowsError(try CosmoXCard(transport: pipe).authenticate())
            XCTAssertEqual(pipe.commands.count, index + 1)
            XCTAssertFalse(pipe.commands.contains { $0[1] == 0x82 })
            XCTAssertEqual(state.verifyAttempts, 0)
        }
    }

    func testShortChallengeAndSerialCannotReachAuthentication() {
        for instruction: UInt8 in [0xB0, 0x84] {
            let pipe = ContactlessSimulator(state: SimulatedCardState())
            pipe.mutate = { command, response in
                command[1] == instruction ? Data(response.prefix(8)) + Data(hex: "9000") : response
            }
            XCTAssertThrowsError(try CosmoXCard(transport: pipe).authenticate())
            XCTAssertFalse(pipe.commands.contains { $0[1] == 0x82 })
        }
    }

    func testValidMACWithWrongChallengeOrTerminalBindingIsRejected() throws {
        for offset in [0, 16, 24, 40] {
            let state = SimulatedCardState()
            let pipe = ContactlessSimulator(state: state)
            pipe.mutate = { command, response in
                guard command[1] == 0x82 else { return response }
                let aes = AES(key: CryptoTests.kenc)
                var plain = try aes.cbcDecrypt(Data(response.prefix(80)), iv: Data(count: 16))
                plain[offset] ^= 1
                let ciphertext = try aes.cbcEncrypt(plain, iv: Data(count: 16))
                return ciphertext + AES.cmac(key: CryptoTests.kmac, message: ciphertext) + Data(hex: "9000")
            }
            let card = CosmoXCard(transport: pipe)
            XCTAssertThrowsError(try card.authenticate()) {
                guard case CardError.macVerificationFailed = $0 else { return XCTFail("Unexpected error: \($0)") }
            }
            XCTAssertThrowsError(try card.selectMF(), "No secure channel may survive failed authentication")
            XCTAssertEqual(pipe.commands.filter { $0[1] == 0x82 }.count, 1)
            XCTAssertEqual(state.verifyAttempts, 0)
        }
    }

    func testTerminalRandomAndKeyAreFreshForEachSession() throws {
        var requests: [Data] = []
        for _ in 0..<2 {
            let pipe = ContactlessSimulator(state: SimulatedCardState())
            try CosmoXCard(transport: pipe).authenticate()
            let command = try XCTUnwrap(pipe.commands.first { $0[1] == 0x82 })
            requests.append(try AES(key: CryptoTests.kenc).cbcDecrypt(command.subdata(in: 5..<85), iv: Data(count: 16)))
        }
        XCTAssertNotEqual(requests[0].prefix(16), requests[1].prefix(16))
        XCTAssertNotEqual(requests[0].suffix(32), requests[1].suffix(32))
    }
}

private final class ContactlessSimulator: CardTransport {
    let readerName = "Synthetic NFC"
    let base: SimulatedCosmoXCard
    let identity: TestIdentity
    var commands: [Data] = []
    private(set) var disconnectCount = 0
    var failCommand: Int?
    var mutate: ((Data, Data) throws -> Data)?
    private var file = Data()
    private var pending = Data()
    init(state: SimulatedCardState, identity: TestIdentity = .shared) {
        self.identity = identity
        base = SimulatedCosmoXCard(state: state, identity: identity)
    }
    func disconnect() { disconnectCount += 1; base.disconnect() }
    func transmit(_ command: Data) throws -> Data {
        commands.append(command)
        if failCommand == commands.count - 1 { return Data(hex: "6985") }
        if command[1] == 0xC0 {
            guard !pending.isEmpty else { throw CardError.cardNotResponding }
            let response = pending; pending = Data()
            return split(response)
        }
        guard pending.isEmpty else { throw CardError.cardNotResponding }
        if command[0] == 0, command[1] == 0xA4 {
            file = command.subdata(in: 5..<(5 + Int(command[4])))
        }
        if command[0] == 0, command[1] == 0xB0, file == Data([0, 1]) {
            let offset = Int(command[2]) * 256 + Int(command[3])
            return identity.certDER.subdata(in: offset..<min(identity.certDER.count, offset + Int(command[4]))) + Data(hex: "9000")
        }
        let raw = try base.transmit(command)
        let response = try mutate?(command, raw) ?? raw
        if command[1] == 0x82, response.count == 98 {
            pending = response
            return Data(hex: "6160")
        }
        return split(response)
    }
    private func split(_ response: Data) -> Data {
        guard response.count > 258 else { return response }
        pending = Data(response.dropFirst(256))
        let remaining = pending.count - 2
        return Data(response.prefix(256)) + Data([0x61, remaining >= 256 ? 0 : UInt8(remaining)])
    }
}
#endif
