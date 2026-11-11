package md.moldsign.app

import android.app.Instrumentation
import android.content.Context
import android.content.Intent

/** Exercises real disclosure controls while preserving the emulator's original acknowledgement. */
internal class FirstLaunchAutomation(private val runner: Instrumentation) {
    private val preferences = runner.targetContext.getSharedPreferences("public_information", Context.MODE_PRIVATE)
    private val key = "independence_notice_v1"
    private val hadAcknowledgement = preferences.contains(key)
    private val originalAcknowledgement = preferences.getBoolean(key, false)
    private val ui = NativeJourneyDriver(runner)

    fun run(): String {
        check(preferences.edit().remove(key).commit())
        repeat(2) { launch ->
            val activity = runner.startActivitySync(Intent(runner.targetContext, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                .putExtra("demo", "verify-valid").putExtra("demo_page", "verify").putExtra("store_capture", true))
            try {
                val title = activity.getString(R.string.government_independence_title)
                if (launch == 0) {
                    ui.await("first-launch disclosure") { ui.text(title) != null }
                    ui.clickText(activity.getString(R.string.government_notice_continue))
                }
                ui.await("verification after disclosure") { ui.text(activity.getString(R.string.verdict_valid)) != null }
                runner.waitForIdleSync()
                check(ui.text(title) == null) { "Acknowledged disclosure reappeared" }
                check(preferences.getBoolean(key, false)) { "Disclosure acknowledgement was not retained" }
            } finally {
                runner.runOnMainSync { activity.finish() }
                runner.waitForIdleSync()
            }
        }
        return "first-launch-disclosure:pass"
    }

    fun restore() {
        val edit = preferences.edit()
        if (hadAcknowledgement) edit.putBoolean(key, originalAcknowledgement) else edit.remove(key)
        check(edit.commit())
    }
}
