import SwiftUI
import AppKit

/// Floating panel for the PIN and consent sheets.
///
/// A menu-bar agent has no window to attach sheets to, and bridge requests arrive while the browser
/// is frontmost, so the panel activates the app and floats above everything (MAC-04, MAC-07).
@MainActor
final class AuthPanelController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    private weak var model: AppModel?

    func attach(_ model: AppModel) {
        guard self.model == nil else { return }
        self.model = model
        model.presentAuthUI = { [weak self] in self?.show() }
    }

    private func show() {
        guard let model else { return }
        let root = AuthPanelContent(onFinish: { [weak self] in self?.hide() }).environment(model).appPreferences()
        let panel = self.panel ?? makePanel()
        let host = NSHostingController(rootView: root)
        panel.contentViewController = host
        panel.setContentSize(host.view.fittingSize)
        Self.centerOnActiveScreen(panel)
        WindowPresentation.bringForward(panel)
        self.panel = panel
    }

    /// True center of the screen the user is working on (the one under the pointer); `NSWindow.center()` sits higher.
    private static func centerOnActiveScreen(_ window: NSWindow) {
        let mouse = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main
        else { return window.center() }
        let area = screen.visibleFrame
        let size = window.frame.size
        window.setFrameOrigin(NSPoint(x: (area.midX - size.width / 2).rounded(), y: (area.midY - size.height / 2).rounded()))
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if model?.bridgeStampRequest != nil { model?.answerBridgeStamp(.cancel); hide(); return false }
        return true
    }

    private func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 320),
                            styleMask: [.titled, .closable, .fullSizeContentView],
                            backing: .buffered, defer: false)
        panel.delegate = self
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
            if let stamp = model.bridgeStampRequest {
                PDFStampEditor(url: stamp.url, initial: .init(), holder: stamp.holder,
                    save: { model.answerBridgeStamp(.proceed($0)); onFinish() },
                    onCancel: { model.answerBridgeStamp(.cancel); onFinish() }, requester: stamp.origin)
            } else if let consent = model.consentRequest {
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
