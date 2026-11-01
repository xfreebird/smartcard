import SwiftUI
import WebKit
import AppKit
import UniformTypeIdentifiers

/// A persistent portal session hosted in the app, sharing the normal consent-protected bridge.
struct MacBrowserScreen: View {
    @Environment(AppModel.self) private var model
    let browser: MacPortalBrowser
    @State private var address = "https://msign.gov.md/#/"
    @State private var invalidAddress = false
    @State private var showBrowserData = false
    @State private var clearCache = true
    @State private var clearCookies = true
    @State private var clearHistory = true
    @State private var clearingData = false

    var body: some View {
        VStack(spacing: 0) {
            if invalidAddress {
                Text(L10n.text(.ui_enter_a_valid_web_address_https))
                    .foregroundStyle(Theme.warning).font(.caption).padding(8)
            }
            if model.showsDemoNotice {
                ContentUnavailableView(L10n.text(.demo_banner), systemImage: "sparkles",
                                       description: Text(L10n.text(.demo_settings_description)))
            } else {
                MacPortalWebView(browser: browser).id(browser.sessionID)
            }
            if let error = browser.error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption).padding(10).frame(maxWidth: .infinity, alignment: .leading).background(.bar)
            }
        }
        .navigationTitle(L10n.text(.ui_browser))
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button { browser.webView.goBack() } label: { Image(systemName: "chevron.left") }
                    .help(L10n.text(.ui_back)).accessibilityLabel(L10n.text(.ui_back))
                    .disabled(model.showsDemoNotice || !browser.canGoBack)
                Button { browser.webView.goForward() } label: { Image(systemName: "chevron.right") }
                    .help(L10n.text(.ui_forward)).accessibilityLabel(L10n.text(.ui_forward))
                    .disabled(model.showsDemoNotice || !browser.canGoForward)
            }
            ToolbarItem(placement: .principal) {
                TextField(L10n.text(.ui_https_example_md), text: $address)
                    .textFieldStyle(.roundedBorder).onSubmit(openAddress)
                    .frame(minWidth: 160, idealWidth: 300, maxWidth: 440)
                    .accessibilityLabel(L10n.text(.ui_open_an_address))
                    .disabled(model.showsDemoNotice)
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: openAddress) { Image(systemName: "arrow.right") }
                    .help(L10n.text(.ui_open)).accessibilityLabel(L10n.text(.ui_open))
                    .disabled(model.showsDemoNotice)
                Button { browser.webView.reload() } label: { Image(systemName: "arrow.clockwise") }
                    .help(L10n.text(.ui_reload)).accessibilityLabel(L10n.text(.ui_reload))
                    .disabled(model.showsDemoNotice)
                Menu {
                    ForEach(PortalService.all) { service in
                        Button { browser.open(service.url) } label: {
                            Label {
                                Text(service.title)
                            } icon: {
                                Image(nsImage: serviceMenuImage(service)).renderingMode(.original)
                            }
                        }
                    }
                    Divider()
                    Button(L10n.text(.browser_clear_data)) { showBrowserData = true }
                } label: { Image(systemName: "bookmark") }
                    .help(L10n.text(.browser_services)).accessibilityLabel(L10n.text(.browser_services))
                    .disabled(model.showsDemoNotice)
                if browser.loading || clearingData { ProgressView().controlSize(.small) }
                Button {
                    if !model.demoMode && !model.bridgeEnabled { model.bridgeEnabled = true }
                } label: {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(model.bridgeState == .running ? Theme.success : Theme.warning)
                }
                .help(L10n.text(model.bridgeState == .running ? .ui_browser_connection_on : .ui_browser_connection_off))
                .accessibilityLabel(L10n.text(model.bridgeState == .running ? .ui_browser_connection_on : .ui_browser_connection_off))
                .disabled(model.showsDemoNotice || model.bridgeState == .running)
            }
        }

        .disabled(clearingData)
        .sheet(isPresented: $showBrowserData) {
            VStack(alignment: .leading, spacing: 18) {
                Text(L10n.text(.browser_clear_data)).font(.headline)
                Toggle(L10n.text(.browser_cache), isOn: $clearCache)
                Toggle(L10n.text(.browser_cookies), isOn: $clearCookies)
                Toggle(L10n.text(.browser_history), isOn: $clearHistory)
                Text(L10n.text(.browser_data_reset_note)).font(.caption).foregroundStyle(.secondary)
                HStack {
                    Spacer()
                    Button(L10n.text(.ui_cancel)) { showBrowserData = false }
                        .keyboardShortcut(.cancelAction)
                    Button(L10n.text(.browser_clear_selected)) {
                        showBrowserData = false
                        clearingData = true
                        Task { @MainActor in
                            await browser.clearBrowsingData(cache: clearCache, cookies: clearCookies, history: clearHistory)
                            if clearCookies || clearHistory { address = "" }
                            clearingData = false
                        }
                    }
                    .disabled(!clearCache && !clearCookies && !clearHistory)
                    .keyboardShortcut(.defaultAction)
                }
            }.padding(24).frame(width: 440)
        }
        .onChange(of: browser.url) { _, url in if let url { address = url.absoluteString } }
        .onChange(of: model.browserURL) { _, url in if !model.demoMode, let url { browser.open(url) } }
        .onChange(of: model.demoMode) { _, demo in
            browser.webView.stopLoading()
            browser.clearSessionNavigation()
            if !demo { openInitialPage() }
        }
        .onAppear { openInitialPage() }
    }

    /// AppKit menus use NSImage's natural size, ignoring SwiftUI resizable/frame modifiers.
    private func serviceMenuImage(_ service: PortalService) -> NSImage {
        let image = (NSImage(named: service.imageName)?.copy() as? NSImage) ?? NSImage(size: NSSize(width: 16, height: 16))
        image.size = NSSize(width: 16, height: 16)
        image.isTemplate = false
        return image
    }

    private func openInitialPage() {
        guard !model.demoMode || model.isScreenshotCapture else { return }
        if model.bridgeEnabled { model.startBridge() }
        if browser.url == nil && !browser.initialPageRequested {
            browser.initialPageRequested = true
            #if DEBUG
            let initial = ProcessInfo.processInfo.environment["MSIGN_BROWSER_URL"].flatMap(URL.init(string:))
            #else
            let initial: URL? = nil
            #endif
            browser.open(model.browserURL ?? initial ?? URL(string: "https://msign.gov.md/#/")!)
        }
    }

    private func openAddress() {
        guard !model.demoMode || model.isScreenshotCapture else { return }
        let raw = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = raw.contains("://") ? raw : "https://" + raw
        guard let url = URL(string: candidate), MacPortalBrowser.isWebURL(url),
              url.user == nil, url.password == nil else { invalidAddress = true; return }
        invalidAddress = false
        browser.open(url)
    }
}

@MainActor @Observable
final class MacPortalBrowser: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
    var webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    var sessionID = UUID()
    var initialPageRequested = false
    var url: URL?
    var canGoBack = false
    var canGoForward = false
    var loading = false
    var error: String?
    private var downloads: [ObjectIdentifier: WKDownload] = [:]

    override init() {
        super.init()
        configureWebView()
    }

    private func configureWebView() {
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
    }

    /// Remove only selected web data. Recreate the view to discard WebKit's back/forward list.
    func clearBrowsingData(cache: Bool, cookies: Bool, history: Bool) async {
        // Reusing configuration keeps its process pool and session cookies when only history is cleared.
        let configuration = webView.configuration
        let store = configuration.websiteDataStore
        let retainedCookies: [HTTPCookie]
        if history && !cookies {
            retainedCookies = await withCheckedContinuation { continuation in
                store.httpCookieStore.getAllCookies { continuation.resume(returning: $0) }
            }
        } else { retainedCookies = [] }
        let cacheTypes: Set<String> = [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache,
                                      WKWebsiteDataTypeOfflineWebApplicationCache, WKWebsiteDataTypeFetchCache,
                                      WKWebsiteDataTypeServiceWorkerRegistrations]
        var types: Set<String> = cache ? cacheTypes : []
        if cookies { types.formUnion(WKWebsiteDataStore.allWebsiteDataTypes().subtracting(cacheTypes)) }
        if cookies || history {
            webView.stopLoading()
            webView.navigationDelegate = nil
            webView.uiDelegate = nil
            webView.loadHTMLString("", baseURL: nil)
            for download in downloads.values { download.cancel { _ in } }
            downloads.removeAll()
            webView = WKWebView(frame: .zero, configuration: configuration)
            configureWebView()
            sessionID = UUID()
            initialPageRequested = true // Clearing closes the page; do not recreate website data by auto-loading.
            url = nil
            canGoBack = false
            canGoForward = false
            loading = false
            error = nil
        }
        if !types.isEmpty {
            await store.removeData(ofTypes: types, modifiedSince: .distantPast)
        }
        // Preserve login cookies when the user selected only navigation history.
        for cookie in retainedCookies {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                store.httpCookieStore.setCookie(cookie) { continuation.resume() }
            }
        }
    }

    static func isWebURL(_ url: URL) -> Bool {
        ["https", "http"].contains(url.scheme?.lowercased() ?? "") && url.host?.isEmpty == false
    }

    func clearSessionNavigation() {
        initialPageRequested = false
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
        url = nil
        canGoBack = false
        canGoForward = false
        error = nil
    }

    func open(_ url: URL) {
        guard Self.isWebURL(url) else { return }
        initialPageRequested = true
        self.url = url
        error = nil
        webView.load(URLRequest(url: url))
    }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let target = action.request.url else { decisionHandler(.cancel); return }
        let internalDocument = target.scheme == "blob" ||
            (target.scheme == "data" && action.shouldPerformDownload)
        if !Self.isWebURL(target) && target.absoluteString != "about:blank" && !internalDocument {
            // External application links require an explicit user click; redirected schemes never launch apps.
            if action.navigationType == .linkActivated,
               ["mailto", "tel"].contains(target.scheme?.lowercased() ?? "") {
                NSWorkspace.shared.open(target)
            }
            decisionHandler(.cancel)
            return
        }
        if action.shouldPerformDownload {
            // Start through WebKit's download API so the request retains this browser's cookies/TLS policy.
            // Cancelling navigation also keeps the portal result page in place while the file is saved.
            decisionHandler(.cancel)
            webView.startDownload(using: action.request) { [weak self] download in
                self?.retain(download)
            }
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(response.canShowMIMEType ? .allow : .download)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loading = true; error = nil
    }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) { updateNavigation() }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { loading = false; updateNavigation() }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { failed(error) }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { failed(error) }
    private func failed(_ error: Error) {
        loading = false
        if (error as NSError).code != NSURLErrorCancelled { self.error = error.localizedDescription }
        updateNavigation()
    }
    private func updateNavigation() {
        url = webView.url
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if action.targetFrame == nil, let url = action.request.url, Self.isWebURL(url) {
            webView.load(action.request)
        }
        return nil
    }

    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = parameters.allowsDirectories
        panel.allowsMultipleSelection = parameters.allowsMultipleSelection
        let completion: (NSApplication.ModalResponse) -> Void = { response in
            completionHandler(response == .OK ? panel.urls : nil)
        }
        if let window = self.webView.window { panel.beginSheetModal(for: window, completionHandler: completion) }
        else { panel.begin(completionHandler: completion) }
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        retain(download)
    }
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        retain(download)
    }
    private func retain(_ download: WKDownload) {
        downloads[ObjectIdentifier(download)] = download
        download.delegate = self
        loading = false
    }
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                  suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let panel = NSSavePanel()
        var filename = URL(fileURLWithPath: suggestedFilename).lastPathComponent
        if URL(fileURLWithPath: filename).pathExtension.isEmpty,
           let mime = response.mimeType, let ext = UTType(mimeType: mime)?.preferredFilenameExtension {
            filename += "." + ext
        }
        panel.nameFieldStringValue = filename
        let completion: (NSApplication.ModalResponse) -> Void = { result in
            completionHandler(result == .OK ? panel.url : nil)
        }
        if let window = webView.window { panel.beginSheetModal(for: window, completionHandler: completion) }
        else { panel.begin(completionHandler: completion) }
    }
    func downloadDidFinish(_ download: WKDownload) {
        downloads.removeValue(forKey: ObjectIdentifier(download))
    }
    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        downloads.removeValue(forKey: ObjectIdentifier(download))
        failed(error)
    }
}

private struct MacPortalWebView: NSViewRepresentable {
    let browser: MacPortalBrowser
    func makeNSView(context: Context) -> WKWebView { browser.webView }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
