import SwiftUI
import WebKit

/// Foreground browser: the signing connection remains available while a portal is open.
struct BrowserScreen: View {
    @Environment(AppModel.self) private var model
    @State private var browser = PortalBrowser()
    @State private var editingAddress = false
    @State private var address = "https://msign.gov.md/#/"
    @State private var addressError = false

    var body: some View {
        Group {
            if model.demoMode {
                ContentUnavailableView(L10n.text(.demo_banner), systemImage: "sparkles",
                                       description: Text(L10n.text(.demo_settings_description)))
            } else {
                PortalWebView(browser: browser)
            }
        }
            .safeAreaInset(edge: .top) {
                VStack(spacing: 0) {
                if model.demoMode { DemoModeBanner() }
                HStack(spacing: 8) {
                    Circle().fill(model.bridgeState == .running ? Theme.success : Theme.warning).frame(width: 8, height: 8)
                    Text(model.bridgeState == .running ? L10n.text(.ui_browser_connection_on) : L10n.text(.ui_browser_connection_off))
                        .font(.caption)
                    Spacer()
                    if browser.loading { ProgressView().controlSize(.small) }
                }
                .padding(.horizontal).padding(.vertical, 6).background(.bar)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let error = browser.error {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption).padding(8).frame(maxWidth: .infinity).background(.bar)
                }
            }
            .navigationTitle(browser.url?.host ?? L10n.text(.ui_browser))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { address = browser.url?.absoluteString ?? address; editingAddress = true } label: {
                        Label(L10n.text(.ui_open_an_address), systemImage: "link")
                    }.disabled(model.demoMode)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button { browser.webView.goBack() } label: { Label(L10n.text(.ui_back), systemImage: "chevron.left") }
                        .disabled(model.demoMode || !browser.canGoBack)
                    Button { browser.webView.goForward() } label: { Label(L10n.text(.ui_forward), systemImage: "chevron.right") }
                        .disabled(model.demoMode || !browser.canGoForward)
                    Spacer()
                    Button { browser.webView.reload() } label: { Label(L10n.text(.ui_reload), systemImage: "arrow.clockwise") }
                        .disabled(model.demoMode)
                    if let url = browser.url {
                        ShareLink(item: url) { Label(L10n.text(.ui_share), systemImage: "square.and.arrow.up") }
                    }
                }
            }
            .sheet(isPresented: $editingAddress) {
                NavigationStack {
                    Form {
                        TextField(L10n.text(.ui_https_example_md), text: $address)
                            .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                            .onSubmit(openAddress)
                        if addressError { Text(L10n.text(.ui_enter_a_valid_web_address_https)).foregroundStyle(.red) }
                    }
                    .navigationTitle(L10n.text(.ui_open_an_address))
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button(L10n.text(.ui_cancel)) { editingAddress = false } }
                        ToolbarItem(placement: .confirmationAction) { Button(L10n.text(.ui_open), action: openAddress) }
                    }
                }
                .presentationDetents([.medium])
            }
            .onChange(of: model.browserURL) { _, url in if !model.demoMode, let url { browser.open(url) } }
            .onChange(of: model.demoMode) { _, demo in
                if demo { browser.webView.stopLoading(); browser = PortalBrowser() }
                else if browser.url == nil { browser.open(URL(string: "https://msign.gov.md/#/")!) }
            }
            .onAppear {
                if !model.demoMode, browser.url == nil { browser.open(model.browserURL ?? URL(string: "https://msign.gov.md/#/")!) }
            }
    }

    private func openAddress() {
        let raw = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = raw.contains("://") ? raw : "https://" + raw
        guard !model.demoMode else { return }
        guard let url = URL(string: candidate), ["https", "http"].contains(url.scheme?.lowercased() ?? L10n.text(.ui_)),
              let host = url.host, !host.isEmpty else { addressError = true; return }
        browser.open(url)
        addressError = false
        editingAddress = false
    }
}

@MainActor @Observable
private final class PortalBrowser: NSObject, WKNavigationDelegate, WKUIDelegate {
    let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    var url: URL?
    var canGoBack = false
    var canGoForward = false
    var loading = false
    var error: String?

    override init() {
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
    }

    func open(_ url: URL) {
        guard ["https", "http"].contains(url.scheme?.lowercased() ?? L10n.text(.ui_)), webView.url != url else { return }
        self.url = url
        webView.load(URLRequest(url: url))
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loading = true
        error = nil
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { loading = false; updateNavigation() }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loading = false
        self.error = error.localizedDescription
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loading = false
        self.error = error.localizedDescription
    }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) { updateNavigation() }

    private func updateNavigation() {
        url = webView.url
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }

    /// A portal's target=_blank links stay inside the foreground app.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url { open(url) }
        return nil
    }
}

private struct PortalWebView: UIViewRepresentable {
    let browser: PortalBrowser
    func makeUIView(context: Context) -> WKWebView { browser.webView }
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
                    CardSelector(size: .phone)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                }
                Section(L10n.text(.ui_how_to_connect_the_reader)) {
                    tile("cable.connector", L10n.text(.ui_usb_c_usb_a),
                         L10n.text(.ui_iphone_15_or_later_ipad_with_usb_c_usb_c_to_usb_a_adapter))
                    tile("bolt.horizontal", L10n.text(.ui_lightning_to_usb_3_camera_adapter),
                         L10n.text(.ui_iphone_14_or_earlier_an_adapter_with_additional_power_is_recommended))
                }
                Section {
                    Text(L10n.text(.ui_the_bit4id_minilector_reader_is_detected_automatically_insert_the_card_with_the_chip_fac))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(L10n.text(.ui_connect_the_reader))
            .toolbar { Button(L10n.text(.ui_done)) { dismiss() } }
        }
    }

    private func tile(_ symbol: String, _ title: String, _ text: String) -> some View {
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
