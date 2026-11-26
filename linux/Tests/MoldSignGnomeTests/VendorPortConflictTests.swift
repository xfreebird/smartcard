import Foundation
import XCTest
@testable import MoldSignGnome

final class VendorPortConflictTests: GnomeTestCase {
    func testOnlyExactVendorJarIsRecognized() {
        func command(_ args: [String]) -> Data { Data((args.joined(separator: "\0") + "\0").utf8) }
        XCTAssertTrue(VendorPortConflict.isVendorServer(command(["java", "-jar", "/opt/MoldSign/lib/ClientCardServer-2.0.jar"])))
        XCTAssertFalse(VendorPortConflict.isVendorServer(command(["java", "-jar", "/tmp/Other.jar"])))
        XCTAssertFalse(VendorPortConflict.isVendorServer(command(["java", "-cp", "/tmp/ClientCardServer-2.0.jar", "Other"])))
    }

    #if os(Linux)
    func testQuitOnlyIdentifiedListeningVendorProcess() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("listener.c")
        try """
        #include <sys/socket.h>
        #include <netinet/in.h>
        #include <stdlib.h>
        #include <unistd.h>
        int main(int argc, char **argv) {
            if (argc != 4) return 2;
            int fd = socket(AF_INET, SOCK_STREAM, 0), one = 1;
            setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));
            struct sockaddr_in addr = { .sin_family = AF_INET, .sin_port = htons(atoi(argv[3])), .sin_addr.s_addr = htonl(INADDR_LOOPBACK) };
            if (bind(fd, (void *)&addr, sizeof(addr)) || listen(fd, 1)) return 3;
            for (;;) pause();
        }
        """.write(to: source, atomically: true, encoding: .utf8)
        let compiler = Process(); compiler.executableURL = URL(fileURLWithPath: "/usr/bin/cc")
        let executable = root.appendingPathComponent("java")
        compiler.arguments = [source.path, "-o", executable.path]
        try compiler.run(); compiler.waitUntilExit()
        guard compiler.terminationStatus == 0 else { throw XCTSkip("C compiler unavailable") }
        func launch(_ jar: String, _ port: String) throws -> Process {
            let process = Process(); process.executableURL = executable
            process.arguments = ["-jar", jar, port]; try process.run(); return process
        }
        let vendor = try launch("ClientCardServer-2.0.jar", "18480")
        let other = try launch("Other.jar", "18443")
        defer { if vendor.isRunning { vendor.terminate() }; if other.isRunning { other.terminate() } }
        var found: [VendorPortConflict.Listener] = []
        for _ in 0..<30 {
            if !vendor.isRunning || !other.isRunning { throw XCTSkip("Bridge ports already occupied") }
            found = VendorPortConflict.listeners()
            if found.contains(where: { $0.pid == vendor.processIdentifier }) { break }
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTAssertTrue(found.contains { $0.pid == vendor.processIdentifier })
        XCTAssertFalse(found.contains { $0.pid == other.processIdentifier })
        VendorPortConflict.requestQuit(found.filter { $0.pid == vendor.processIdentifier })
        for _ in 0..<30 where vendor.isRunning { Thread.sleep(forTimeInterval: 0.1) }
        XCTAssertFalse(vendor.isRunning)
        XCTAssertTrue(other.isRunning)
    }
    #endif
}
