package md.moldsign.app

import android.app.Activity
import android.app.Instrumentation
import android.content.Intent
import md.moldsign.app.application.AppContainer
import md.moldsign.app.infrastructure.demo.DemoSigningService
import md.moldsign.core.*
import java.util.concurrent.atomic.AtomicInteger

/** Drives the production UI; only hardware/signing services are replaced. No ViewModel commands are invoked. */
internal class MockWorkflowAutomation(private val runner: Instrumentation, private val app: MoldSignApp) {
    private val ui = NativeJourneyDriver(runner)
    fun run(): List<String> {
        val results = mutableListOf<String>()
        for ((scenario, successes, calls) in listOf(Triple("success", 2, 2), Triple("mixed", 1, 2), Triple("fatal", 0, 1))) {
            val signer = ScriptedSigner(scenario)
            install(signer)
            withActivity {
                val before = app.container.activity.signedDocuments.value.map { it.id }.toSet()
                ui.clickId("sign.submit")
                ui.await("scripted signing completes") { signer.calls.get() == calls && !app.container.busy.value }
                check(app.container.consentBroker.pending.value == null)
                check((app.container.activity.signedDocuments.value.map { it.id }.toSet() - before).size == successes)
                if (successes > 0) {
                    val output = if (scenario == "success") "DEMO-contract-NOT-SIGNED.pdf" else "DEMO-request-NOT-SIGNED.pdf"
                    ui.await("saved output on screen") { ui.text(output) != null }
                    val saved = app.container.activity.signedDocuments.value.filter { it.title.contains("NOT-SIGNED") }
                    check(saved.size >= successes)
                    val count = app.container.activity.signedDocuments.value.size
                    ui.clickIdAndAwait("sign.clearResults", "results hidden") { ui.text(output) == null }
                    check(app.container.activity.signedDocuments.value.size == count) { "Hiding results removed saved documents" }
                }
                if (scenario != "success") {
                    ui.await("failed input retained") { ui.text("DEMO-contract.pdf") != null }
                }
                check(signer.calls.get() == calls) { "Fatal failure retried" }
            }
            results += "mock-sign-$scenario:pass"
        }
        install(ScriptedSigner("success"))
        withActivity { activity ->
            // Choose a new format through the batch menu, then remove the queued inputs through that same menu.
            ui.clickText(activity.getString(R.string.batch_options))
            ui.clickText(activity.getString(R.string.format_xml))
            ui.await("XML format selected and menu dismissed") {
                ui.text(activity.getString(R.string.batch_options)) != null &&
                    ui.text(activity.getString(R.string.batch_remove)) == null &&
                    ui.text(activity.getString(R.string.format_xml)) != null
            }
            ui.clickText(activity.getString(R.string.batch_options))
            ui.clickText(activity.getString(R.string.batch_remove))
            ui.await("queue removed") { ui.id("sign.submit") == null }
            check(app.container.consentBroker.pending.value == null)
        }
        results += "mock-remove-batch:pass"
        install(ScriptedSigner("success"))
        withActivity(page = "activity", scenario = "cards") { activity ->
            ui.clickIdAndAwait("documents.historyTab", "history controls displayed") {
                ui.id("documents.clearHistory") != null
            }
            val saved = app.container.activity.signedDocuments.value.map { it.id }.toSet()
            check(saved.isNotEmpty())
            ui.clickId("documents.clearHistory")
            ui.clickIdAndAwait("documents.clearHistory.cancel", "history dialog dismissed") {
                ui.id("documents.clearHistory.cancel") == null
            }
            check(app.container.activity.entries.value.isNotEmpty())
            ui.clickId("documents.clearHistory")
            ui.clickId("documents.clearHistory.confirm")
            ui.await("history cleared") { app.container.activity.entries.value.isEmpty() }
            check(app.container.activity.signedDocuments.value.map { it.id }.toSet() == saved)
            ui.clickId("documents.savedTab")
            val savedTitle = app.container.activity.signedDocuments.value.first().title
            ui.reveal("saved library after history clear") { ui.text(savedTitle) }
            check(ui.text(activity.getString(R.string.saved_empty)) == null)
        }
        results += "mock-history-cancel-and-clear:pass"
        install(ScriptedSigner("success"))
        withActivity { activity ->
            ui.clickText(activity.getString(R.string.batch_options))
            ui.clickText(activity.getString(R.string.batch_stamp))
            ui.clickText(activity.getString(R.string.action_cancel))
            ui.await("stamp dismissed") { ui.text(activity.getString(R.string.stamp_save)) == null }
            ui.reveal("queue retained") { ui.text(activity.getString(R.string.batch_options)) }
            check(app.container.consentBroker.pending.value == null)
        }
        results += "mock-cancel-stamp:pass"
        for (scenario in listOf("pin", "pin-warning")) {
            install(ScriptedSigner("success"))
            withActivity(scenario = scenario) { activity ->
                ui.await("pending mock consent") { app.container.consentBroker.pending.value != null }
                ui.clickText(activity.getString(R.string.action_cancel))
                ui.await("consent cancelled") { app.container.consentBroker.pending.value == null }
                check(!app.container.busy.value)
            }
            results += "mock-cancel-$scenario:pass"
        }
        install(ScriptedSigner("success"))
        withActivity(page = "verify", scenario = "verify-valid") { activity ->
            ui.await("verification result before disclosure scrolling") {
                ui.text(activity.getString(R.string.verdict_valid)) != null
            }
            for ((toggle, content) in listOf("verify.certificateToggle" to "verify.certificateContents",
                                            "verify.technicalToggle" to "verify.technicalContents")) {
                ui.clickIdAndAwait(toggle, "expanded $toggle") {
                    ui.id(toggle)?.stateDescription?.toString() == activity.getString(R.string.state_expanded)
                }
                ui.reveal("expanded $content") { ui.id(content) }
                ui.revealUp(toggle) { ui.id(toggle) }
                ui.clickIdAndAwait(toggle, "collapsed $toggle") {
                    ui.id(toggle)?.stateDescription?.toString() == activity.getString(R.string.state_collapsed) && ui.id(content) == null
                }
            }
        }
        results += "mock-verification-disclosures:pass"
        return results
    }

    private fun install(signer: SigningService) {
        runner.runOnMainSync { app.installTestContainer(AppContainer(app, userDemoMode = true, demoSigningFactory = { signer })) }
    }
    private fun withActivity(page: String = "sign", scenario: String = "documents", action: (Activity) -> Unit) {
        val activity = runner.startActivitySync(Intent(runner.targetContext, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            .putExtra("demo", scenario).putExtra("demo_page", page).putExtra("store_capture", true)
            .putExtra("capture_expand", "none"))
        try { action(activity) }
        finally { runner.runOnMainSync { activity.finish() }; runner.waitForIdleSync() }
    }
    private class ScriptedSigner(private val scenario: String, private val base: SigningService = DemoSigningService()) : SigningService by base {
        val calls = AtomicInteger()
        override fun sign(input: Document, format: SignFormat, consent: Consent, requester: String?, reader: String?,
                          expectedCertificateSha1: String?, placement: PdfStampPlacement?): SignResult {
            val call = calls.incrementAndGet()
            if (call == 1 && scenario == "mixed") throw CardError.Format("Mock document failure")
            if (call == 1 && scenario == "fatal") throw CardError.PinBlocked()
            return base.sign(input, format, Consent { error("Mock must not ask for PIN") }, requester, reader, expectedCertificateSha1, placement)
        }
    }
}
