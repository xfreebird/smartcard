/// Compile-time product capabilities. The App Store build contains only sandbox-compatible workflows.
enum AppDistribution {
    #if os(macOS) && APP_STORE
    static let browserBridge = false
    static let writesBesideInput = false
    #else
    static let browserBridge = true
    #if os(macOS)
    static let writesBesideInput = true
    #else
    static let writesBesideInput = false
    #endif
    #endif
}
