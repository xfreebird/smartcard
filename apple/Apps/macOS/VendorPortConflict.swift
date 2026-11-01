import AppKit
import Darwin
import Foundation

/// Restricts the quit action to listeners belonging to the installed MoldSign suite.
enum VendorPortConflict {
    private static let vendorRoot = "/Applications/STISC/MoldSign/"

    static func listeners() -> [pid_t] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-nP", "-tiTCP:18480,18443", "-sTCP:LISTEN"]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do { try process.run() } catch { return [] }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (String(data: data, encoding: .utf8) ?? "")
            .split(whereSeparator: \.isNewline)
            .compactMap { pid_t($0) }
            .filter { isVendorExecutable($0) }
    }

    static func terminateListeners() {
        // Recheck executable identities immediately before signalling: never kill an unknown port owner.
        for pid in listeners() where isVendorExecutable(pid) {
            if let app = NSRunningApplication(processIdentifier: pid) {
                _ = app.terminate()
            } else {
                _ = kill(pid, SIGTERM)
            }
        }
    }

    private static func isVendorExecutable(_ pid: pid_t) -> Bool {
        var buffer = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return false }
        let path = URL(fileURLWithPath: String(cString: buffer)).resolvingSymlinksInPath().path
        return path.hasPrefix(vendorRoot)
    }
}
