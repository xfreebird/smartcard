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
                .task { model.start() }
                .onOpenURL { url in model.addFiles([url]) }   // "Open in…" / share-to (IOS-04)
        }
        .onChange(of: scenePhase) { _, phase in
            // R-01: iOS suspends us in the background; the bridge only serves while we are foreground
            if phase == .active, model.bridgeEnabled { model.startBridge() }
            if phase == .background { model.stopBridge() }
        }
    }
}

struct RootTabView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView {
            NavigationStack { SignScreen().safeAreaInset(edge: .top) { ConnectionBanner() } }
                .tabItem { Label("Semnează", systemImage: "signature") }
            NavigationStack { VerifyScreen() }
                .tabItem { Label("Verifică", systemImage: "checkmark.seal") }
            NavigationStack { BrowserScreen() }
                .tabItem { Label("Browser", systemImage: "globe") }
            NavigationStack { CardScreen() }
                .tabItem { Label("Card", systemImage: "person.text.rectangle") }
        }
        .tint(Theme.brand)
        .sheet(item: $model.pinRequest) { request in
            PinEntryView(request: request,
                         onSubmit: { model.submitPIN($0, remember: $1) },
                         onCancel: { model.cancelPIN() })
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
        }
        .sheet(item: $model.consentRequest) { consent in
            ConsentView(consent: consent) { model.answerConsent(approved: $0, trust: $1) }
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
        }
    }
}

/// Top banner mirroring the StatusCard; tapping it in `noReader` opens the adapter guide (IOS-03).
struct ConnectionBanner: View {
    @Environment(AppModel.self) private var model
    @State private var showGuide = false

    var body: some View {
        Button { showGuide = true } label: {
            StatusCardView(status: model.status, compact: true)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.top, Theme.Space.s)
        .sheet(isPresented: $showGuide) { ConnectionGuideView() }
    }
}
