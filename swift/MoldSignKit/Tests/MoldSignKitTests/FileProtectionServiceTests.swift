import Foundation
import XCTest
@testable import MoldSignKit

final class FileProtectionServiceTests: XCTestCase {
    func testRoundTripPreservesOriginalAndCreatesDistinctPrivateOutputs() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let input = root.appendingPathComponent("contract.txt")
        let original = Data("Synthetic contract șț".utf8)
        try original.write(to: input)
        let service = FileProtectionService(outputDirectory: root.appendingPathComponent("outputs"))
        let encrypted = try await service.process(input, operation: .encrypt, password: "test-password")
        let encryptedURL = try XCTUnwrap(encrypted)
        let decrypted = try await service.process(encryptedURL, operation: .decrypt, password: "test-password")
        let decryptedURL = try XCTUnwrap(decrypted)
        XCTAssertEqual(try Data(contentsOf: input), original)
        XCTAssertEqual(try Data(contentsOf: decryptedURL), original)
        XCTAssertNotEqual(encryptedURL.deletingLastPathComponent(), decryptedURL.deletingLastPathComponent())
        XCTAssertEqual(decryptedURL.lastPathComponent, "decrypted-contract.txt")
        let attributes = try FileManager.default.attributesOfItem(atPath: decryptedURL.path)
        XCTAssertEqual((attributes[.posixPermissions] as? NSNumber)?.intValue, 0o600)
    }

    func testMalformedEnvelopeLeavesNoOutputAndPreservesInput() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let input = root.appendingPathComponent("contract.p7m")
        let bytes = Data("Not an encrypted envelope".utf8)
        try bytes.write(to: input)
        let output = root.appendingPathComponent("outputs")
        let service = FileProtectionService(outputDirectory: output)
        do {
            _ = try await service.process(input, operation: .decrypt, password: "incorrect")
            XCTFail("Malformed envelope must fail")
        } catch { }
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
        XCTAssertEqual(try Data(contentsOf: input), bytes)
    }

    func testFailedDestinationDoesNotModifySource() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let input = root.appendingPathComponent("source")
        let output = root.appendingPathComponent("not-a-directory")
        let bytes = Data("Original".utf8)
        try bytes.write(to: input)
        try bytes.write(to: output)
        do {
            _ = try await FileProtectionService(outputDirectory: output).process(input, operation: .encrypt, password: "test")
            XCTFail("Writing under a regular file must fail")
        } catch { }
        XCTAssertEqual(try Data(contentsOf: input), bytes)
        XCTAssertEqual(try Data(contentsOf: output), bytes)
    }

    func testCancelledRequestDoesNotReadOrWrite() async throws {
        let root = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let service = FileProtectionService(outputDirectory: root.appendingPathComponent("outputs"))
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await service.process(root.appendingPathComponent("missing"), operation: .encrypt, password: "test")
        }
        do { _ = try await task.value; XCTFail("Cancelled request must fail") }
        catch is CancellationError { }
        catch { XCTFail("Unexpected error: \(error)") }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path), [])
    }

    private func makeDirectory() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
}
