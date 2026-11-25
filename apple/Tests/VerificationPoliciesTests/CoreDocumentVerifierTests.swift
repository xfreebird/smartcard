import XCTest
import MoldSignKit
@testable import VerificationPolicies

final class CoreDocumentVerifierTests: XCTestCase {
    private var directory: URL!
    private let verifier = CoreDocumentVerifier(service: .shared)

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    /// The core suite's public unsigned fixture, shared from this checkout.
    private func unsignedPDF() throws -> Data {
        let repository = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try Data(contentsOf: repository.appendingPathComponent("swift/MoldSignKit/Tests/MoldSignKitTests/Fixtures/unsigned.pdf"))
    }

    func testSignedPDFProducesOneReportAndUnsignedNone() async throws {
        let original = try unsignedPDF()
        let signed = try PAdESSigner().signPDF(original, certDER: ChainCerts.mdQSign, tsaUnsignedAttr: Data()) { _ in
            Data(repeating: 0xAB, count: 512)
        }
        let signedURL = directory.appendingPathComponent("contract-semnat.PDF")
        let unsignedURL = directory.appendingPathComponent("contract.pdf")
        try signed.write(to: signedURL)
        try original.write(to: unsignedURL)

        let reports = await verifier.verify(signedURL)
        XCTAssertEqual(reports.count, 1)
        XCTAssertEqual(reports.first?.kind, "PAdES")
        XCTAssertEqual(reports.first?.contentIntact, true)
        XCTAssertEqual(reports.first?.signatureValid, false, "a placeholder signature never verifies")
        let unsignedReports = try await verifier.inspect(unsignedURL)
        XCTAssertTrue(unsignedReports.isEmpty)
    }

    func testUnreadableFilesAreEmptyForVerifyAndErrorsForInspect() async {
        let missing = directory.appendingPathComponent("missing.xml")
        let reports = await verifier.verify(missing)
        XCTAssertTrue(reports.isEmpty)
        do {
            _ = try await verifier.inspect(missing, companions: [])
            XCTFail("a missing document must not look like an unsigned one")
        } catch {
            XCTAssertEqual((error as? CocoaError)?.code, .fileReadNoSuchFile)
        }
    }

    func testXMLWithoutSignaturesFindsNoCompanions() async throws {
        let xml = directory.appendingPathComponent("plain.xml")
        try Data("<document>not signed</document>".utf8).write(to: xml)
        let companion = directory.appendingPathComponent("other.txt")
        try Data("unrelated".utf8).write(to: companion)
        let reports = try await verifier.inspect(xml, companions: [companion])
        XCTAssertTrue(reports.isEmpty)
    }

    func testCancelledInspectionStopsBeforeReading() async throws {
        let pdf = directory.appendingPathComponent("contract.pdf")
        try unsignedPDF().write(to: pdf)
        let task = Task { [verifier] in
            withUnsafeCurrentTask { $0?.cancel() }
            return try await verifier.inspect(pdf)
        }
        do {
            _ = try await task.value
            XCTFail("cancelled inspection returned")
        } catch {
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
    }

    func testDefaultInspectionForwardsToVerify() async throws {
        struct FixedVerifier: DocumentVerifying {
            let reports: [Validator.Report]
            func verify(_ url: URL) async -> [Validator.Report] { reports }
        }
        let fixed = FixedVerifier(reports: [])
        let viaInspect = try await fixed.inspect(URL(fileURLWithPath: "/a.pdf"))
        let viaCompanions = try await fixed.inspect(URL(fileURLWithPath: "/a.xml"), companions: [URL(fileURLWithPath: "/b.txt")])
        XCTAssertTrue(viaInspect.isEmpty)
        XCTAssertTrue(viaCompanions.isEmpty)
    }
}
