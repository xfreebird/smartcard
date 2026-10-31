struct ReaderSlot: Equatable {
    enum State: Equatable { case empty, card, mute }
    let name: String
    var state: State
    /// Bumped on every card insertion in this reader.
    var generation: Int
}

struct ReaderSnapshot: Equatable {
    var slots: [ReaderSlot] = []
    /// False when PC/SC itself doesn't answer (Linux: `pcscd` not running), as opposed to "no reader".
    var serviceAvailable = true

    var readers: [String] { slots.map(\.name) }
    var muteCard: Bool { slots.contains { $0.state == .mute } }
}
