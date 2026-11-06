import SwiftUI
import WebKit

/// Foreground browser: the signing connection remains available while a portal is open.
struct BrowserScreen: View {
    @Environment(AppModel.self) private var model
    @State private var browser = PortalBrowser()
    @State private var editingAddress = false
    @State private var address = "https://msign.gov.md/#/"
    @State private var addressError = false
    @State private var showingDataReset = false
    @State private var bookmarks = BrowserBookmarks()
    @State private var showingBookmarks = false
    @State private var clearCache = true
    @State private var clearCookies = true
    @State private var clearHistory = true
    @State private var clearingData = false
    @State private var initialPageRequested = false

    var body: some View {
        Group {
            if model.demoMode {
                ContentUnavailableView(L10n.text(.demo_banner), systemImage: "sparkles",
                                       description: Text(L10n.text(.demo_settings_description)))
            } else {
                PortalWebView(browser: browser).id(browser.id)
            }
        }
            .safeAreaInset(edge: .top) {
                VStack(spacing: 0) {
                if model.showsDemoNotice { DemoModeBanner() }
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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    if let error = browser.error {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.caption).padding(8).frame(maxWidth: .infinity)
                    }
                    HStack {
                        Button { browser.webView.goBack() } label: {
                            Label(L10n.text(.ui_back), systemImage: "chevron.left")
                                .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                        }
                        .disabled(model.demoMode || !browser.canGoBack)
                        Button { browser.webView.goForward() } label: {
                            Label(L10n.text(.ui_forward), systemImage: "chevron.right")
                                .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                        }
                        .disabled(model.demoMode || !browser.canGoForward)
                        Spacer()
                        Button { browser.webView.reload() } label: {
                            Label(L10n.text(.ui_reload), systemImage: "arrow.clockwise")
                                .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                        }
                        .disabled(model.demoMode)
                        if let url = browser.url {
                            ShareLink(item: url) {
                                Label(L10n.text(.ui_share), systemImage: "square.and.arrow.up")
                                    .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                            }
                        }
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .frame(minHeight: 50)
                    .padding(.horizontal, 20)
                }
                .background(.bar)
            }
            .navigationTitle(browser.url?.host ?? L10n.text(.ui_browser))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { showingDataReset = true } label: {
                            Label(L10n.text(.browser_clear_data), systemImage: "trash")
                        }
                        Divider()
                        ForEach(bookmarks.items) { item in
                            Button { browser.open(item.url) } label: {
                                Label { Text(item.title) } icon: { BookmarkIcon(bookmark: item) }
                            }
                        }
                        Divider()
                        Button(L10n.text(.browser_bookmark_add)) { showingBookmarks = true }
                        Button(L10n.text(.browser_bookmark_manage)) { showingBookmarks = true }
                    } label: {
                        Label(L10n.text(.browser_services), systemImage: "bookmark")
                    }.disabled(model.demoMode)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { address = browser.url?.absoluteString ?? address; editingAddress = true } label: {
                        Label(L10n.text(.ui_open_an_address), systemImage: "link")
                    }.disabled(model.demoMode)
                }
            }
            .sheet(isPresented: $showingBookmarks) {
                BookmarkManager(bookmarks: bookmarks, currentURL: browser.url, currentTitle: browser.webView.title)
                    .appPreferences()
            }
            .sheet(isPresented: $showingDataReset) {
                NavigationStack {
                    Form {
                        Section {
                            Toggle(L10n.text(.browser_cache), isOn: $clearCache)
                            Toggle(L10n.text(.browser_cookies), isOn: $clearCookies)
                            Toggle(L10n.text(.browser_history), isOn: $clearHistory)
                        } footer: { Text(L10n.text(.browser_data_reset_note)) }
                        if clearingData { ProgressView() }
                    }
                    .navigationTitle(L10n.text(.browser_clear_data))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(L10n.text(.ui_cancel)) { showingDataReset = false }.disabled(clearingData)
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(L10n.text(.ui_clear)) { Task { await resetBrowserData() } }
                                .disabled(clearingData || !(clearCache || clearCookies || clearHistory))
                        }
                    }
                    .disabled(clearingData)
                }.interactiveDismissDisabled(clearingData)
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
                if !model.demoMode, !initialPageRequested {
                    initialPageRequested = true
                    browser.open(model.browserURL ?? URL(string: "https://msign.gov.md/#/")!)
                }
            }
    }

    @MainActor
    private func resetBrowserData() async {
        clearingData = true
        browser.webView.stopLoading()
        // Stop the current page from recreating session storage while cookies are removed.
        if clearCookies || clearHistory {
            initialPageRequested = true
            browser.webView.loadHTMLString("", baseURL: nil)
            browser.webView.navigationDelegate = nil
            browser.webView.uiDelegate = nil
            browser = PortalBrowser(configuration: browser.webView.configuration)
            address = ""
        }
        var types = Set<String>()
        if clearCache {
            types.formUnion([WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache,
                             WKWebsiteDataTypeFetchCache, WKWebsiteDataTypeServiceWorkerRegistrations])
        }
        if clearCookies {
            types.formUnion([WKWebsiteDataTypeCookies, WKWebsiteDataTypeLocalStorage,
                             WKWebsiteDataTypeSessionStorage, WKWebsiteDataTypeIndexedDBDatabases,
                             WKWebsiteDataTypeWebSQLDatabases])
        }
        if !types.isEmpty {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: .distantPast) { continuation.resume() }
            }
        }
        clearingData = false
        showingDataReset = false
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
    let id = UUID()
    let webView: WKWebView
    var url: URL?
    var canGoBack = false
    var canGoForward = false
    var loading = false
    var error: String?
    @ObservationIgnored private var navigationObservations: [NSKeyValueObservation] = []
    private let mpassHosts: Set<String> = ["mpass.gov.md", "testmpass.gov.md", "mpass.staging.egov.md"]

    init(configuration: WKWebViewConfiguration = WKWebViewConfiguration()) {
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        // A redirect or POST may reach MPass before navigation preferences are applied.
        // Set a desktop user agent from the first request so its login preserves SSO state.
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        // Portals can change history and URL through the History API without a navigation
        // delegate callback. Keep the controls and share URL in sync with WebKit itself.
        navigationObservations = [
            webView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.updateNavigation() }
            },
            webView.observe(\.canGoForward, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.updateNavigation() }
            },
            webView.observe(\.url, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.updateNavigation() }
            },
        ]
    }

    func open(_ url: URL) {
        guard ["https", "http"].contains(url.scheme?.lowercased() ?? L10n.text(.ui_)), webView.url != url else { return }
        self.url = url
        webView.load(URLRequest(url: url))
    }

    /// MPass's server omits the identity-card option for mobile user agents. Request its
    /// desktop page before navigation; unrelated sites retain WebKit's recommended mobile mode.
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 preferences: WKWebpagePreferences,
                 decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        let host = navigationAction.request.url?.host?.lowercased()
        preferences.preferredContentMode = host.map(mpassHosts.contains) == true ? .desktop : .recommended
        decisionHandler(.allow, preferences)
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
        if navigationAction.targetFrame == nil { webView.load(navigationAction.request) }
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
                    Text(L10n.text(.ui_iphone_ipad_os_17_or_later))
                }
                Section(L10n.text(.ui_how_to_connect_the_reader)) {
                    tile("cable.connector", L10n.text(.ui_usb_c_usb_a),
                         L10n.text(.ui_usb_c_reader_connection))
                    tile("bolt.horizontal", L10n.text(.ui_lightning_to_usb_a_adapter),
                         L10n.text(.ui_lightning_reader_connection))
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
