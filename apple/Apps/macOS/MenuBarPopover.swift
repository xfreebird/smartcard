import SwiftUI

/// Menu-bar popover (docs/10 §0, UX-03): the card selector (the card shows its own status), quick actions,
/// recents, browser bridge, then menu-style rows. No drop target: the popover closes as soon as you start
/// dragging from Finder, so files go to the window or the Dock icon instead.
struct MenuBarPopover: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @State private var hostWindow: NSWindow?

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(L10n.text(.ui_esemnbun)).font(.headline)
                Spacer()
                Button {
                    dismissThen { WindowPresentation.shared.present(.settings) { openSettings() } }
                } label: { Image(systemName: "gearshape") }
                    .buttonStyle(.borderless)
                    .help(L10n.text(.ui_settings))
                    .accessibilityLabel(L10n.text(.ui_settings))
            }

            if model.demoMode { DemoModeBanner() }
            CardSelector(size: .compact)

            if let step = model.currentStep {
                StepProgressView(current: step)
            }
            if let error = model.lastError {
                Label {
                    Text("\(error.message). \(error.recovery)")
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                }
                .font(.caption)
            }

            HStack(spacing: 10) {
                Button { showMain(.sign) } label: { Label(L10n.text(.ui_sign_2), systemImage: "signature").frame(maxWidth: .infinity) }
                Button { showMain(.verify) } label: { Label(L10n.text(.ui_verify_2), systemImage: "checkmark.seal").frame(maxWidth: .infinity) }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            let recents = model.recentDocuments.prefix(3)
            if !recents.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L10n.text(.ui_recent_documents)).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        Spacer()
                        Button(L10n.text(.ui_clear)) { model.clearRecents() }
                            .buttonStyle(.borderless)
                            .font(.caption)
                            .help(L10n.text(.ui_clear_the_recent_documents_list_files_and_activity_history_are_kept))
                    }
                    ForEach(recents) { item in
                        Button {
                            dismissThen { if let url = item.fileURL { NSWorkspace.shared.activateFileViewerSelecting([url]) } }
                        } label: {
                            ActivityRowView(item: item, showsDate: false).font(.subheadline).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help(L10n.text(.ui_show_in_finder))
                    }
                }
            }

            #if !APP_STORE
            Divider()
            HStack(spacing: 8) {
                StatusLightView(light: bridgeLight)
                Text(bridgeText)
                Spacer()
                Toggle(bridgeText, isOn: $model.bridgeEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            #endif
            Divider()
            VStack(spacing: 0) {
                MenuRow(title: L10n.text(.ui_open_esemnbun)) { showMain(.sign) }
                MenuRow(title: L10n.text(.about_app_title)) {
                    dismissThen {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "about")
                    }
                }
                Divider().padding(.vertical, 4)
                MenuRow(title: L10n.text(.ui_quit), shortcut: "⌘Q") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
            .padding(.horizontal, -6)   // hover highlight reaches the content edges, like menu items
        }
        .padding(16)
        .frame(width: 320)
        .background(WindowReader { hostWindow = $0 })
        .onAppear { model.pruneMissingFiles() }
    }

    /// MenuBarExtra has no dismiss API: close its window first so the popover doesn't hang over what opens next.
    private func dismissThen(_ action: @escaping () -> Void) {
        hostWindow?.close()
        DispatchQueue.main.async(execute: action)
    }

    private var bridgeLight: StatusLight {
        switch model.bridgeState {
        case .running: return .ready
        case .stopped: return .idle
        case .portBusy: return .reader
        case .failed: return .error
        }
    }

    private var bridgeText: String {
        switch model.bridgeState {
        case .running: return L10n.text(.ui_browser_connection_on)
        case .stopped: return L10n.text(.ui_browser_connection_off)
        case .portBusy: return L10n.text(.ui_bridge_ports_busy)
        case .failed: return L10n.text(.ui_bridge_connection_error)
        }
    }

    private func showMain(_ section: MainWindowView.Section) {
        AppPreferencesStore.defaults.set(section.rawValue, forKey: "mainSection")
        dismissThen {
            WindowPresentation.shared.present(.main) { openWindow(id: "main") }
        }
    }
}

/// The NSWindow hosting a SwiftUI view.
@MainActor
struct WindowReader: NSViewRepresentable {
    let onWindow: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { onWindow(view.window) }
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async { onWindow(view.window) }
    }
}

/// A full-width, menu-item-like row: highlights on hover, optional shortcut on the trailing side.
private struct MenuRow: View {
    let title: String
    var shortcut: String?
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if let shortcut { Text(shortcut).foregroundStyle(hovered ? Color.white.opacity(0.85) : .secondary) }
            }
            .foregroundStyle(hovered ? Color.white : .primary)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background(hovered ? Color.accentColor : .clear, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }
}

/// The status light as a dot, with an outline when idle so the "nothing" state is still visible.
struct StatusLightView: View {
    let light: StatusLight

    var body: some View {
        Group {
            if let color = light.color {
                Circle().fill(color)
                    .overlay(Circle().strokeBorder(.black.opacity(0.12), lineWidth: 0.5))
                    .symbolEffect(.pulse, isActive: light == .busy)
            } else {
                Circle().strokeBorder(.secondary, lineWidth: 1.2)
            }
        }
        .frame(width: 9, height: 9)
        .accessibilityHidden(true)
    }
}

/// Sidebar window (docs/10 §4.2, UX-03).
struct MainWindowView: View {
    enum Section: String, CaseIterable, Identifiable {
        case sign, verify, browser, card, activity
        var id: String { rawValue }
        var title: String {
            switch self {
            case .sign: return L10n.text(.ui_sign)
            case .verify: return L10n.text(.ui_verify)
            case .browser: return L10n.text(.ui_browser)
            case .card: return L10n.text(.ui_card)
            case .activity: return L10n.text(.ui_activity)
            }
        }
        var symbol: String {
            switch self {
            case .sign: return "signature"
            case .verify: return "checkmark.seal"
            case .browser: return "globe"
            case .card: return "person.text.rectangle"
            case .activity: return "clock"
            }
        }
    }

    @Environment(AppModel.self) private var model
    @State private var portalBrowser = MacPortalBrowser()
    @AppStorage("mainSection", store: AppPreferencesStore.defaults) private var stored = Section.sign.rawValue

    var body: some View {
        let selection = Binding<Section?>(get: { Section(rawValue: stored) ?? .sign }, set: { stored = ($0 ?? .sign).rawValue })
        NavigationSplitView {
            List(selection: selection) {
                SwiftUI.Section(L10n.text(.ui_documents)) {
                    ForEach([Section.sign, .verify, .browser]) { item in Label(item.title, systemImage: item.symbol).tag(item) }
                }
                SwiftUI.Section(L10n.text(.ui_account)) {
                    ForEach([Section.card, .activity]) { item in Label(item.title, systemImage: item.symbol).tag(item) }
                }
            }
            .navigationSplitViewColumnWidth(min: 190, ideal: 210)
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 8) {
                    StatusLightView(light: model.light)
                    Text(model.lightLabel).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    Spacer()
                }
                .padding(12)
            }
        } detail: {
            NavigationStack {
                VStack(spacing: 0) {
                    if model.demoMode { DemoModeBanner() }
                    switch Section(rawValue: stored) ?? .sign {
                    case .sign: SignScreen()
                    case .verify: VerifyScreen()
                    case .browser: MacBrowserScreen(browser: portalBrowser)
                    case .card: CardScreen()
                    case .activity: ActivityScreen()
                    }
                }
            }
            .background(WindowReader { WindowPresentation.shared.register($0, for: .main) })
        }
        .onChange(of: model.browserURL) { _, url in
            if url != nil { stored = Section.browser.rawValue }
        }
    }
}
