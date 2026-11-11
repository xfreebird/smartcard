#if DEBUG
import Foundation
import MoldSignKit

/// Builds presentation fixtures without owning a view, transport, listener or credential operation.
@MainActor
struct DemoScenarioState {
    var cards: [CardSlot]
    var readers: [String]
    var status: ReaderStatus
    var signItems: [SignItem]
    var recomputeReaderStatus = false
    var currentStep: SigningService.Step?
    var lastSigned: [URL]?
    var verification: (url: URL, reports: [Validator.Report], loading: Bool)?
    var activity: [ActivityItem]?
    var consent: ConsentRequest?
    var pin: PinRequest?

    init(scenario: String, screenshot: Bool, cards: [CardSlot], readers: [String], status: ReaderStatus,
         items: [SignItem], holder: String?, directory: URL) {
        self.cards = cards
        self.readers = readers
        self.status = status
        self.signItems = items
        if screenshot {
            if scenario.hasPrefix("verify-") && scenario != "verify-empty" {
                let url = URL(fileURLWithPath: scenario.contains("incomplete") ? "/capture/Contract.xml" : "/capture/Contract-semnat.pdf")
                verification = (url, ScreenshotFixtures.reports(scenario), scenario == "verify-loading")
            }
            if scenario.hasPrefix("documents-") && scenario != "documents-empty" || scenario == "history-populated" {
                activity = ScreenshotFixtures.activityRecords(scenario, in: directory)
            }
        }
        switch scenario {
        case "no-reader": self.cards = []; self.readers = []; self.status = .noReader
        case "empty-reader": self.cards = []; self.readers = ["USB demo reader"]; self.status = .empty(reader: self.readers[0])
        case "unavailable": self.cards = []; self.readers = []; self.status = .unavailable
        case "reading", "error":
            if !self.cards.isEmpty {
                self.cards[0].certificate = nil
                if scenario == "error" { self.cards[0].problemText = .localized(.ui_the_card_does_not_respond) }
                recomputeReaderStatus = true
            }
        case "sign-failure":
            if !signItems.isEmpty { signItems[0].signingError = L10n.text(.ui_failed_value_value, L10n.text(.format_pdf), "No /Root in trailer") }
        case "signing": currentStep = .timestamping
        case "success": lastSigned = items.map(\.url); signItems = []
        case "consent", "consent-batch":
            if screenshot {
                let names = scenario == "consent-batch" ? (1...8).map { "Document-\($0).pdf" } : ["Contract.pdf"]
                consent = ConsentRequest(request: BridgeRequest(origin: "https://msign.gov.md", operation: .signPDF,
                    documentName: names.first, documentNames: names, contentBytes: 65536, format: "PAdES-T", pinIncluded: false),
                    holder: "Popescu Ion", hasStoredPIN: false)
            }
        case "pin", "pin-warning", "pin-empty":
            pin = PinRequest(holder: holder ?? "Popescu Ion", attemptsLeft: scenario == "pin-warning" ? 1 : 3,
                canRemember: true, documentNames: scenario == "pin-empty" ? [] : items.map { $0.url.lastPathComponent })
        default: break
        }
    }
}
#endif
