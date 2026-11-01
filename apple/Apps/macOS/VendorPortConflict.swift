#if !APP_STORE
import Darwin
import Foundation

/// Only current-user listeners inside the installed vendor directory are eligible.
enum VendorPortConflict {
    private static let vendorRoot = "/Applications/STISC/MoldSign/"
    private struct Identity: Equatable {
        let pid: pid_t
        let path: String
        let startedSeconds: UInt64
        let startedMicroseconds: UInt64
    }

    static func listeners() -> [pid_t] { listenerIdentities().map(\.pid) }

    /// SIGTERM runs the JVM's shutdown hooks without depending on Java's GUI quit handler
    /// or Apple Events permissions. Never escalate to SIGKILL or signal a reused PID.
    @discardableResult
    static func terminateListeners() -> Bool {
        ProcessShutdown.request(approved: listenerIdentities(), current: listenerIdentities, signal: { listener in
            // Recheck the creation time immediately before signalling; never trust a PID alone.
            guard identity(listener.pid) == listener else { return true }
            return kill(listener.pid, SIGTERM) == 0 || errno == ESRCH
        }, wait: { Thread.sleep(forTimeInterval: 0.1) })
    }

    private static func listenerIdentities() -> [Identity] {
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
            .compactMap(identity)
    }

    private static func identity(_ pid: pid_t) -> Identity? {
        var info = proc_bsdinfo()
        let count = Int32(MemoryLayout<proc_bsdinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, count) == count,
              info.pbi_uid == getuid() else { return nil }
        var buffer = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return nil }
        let path = URL(fileURLWithPath: String(cString: buffer)).resolvingSymlinksInPath().path
        guard path.hasPrefix(vendorRoot) else { return nil }
        return Identity(pid: pid, path: path, startedSeconds: info.pbi_start_tvsec,
                        startedMicroseconds: info.pbi_start_tvusec)
    }
}
#endif
