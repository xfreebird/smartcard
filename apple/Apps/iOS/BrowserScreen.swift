import SwiftUI
import WebKit

/// In-app browser on msign.gov.md (IOS-06). The bridge runs in-process; because this app stays
/// foreground, the portal's calls to localhost.cts.md / 127.0.0.1 reach it (R-01).
/// TODO(IOS-06): the https listener needs the localhost.cts.md identity (D-03); until then only http :18480 serves.
struct BrowserScreen: View {
    @Environment(AppModel.self) private var model
    @State private var url = URL(string: "https://msign.gov.md/#/")!

    var body: some View {
        PortalWebView(url: url)
            .ignoresSafeArea(edges: .bottom)
            .safeAreaInset(edge: .top) {
                HStack(spacing: Theme.Space.s) {
                    Circle().fill(model.bridgeState == .running ? Theme.success : Theme.warning).frame(width: 8, height: 8)
                    Text(model.bridgeState == .running ? "Conexiune MoldSign activă" : "Conexiune MoldSign oprită")
                        .font(.caption.weight(.medium))
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(.bar)
            }
            .navigationTitle("msign.gov.md")
            .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PortalWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        view.allowsBackForwardNavigationGestures = true
        view.load(URLRequest(url: url))
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

/// Adapter tiles (docs/10 §3 ConnectionGuide).
struct ConnectionGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            List {
                Section {
                    StatusCardView(status: model.status)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                Section("Cum conectezi cititorul") {
                    tile("cable.connector", "USB-C → USB-A",
                         "iPhone 15 sau mai nou, iPad cu USB-C. Adaptor USB-C la USB-A.")
                    tile("bolt.horizontal", "Lightning → USB 3 pentru cameră",
                         "iPhone 14 sau mai vechi. Recomandat adaptorul cu alimentare suplimentară.")
                    tile("externaldrive.connected.to.line.below", "USB-A direct",
                         "Calculatoare (macOS, Windows, Linux).")
                }
                Section {
                    Text("Cititorul bit4id miniLector este recunoscut automat. Introdu cardul cu cipul în sus.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Conectează cititorul")
            .toolbar { Button("Gata") { dismiss() } }
        }
    }

    private func tile(_ symbol: String, _ title: LocalizedStringKey, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: Theme.Space.m) {
            Image(systemName: symbol).font(.title2).foregroundStyle(Theme.brand).frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
