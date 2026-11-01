// swift-tools-version: 6.0
import PackageDescription

// Hardware-free tests for the app's authorization/session policy. UI apps remain Xcode targets.
let package = Package(
    name: "AppleAppPolicies",
    platforms: [.macOS(.v15)],
    targets: [
        .target(name: "AppBatch", path: "Apps/Shared/Services",
                exclude: ["PinVault.swift", "ReaderMonitor.swift", "MockAppServices.swift", "Activity", "Documents", "L10n.swift", "AppPreferencesStore.swift", "Demo"],
                sources: ["SigningBatchRunner.swift", "ReaderSelectionPolicy.swift"]),
        .target(name: "DemoModePolicy", path: "Apps/Shared/Services/Demo",
                exclude: ["DemoAppServices.swift"], sources: ["DemoHardwareGate.swift", "DemoDocumentFiles.swift"]),
        .testTarget(name: "DemoModePolicyTests", dependencies: ["DemoModePolicy"], path: "Tests/DemoModePolicyTests"),
        .testTarget(name: "AppBatchTests", dependencies: ["AppBatch"], path: "Tests/AppBatchTests"),
        .target(name: "ReaderInsertionPolicy", path: "Helpers/ReaderWatcher",
                exclude: ["main.swift", "md.esemnbun.reader-watcher.plist", "README.md", "ReaderWatcher.entitlements"], sources: ["InsertionPolicy.swift"]),
        .testTarget(name: "ReaderInsertionPolicyTests", dependencies: ["ReaderInsertionPolicy"], path: "Tests/ReaderInsertionPolicyTests")
    ],
    swiftLanguageModes: [.v5]
)
