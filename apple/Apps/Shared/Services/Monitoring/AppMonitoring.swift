import Foundation
#if os(macOS)
import Sentry
#endif

/// App diagnostics have a deliberately narrow boundary: no signing inputs, card objects or NSError
/// descriptions enter telemetry. Automatic request/file/UI recording is disabled for this signer.
@MainActor
enum AppMonitoring {
    #if os(macOS)
    private static var activeConsent: MonitoringConsent?
    private static var session: URLSession?
    private static var gate: MonitoringDeliveryGate?
    private static let cacheKey = "monitoringCacheEpoch.v1"
    private static var cacheRoot: URL {
        let parent = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        #if DEBUG
        if ProcessInfo.processInfo.environment["MSIGN_DEMO_PREFERENCES_SUITE"]?.hasPrefix("md.esemnbun.qa.") == true {
            return parent.appendingPathComponent("md.esemnbun.qa.monitoring")
        }
        #endif
        return parent.appendingPathComponent("md.esemnbun.mac.monitoring")
    }
    private static let dsn = "https://8dae0be97332fe0142a5310ddaa068db@o4512349416980480.ingest.de.sentry.io/4512349440966736"
    nonisolated private static let verificationMessage = "eSemnBun Apple monitoring verification"
    #endif

    static func start() {
        #if os(macOS)
        guard !AppPreferencesStore.defaults.bool(forKey: "demoModeEnabled") else { stopAndPurge(); return }
        let consent = MonitoringConsent.load(from: AppPreferencesStore.defaults)
        guard activeConsent != consent else { return }
        if activeConsent != nil || !consent.canStart { stopAndPurge() }
        let env = ProcessInfo.processInfo.environment
        guard consent.canStart, env["MSIGN_SENTRY_DISABLED"] != "1" else { return }
        #if DEBUG
        let verification = env["MSIGN_SENTRY_VERIFY"] == "1" && env["MSIGN_DEMO_CARDS"] != nil
        // UI capture and mock suites should not generate production diagnostic traffic.
        if env["MSIGN_DEMO_CARDS"] != nil && !verification && env["MSIGN_SENTRY_CONSENT_QA"] != "1" { return }
        let environment = verification ? "verification" : "development"
        #else
        let environment = "production"
        #endif
        let gate = MonitoringDeliveryGate(consent)
        self.gate = gate
        let session = URLSession(configuration: .ephemeral)
        self.session = session
        activeConsent = consent
        let defaults = AppPreferencesStore.defaults
        let previousCache = defaults.dictionary(forKey: cacheKey)
        let sameChoice = previousCache?["crashes"] as? Bool == consent.crashes && previousCache?["metrics"] as? Bool == consent.metrics
        let epoch: String
        if sameChoice, let existing = previousCache?["id"] as? String, UUID(uuidString: existing) != nil {
            epoch = existing
        } else {
            try? FileManager.default.removeItem(at: cacheRoot)
            epoch = UUID().uuidString
        }
        defaults.set(["id": epoch, "crashes": consent.crashes, "metrics": consent.metrics], forKey: cacheKey)
        let cache = cacheRoot.appendingPathComponent(epoch)
        let bundle = Bundle.main
        let identifier = bundle.bundleIdentifier ?? "md.esemnbun.apple"
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        SentrySDK.start(configureOptions: { options in
            options.dsn = dsn
            options.urlSession = session
            options.cacheDirectoryPath = cache.path
            options.shutdownTimeInterval = 0
            options.enableCrashHandler = consent.crashes
            options.enableAppHangTracking = false
            options.enableWatchdogTerminationTracking = consent.crashes
            options.sendClientReports = false
            options.environment = environment
            options.releaseName = "\(identifier)@\(version)+\(build)"
            options.dist = build
            options.sendDefaultPii = false
            options.debug = false
            options.attachStacktrace = true
            options.enableMemoryIntrospection = false
            options.enableAutoSessionTracking = false
            options.enableAutoBreadcrumbTracking = false
            options.enableNetworkBreadcrumbs = false
            options.enableNetworkTracking = false
            options.enableCaptureFailedRequests = false
            options.enableFileIOTracing = false
            options.enableDataSwizzling = false
            options.enableFileManagerSwizzling = false
            options.enableCoreDataTracing = false
            options.enableAutoPerformanceTracing = false
            options.enableSwizzling = false
            options.enableLogs = false
            options.enableMetrics = consent.metrics
            options.beforeSendMetric = { metric in
                guard gate.allows(transaction: true), ["app.launch", "document.sign"].contains(metric.name) else { return nil }
                var safe = metric
                safe.attributes = ["sentry.release": .string("\(identifier)@\(version)+\(build)"),
                                   "sentry.environment": .string(environment), "app.platform": .string("macos")]
                return safe
            }
            options.enableMetricKit = false
            options.enableMetricKitRawPayload = false
            options.tracePropagationTargets = []
            options.maxBreadcrumbs = 0
            options.tracesSampleRate = consent.metrics ? (environment == "production" ? 0.1 : 1) : 0
            options.beforeBreadcrumb = { _ in nil }
            // Sentry9 applies beforeSend to errors and transactions. Only fixed operation names survive.
            options.beforeSend = { event in
                guard gate.allows(transaction: event is Transaction) else { return nil }
                if let transaction = event as? Transaction {
                    guard ["app.start", "document.sign"].contains(transaction.transaction ?? "") else { return nil }
                    transaction.spans = []
                }
                return sanitize(event)
            }
        })
        if consent.metrics {
            SentrySDK.metrics.count("app.launch")
            let startup = SentrySDK.startTransaction(name: "app.start", operation: "app.lifecycle")
            startup.finish()
        }
        #if DEBUG
        if verification && consent.crashes {
            // An opt-in, handled exception through this running application's real SDK initialization.
            do { throw VerificationError.requested }
            catch {
                SentrySDK.capture(error: error)
                // The fixture contains no documents, PIN or reader operations. Flush off the UI thread.
                Task.detached {
                    SentrySDK.flush(timeout: 10)
                    print("SENTRY_APPLE_VERIFICATION_FLUSHED")
                }
            }
        }
        #endif
        #endif
    }

    static func demoModeChanged() {
        #if os(macOS)
        if AppPreferencesStore.defaults.bool(forKey: "demoModeEnabled") { stopAndPurge() }
        else { start() }
        #endif
    }

    #if os(macOS)
    private static func stopAndPurge() {
        let wasActive = activeConsent != nil
        gate?.revoke()
        // Cancel the dedicated transport BEFORE close: Cocoa's close performs an internal zero-time
        // flush, which must never deliver queued events after consent is revoked.
        session?.invalidateAndCancel()
        session = nil
        gate = nil
        activeConsent = nil
        if wasActive { SentrySDK.close() }
        try? FileManager.default.removeItem(at: cacheRoot)
        AppPreferencesStore.defaults.removeObject(forKey: cacheKey)
    }
    #endif

    /// One fixed-name operation; document identifiers and function arguments never become span data.
    static func signDocument<T>(_ operation: () async throws -> T) async rethrows -> T {
        #if os(macOS)
        guard activeConsent?.metrics == true else { return try await operation() }
        SentrySDK.metrics.count("document.sign")
        let transaction = SentrySDK.startTransaction(name: "document.sign", operation: "document.sign")
        defer { transaction.finish() }
        #endif
        return try await operation()
    }

    /// A finite diagnostic code rather than an arbitrary error description or caller-supplied string.
    enum Failure: String { case signingFailed, verificationFailed, readerFailed, bridgeFailed }

    static func capture(_ failure: Failure) {
        #if os(macOS)
        guard activeConsent?.crashes == true else { return }
        let event = Event(level: .error)
        event.message = SentryMessage(formatted: "eSemnBun diagnostic: \(failure.rawValue)")
        event.tags = ["diagnostic": failure.rawValue]
        SentrySDK.capture(event: event)
        #endif
    }

    #if os(macOS)
    nonisolated private static func sanitize(_ event: Event) -> Event {
        let isVerification = event.exceptions?.contains { $0.type?.contains("VerificationError") == true } == true
        let diagnostic = event.tags?["diagnostic"]
        let allowed = ["signingFailed", "verificationFailed", "readerFailed", "bridgeFailed"]
        let safeMessage = diagnostic.flatMap { allowed.contains($0) ? "eSemnBun diagnostic: \($0)" : nil }
        event.message = SentryMessage(formatted: isVerification ? verificationMessage : safeMessage ?? "eSemnBun application diagnostic")
        event.user = nil
        event.request = nil
        event.extra = nil
        event.breadcrumbs = nil
        event.serverName = nil
        event.logger = nil
        event.fingerprint = nil
        event.tags = diagnostic.map { allowed.contains($0) ? ["diagnostic": $0] : [:] } ?? [:]
        #if os(macOS)
        event.tags?["app.platform"] = "macos"
        #else
        event.tags?["app.platform"] = "ios"
        #endif
        let contextKeys: [String: Set<String>] = [
            "app": ["app_identifier", "app_version", "app_build", "app_name"],
            "os": ["name", "version", "build", "kernel_version", "rooted"],
            "device": ["arch", "family", "model", "model_id", "simulator", "memory_size", "processor_count"],
            "runtime": ["name", "version"],
            "trace": ["trace_id", "span_id", "parent_span_id", "op", "status", "origin"]
        ]
        if let contexts = event.context?.filter({ contextKeys[$0.key] != nil }) {
            event.context = contexts.mapValues { _ in [:] }
            for (name, fields) in contexts {
                event.context?[name] = fields.filter { contextKeys[name]?.contains($0.key) == true }
            }
        }
        for exception in event.exceptions ?? [] {
            exception.value = isVerification ? verificationMessage : "Application failure; details withheld"
            exception.type = isVerification ? "eSemnBunMonitoringVerificationError" : "eSemnBunApplicationError"
            exception.module = nil
            exception.mechanism?.data = nil
            exception.mechanism?.desc = nil
            exception.mechanism?.helpLink = nil
            exception.mechanism?.meta = nil
            scrub(exception.stacktrace)
        }
        for thread in event.threads ?? [] {
            thread.name = nil
            scrub(thread.stacktrace)
        }
        for image in event.debugMeta ?? [] {
            if let path = image.codeFile { image.codeFile = URL(fileURLWithPath: path).lastPathComponent }
        }
        scrub(event.stacktrace)
        return event
    }

    nonisolated private static func scrub(_ stacktrace: SentryStacktrace?) {
        stacktrace?.registers = [:]
        for frame in stacktrace?.frames ?? [] {
            frame.vars = nil
            frame.contextLine = nil
            frame.preContext = nil
            frame.postContext = nil
            if let path = frame.fileName { frame.fileName = URL(fileURLWithPath: path).lastPathComponent }
            if let path = frame.package { frame.package = URL(fileURLWithPath: path).lastPathComponent }
        }
    }

    #if DEBUG
    private enum VerificationError: Error { case requested }
    #endif
    #endif
}

#if os(macOS)
/// Captured per SDK generation so old asynchronous callbacks cannot inherit a later opt-in.
private final class MonitoringDeliveryGate: @unchecked Sendable {
    private let lock = NSLock()
    private var consent: MonitoringConsent
    init(_ consent: MonitoringConsent) { self.consent = consent }
    func revoke() { lock.lock(); defer { lock.unlock() }; consent = MonitoringConsent() }
    func allows(transaction: Bool) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return consent.permits(transaction ? .metrics : .crashes)
    }
}
#endif
