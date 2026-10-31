import Foundation
import ServiceManagement

/// The non-store watcher is its own launchd process: quitting the UI does not stop insertion detection.
@MainActor
protocol ReaderActivationManaging {
    var enabled: Bool { get }
    var requiresApproval: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

@MainActor
struct ReaderActivationService: ReaderActivationManaging {
    #if !APP_STORE
    private var service: SMAppService { .agent(plistName: "md.esemnbun.reader-watcher.plist") }
    var enabled: Bool { service.status == .enabled || service.status == .requiresApproval }
    var requiresApproval: Bool { service.status == .requiresApproval }
    func setEnabled(_ enabled: Bool) throws {
        if enabled { try service.register() } else { try service.unregister() }
    }
    #else
    var enabled: Bool { false }
    var requiresApproval: Bool { false }
    func setEnabled(_ enabled: Bool) throws {}
    #endif
}
