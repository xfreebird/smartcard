import SwiftUI
import WebKit
import AppKit

/// A persistent portal session hosted in the app, sharing the normal consent-protected bridge.
struct MacBrowserScreen: View {
    @Environment(AppModel.self) private var model
    let browser: MacPortalBrowser
    @State private var address = "https://msign.gov.md/#/"
    @State private var invalidAddress = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button { browser.webView.goBack() } label: { Image(systemName: "chevron.left") }
                    .help(L10n.text(.ui_back)).accessibilityLabel(L10n.text(.ui_back)).disabled(model.demoMode || !browser.canGoBack)
                Button { browser.webView.goForward() } label: { Image(systemName: "chevron.right") }
                    .help(L10n.text(.ui_forward)).accessibilityLabel(L10n.text(.ui_forward)).disabled(model.demoMode || !browser.canGoForward)
                TextField(L10n.text(.ui_https_example_md), text: $address)
                    .textFieldStyle(.roundedBorder).onSubmit(openAddress)
                    .disabled(model.demoMode)
                Button(action: openAddress) { Image(systemName: "arrow.right") }
                    .help(L10n.text(.ui_open)).accessibilityLabel(L10n.text(.ui_open)).disabled(model.demoMode)
                Button { browser.webView.reload() } label: { Image(systemName: "arrow.clockwise") }
                    .help(L10n.text(.ui_reload)).accessibilityLabel(L10n.text(.ui_reload)).disabled(model.demoMode)
                if browser.loading { ProgressView().controlSize(.small) }
            }
            .padding(12).background(.bar)
            HStack(spacing: 8) {
                Circle().fill(model.bridgeState == .running ? Theme.success : Theme.warning)
                    .frame(width: 8, height: 8)
                Text(L10n.text(model.bridgeState == .running ? .ui_browser_connection_on : .ui_browser_connection_off))
                    .font(.caption)
                Spacer()
                if !model.bridgeEnabled && !model.demoMode {
                    Button(L10n.text(.ui_browser_connection_on)) { model.bridgeEnabled = true }
                }
            }.padding(.horizontal, 12).padding(.vertical, 8)
            if invalidAddress {
                Text(L10n.text(.ui_enter_a_valid_web_address_https))
                    .foregroundStyle(Theme.warning).font(.caption).padding(8)
            }
            if model.demoMode {
                ContentUnavailableView(L10n.text(.demo_banner), systemImage: "sparkles",
                                       description: Text(L10n.text(.demo_settings_description)))
            } else {
                MacPortalWebView(browser: browser)
            }
            if let error = browser.error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption).padding(10).frame(maxWidth: .infinity, alignment: .leading).background(.bar)
            }
        }
        .navigationTitle(L10n.text(.ui_browser))
        .onChange(of: browser.url) { _, url in if let url { address = url.absoluteString } }
        .onChange(of: model.browserURL) { _, url in if !model.demoMode, let url { browser.open(url) } }
        .onChange(of: model.demoMode) { _, demo in
            browser.webView.stopLoading()
            browser.clearSessionNavigation()
            if !demo { openInitialPage() }
        }
        .onAppear { openInitialPage() }
    }

    private func openInitialPage() {
        guard !model.demoMode else { return }
        if model.bridgeEnabled { model.startBridge() }
        if browser.url == nil {
            #if DEBUG
            let initial = ProcessInfo.processInfo.environment["MSIGN_BROWSER_URL"].flatMap(URL.init(string:))
            #else
            let initial: URL? = nil
            #endif
            browser.open(model.browserURL ?? initial ?? URL(string: "https://msign.gov.md/#/")!)
        }
    }

    private func openAddress() {
        guard !model.demoMode else { return }
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
    let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    var url: URL?
    var canGoBack = false
    var canGoForward = false
    var loading = false
    var error: String?

    override init() {
        super.init()
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
    }

    static func isWebURL(_ url: URL) -> Bool {
        ["https", "http"].contains(url.scheme?.lowercased() ?? "") && url.host?.isEmpty == false
    }

    func clearSessionNavigation() {
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
        url = nil
        canGoBack = false
        canGoForward = false
        error = nil
    }

    func open(_ url: URL) {
        guard Self.isWebURL(url) else { return }
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
        decisionHandler(action.shouldPerformDownload ? .download : .allow)
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
        panel.begin { response in completionHandler(response == .OK ? panel.urls : nil) }
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                  suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = URL(fileURLWithPath: suggestedFilename).lastPathComponent
        panel.begin { result in completionHandler(result == .OK ? panel.url : nil) }
    }
    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) { failed(error) }
}

private struct MacPortalWebView: NSViewRepresentable {
    let browser: MacPortalBrowser
    func makeNSView(context: Context) -> WKWebView { browser.webView }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
