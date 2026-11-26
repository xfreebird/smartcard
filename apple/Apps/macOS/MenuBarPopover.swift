import SwiftUI

/// Menu-bar popover (docs/10 §0, UX-03): the card selector (the card shows its own status), quick actions,
/// recents, browser bridge, then menu-style rows. No drop target: the popover closes as soon as you start
/// dragging from Finder, so files go to the window or the Dock icon instead.
struct MenuBarPopover: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    @State private var hostWindow: NSWindow?
    @State private var contentHeight: CGFloat = 600
    #if !APP_STORE
    @State private var vendorListening = false
    @State private var confirmQuitVendor = false
    @State private var vendorQuitFailed = false
    @State private var quittingVendor = false
    #endif

    var body: some View {
        let screen = hostWindow?.screen ?? NSScreen.main
        ScrollView(.vertical) {
            menuContent
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(width: min(380, (screen?.visibleFrame.width ?? 400) - 16),
               height: min(ceil(contentHeight), (screen?.visibleFrame.height ?? 800) - 24))
        .background(WindowReader { hostWindow = $0 })
    }

    @ViewBuilder private var menuContent: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(L10n.text(.ui_esemnbun)).font(.headline)
                Spacer()
                Button {
                    dismissThen { WindowPresentation.shared.present(.settings) { openSettings() } }
                } label: { Image(systemName: "gearshape") }
                    .buttonStyle(TrayButtonStyle())
                    .help(L10n.text(.ui_settings))
                    .accessibilityLabel(L10n.text(.ui_settings))
            }

            if model.showsDemoNotice { DemoModeBanner() }
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
                quickAction(.sign, symbol: "signature")
                quickAction(.verify, symbol: "checkmark.seal")
            }
            .controlSize(.large)

            let recents = model.recentDocuments.prefix(3)
            if !recents.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L10n.text(.ui_recent_documents)).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        Spacer()
                        Button(L10n.text(.ui_clear)) { model.clearRecents() }
                            .buttonStyle(TrayButtonStyle())
                            .font(.caption)
                            .help(L10n.text(.ui_clear_the_recent_documents_list_files_and_activity_history_are_kept))
                    }
                    ForEach(recents) { item in
                        Button {
                            dismissThen { if let url = item.fileURL { NSWorkspace.shared.activateFileViewerSelecting([url]) } }
                        } label: {
                            ActivityRowView(item: item, showsDate: false).font(.subheadline).contentShape(Rectangle())
                        }
                        .buttonStyle(TrayButtonStyle(subtle: true))
                        .help(L10n.text(.ui_show_in_finder))
                    }
                }
            }

            Divider()
            Toggle(isOn: $model.bridgeEnabled) {
                HStack(spacing: 8) {
                    StatusLightView(light: bridgeLight)
                    Text(bridgeText).fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }.contentShape(Rectangle())
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .modifier(TrayHoverSurface(subtle: true))

            if model.bridgeState == .portBusy {
                #if !APP_STORE
                if vendorListening {
                    Button(L10n.text(.vendor_quit_action)) { confirmQuitVendor = true }
                        .buttonStyle(TrayButtonStyle(filled: true))
                        .disabled(quittingVendor)
                } else {
                    retryBridgeButton
                }
                if quittingVendor { ProgressView().controlSize(.small) }
                if vendorQuitFailed { Text(L10n.text(.vendor_quit_failed)).font(.callout).foregroundStyle(.red) }
                #else
                retryBridgeButton
                #endif
            }
            Divider()
            VStack(spacing: 0) {
                MenuRow(title: L10n.text(.ui_open_esemnbun)) { showMain(.sign) }
                MenuRow(title: L10n.text(.about_app_title)) {
                    dismissThen {
                        WindowPresentation.shared.present(.about) { openWindow(id: "about") }
                    }
                }
                Divider().padding(.vertical, 4)
                MenuRow(title: L10n.text(.ui_quit), shortcut: "⌘Q") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
            .padding(.horizontal, -6)   // hover highlight reaches the content edges, like menu items
        }
        .lineLimit(nil)
        .multilineTextAlignment(.leading)
        .onAppear { model.pruneMissingFiles() }
        #if !APP_STORE
        .task(id: model.bridgeState == .portBusy) {
            vendorListening = model.bridgeState == .portBusy
                ? await Task.detached { !VendorPortConflict.listeners().isEmpty }.value : false
        }
        .alert(L10n.text(.vendor_quit_confirmation), isPresented: $confirmQuitVendor) {
            Button(L10n.text(.vendor_quit_action), role: .destructive) {
                quittingVendor = true
                Task { @MainActor in
                    defer { quittingVendor = false }
                    let stopped = await Task.detached { VendorPortConflict.terminateListeners() }.value
                    vendorQuitFailed = !stopped
                    if stopped { restartBridge() }
                }
            }
            Button(L10n.text(.ui_cancel), role: .cancel) { }
        } message: { Text(L10n.text(.vendor_quit_explanation)) }
        #endif
    }

    /// MenuBarExtra has no dismiss API: close its window first so the popover doesn't hang over what opens next.
    private func dismissThen(_ action: @escaping () -> Void) {
        hostWindow?.close()
        DispatchQueue.main.async(execute: action)
    }

    @State private var hoveredAction: MainWindowView.Section?

    private func quickAction(_ section: MainWindowView.Section, symbol: String) -> some View {
        Button { showMain(section) } label: {
            Label(section.title, systemImage: symbol).frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(hoveredAction == section ? Color.accentColor : nil)
        .onHover { inside in
            if inside { hoveredAction = section }
            else if hoveredAction == section { hoveredAction = nil }
        }
    }

    private var retryBridgeButton: some View {
        Button(L10n.text(.vendor_retry)) { restartBridge() }
            .buttonStyle(TrayButtonStyle(filled: true))
    }

    private func restartBridge() {
        model.stopBridge()
        if model.bridgeEnabled { model.startBridge() }
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

    final class ReaderView: NSView {
        var onWindow: ((NSWindow?) -> Void)?
        private var reopenObserver: NSObjectProtocol?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            observeReopening()
            // Deliver outside SwiftUI's view update, after AppKit attaches the actual window.
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.onWindow?(self.window)
            }
        }

        /// SwiftUI reopens a closed `Window` scene in the same NSWindow, so this view never moves again.
        /// Deliver the window once more whenever it is back on screen; closing it delivers nothing.
        private func observeReopening() {
            if let reopenObserver { NotificationCenter.default.removeObserver(reopenObserver) }
            reopenObserver = window.map { window in
                NotificationCenter.default.addObserver(forName: NSWindow.didChangeOcclusionStateNotification,
                                                       object: window, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated {
                        guard let self, let window = self.window, window.isVisible else { return }
                        self.onWindow?(window)
                    }
                }
            }
        }

        deinit {
            if let reopenObserver { NotificationCenter.default.removeObserver(reopenObserver) }
        }
    }

    func makeNSView(context: Context) -> ReaderView {
        let view = ReaderView()
        view.onWindow = onWindow
        return view
    }

    func updateNSView(_ view: ReaderView, context: Context) {
        view.onWindow = onWindow
    }
}

/// A full-width, menu-item-like row: highlights on hover, optional shortcut on the trailing side.
private struct MenuRow: View {
    let title: String
    var shortcut: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                if let shortcut { Text(shortcut).opacity(0.8) }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(TrayButtonStyle())
    }
}

private struct TrayButtonStyle: ButtonStyle {
    var filled = false
    var subtle = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.modifier(TrayHoverSurface(filled: filled, subtle: subtle, pressed: configuration.isPressed))
    }
}

private struct TrayHoverSurface: ViewModifier {
    var filled = false
    var subtle = false
    var pressed = false
    @Environment(\.isEnabled) private var enabled
    @State private var hovered = false

    func body(content: Content) -> some View {
        let highlighted = enabled && (hovered || pressed)
        let background = highlighted ? Color.accentColor.opacity(subtle ? 0.18 : 1)
            : filled ? Color.secondary.opacity(0.12) : .clear
        content
            .foregroundStyle(highlighted && !subtle ? Color.white : .primary)
            .padding(.horizontal, filled ? 10 : 6)
            .padding(.vertical, filled ? 7 : 4)
            .background(background, in: RoundedRectangle(cornerRadius: filled ? 8 : 5))
            .contentShape(Rectangle())
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
        case sign, verify, browser, activity
        var id: String { rawValue }
        var title: String {
            switch self {
            case .sign: return L10n.text(.ui_sign)
            case .verify: return L10n.text(.ui_verify)
            case .browser: return L10n.text(.ui_browser)
            case .activity: return L10n.text(.ui_activity)
            }
        }
        var symbol: String {
            switch self {
            case .sign: return "signature"
            case .verify: return "checkmark.seal"
            case .browser: return "globe"
            case .activity: return "folder"
            }
        }
    }

    #if DEBUG
    @Environment(\.openSettings) private var openSettingsForCapture
    #endif
    @Environment(AppModel.self) private var model
    @State private var shortcutNavigation = ShortcutNavigation.shared
    @State private var portalBrowser = MacPortalBrowser()
    @State private var onboardingPresented = false
    @AppStorage("mainSection", store: AppPreferencesStore.defaults) private var stored = Section.sign.rawValue

    var body: some View {
        let selection = Binding<Section?>(get: { Section(rawValue: stored) ?? .sign }, set: { stored = ($0 ?? .sign).rawValue })
        NavigationSplitView {
            List(selection: selection) {
                SwiftUI.Section(L10n.text(.ui_documents)) {
                    ForEach([Section.sign, .verify, .activity, .browser]) { item in Label(item.title, systemImage: item.symbol).tag(item) }
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
                    if model.showsDemoNotice { DemoModeBanner() }
                    switch Section(rawValue: stored) ?? .sign {
                    case .sign: SignScreen()
                    case .verify: VerifyScreen()
                    case .browser: MacBrowserScreen(browser: portalBrowser)
                    case .activity: ActivityScreen()
                    }
                }
            }
            .background(WindowReader { WindowPresentation.shared.register($0, for: .main) })
        }
        .toolbar {
            // Keep native title/toolbar geometry when a section has no actions.
            #if compiler(>=6.2)
            if #available(macOS 26.0, *) {
                ToolbarItem(placement: .principal) {
                    toolbarHeightReservation
                }
                .sharedBackgroundVisibility(.hidden)
            } else {
                ToolbarItem(placement: .principal) {
                    toolbarHeightReservation
                }
            }
            #else
            ToolbarItem(placement: .principal) {
                toolbarHeightReservation
            }
            #endif
        }
        #if DEBUG
        .task {
            if model.isScreenshotCapture, ProcessInfo.processInfo.environment["MSIGN_DEMO_SETTINGS"] == "1" {
                WindowPresentation.shared.present(.settings) { openSettingsForCapture() }
            }
        }
        #endif
        .onChange(of: model.browserURL) { _, url in
            if url != nil { stored = Section.browser.rawValue }
        }
        .sheet(isPresented: $onboardingPresented, onDismiss: markOnboardingComplete) {
            OnboardingView { onboardingPresented = false }
        }
        .onAppear { presentOnboardingIfNeeded(); consumeShortcutNavigation(); DocumentDiscovery.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            DocumentDiscovery.refresh()
            consumeShortcutNavigation()
        }
        .onChange(of: shortcutNavigation.request?.id) { _, _ in consumeShortcutNavigation() }
        .userActivity(DocumentDiscovery.activityType, isActive: stored == Section.activity.rawValue) { activity in
            activity.title = L10n.text(.saved_title)
            activity.isEligibleForHandoff = true
            activity.isEligibleForSearch = false
            activity.isEligibleForPublicIndexing = false
        }
    }

    private func consumeShortcutNavigation() {
        guard let request = shortcutNavigation.request else { return }
        shortcutNavigation.request = nil
        if let purpose = request.pickerPurpose {
            stored = purpose == .verify ? Section.verify.rawValue : Section.sign.rawValue
            shortcutNavigation.pendingPDFSelection = .init(id: request.id, purpose: purpose, waitsForIntent: request.pickerWaitsForIntent)
        } else if let url = request.preparedURL {
            model.addFiles([url])
            stored = Section.sign.rawValue
        } else if let reports = request.reports, let filename = request.filename {
            model.clearVerification()
            let url = URL(string: "esemnbun-verification://result")!.appendingPathComponent(filename)
            model.verifyFile = url
            model.verifyReports = reports
            model.verifiedDocuments = [(url, reports)]
            stored = Section.verify.rawValue
        } else {
            if let id = request.documentID { shortcutNavigation.selectedDocumentID = id }
            stored = Section.activity.rawValue
        }
    }

    private var toolbarHeightReservation: some View {
        Color.clear.frame(width: 1, height: 28)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }

    /// First-run onboarding (MAC-17, docs/10 §4.7): once, over the main window the first time it appears.
    private func presentOnboardingIfNeeded() {
        #if DEBUG
        let captureEnvironment = ProcessInfo.processInfo.environment
        if model.demoMode,
           captureEnvironment["MSIGN_SCREENSHOT_CAPTURE"] == "1",
           captureEnvironment["MSIGN_QA_NO_HARDWARE"] == "1",
           captureEnvironment["MSIGN_CAPTURE_SHEET"] == "onboarding",
           captureEnvironment["MSIGN_DEMO_PREFERENCES_SUITE"]?.hasPrefix("md.esemnbun.qa.") == true {
            onboardingPresented = true
            return
        }
        #endif
        guard !AppPreferencesStore.defaults.bool(forKey: "didCompleteOnboarding") else { return }
        if model.demoMode { return }   // demo previews and demo sessions stay unobstructed
        #if DEBUG
        if ProcessInfo.processInfo.environment["MSIGN_SCREENSHOT_CAPTURE"] == "1" { return }
        #endif
        onboardingPresented = true
    }

    /// Any dismissal (Get started or Escape) counts: the choices are already applied live.
    private func markOnboardingComplete() {
        AppPreferencesStore.defaults.set(true, forKey: "didCompleteOnboarding")
    }
}
