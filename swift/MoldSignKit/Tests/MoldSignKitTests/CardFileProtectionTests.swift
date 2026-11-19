#if canImport(Security) && !MOLDSIGN_PORTABLE
import XCTest
@testable import MoldSignKit

final class CardFileProtectionTests: XCTestCase {
    private func setup(mirrorsEOFWarning: Bool = false, paddedDirectories: Bool = false,
                       policy: CertificateRecipientPolicy = .encryptionCertificate, encryptionCertificate: Bool = true) throws -> (CosmoXCard,SimulatedCosmoXCard,SimulatedCardState,CardEncryptionIdentity,Data) {
        let identity = try TestIdentity(encryption: encryptionCertificate)
        let state = SimulatedCardState()
        let transport = SimulatedCosmoXCard(state: state,identity: identity)
        transport.mirrorsEOFWarning = mirrorsEOFWarning
        let (keys,certificates,authentication) = CardEncryptionDirectoryTests().fixture()
        transport.extraFiles = [Data([0x70,1]):authentication,Data([0x70,2]):keys,
                                Data([0x70,5]):certificates,Data([0,2]):identity.certDER]
        if paddedDirectories {
            for file in [Data([0x70,1]),Data([0x70,2]),Data([0x70,5])] {
                let bytes = transport.extraFiles[file]!
                transport.extraFiles[file] = bytes + Data(repeating: 0, count: 128 - bytes.count % 128)
            }
        }
        let card = CosmoXCard(transport: transport)
        try card.authenticate()
        let selected = try XCTUnwrap(card.encryptionIdentities(policy: policy).first)
        return (card,transport,state,selected,try CertificateFileProtection.encrypt(Data("Fictional private document".utf8),certificate:identity.certDER,policy: policy))
    }
    func testEncryptedFileThroughSimulatedCard() throws {
        let (card,transport,state,identity,envelope) = try setup()
        XCTAssertEqual(state.verifyAttempts,0)
        XCTAssertEqual(try card.decryptFile(envelope,identity:identity,pin:"1234"),Data("Fictional private document".utf8))
        XCTAssertEqual(state.verifyAttempts,1)
        XCTAssertEqual(transport.decryptAttempts,1)
    }
    func testDiscoveryAcceptsAuthenticatedEOFWithoutSendingPIN() throws {
        let (_,transport,state,identity,_) = try setup(mirrorsEOFWarning: true)
        XCTAssertFalse(identity.certificate.isEmpty)
        XCTAssertEqual(state.verifyAttempts,0)
        XCTAssertEqual(transport.decryptAttempts,0)
    }
    func testDiscoveryAcceptsAuthenticatedPastEOFOnBlockBoundary() throws {
        let (_,transport,state,identity,_) = try setup(mirrorsEOFWarning: true, paddedDirectories: true)
        XCTAssertFalse(identity.certificate.isEmpty)
        XCTAssertEqual(state.verifyAttempts,0)
        XCTAssertEqual(transport.decryptAttempts,0)
    }
    func testWrongPINStopsBeforeDecipherWithoutRetry() throws {
        let (card,transport,state,identity,envelope) = try setup()
        XCTAssertThrowsError(try card.decryptFile(envelope,identity:identity,pin:"9999"))
        XCTAssertEqual(state.verifyAttempts,1)
        XCTAssertEqual(state.triesLeft,2)
        XCTAssertEqual(transport.decryptAttempts,0)
    }
    func testPublicKeyCompatibilityIsExplicitAndDecryptsWithAdvertisedCardKey() throws {
        let (card,transport,state,identity,envelope) = try setup(policy: .cardPublicKey,encryptionCertificate: false)
        XCTAssertTrue(try card.encryptionIdentities().isEmpty)
        XCTAssertThrowsError(try CertificateFileProtection.validateRecipient(identity.certificate))
        XCTAssertEqual(identity.recipientPolicy,.cardPublicKey)
        XCTAssertEqual(state.verifyAttempts,0)
        XCTAssertEqual(try card.decryptFile(envelope,identity:identity,pin:"1234"),Data("Fictional private document".utf8))
        XCTAssertEqual(state.verifyAttempts,1)
        XCTAssertEqual(transport.decryptAttempts,1)
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
