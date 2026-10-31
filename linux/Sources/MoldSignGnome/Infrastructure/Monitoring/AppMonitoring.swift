import CSentryRuntime
import Foundation

/// Sentry is confined to sanitized operational diagnostics. No signing data is accepted.
enum AppMonitoring {
    private static let coordinator = MonitoringCoordinator(store: JSONMonitoringConsentStore(),
        start: startSDK, revoke: revoke)
    static var consent: MonitoringConsent? { coordinator.consent }
    static func start() {
        // Remove pre-consent SDK data left by older builds without ever initializing the SDK.
        if coordinator.consent == nil { purgeCache() }
        coordinator.restore()
    }
    @discardableResult static func choose(crashes: Bool, metrics: Bool) -> Bool {
        do { try coordinator.choose(MonitoringConsent(crashes: crashes, metrics: metrics)); return true }
        catch { return false }
    }
    private static var cache: URL {
        let env = ProcessInfo.processInfo.environment
        let root = env["XDG_CACHE_HOME"].map { URL(fileURLWithPath: $0) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".cache")
        return root.appendingPathComponent("esemnbun/sentry")
    }
    private static func purgeCache() { try? FileManager.default.removeItem(at: cache) }
    private static func revoke() { ms_sentry_close(); purgeCache() }
    private static func startSDK(_ consent: MonitoringConsent) {
        let env = ProcessInfo.processInfo.environment
        guard env["MSIGN_SENTRY_DISABLED"] != "1" else { return }
        let verification: Bool
        #if MOLDSIGN_DEMO
        verification = env["MSIGN_SENTRY_VERIFY"] == "1" && env["MSIGN_DEMO_CARDS"] != nil
        #else
        verification = false
        #endif
        // Screenshot/mock runs do not produce telemetry unless explicitly verifying Sentry.
        guard env["MSIGN_DEMO_CARDS"] == nil || verification else { return }
        #if os(Linux)
        let executable = (try? FileManager.default.destinationOfSymbolicLink(atPath: "/proc/self/exe")) ?? CommandLine.arguments[0]
        #else
        let executable = CommandLine.arguments[0]
        #endif
        let prefix = URL(fileURLWithPath: executable).deletingLastPathComponent().deletingLastPathComponent()
        let library = env["MSIGN_SENTRY_LIBRARY"] ?? prefix.appendingPathComponent("lib/esemnbun/libsentry.so").path
        try? FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
        #if DEBUG
        let environment = "development"
        #else
        let environment = "production"
        #endif
        let ready = ms_sentry_start(library,
            "https://e9d0c95c4eaf3582bb33b59305a49a7b@o4512349416980480.ingest.de.sentry.io/4512349473931344",
            "md.esemnbun.linux@0.2.0", verification ? "verification" : environment, cache.path, verification ? 1 : 0, consent.crashes ? 1 : 0, consent.metrics ? 1 : 0)
        #if MOLDSIGN_DEMO
        if ready != 0 && consent.crashes && env["MSIGN_SENTRY_CRASH_TEST"] == "1" && env["MSIGN_DEMO_CARDS"] != nil {
            abort() // Explicit mock-only crash fixture, still requires persisted crash consent.
        }
        #endif
        if verification {
            let result = ready != 0 ? ms_sentry_verify() : -1
            fputs("Sentry verification transport result: \(result)\n", stderr)
        }
    }
    static func operationFinished(failed: Bool) {
        if consent?.metrics == true { ms_sentry_metric_operation(failed ? 1 : 0) }
        if failed && consent?.crashes == true { ms_sentry_failure() }
    }
    static func close() { ms_sentry_finish() }
}
