import Foundation
import WebKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

@MainActor final class LocaleProbe: NSObject, WKNavigationDelegate {
    var web: WKWebView!
    var continuation: CheckedContinuation<Void, Error>?
    var results: [[String: Any]] = []
    let html = """
    <!doctype html><html><body>Locale fixture<script>
    window.atBoot = {language:navigator.language, languages:navigator.languages,
      state:JSON.parse(localStorage.getItem('vuex') || '{}')};
    </script></body></html>
    """

    func load(_ url: String = "https://msign.gov.md/") async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            web.loadHTMLString(html, baseURL: URL(string: url))
        }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        continuation?.resume(); continuation = nil
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error); continuation = nil
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error); continuation = nil
    }
    func js(_ source: String) async throws -> Any {
        try await web.evaluateJavaScript(source) as Any
    }
    func check(_ condition: Bool, _ message: String) throws {
        if !condition { throw NSError(domain: "LocaleProbe", code: 1, userInfo: [NSLocalizedDescriptionKey:message]) }
    }
    func run() async {
        do {
            if let expected = ProcessInfo.processInfo.environment["MSIGN_EXPECTED_SYSTEM_LANGUAGE"] {
                AppPreferencesStore.defaults.set("system", forKey: "appLanguage")
                let actual = BrowserLocale.language
                try check(actual == expected, "System language: expected " + expected + ", actual " + actual)
                finish(["status":"PASS", "systemLanguage":actual, "preferredLanguages":Locale.preferredLanguages])
                return
            }
            for language in ["en", "ro", "ru"] {
                AppPreferencesStore.defaults.set(language, forKey: "appLanguage")
                try check(BrowserLocale.language == language, "App language resolver: " + language)
                let configuration = WKWebViewConfiguration()
                configuration.websiteDataStore = .nonPersistent()
                BrowserLocale.install(in: configuration, language: BrowserLocale.language)
                web = WKWebView(frame: CGRect(x: 0,y: 0,width: 700,height: 600), configuration: configuration)
                web.navigationDelegate = self
                try await load()
                var boot = try await js("window.atBoot") as! [String:Any]
                try check(boot["language"] as? String == language, "navigator first script: " + language)
                var state = boot["state"] as! [String:Any]
                try check((state["language"] as? [String:Any])?["culture"] as? String == language, "MSign first script: " + language)
                _ = try await js("localStorage.setItem('vuex',JSON.stringify({language:{culture:'ro',other:42},auth:{session:'fixture'}})); true")
                try await load()
                boot = try await js("window.atBoot") as! [String:Any]
                state = boot["state"] as! [String:Any]
                try check((state["language"] as? [String:Any])?["culture"] as? String == language, "stored culture: " + language)
                try check((state["auth"] as? [String:Any])?["session"] as? String == "fixture", "preserve fixture state")
                BrowserLocale.install(in: web.configuration, language: "ru")
                BrowserLocale.install(in: web.configuration, language: language)
                try check(web.configuration.userContentController.userScripts.count == 1, "duplicate scripts after reset")
                try await load()
                try await load("https://example.com/")
                let untouched = try await js("localStorage.getItem('vuex') === null") as! Bool
                try check(untouched, "other origin storage")
                var request = URLRequest(url: URL(string:"https://mpass.gov.md/fixture")!)
                request.httpMethod = "POST"; request.httpBody = Data("fixture=1".utf8)
                let localized = BrowserLocale.request(request,language:language)
                try check(localized.httpMethod == "POST" && localized.httpBody == request.httpBody, "POST preserved")
                try check(localized.value(forHTTPHeaderField:"Accept-Language") == language, "request header")
                results.append(["language":language,"firstScript":true,"persistedState":true,"reset":true,"originIsolation":true,"postPreserved":true])
                web.stopLoading(); web.navigationDelegate = nil; web = nil
            }
            finish(["status":"PASS","cases":results])
        } catch { finish(["status":"FAIL","error":String(describing:error),"cases":results]) }
    }
    func finish(_ result: [String:Any]) {
        let data = try! JSONSerialization.data(withJSONObject:result, options:[.prettyPrinted,.sortedKeys])
        let root = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0]
        try? FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        try! data.write(to:root.appendingPathComponent("browser-locale-result.json"))
        print(String(data:data,encoding:.utf8)!)
        #if os(macOS)
        NSApplication.shared.terminate(nil)
        #endif
    }
}

#if os(macOS)
@main struct Main {
    @MainActor static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let probe = LocaleProbe()
        Task { await probe.run() }
        app.run()
        withExtendedLifetime(probe) {}
    }
}
#else
@main final class App: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var probe = LocaleProbe()
    func application(_ app: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey:Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()
        Task { await probe.run() }
        return true
    }
}
#endif
