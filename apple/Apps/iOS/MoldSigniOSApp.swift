import SwiftUI
import MoldSignKit

/// iOS / iPadOS app: Semnează · Verifică · Browser · Card (docs/10 §4.4).
@main
struct MoldSigniOSApp: App {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(model)
                .appPreferences()
                .task { model.start() }
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
            if phase == .active, model.bridgeEnabled { model.startBridge() }
            if phase == .background { model.stopBridge() }
        }
    }
}

struct RootTabView: View {
    enum TabID: String { case sign, verify, browser, card }

    @Environment(AppModel.self) private var model
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
            NavigationStack { SignScreen() }
                .tabItem { Label(L10n.text(.ui_sign), systemImage: "signature") }
                .tag(TabID.sign)
            NavigationStack { VerifyScreen() }
                .tabItem { Label(L10n.text(.ui_verify), systemImage: "checkmark.seal") }
                .tag(TabID.verify)
            NavigationStack { BrowserScreen() }
                .tabItem { Label(L10n.text(.ui_browser), systemImage: "globe") }
                .tag(TabID.browser)
            NavigationStack { CardScreen() }
                .tabItem { Label(L10n.text(.ui_card), systemImage: "person.text.rectangle") }
                .tag(TabID.card)
        }
        .onChange(of: model.browserURL) { _, url in if url != nil { tab = .browser } }
        .tint(Theme.brand)
        .sheet(item: $model.pinRequest) { request in
            PinEntryView(request: request,
                         onSubmit: { model.submitPIN($0, remember: $1) },
                         onCancel: { model.cancelPIN() })
                .presentationDetents(request.documentNames.isEmpty ? [.medium] : [.large])
                .interactiveDismissDisabled()
        }
        .sheet(item: $model.consentRequest) { consent in
            ConsentView(consent: consent) { model.answerConsent(approved: $0, trust: $1) }
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
        }
    }
}
