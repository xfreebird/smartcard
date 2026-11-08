import Foundation
import XCTest
@testable import MoldSignMCP

final class BoundedCredentialCommandTests: XCTestCase {
    func testReturnsOnlyStdoutAndDiscardsDiagnostics() throws {
        let data = try MCPBoundedCredentialCommand.read(executable: "/bin/sh",
            arguments: ["-c", "printf '1234'; printf 'diagnostic must stay private' >&2"], timeout: 2)
        XCTAssertEqual(data, Data("1234".utf8))
    }

    func testRejectsOversizedOutputWithoutWaitingForPipeToDrain() {
        assertCredentialFailure("while :; do printf '12345678901234567890123456789012345'; done")
    }

    func testRejectsNonzeroExitEvenWhenItProducesAPIN() {
        assertCredentialFailure("printf '1234'; exit 1")
    }

    func testTerminatesTimedOutProvider() {
        assertCredentialFailure("exec /bin/sleep 5", timeout: 0.15)
    }

    func testInheritedPipeCannotOutliveTheDeadline() {
        // The direct provider exits immediately, but a descendant still owns stdout.
        // A blocking FileHandle read after waiting for the provider would wait one second.
        assertCredentialFailure("/bin/sleep 1 & printf '1234'; exit 0", timeout: 0.1, maximumDuration: 0.8)
    }

    private func assertCredentialFailure(_ script: String, timeout: TimeInterval = 1,
                                         maximumDuration: TimeInterval = 3,
                                         file: StaticString = #filePath, line: UInt = #line) {
        let start = ProcessInfo.processInfo.systemUptime
        XCTAssertThrowsError(try MCPBoundedCredentialCommand.read(executable: "/bin/sh",
            arguments: ["-c", script], timeout: timeout), file: file, line: line) { error in
            guard case MCPFailure.credentialUnavailable = error else {
                return XCTFail("Expected a sanitized credential error", file: file, line: line)
            }
        }
        XCTAssertLessThan(ProcessInfo.processInfo.systemUptime - start, maximumDuration, file: file, line: line)
    }
}
