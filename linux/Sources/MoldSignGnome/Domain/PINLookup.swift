enum PINLookup {
    case found(String)
    case missing
    /// No Secret Service on the bus (headless, macOS dev builds, sandbox without the talk-name).
    case unavailable(String)
}
