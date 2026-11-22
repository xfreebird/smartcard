package md.moldsign.app

import android.app.Instrumentation
import android.app.UiAutomation
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Rect
import android.os.Build
import android.view.accessibility.AccessibilityWindowInfo
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import java.io.File

/** Real window/accessibility bounds and IME interaction, using fictional fixtures on an emulator. */
internal class EdgeToEdgeUIIntegration(private val runner: Instrumentation) {
    private val ui = NativeJourneyDriver(runner)

    fun run(caseName: String): String {
        check(BuildConfig.DEBUG && Build.HARDWARE in setOf("ranchu", "goldfish")) { "Dedicated emulator required" }
        require(caseName.matches(Regex("[a-zA-Z0-9-]+")))
        val service = runner.uiAutomation.serviceInfo
        service.flags = service.flags or android.accessibilityservice.AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
            android.accessibilityservice.AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        runner.uiAutomation.serviceInfo = service
        val preferences = runner.targetContext.getSharedPreferences("settings", Context.MODE_PRIVATE)
        val previousTheme = preferences.getString("app_theme", null)
        val previousNightMode = AppCompatDelegate.getDefaultNightMode()
        val disclosure = FirstLaunchAutomation(runner)
        val results = mutableListOf<String>()
        val keyboardPolicy = shell("settings get secure show_ime_with_hard_keyboard")
        try {
            shell("settings put secure show_ime_with_hard_keyboard 1")
            for (theme in listOf("light", "dark")) {
                check(preferences.edit().putString("app_theme", theme).commit())
                // Apply before attachBaseContext, as a normal recreation does after the app's
                // theme control. Changing only the preference mid-process races AppCompat recreation.
                runner.runOnMainSync {
                    AppCompatDelegate.setDefaultNightMode(if (theme == "dark") AppCompatDelegate.MODE_NIGHT_YES else AppCompatDelegate.MODE_NIGHT_NO)
                }
                val activity = launch("verify-valid", "verify", caseName)
                try {
                    ui.await("workspace or disclosure") {
                        ui.id("verify.clearResults") != null || ui.text(activity.getString(R.string.government_independence_title)) != null
                    }
                    if (ui.text(activity.getString(R.string.government_independence_title)) != null) {
                        ui.clickText(activity.getString(R.string.government_notice_continue))
                    }
                    ui.await("verification workspace") { ui.id("verify.clearResults") != null && ui.id("nav.verify") != null }
                    runner.waitForIdleSync()
                    var safe = Rect()
                    var window = Rect()
                    onMain {
                        val content = activity.findViewById<android.view.View>(android.R.id.content)
                        val rootInsets = checkNotNull(ViewCompat.getRootWindowInsets(content))
                        if (caseName.startsWith("phone-")) check(rootInsets.displayCutout != null) { "Requested display cutout is missing" }
                        val insets = rootInsets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout())
                        val decor = activity.window.decorView
                        window = Rect(0, 0, decor.width, decor.height)
                        if (caseName.endsWith("landscape")) check(window.width() > window.height()) { "Landscape rotation did not take effect: $window" }
                        if (caseName.endsWith("portrait")) check(window.height() > window.width()) { "Portrait rotation did not take effect: $window" }
                        safe = Rect(insets.left, insets.top, decor.width - insets.right, decor.height - insets.bottom)
                        val icons = WindowCompat.getInsetsController(activity.window, decor)
                        check(icons.isAppearanceLightStatusBars == (theme == "light")) { "Status icon theme mismatch" }
                        if (Build.VERSION.SDK_INT >= 27) check(icons.isAppearanceLightNavigationBars == (theme == "light")) { "Navigation icon theme mismatch" }
                        if (Build.VERSION.SDK_INT >= 30) check(activity.window.attributes.layoutInDisplayCutoutMode == 3) { "Cutout must use ALWAYS" }
                    }
                    val root = bounds("app.window")
                    check(root == window) { "Workspace is not edge-to-edge: root=$root window=$window" }
                    for (id in listOf("verify.clearResults", "nav.verify")) {
                        check(safe.contains(bounds(id))) { "$id is obscured: bounds=${bounds(id)} safe=$safe" }
                    }
                    capture("$caseName-$theme-workspace")
                } finally { finish(activity) }

                // The production PIN dialog requests a keyboard, but this test never enters a PIN.
                val pin = launch("pin", "sign", caseName)
                try {
                    ui.await("PIN field") { ui.id("pin.field") != null }
                    ui.clickId("pin.field")
                    var keyboard = Rect()
                    ui.await("visible keyboard") {
                        val ime = runner.uiAutomation.windows.firstOrNull { it.type == AccessibilityWindowInfo.TYPE_INPUT_METHOD }
                        ime?.getBoundsInScreen(keyboard)
                        ime != null && keyboard.height() > 0
                    }
                    ui.await("PIN actions above keyboard") {
                        val actions = ui.id("pin.actions") ?: return@await false
                        val rect = Rect().also(actions::getBoundsInScreen)
                        rect.bottom <= keyboard.top && rect.height() > 0
                    }
                    check(bounds("pin.confirm").bottom <= keyboard.top)
                    check(bounds("pin.cancel").bottom <= keyboard.top)
                    capture("$caseName-$theme-keyboard")
                    ui.clickIdAndAwait("pin.cancel", "dismissed PIN") { ui.id("pin.dialog") == null }
                } finally { finish(pin) }
                results += "$caseName-$theme:pass"
            }
        } finally {
            val edit = preferences.edit()
            if (previousTheme == null) edit.remove("app_theme") else edit.putString("app_theme", previousTheme)
            check(edit.commit())
            runner.runOnMainSync { AppCompatDelegate.setDefaultNightMode(previousNightMode) }
            disclosure.restore()
            shell(if (keyboardPolicy in setOf("0", "1")) "settings put secure show_ime_with_hard_keyboard $keyboardPolicy"
                else "settings delete secure show_ime_with_hard_keyboard")
        }
        return "PASS: edge-to-edge\n" + results.joinToString("\n")
    }

    private fun launch(scenario: String, page: String, caseName: String): MainActivity {
        val monitor = runner.addMonitor(MainActivity::class.java.name, null, false)
        try {
            runner.startActivitySync(Intent(runner.targetContext, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                .putExtra("demo", scenario).putExtra("demo_page", page).putExtra("store_capture", true))
            if (caseName.endsWith("portrait") || caseName.endsWith("landscape")) {
                check(runner.uiAutomation.setRotation(if (caseName.endsWith("landscape")) UiAutomation.ROTATION_FREEZE_90 else UiAutomation.ROTATION_FREEZE_0))
                ui.await("requested window orientation") {
                    val activity = monitor.lastActivity ?: return@await false
                    val decor = activity.window.decorView
                    !activity.isDestroyed && decor.width > 0 && decor.height > 0 &&
                        (decor.width > decor.height) == caseName.endsWith("landscape")
                }
            }
            runner.waitForIdleSync()
            runner.uiAutomation.waitForIdle(200, 5_000)
            return checkNotNull(monitor.lastActivity) as MainActivity
        } finally { runner.removeMonitor(monitor) }
    }

    private fun onMain(block: () -> Unit) {
        var failure: Throwable? = null
        runner.runOnMainSync { try { block() } catch (error: Throwable) { failure = error } }
        failure?.let { throw it }
    }

    private fun shell(command: String): String = android.os.ParcelFileDescriptor.AutoCloseInputStream(
        runner.uiAutomation.executeShellCommand(command),
    ).bufferedReader().use { it.readText().trim() }

    private fun finish(activity: MainActivity) {
        runner.runOnMainSync { activity.finish() }
        runner.waitForIdleSync()
        // onCleared cancels consent. Do not launch the next fixture until that cleanup finishes.
        ui.await("destroyed activity") { activity.isDestroyed }
    }

    private fun bounds(id: String) = Rect().also { checkNotNull(ui.id(id)) { "Missing $id" }.getBoundsInScreen(it) }

    private fun capture(name: String) {
        val bitmap = checkNotNull(runner.uiAutomation.takeScreenshot())
        try {
            val directory = File(runner.targetContext.cacheDir, "edge-to-edge").apply { mkdirs() }
            File(directory, "$name.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        } finally { bitmap.recycle() }
    }
}
