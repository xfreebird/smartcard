import AppKit
import CryptoTokenKit
import Darwin

// No PC/SC connection, certificate, APDU, signing service or credential access: observe slot state only.
// launchd's BundleProgram may supply a relative argv[0]; resolve the actual process
// executable rather than interpreting that argument relative to launchd's working directory.
var executablePath = [CChar](repeating: 0, count: 4096)
guard proc_pidpath(getpid(), &executablePath, UInt32(executablePath.count)) > 0 else { exit(2) }
let executable = URL(filePath: String(cString: executablePath)).standardizedFileURL
let app = executable.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
guard app.pathExtension == "app" else { exit(2) }
#if DEBUG
let mockPath: String? = CommandLine.arguments.firstIndex(of: "--mock-snapshot").flatMap { index in
    CommandLine.arguments.indices.contains(index + 1) ? CommandLine.arguments[index + 1] : nil
}
#else
let mockPath: String? = nil
#endif
#if APP_STORE
guard let suite = Bundle(url: app)?.object(forInfoDictionaryKey: "ReaderWatcherPreferencesSuite") as? String,
      let preferences = UserDefaults(suiteName: suite) else { exit(2) }
#else
let preferenceDomain: String = {
    #if DEBUG
    if let suite = ProcessInfo.processInfo.environment["MSIGN_DEMO_PREFERENCES_SUITE"], suite.hasPrefix("md.esemnbun.qa.") { return suite }
    #endif
    return Bundle(url: app)?.bundleIdentifier ?? "md.esemnbun.mac"
}()
let preferences = UserDefaults(suiteName: preferenceDomain) ?? .standard
#endif
let manager = mockPath == nil ? TKSmartCardSlotManager.default : nil
#if APP_STORE
var monitor = ReaderInsertionMonitor(storeEdition: true)
#else
var monitor = ReaderInsertionMonitor(storeEdition: false)
#endif

func sample() {
    let current: [String: Bool]
    if let mockPath {
        guard let data = try? Data(contentsOf: URL(filePath: mockPath)),
              let snapshot = ReaderInsertionMonitor.mockSnapshot(data) else { return }
        current = snapshot
    } else {
        guard let manager else { return }
        current = Dictionary(uniqueKeysWithValues: manager.slotNames.map { name in
            (name, ReaderInsertionMonitor.cardPresent(manager.slotNamed(name)?.state))
        })
    }
    preferences.synchronize()
    let demo = monitor.demoMode(stored: preferences.object(forKey: "demoModeEnabled"),
                                flag: preferences.bool(forKey: "demoModeEnabled"))
    let deliver = monitor.shouldDeliver(for: current, demoMode: demo, at: Date())
    #if DEBUG
    if mockPath != nil && demo {
        FileHandle.standardOutput.write(Data("MOCK_WATCHER_DEMO_SUPPRESSED\n".utf8))
    }
    #endif
    guard deliver else { return }
    // Only this bundle counts, not another installed edition. The mock fixture starts its own isolated
    // instance unless a QA run explicitly targets the isolated instance it already launched.
    #if DEBUG
    let detectsRunningApp = mockPath == nil || ProcessInfo.processInfo.environment["MSIGN_QA_HELPER_RUNNING_APP"] == "1"
    #else
    let detectsRunningApp = true
    #endif
    let bundlePath = app.resolvingSymlinksInPath().path
    let running = detectsRunningApp && NSRunningApplication.runningApplications(
        withBundleIdentifier: Bundle(url: app)?.bundleIdentifier ?? "").contains { process in
            !process.isTerminated && process.bundleURL?.resolvingSymlinksInPath().path == bundlePath
        }
    let delivery = monitor.delivery(appRunning: running)
    let configuration = NSWorkspace.OpenConfiguration()
    configuration.activates = delivery.activates
    switch delivery.route {
    case .readerURL:
        // Launch Services delivers this URL on both cold launch and reopen.
        NSWorkspace.shared.open([URL(string: "esemnbun-reader://inserted")!],
                                withApplicationAt: app, configuration: configuration) { _, error in
            #if DEBUG
            if mockPath != nil {
                let outcome = error == nil ? "MOCK_WATCHER_DELIVERED activates=\(delivery.activates)" : "MOCK_WATCHER_FAILED"
                FileHandle.standardOutput.write(Data((outcome + "\n").utf8))
            }
            #endif
        }
    case .launchApplication:
        configuration.arguments = ["--show-main-window"]
        #if DEBUG
        if mockPath != nil {
            configuration.createsNewApplicationInstance = true
            configuration.environment = ["MSIGN_DEMO_CARDS": "none", "MSIGN_DEMO_PREVIEW": "0", "MSIGN_DEMO_PREFERENCES_SUITE": "md.esemnbun.qa.helper"]
        }
        #endif
        NSWorkspace.shared.openApplication(at: app, configuration: configuration) { _, error in
            #if DEBUG
            if mockPath != nil {
                FileHandle.standardOutput.write(Data((error == nil ? "MOCK_WATCHER_OPENED\n" : "MOCK_WATCHER_FAILED\n").utf8))
            }
            #endif
        }
    }
}
sample()
let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in sample() }
RunLoop.main.add(timer, forMode: .common)
RunLoop.main.run()
