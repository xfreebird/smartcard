package md.moldsign.app

import android.app.Instrumentation
import android.content.Intent
import android.os.Build
import md.moldsign.app.application.AppContainer
import md.moldsign.app.application.DocumentOutputStore
import md.moldsign.app.application.SignDocuments
import md.moldsign.app.infrastructure.demo.DemoDataProvider
import md.moldsign.core.Consent
import md.moldsign.core.ConsentResult

/** Native accessibility interactions. Run only on a dedicated emulator, never a working phone. */
internal class JourneyAutomation(private val runner: Instrumentation) {
    private val ui = NativeJourneyDriver(runner)
    fun run(): String {
        check(Build.FINGERPRINT.contains("generic") || Build.MODEL.contains("sdk", true) || Build.HARDWARE in listOf("ranchu", "goldfish")) {
            "A dedicated emulator is required"
        }
        check(BuildConfig.DEBUG) { "Debug build required" }
        val accessibility = runner.uiAutomation.serviceInfo
        accessibility.flags = accessibility.flags or android.accessibilityservice.AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
        runner.uiAutomation.serviceInfo = accessibility
        val app = runner.targetContext.applicationContext as MoldSignApp
        val originalDemo = app.demoModeEnabled
        val results = mutableListOf<String>()
        val firstLaunch = FirstLaunchAutomation(runner)
        runner.runOnMainSync { check(app.changeDemoMode(true)) }
        try {
            results += firstLaunch.run()
            for ((scenario, verdict) in listOf(
                "verify-valid" to R.string.verdict_valid,
                "verify-invalid" to R.string.verdict_invalid,
                "verify-unconfirmed" to R.string.verdict_unconfirmed,
                "verify-none" to R.string.verdict_none,
                "verify-xml-missing" to R.string.verdict_unconfirmed,
                "verify-xml-complete" to R.string.verdict_valid,
            )) {
                val activity = runner.startActivitySync(Intent(runner.targetContext, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                    .putExtra("demo", scenario).putExtra("demo_page", "verify").putExtra("store_capture", true))
                try {
                    val title = activity.getString(verdict)
                    ui.await(title) { ui.text(title) != null }
                    val clear = activity.getString(R.string.clear_results)
                    ui.await("navigation-bar clear action") { ui.id("verify.clearResults") != null }
                    val actionBounds = android.graphics.Rect().also { ui.id("verify.clearResults")!!.getBoundsInScreen(it) }
                    val titleBounds = android.graphics.Rect().also { ui.text(activity.getString(R.string.nav_verify))!!.getBoundsInScreen(it) }
                    check(kotlin.math.abs(actionBounds.centerY() - titleBounds.centerY()) <= 24 * activity.resources.displayMetrics.density) {
                        "Clear results must be beside the navigation-bar title"
                    }
                    ui.clickIdAndAwait("verify.clearResults", "cleared verdict") { ui.text(title) == null && ui.text(clear) == null }
                    check(ui.id("verify.pickFiles") != null)
                    check(ui.text(activity.getString(R.string.action_choose_document)) != null)
                    results += "$scenario:pass"
                } finally {
                    runner.runOnMainSync { activity.finish() }
                    runner.waitForIdleSync()
                }
            }
            for ((scenario, expected) in listOf(
                "noreader" to R.string.wallet_connect_title,
                "empty" to R.string.wallet_insert_title,
                "reading" to R.string.action_sign_with,
                "permission" to R.string.usb_permission_title,
            )) {
                val activity = runner.startActivitySync(Intent(runner.targetContext, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                    .putExtra("demo", scenario).putExtra("demo_page", "card").putExtra("store_capture", true))
                try {
                    val method = activity.getString(R.string.guided_method_caption)
                    ui.clickTextAndAwait(activity.getString(R.string.settings_card_reader), "Cards and readers sheet") { ui.text(method) != null }
                    ui.clickText(method)
                    val readerState = if (scenario == "reading") {
                        val card = app.container.status.value.wallet.cards.single()
                        check(card.isReading)
                        activity.getString(expected, card.readerName)
                    } else activity.getString(expected)
                    ui.clickTextAndAwait(activity.getString(R.string.guided_reader), "reader state $scenario") { ui.text(readerState) != null }
                    check(app.container.consentBroker.pending.value == null)
                    check(!app.container.signingService.progress.value.toString().contains("Signing"))
                    results += "$scenario:pass"
                } finally { runner.runOnMainSync { activity.finish() }; runner.waitForIdleSync() }
            }
            val activity = runner.startActivitySync(Intent(runner.targetContext, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                .putExtra("demo", "results").putExtra("demo_page", "sign").putExtra("store_capture", true))
            try {
                val clear = activity.getString(R.string.results_clear)
                ui.clickTextAndAwait(clear, "hidden completed results") { ui.text(clear) == null }
                check(app.container.consentBroker.pending.value == null)
                results += "hide-signing-results:pass"
            } finally { runner.runOnMainSync { activity.finish() }; runner.waitForIdleSync() }
            verifyDemoWorkflow(app)
            results += "demo-sign-storage-integration:pass"
            results += SigningWorkflowIntegration.run()
            results += ProtectionWorkflowIntegration.run()
            results += DocumentImportIntegration.run()
            results += MockWorkflowAutomation(runner, app).run()
        } finally {
            try { firstLaunch.restore() }
            finally { runner.runOnMainSync { check(app.changeDemoMode(originalDemo)) } }
        }
        return results.joinToString("\n")
    }

    private fun verifyDemoWorkflow(app: MoldSignApp) {
        val container = AppContainer(app, userDemoMode = true)
        val data = DemoDataProvider()
        val outputs = mutableListOf<ByteArray>()
        val events = mutableListOf<SignDocuments.Event>()
        val workflow = SignDocuments(container.signingService, data, DocumentOutputStore { _, _, bytes ->
            outputs += bytes.copyOf()
            android.net.Uri.parse("demo://output/${outputs.size}")
        })
        try {
            workflow.execute(data.inputs().map { md.moldsign.app.application.SignItem(it) }, "preview-1", "fixture",
                Consent { error("Demo must never ask for a PIN") }, events::add)
            check(outputs.size == 2)
            check(events.count { it is SignDocuments.Event.Saved } == 2)
            check(events.none { it is SignDocuments.Event.Failed })
            check(outputs.all { String(it).contains("DEMO ONLY - NOT SIGNED") })
            check(!container.busy.value)
        } finally { container.stop() }
    }

}
