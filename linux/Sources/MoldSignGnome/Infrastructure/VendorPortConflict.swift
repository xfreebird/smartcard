import Foundation
#if os(Linux)
import Glibc
#endif

/// A narrow, best-effort identification: only the current user's Java process running the
/// vendor's server JAR and actually listening on a bridge port is eligible for termination.
enum VendorPortConflict {
    struct Listener: Equatable {
        let pid: Int32
        let startTime: String
    }

    static func listeners() -> [Listener] {
        #if os(Linux)
        let fm = FileManager.default
        let inodes = listeningInodes()
        guard !inodes.isEmpty, let entries = try? fm.contentsOfDirectory(atPath: "/proc") else { return [] }
        return entries.compactMap { entry in
            guard let pid = Int32(entry), pid > 0,
                  let attributes = try? fm.attributesOfItem(atPath: "/proc/\(pid)"),
                  let owner = attributes[.ownerAccountID] as? NSNumber, owner.uint32Value == getuid(),
                  let executable = try? fm.destinationOfSymbolicLink(atPath: "/proc/\(pid)/exe"),
                  URL(fileURLWithPath: executable).lastPathComponent == "java",
                  let command = try? Data(contentsOf: URL(fileURLWithPath: "/proc/\(pid)/cmdline")),
                  isVendorServer(command), let start = processStartTime(pid),
                  let descriptors = try? fm.contentsOfDirectory(atPath: "/proc/\(pid)/fd"),
                  descriptors.contains(where: { fd in
                      guard let target = try? fm.destinationOfSymbolicLink(atPath: "/proc/\(pid)/fd/\(fd)") else { return false }
                      return inodes.contains(target)
                  }) else { return nil }
            return Listener(pid: pid, startTime: start)
        }
        #else
        return []
        #endif
    }

    /// Re-read identity and socket ownership immediately before signalling; never escalate to SIGKILL.
    static func requestQuit(_ approved: [Listener]) {
        #if os(Linux)
        let current = listeners()
        for listener in approved where current.contains(listener) { _ = kill(listener.pid, SIGTERM) }
        #endif
    }

    static func isVendorServer(_ command: Data) -> Bool {
        let args = command.split(separator: 0).compactMap { String(data: Data($0), encoding: .utf8) }
        guard let jarFlag = args.firstIndex(of: "-jar"), args.indices.contains(jarFlag + 1) else { return false }
        return URL(fileURLWithPath: args[jarFlag + 1]).lastPathComponent == "ClientCardServer-2.0.jar"
    }

    #if os(Linux)
    private static func listeningInodes() -> Set<String> {
        var result = Set<String>()
        for path in ["/proc/net/tcp", "/proc/net/tcp6"] {
            guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else { continue }
            for line in contents.split(separator: "\n").dropFirst() {
                let fields = line.split(whereSeparator: \.isWhitespace)
                guard fields.count > 9, fields[3] == "0A",
                      let port = fields[1].split(separator: ":").last,
                      port == "4830" || port == "480B" else { continue } // 18480 / 18443
                result.insert("socket:[\(fields[9])]")
            }
        }
        return result
    }

    private static func processStartTime(_ pid: Int32) -> String? {
        guard let stat = try? String(contentsOfFile: "/proc/\(pid)/stat", encoding: .utf8),
              let end = stat.lastIndex(of: ")") else { return nil }
        let fields = stat[stat.index(after: end)...].split(whereSeparator: \.isWhitespace)
        return fields.count > 19 ? String(fields[19]) : nil // field 22; fields begin at 3
    }
    #endif
}
