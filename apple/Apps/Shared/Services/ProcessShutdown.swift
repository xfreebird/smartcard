/// A bounded graceful shutdown: only identities approved before the action can be signalled.
/// A replacement process must be approved by a new user action, even if it reused the same PID.
enum ProcessShutdown {
    static func request<Identity: Equatable>(approved: [Identity], current: () -> [Identity],
                                            signal: (Identity) -> Bool, wait: () -> Void,
                                            maximumPolls: Int = 50) -> Bool {
        for identity in approved {
            guard current().contains(identity) else { continue }
            guard signal(identity) else { return false }
        }
        for attempt in 0..<max(1, maximumPolls) {
            if current().isEmpty { return true }
            if attempt + 1 < maximumPolls { wait() }
        }
        return false
    }
}
