import Foundation
import WebKit

/// The browser follows the app preference, including its bundled-language fallback.
@MainActor
enum BrowserLocale {
    static var language: String {
        let preference = AppPreferencesStore.defaults.string(forKey: "appLanguage") ?? "system"
        let requested = preference == "system" ? Locale.preferredLanguages.first : preference
        let code = requested.map { String($0.prefix(2)).lowercased() } ?? "ro"
        if ["ro", "en", "ru"].contains(code) { return code }
        let fallback = Bundle.main.preferredLocalizations.first ?? "ro"
        return ["ro", "en", "ru"].contains(fallback) ? fallback : "ro"
    }

    private static let marker = "// eSemnBun browser locale\n"

    static func install(in configuration: WKWebViewConfiguration, language: String) {
        let controller = configuration.userContentController
        // History-only resets reuse the configuration. Replace our script without
        // accumulating old locales or removing scripts belonging to other features.
        let retained = controller.userScripts.filter { !$0.source.hasPrefix(marker) }
        controller.removeAllUserScripts()
        controller.addUserScript(WKUserScript(source: marker + BrowserLocaleScript.source(language: language),
                                             injectionTime: .atDocumentStart, forMainFrameOnly: false))
        retained.forEach(controller.addUserScript)
    }

    static func request(_ request: URLRequest, language: String) -> URLRequest {
        var request = request
        if ["https", "http"].contains(request.url?.scheme?.lowercased() ?? "") {
            request.setValue(language, forHTTPHeaderField: "Accept-Language")
        }
        return request
    }
}
