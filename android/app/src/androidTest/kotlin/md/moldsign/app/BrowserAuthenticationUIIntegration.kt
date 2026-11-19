package md.moldsign.app

import android.app.Instrumentation
import android.content.Intent
import android.os.Build
import androidx.lifecycle.ViewModelProvider
import kotlinx.coroutines.flow.MutableStateFlow
import md.moldsign.app.presentation.MainViewModel
import md.moldsign.core.CertificateSummary

/** Exercise the actual browser sheet with a fictional identity and no physical NFC capability. */
internal class BrowserAuthenticationUIIntegration(private val runner: Instrumentation) {
    fun run(): String {
        check(BuildConfig.DEBUG && Build.HARDWARE in setOf("ranchu", "goldfish")) { "Use a dedicated emulator" }
        val app = runner.targetContext.applicationContext as MoldSignApp
        check(!app.demoModeEnabled) { "Start from the normal app composition; the Debug intent supplies the isolated fixture" }
        val accessibility = runner.uiAutomation.serviceInfo
        accessibility.flags = accessibility.flags or android.accessibilityservice.AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
        runner.uiAutomation.serviceInfo = accessibility
        val ui = NativeJourneyDriver(runner)
        val disclosureState = FirstLaunchAutomation(runner)
        val activity = runner.startActivitySync(Intent(runner.targetContext, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            .putExtra("demo", "one").putExtra("demo_page", "browser").putExtra("store_capture", true)) as MainActivity
        try {
            lateinit var card: CertificateSummary
            runner.runOnMainSync {
                val container = app.container
                check(container.isDemo && !container.userDemoMode)
                card = checkNotNull(container.wallet.value.selectedCard?.certificate)
                val vm = ViewModelProvider(activity)[MainViewModel::class.java]
                // Duplicate metadata plus the active certificate must still render as one identity.
                val known = MainViewModel::class.java.getDeclaredField("_learnedCards").apply { isAccessible = true }
                @Suppress("UNCHECKED_CAST")
                (known.get(vm) as MutableStateFlow<List<CertificateSummary>>).value = listOf(card, card)
                vm.browserNfc.seed(card)
                // UI fixture only: an emulator has no NFC adapter. Signing remains blocked by isDemo.
                val method = vm.browserNfc.javaClass.getDeclaredField("method").apply { isAccessible = true }
                @Suppress("UNCHECKED_CAST")
                (method.get(vm.browserNfc) as MutableStateFlow<Boolean>).value = true
            }
            val authentication = activity.getString(R.string.browser_authentication_short)
            val disclosure = activity.getString(R.string.government_independence_title)
            ui.await("browser entry or first-launch notice") { ui.text(authentication) != null || ui.text(disclosure) != null }
            if (ui.text(disclosure) != null) {
                ui.clickTextAndAwait(activity.getString(R.string.government_notice_continue), "acknowledged first-launch notice") {
                    ui.text(authentication) != null
                }
            }
            ui.await("browser authentication entry") { ui.text(authentication) != null }
            ui.clickTextAndAwait(authentication, "known-card choices") { ui.text(activity.getString(R.string.browser_nfc_saved_cards)) != null }
            check(ui.textCount(card.commonName) == 1) { "A certificate must appear once: ${ui.describe()}" }
            check(ui.text("${activity.getString(R.string.card_serial)}: ${card.serialHex}") != null)
            ui.clickTextAndAwait(activity.getString(R.string.browser_nfc_reader), "reader method") { ui.text(card.commonName) == null }
            ui.clickTextAndAwait(activity.getString(R.string.action_close), "closed authentication sheet") { ui.text(authentication) != null }
            check(!app.container.browserNfc.enabled.value)
            check(app.container.consentBroker.pending.value == null && app.container.nfc.phase.value == null)
            return "PASS: browser-authentication. One row per certificate, a serial number, method switching and sheet dismissal passed without NFC or PIN entry."
        } finally {
            runner.runOnMainSync { activity.finish() }
            runner.waitForIdleSync()
            disclosureState.restore()
        }
    }
}
