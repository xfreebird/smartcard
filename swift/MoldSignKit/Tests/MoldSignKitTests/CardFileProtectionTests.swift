#if canImport(Security) && !MOLDSIGN_PORTABLE
import XCTest
@testable import MoldSignKit

final class CardFileProtectionTests: XCTestCase {
    private func setup() throws -> (CosmoXCard,SimulatedCosmoXCard,SimulatedCardState,CardEncryptionIdentity,Data) {
        let identity = try TestIdentity(encryption: true)
        let state = SimulatedCardState()
        let transport = SimulatedCosmoXCard(state: state,identity: identity)
        let (keys,certificates,authentication) = CardEncryptionDirectoryTests().fixture()
        transport.extraFiles = [Data([0x70,1]):authentication,Data([0x70,2]):keys,
                                Data([0x70,5]):certificates,Data([0,2]):identity.certDER]
        let card = CosmoXCard(transport: transport)
        try card.authenticate()
        let selected = try XCTUnwrap(card.encryptionIdentities().first)
        return (card,transport,state,selected,try CertificateFileProtection.encrypt(Data("Fictional private document".utf8),certificate:identity.certDER))
    }
    func testEncryptedFileThroughSimulatedCard() throws {
        let (card,transport,state,identity,envelope) = try setup()
        XCTAssertEqual(state.verifyAttempts,0)
        XCTAssertEqual(try card.decryptFile(envelope,identity:identity,pin:"1234"),Data("Fictional private document".utf8))
        XCTAssertEqual(state.verifyAttempts,1)
        XCTAssertEqual(transport.decryptAttempts,1)
    }
    func testWrongPINStopsBeforeDecipherWithoutRetry() throws {
        let (card,transport,state,identity,envelope) = try setup()
        XCTAssertThrowsError(try card.decryptFile(envelope,identity:identity,pin:"9999"))
        XCTAssertEqual(state.verifyAttempts,1)
        XCTAssertEqual(state.triesLeft,2)
        XCTAssertEqual(transport.decryptAttempts,0)
    }
    func testChangedIdentityAndMalformedEnvelopeNeverSendPIN() throws {
        let (card,transport,state,identity,envelope) = try setup()
        XCTAssertThrowsError(try card.decryptFile(Data(envelope.dropLast()),identity:identity,pin:"1234"))
        transport.extraFiles[Data([0,2])] = try TestIdentity(encryption:true).certDER
        XCTAssertThrowsError(try card.decryptFile(envelope,identity:identity,pin:"1234"))
        XCTAssertEqual(state.verifyAttempts,0)
        XCTAssertEqual(transport.decryptAttempts,0)
    }
}
#endif
