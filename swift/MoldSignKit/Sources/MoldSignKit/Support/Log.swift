import Foundation

/// Core diagnostics sink (F-06).
///
/// The core prints card/SM traces that were essential during reverse engineering. The CLI keeps
/// that output (default sink). Apps must set `MSLog.sink = nil` or route it to a debug-only
/// logger: traces include session keys and SM state (SEC-04).
public enum MSLog {
    public enum Level { case info, debug, trace }

    /// `.trace` goes to stderr (as the old `dbg()` did), everything else to stdout.
    public static var sink: ((Level, String) -> Void)? = { level, message in
        if level == .trace {
            FileHandle.standardError.write(Data((message + "\n").utf8))
        } else {
            print(message)
        }
    }

    static func info(_ message: @autoclosure () -> String) { sink?(.info, message()) }
    static func debug(_ message: @autoclosure () -> String) { sink?(.debug, message()) }
    static func trace(_ message: @autoclosure () -> String) { sink?(.trace, message()) }
}
