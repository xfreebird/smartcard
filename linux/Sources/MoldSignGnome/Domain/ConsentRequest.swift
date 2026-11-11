import Foundation
import MoldSignKit

/// A browser asking for a signature (SEC-02).
struct ConsentRequest {
    let request: BridgeRequest
    let holder: String
    let hasStoredPIN: Bool

    var originHost: String {
        request.origin.flatMap { URL(string: $0)?.host } ?? L10n.text(.ui_a_local_application)
    }
}
