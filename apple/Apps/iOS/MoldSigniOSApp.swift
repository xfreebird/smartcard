import SwiftUI
import AppIntents
import CoreSpotlight
import MoldSignKit

/// iOS / iPadOS app: Semnează · Verifică · Browser · Card (docs/10 §4.4).
@main
struct MoldSigniOSApp: App {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    init() { ESemnBunShortcuts.updateAppShortcutParameters() }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(model)
                .appPreferences()
                .task {
                    model.start()
                    model.addFiles(SharedDocumentInbox.takeDocuments())
                }
                .onOpenURL { url in
                    if ["https", "http"].contains(url.scheme?.lowercased() ?? L10n.text(.ui_)) { model.browserURL = url }
                    else if url.scheme == "esemnbun", url.host == "browser",
                            let target = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "url" })?.value,
                            let webURL = URL(string: target), ["https", "http"].contains(webURL.scheme?.lowercased() ?? L10n.text(.ui_)) {
                        model.browserURL = webURL
                    } else if url.isFileURL { model.addFiles([url]) }
                }   // "Open in…" / share-to (IOS-04)
        }
        .onChange(of: scenePhase) { _, phase in
            // R-01: iOS suspends us in the background; the bridge only serves while we are foreground
            if phase == .active {
                DocumentDiscovery.refresh()
                let shared = SharedDocumentInbox.takeDocuments()
                model.addFiles(shared)
                if !shared.isEmpty { NotificationCenter.default.post(name: .sharedDocumentsImported, object: nil) }
                if model.bridgeEnabled { model.startBridge() }
            }
            if phase == .background { model.stopBridge() }
        }
    }
}

struct RootTabView: View {
    enum TabID: String { case sign, verify, documents, browser, card }

    @Environment(AppModel.self) private var model
    @State private var shortcutNavigation = ShortcutNavigation.shared
    @State private var tab: TabID = {
        #if DEBUG
        // design QA: MSIGN_DEMO_TAB=card opens on the Card tab (debug builds only)
        if let raw = ProcessInfo.processInfo.environment["MSIGN_DEMO_TAB"], let tab = TabID(rawValue: raw) { return tab }
        #endif
        return .sign
    }()

    var body: some View {
        @Bindable var model = model
        TabView(selection: $tab) {
            NavigationStack { SignScreen(onOpenDocuments: { tab = .documents }) }
                .tabItem { Label(L10n.text(.ui_sign), systemImage: "signature") }
                .tag(TabID.sign)
            NavigationStack { VerifyScreen() }
                .tabItem { Label(L10n.text(.ui_verify), systemImage: "checkmark.seal") }
                .tag(TabID.verify)
            NavigationStack { ActivityScreen() }
                .tabItem { Label(L10n.text(.saved_title), systemImage: "folder") }
                .tag(TabID.documents)
            NavigationStack { BrowserScreen() }
                .tabItem { Label(L10n.text(.ui_browser), systemImage: "globe") }
                .tag(TabID.browser)
            NavigationStack { CardScreen() }
                .tabItem { Label(L10n.text(.ui_card), systemImage: "person.text.rectangle") }
                .tag(TabID.card)
        }
        .onContinueUserActivity(DocumentDiscovery.activityType, perform: DocumentDiscovery.resume)
        .onContinueUserActivity(CSSearchableItemActionType, perform: DocumentDiscovery.resume)
        .userActivity(DocumentDiscovery.activityType, isActive: tab == .documents) { activity in
            activity.title = L10n.text(.saved_title)
            activity.isEligibleForHandoff = true
            activity.isEligibleForSearch = false
            activity.isEligibleForPublicIndexing = false
        }
        .onChange(of: model.browserURL) { _, url in if url != nil { tab = .browser } }
        .onReceive(NotificationCenter.default.publisher(for: .sharedDocumentsImported)) { _ in tab = .sign }
        .task { consumeShortcutNavigation() }
        .onChange(of: shortcutNavigation.request?.id) { _, _ in consumeShortcutNavigation() }
        .tint(Theme.brand)
        .sheet(item: $model.bridgeStampRequest, onDismiss: { model.finishBridgeStampDismissal() }) { stamp in
            PDFStampEditor(url: stamp.url, initial: .init(), holder: stamp.holder,
                save: { model.answerBridgeStamp(.proceed($0), afterDismissal: true) },
                onCancel: { model.answerBridgeStamp(.cancel, afterDismissal: true) }, requester: stamp.origin)
                .interactiveDismissDisabled()
        }
        .sheet(item: $model.pinRequest) { request in
            PinEntryView(request: request,
                         onSubmit: { model.submitPIN($0, remember: $1) },
                         onCancel: { model.cancelPIN() })
                .presentationDetents([.large])
                .interactiveDismissDisabled()
        }
        .sheet(item: $model.consentRequest) { consent in
            ConsentView(consent: consent) { model.answerConsent(approved: $0, trust: $1) }
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
        }
    }

    private func consumeShortcutNavigation() {
        guard let request = shortcutNavigation.request else { return }
        shortcutNavigation.request = nil
        if let url = request.preparedURL {
            model.addFiles([url])
            tab = .sign
        } else if let reports = request.reports, let filename = request.filename {
            model.clearVerification()
            // Results contain metadata only. The shortcut's private input copy has been erased;
            // this display URL is deliberately not a file URL or persistent document permission.
            let displayURL = URL(string: "esemnbun-verification://result")!.appendingPathComponent(filename)
            model.verifyFile = displayURL
            model.verifyReports = reports
            model.verifiedDocuments = [(displayURL, reports)]
            tab = .verify
        } else {
            tab = .documents
        }
    }
}
