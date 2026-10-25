import SwiftUI
import AppKit

/// Floating panel for the PIN and consent sheets.
///
/// A menu-bar agent has no window to attach sheets to, and bridge requests arrive while the browser
/// is frontmost, so the panel activates the app and floats above everything (MAC-04, MAC-07).
@MainActor
final class AuthPanelController {
    private var panel: NSPanel?
    private weak var model: AppModel?

    func attach(_ model: AppModel) {
        guard self.model == nil else { return }
        self.model = model
        model.presentAuthUI = { [weak self] in self?.show() }
    }

    private func show() {
        guard let model else { return }
        let root = AuthPanelContent(onFinish: { [weak self] in self?.hide() }).environment(model)
        let panel = self.panel ?? makePanel()
        panel.contentViewController = NSHostingController(rootView: root)
        panel.center()
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    private func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 320),
                            styleMask: [.titled, .closable, .fullSizeContentView],
                            backing: .buffered, defer: false)
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        return panel
    }
}

private struct AuthPanelContent: View {
    @Environment(AppModel.self) private var model
    let onFinish: () -> Void

    var body: some View {
        Group {
            if let consent = model.consentRequest {
                ConsentView(consent: consent) { approved, trust in
                    model.answerConsent(approved: approved, trust: trust)
                    if !approved { onFinish() }
                }
            } else if let request = model.pinRequest {
                PinEntryView(request: request,
                             onSubmit: { pin, remember in model.submitPIN(pin, remember: remember); onFinish() },
                             onCancel: { model.cancelPIN(); onFinish() })
            } else {
                Color.clear.frame(width: 1, height: 1).onAppear(perform: onFinish)
            }
        }
        .fixedSize()
    }
}
