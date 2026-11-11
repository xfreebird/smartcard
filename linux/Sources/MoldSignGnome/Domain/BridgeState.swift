import Foundation
import MoldSignKit

enum BridgeState: Equatable {
    case stopped
    case running
    case identityRequired
    case portBusy   // the vendor Java server holds 18480/18443 (MAC-08)
    case failed(String)

    var description: String {
        switch self {
        case .stopped: return L10n.text(.ui_off)
        case .running: return localized(.linux_bridge_active, String(MoldSignServer.defaultHTTPPort), String(MoldSignServer.defaultHTTPSPort))
        case .identityRequired: return L10n.text(.ui_the_moldsign_https_identity_is_missing_or_cannot_be_read_import_the_localhost_p12_file_f)
        case .portBusy: return localized(.linux_bridge_ports_busy, String(MoldSignServer.defaultHTTPPort), String(MoldSignServer.defaultHTTPSPort))
        case .failed(let message): return localized(.linux_bridge_failed, message)
        }
    }
}
