import CAdwaita
import Foundation
import XCTest
import MoldSignKit
@testable import MoldSignGnome

/// Demo-only copy (demo data banner, simulated results, fictional-card notices) belongs to the isolated preview
/// window. The real app's signing, results, documents, preferences, card dialogs and Background portal status
/// never show it, in any language.
final class DemoLeakTests: GnomeTestCase {
    private static let demoOnly: [L10n.Key] = [
        .ui_demo_data_no_real_card_pin_or_signatures, .ui_demo_data_cryptographic_verification_was_not_performed,
        .ui_demo_result_document_is_unsigned, .ui_demo_request_cancelled, .ui_demo_mode_signing_is_disabled,
        .ui_demo_data_could_not_be_prepared,
    ]

    private func demoPhrases() -> [String] {
        var phrases: [String] = []
        let current = L10n.language
        for language in ["ro", "en", "ru"] {
            L10n.language = language
            phrases += Self.demoOnly.map { L10n.text($0) }
        }
        L10n.language = current
        return phrases + ["DEMO", "fictional", "fictiv", "вымышлен"]
    }

    private func leaks(in texts: [String]) -> [String] {
        let phrases = demoPhrases()
        return texts.filter { text in phrases.contains { text.contains($0) } }
    }

    override func tearDown() { L10n.language = nil }

    func testRealAppScreensNeverShowDemoCopy() throws {
        try GTKTest.require()
        let folder = TestEnvironment.directory()
        for language in ["ro", "en", "ru"] {
            L10n.language = language
            let document = try Fixtures.pdf(in: folder, name: "contract-\(language).pdf")
            let signed = ActivityItem(kind: .signed, title: document.lastPathComponent, subtitle: "PAdES-T", ok: true, filePath: document.path)
            let bridge = ActivityItem(kind: .bridge, title: "msign.gov.md", subtitle: "XAdES-T", ok: true)
            let h = ControllerHarness(cards: 2, activity: [signed, bridge], documents: [signed])
            defer { h.controller.shutdown() }
            h.verifier.reports[document.lastPathComponent] = [Fixtures.report()]
            let main = MainWindow(app: GTKTest.application, controller: h.controller)
            main.present()
            defer { GTKTest.dismissDialogs(main.window); GTKTest.close(main.window) }
            h.controller.addFiles([document.path])
            h.controller.verify(path: document.path)
            GTKTest.pump(until: { h.controller.verifyReports != nil })
            var texts: [String] = []
            for page in ["sign", "verify", "activity"] {
                main.show(page: page)
                GTKTest.pump(0.1)
                texts += GTKTest.texts(main.window.widget)
            }
            let banner = GTKTest.widgets(main.window.widget, ofType: adw_banner_get_type()).first!
            XCTAssertEqual(adw_banner_get_revealed(banner.opaque), 0, "No banner in the real app")
            for page in ["settings", "card"] {
                main.show(page: page)
                GTKTest.pump(0.2)
                if let dialog = GTKTest.visibleDialog(main.window) { texts += GTKTest.texts(dialog.cast()) }
                GTKTest.dismissDialogs(main.window)
            }
            presentPINDialog(parent: main.window.widget, request: PinRequest(holder: "POPESCU ION", purpose: "contract.pdf", attemptsLeft: nil,
                                                                              canRemember: true, vaultProblem: nil)) { _ in }
            GTKTest.pump(0.1)
            texts += GTKTest.texts(GTKTest.visibleDialog(main.window)!.cast())
            XCTAssertEqual(leaks(in: texts), [], "Demo copy leaked into the real app (\(language))")
            XCTAssertTrue(texts.contains { $0.contains(L10n.text(.linux_demo_mode_description)) }, "The option itself is described neutrally")
            XCTAssertEqual(leaks(in: [h.controller.backgroundStatusText ?? "", h.controller.statusLight.text]), [])
            XCTAssertNotNil(h.controller.backgroundStatusText)
        }
    }

    func testThePreviewWindowIsClearlyLabelledAndKeepsTheRealStatus() throws {
        try GTKTest.require()
        L10n.language = "en"
        let controller = AppController(vault: FakeVault(), monitor: FakeMonitor(), settingsStore: TestSettings(), bridge: FakeBridge(),
                                       demo: DemoMode("2"))
        controller.start()
        defer { controller.shutdown() }
        let main = MainWindow(app: GTKTest.application, controller: controller)
        main.present()
        defer { GTKTest.dismissDialogs(main.window); GTKTest.close(main.window) }
        GTKTest.pump(until: { controller.cards.count == 2 && controller.certificate != nil }, timeout: 3)
        GTKTest.pump()
        let banner = GTKTest.widgets(main.window.widget, ofType: adw_banner_get_type()).first!
        XCTAssertEqual(adw_banner_get_revealed(banner.opaque), 1)
        XCTAssertEqual(String(cString: adw_banner_get_title(banner.opaque)), L10n.text(.ui_demo_data_no_real_card_pin_or_signatures))
        main.show(page: "settings")
        GTKTest.pump(0.2)
        let preferences = try XCTUnwrap(GTKTest.visibleDialog(main.window)).cast(GtkWidget.self)
        XCTAssertTrue(GTKTest.contains(preferences, text: L10n.text(.ui_demo_data_no_real_card_pin_or_signatures)))
        XCTAssertNil(controller.backgroundStatusText, "A preview never publishes fictional holders to GNOME's Background Apps")
    }
}
