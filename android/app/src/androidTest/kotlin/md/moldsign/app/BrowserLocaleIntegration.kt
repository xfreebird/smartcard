package md.moldsign.app

import android.app.Instrumentation
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import md.moldsign.app.ui.screens.BrowserLocaleScript
import org.json.JSONObject
import org.json.JSONTokener
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/** Real WebView regression checks using synthetic portal HTML; no login or card required. */
internal class BrowserLocaleIntegration(private val runner: Instrumentation) {
    private val html = """<!doctype html><html><body>Locale fixture<script>
        window.atBoot = {language:navigator.language, languages:navigator.languages,
          state:JSON.parse(localStorage.getItem('vuex') || '{}')};
        </script></body></html>"""
    private lateinit var web: WebView

    fun run(): String {
        for (language in listOf("en", "ro", "ru")) {
            runner.runOnMainSync {
                check(WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT)) {
                    "The native document-start test requires an updated WebView provider"
                }
                web = WebView(runner.targetContext).apply {
                    settings.javaScriptEnabled = true
                    settings.domStorageEnabled = true
                    WebViewCompat.addDocumentStartJavaScript(this,
                        BrowserLocaleScript.source(language), setOf("*"))
                }
            }
            try {
                load()
                checkBoot(language)
                evaluate("""localStorage.setItem('vuex', JSON.stringify({
                    language:{culture:'ro',other:42}, auth:{session:'fixture'}})); true""")
                load()
                val state = checkBoot(language).getJSONObject("state")
                check(state.getJSONObject("auth").getString("session") == "fixture")
                check(state.getJSONObject("language").getInt("other") == 42)
                load("https://example.com/")
                check(evaluate("localStorage.getItem('vuex') === null") == "true")
            } finally { runner.runOnMainSync { web.destroy() } }
        }
        // Exercise the legacy-provider path without document-start injection.
        runner.runOnMainSync {
            web = WebView(runner.targetContext).apply {
                settings.javaScriptEnabled = true
                settings.domStorageEnabled = true
            }
        }
        try {
            load()
            evaluate("localStorage.setItem('vuex', JSON.stringify({language:{culture:'ro'}})); true")
            check(evaluate(BrowserLocaleScript.source("en")) == "true")
            load()
            val state = JSONObject(JSONTokener(evaluate("JSON.stringify(window.atBoot)")).nextValue() as String)
                .getJSONObject("state")
            check(state.getJSONObject("language").getString("culture") == "en")
            check(evaluate(BrowserLocaleScript.source("en")) == "false") // No reload loop.
        } finally { runner.runOnMainSync { web.destroy() } }
        return "PASS: WebView EN/RO/RU before first page script; persisted state; origin isolation; legacy fallback idempotence"
    }

    private fun load(url: String = "https://msign.gov.md/") {
        val done = CountDownLatch(1)
        runner.runOnMainSync {
            web.webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView, url: String) { done.countDown() }
            }
            web.loadDataWithBaseURL(url, html, "text/html", "UTF-8", null)
        }
        check(done.await(30, TimeUnit.SECONDS)) { "Timed out loading locale fixture" }
    }

    private fun evaluate(source: String): String {
        val done = CountDownLatch(1)
        var result = ""
        runner.runOnMainSync {
            web.evaluateJavascript(source) { result = it; done.countDown() }
        }
        check(done.await(15, TimeUnit.SECONDS)) { "Timed out evaluating locale fixture" }
        return result
    }

    private fun checkBoot(language: String): JSONObject {
        val boot = JSONObject(JSONTokener(evaluate("JSON.stringify(window.atBoot)")).nextValue() as String)
        check(boot.getString("language") == language) { "Browser locale at first script: $boot" }
        check(boot.getJSONObject("state").getJSONObject("language").getString("culture") == language) {
            "MSign locale at first script: $boot"
        }
        return boot
    }
}
