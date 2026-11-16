package md.moldsign.app

import android.app.Instrumentation
import android.content.Intent
import android.graphics.Rect
import android.os.Bundle
import android.view.Surface
import android.view.accessibility.AccessibilityNodeInfo
import androidx.lifecycle.ViewModelProvider
import md.moldsign.app.presentation.MainViewModel
import java.io.File

/** Separate test install only. Exercises PIN layout and cancellation; never submits a PIN or sends APDUs. */
internal class NfcPreparationIntegration(private val runner: Instrumentation) {
    fun run(): String {
        check(BuildConfig.DEBUG && runner.targetContext.packageName.endsWith(".nfctest"))
        val app = runner.targetContext.applicationContext as MoldSignApp
        check(!app.container.isDemo)
        val accessibility = runner.uiAutomation.serviceInfo
        accessibility.flags = accessibility.flags or android.accessibilityservice.AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
        runner.uiAutomation.serviceInfo = accessibility
        val ui = NativeJourneyDriver(runner)
        val results = mutableListOf<String>()
        try {
            for ((name, rotation) in listOf("portrait" to Surface.ROTATION_0, "landscape" to Surface.ROTATION_90)) {
                runner.uiAutomation.setRotation(rotation)
                val activity = runner.startActivitySync(Intent(runner.targetContext, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)) as MainActivity
                try {
                    ui.await("screen") { ui.id("sign.method") != null || ui.text(activity.getString(R.string.government_notice_continue)) != null }
                    if (ui.text(activity.getString(R.string.government_notice_continue)) != null)
                        ui.clickText(activity.getString(R.string.government_notice_continue))
                    ui.clickId("sign.method")
                    ui.clickId("sign.nfc")
                    lateinit var vm: MainViewModel
                    runner.runOnMainSync { vm = ViewModelProvider(activity)[MainViewModel::class.java] }
                    ui.await("NFC selection") { vm.signingMethod.value == MainViewModel.SigningMethod.NFC }
                    check(ui.id("sign.method")?.isEnabled == true)
                    val fixture = File(activity.cacheDir, "NFC-test-document.pdf")
                    fixture.writeBytes(md.moldsign.app.infrastructure.demo.DemoFixtures.samplePdf)
                    runner.runOnMainSync { vm.addForSigning(listOf(android.net.Uri.fromFile(fixture))) }
                    ui.await("document ready") { vm.signItems.value.size == 1 }
                    ui.clickId("sign.submit")
                    ui.await("PIN before NFC") { ui.id("pin.field") != null }
                    check(app.container.nfc.phase.value == null) { "Antenna enabled before PIN consent" }
                    // Fictional text is only used to check the button; Cancel is the only dispatched action.
                    check(ui.id("pin.field")!!.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT,
                        Bundle().apply { putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, "1234") }))
                    ui.await("PIN actions") { ui.id("pin.confirm")?.isEnabled == true }
                    runner.uiAutomation.waitForIdle(500, 5_000)
                    val confirm = Rect().also { ui.id("pin.confirm")!!.getBoundsInScreen(it) }
                    check(!confirm.isEmpty)
                    val screenshot = checkNotNull(runner.uiAutomation.takeScreenshot())
                    check(confirm.bottom <= screenshot.height && confirm.right <= screenshot.width)
                    File(activity.cacheDir, "nfc-ui-$name.png").outputStream().use {
                        screenshot.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it)
                    }
                    screenshot.recycle()
                    ui.clickId("pin.cancel")
                    ui.await("cancelled without NFC") { !vm.working.value && app.container.consentBroker.pending.value == null }
                    check(app.container.nfc.phase.value == null)
                    results += "$name: NFC choice, PIN-before-scan, keyboard actions and cancellation passed"
                } finally { runner.runOnMainSync { activity.finish() }; runner.waitForIdleSync() }
            }
        } finally { runner.uiAutomation.setRotation(android.app.UiAutomation.ROTATION_UNFREEZE) }
        return results.joinToString("\n")
    }
}
