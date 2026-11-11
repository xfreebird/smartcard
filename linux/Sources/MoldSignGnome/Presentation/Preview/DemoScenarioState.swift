#if MOLDSIGN_DEMO
import Foundation

/// Fictional scenario data assembled separately from GTK callbacks and application state.
struct DemoScenarioState {
    var signItems: [SignItem] = []
    var isSigning = false
    var currentStep: UIStep?
    var lastAttemptsLeft: Int?
    var lastError: (message: String, recovery: String)?
    var lastSigned: [URL] = []
    var verifyFile: URL?
    var verifyReports: [SignatureReport]?
    var activity: [ActivityItem] = []
    var signedDocuments: [ActivityItem] = []

    init(scenario: DemoScenario, files: DemoDocuments) {
        let now = Date()
        switch scenario {
        case .documents, .signing, .pin, .pinError, .signingError:
            signItems = [SignItem(url: files.input), SignItem(url: files.text)]
        default: break
        }
        switch scenario {
        case .signing:
            isSigning = true
            currentStep = .timestamp
        case .pin, .pinError:
            lastAttemptsLeft = scenario == .pinError ? 2 : nil
        case .signingError:
            signItems[0].error = L10n.text(.ui_the_card_does_not_respond)
            lastError = (L10n.text(.ui_the_card_does_not_respond), L10n.text(.ui_remove_and_re_insert_the_card))
        case .success:
            lastSigned = [files.result]
        case .verifyChecking:
            verifyFile = files.input
            verifyReports = nil
        case .verifyValid, .verifyInvalid, .verifyUnknown:
            verifyFile = files.result
            verifyReports = [scenario.report()]
        case .verifyUnsigned:
            verifyFile = files.input
            verifyReports = []
        case .activity:
            activity = [
                ActivityItem(kind: .signed, title: files.result.lastPathComponent,
                    subtitle: L10n.text(.ui_demo_result_document_is_unsigned), ok: true, date: now.addingTimeInterval(-120), filePath: files.result.path),
                ActivityItem(kind: .verified, title: files.input.lastPathComponent,
                    subtitle: L10n.text(.ui_valid_signature), ok: true, date: now.addingTimeInterval(-300), filePath: files.input.path),
                ActivityItem(kind: .bridge, title: "msign.gov.md · DEMO",
                    subtitle: L10n.text(.ui_demo_request_cancelled), ok: false, date: now.addingTimeInterval(-600)),
            ]
            signedDocuments = activity.filter(\.isSignedDocument)
        case .settings, .documents: break
        }
    }
}
#endif
