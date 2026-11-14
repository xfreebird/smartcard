// swift-tools-version: 6.0
import PackageDescription

// Hardware-free tests for the app's authorization/session policy. UI apps remain Xcode targets.
let package = Package(
    name: "AppleAppPolicies",
    platforms: [.macOS(.v15)],
    dependencies: [.package(path: "../swift/MoldSignKit")],
    targets: [
        // Compiles reusable UI without access to the signing core or application models.
        .target(name: "DesignSystem", path: "Apps/Shared/DesignSystem"),
        .target(name: "VerificationPolicies", dependencies: [.product(name: "MoldSignKit", package: "MoldSignKit")],
                path: "Apps/Shared/Services/Documents",
                exclude: ["CoreCertificateReader.swift", "CoreDocumentSigner.swift", "DocumentWorkflows.swift"],
                sources: ["DocumentVerifying.swift", "DocumentVerificationModel.swift", "CoreDocumentVerifier.swift"]),
        .testTarget(name: "VerificationPoliciesTests", dependencies: ["VerificationPolicies"], path: "Tests/VerificationPoliciesTests"),
        .target(name: "AppBatch", path: "Apps/Shared/Services",
                exclude: ["SelectedReader.swift", "BridgeDecisionBox.swift", "StampDecisionBox.swift", "PinVault.swift", "ReaderMonitor.swift", "MockReaderMonitor.swift", "MemoryPinVault.swift", "Activity", "Documents", "L10n.swift", "AppPreferencesStore.swift", "BrowserLocale.swift", "BrowserLocaleScript.swift", "Demo"],
                sources: ["CancellableRequestScope.swift", "DecisionChannel.swift", "DroppedDocumentLoader.swift", "SigningBatchRunner.swift", "ReaderSelectionPolicy.swift", "UpdateManifest.swift", "BrowserBookmark.swift", "ProcessShutdown.swift"]),
        .target(name: "DemoModePolicy", path: "Apps/Shared/Services/Demo",
                exclude: ["ProtectionPreview.swift", "ScenarioDocumentSigner.swift", "DemoScenarioState.swift", "GatedCardTransport.swift", "DemoDocumentSigner.swift", "DemoDocumentVerifier.swift", "DemoServiceProviding.swift", "DemoServices.swift", "ScreenshotFixtures.swift"], sources: ["DemoHardwareGate.swift", "DemoDocumentProviding.swift", "DemoDocumentFiles.swift"]),
        .testTarget(name: "DemoModePolicyTests", dependencies: ["DemoModePolicy"], path: "Tests/DemoModePolicyTests"),
        .testTarget(name: "AppBatchTests", dependencies: ["AppBatch"], path: "Tests/AppBatchTests"),
        .target(name: "DocumentLibrary", path: "Apps/Shared/Services/Activity"),
        .testTarget(name: "DocumentLibraryTests", dependencies: ["DocumentLibrary"], path: "Tests/DocumentLibraryTests"),
        .target(name: "ReaderInsertionPolicy", path: "Helpers/ReaderWatcher",
                exclude: ["main.swift", "md.esemnbun.reader-watcher.plist", "README.md", "ReaderWatcher.entitlements"], sources: ["InsertionPolicy.swift"]),
        .testTarget(name: "ReaderInsertionPolicyTests", dependencies: ["ReaderInsertionPolicy"], path: "Tests/ReaderInsertionPolicyTests")
    ],
    swiftLanguageModes: [.v5]
)
