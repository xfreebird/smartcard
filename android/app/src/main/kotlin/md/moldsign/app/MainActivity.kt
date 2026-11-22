package md.moldsign.app

import md.moldsign.app.presentation.MainViewModel

import android.content.Intent
import android.content.res.Configuration
import android.content.res.Resources
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.remember
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.core.os.LocaleListCompat
import androidx.compose.foundation.isSystemInDarkTheme
import android.hardware.usb.UsbManager
import android.net.Uri
import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.mutableStateOf
import androidx.core.view.WindowCompat
import androidx.activity.viewModels
import androidx.core.content.IntentCompat
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AppCompatDelegate
import md.moldsign.app.ui.MoldSignRoot
import md.moldsign.app.ui.theme.MoldSignTheme

/** AppCompat also supplies FragmentActivity support for the biometric PIN prompt. */
class MainActivity : AppCompatActivity() {
    /** The same instance MoldSignRoot gets from `viewModel()` (activity scope). */
    private val viewModel: MainViewModel by viewModels()
    private var demoPage by mutableStateOf<String?>(null)
    private var demoGeneration by mutableStateOf(0)

    fun changeDemoMode(enabled: Boolean) {
        if (viewModel.working.value) return
        if ((application as MoldSignApp).changeDemoMode(enabled)) {
            // A new task gives Navigation/Compose a fresh, lifecycle-owned ViewModelStore.
            // Clearing a live store before disposing its NavHost can otherwise crash during recomposition.
            startActivity(Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK))
            finish()
        }
    }

    val appTheme: String
        get() = getSharedPreferences("settings", MODE_PRIVATE).getString("app_theme", "system") ?: "system"

    var themePreference by mutableStateOf("system")
        private set
    private var languagePreference by mutableStateOf("system")

    fun changeAppLanguage(value: String) {
        if (value !in setOf("system", "ro", "en", "ru")) return
        languagePreference = value
        getSharedPreferences("settings", MODE_PRIVATE).edit().putString("widget_language", value).apply()
        AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(if (value == "system") "" else value))
    }

    fun changeAppTheme(value: String) {
        if (value !in setOf("system", "light", "dark")) return
        getSharedPreferences("settings", MODE_PRIVATE).edit().putString("app_theme", value).apply()
        themePreference = value
        delegate.localNightMode = nightMode(value)
    }

    private fun nightMode(value: String): Int = when (value) {
        "light" -> AppCompatDelegate.MODE_NIGHT_NO
        "dark" -> AppCompatDelegate.MODE_NIGHT_YES
        else -> AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        delegate.localNightMode = nightMode(appTheme)
        super.onCreate(savedInstanceState)
        themePreference = appTheme
        languagePreference = AppCompatDelegate.getApplicationLocales().get(0)?.language ?: "system"
        // The launch window is cosmetic; the running activity keeps its regular theme.
        setTheme(R.style.Theme_MoldSign)
        // Keep transparent bars/cutout policy in API-qualified themes. Activity's convenience
        // helper still emits deprecated color setters and SHORT_EDGES into the release DEX.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        // Let Android dismiss its launch window; a custom exit overlay can outlive a cancelled animation.
        // A recreated activity (rotation, dark mode, locale) must not replay the launch intent.
        if (savedInstanceState == null) handleIntent(intent)
        else if (DemoMode.screenshotCapture(intent)) {
            // Retain the isolated fixture destination through theme/rotation recreation without
            // replaying imports, shortcuts or the fictional consent request.
            demoPage = intent.getStringExtra("demo_page")
        }
        setContent {
            val configuration = LocalConfiguration.current
            val localizedConfiguration = remember(configuration, languagePreference) {
                Configuration(configuration).apply {
                    setLocales(if (languagePreference == "system") Resources.getSystem().configuration.locales
                        else android.os.LocaleList.forLanguageTags(languagePreference))
                }
            }
            val localizedContext = remember(localizedConfiguration) {
                android.view.ContextThemeWrapper(this@MainActivity, R.style.Theme_MoldSign).apply {
                    applyOverrideConfiguration(localizedConfiguration)
                }
            }
            val darkTheme = when (themePreference) {
                "light" -> false
                "dark" -> true
                else -> isSystemInDarkTheme()
            }
            SideEffect {
                WindowCompat.getInsetsController(window, window.decorView).apply {
                    isAppearanceLightStatusBars = !darkTheme
                    isAppearanceLightNavigationBars = !darkTheme
                }
            }
            CompositionLocalProvider(LocalContext provides localizedContext, LocalConfiguration provides localizedConfiguration) {
                MoldSignTheme(darkTheme = darkTheme) {
                    // Each screenshot intent gets fresh navigation/scroll/dialog state without a process restart.
                    // The release implementation never enables this isolated fixture key.
                    androidx.compose.runtime.key(if (DemoMode.screenshotCapture(intent)) demoGeneration else 0) {
                        MoldSignRoot(demoPage = demoPage, demoGeneration = demoGeneration)
                    }
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        (application as MoldSignApp).container.nfc.resumed(this)
    }

    override fun onPause() {
        (application as MoldSignApp).container.nfc.paused(this)
        super.onPause()
    }

    override fun onStart() {
        super.onStart()
        (application as MoldSignApp).container.inForeground = true
        md.moldsign.app.widget.DocumentsWidget.refresh(this)
    }

    override fun onStop() {
        (application as MoldSignApp).container.inForeground = false
        md.moldsign.app.widget.DocumentsWidget.refresh(this)
        super.onStop()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    /**
     * The reader was plugged in while we were launched by the USB_DEVICE_ATTACHED filter, or files were shared to
     * "Semnează" (SEND / SEND_MULTIPLE). Debug builds also accept the demo extra (DemoMode, src/debug); release
     * builds compile a no-op DemoMode.
     */
    private fun handleIntent(intent: Intent?) {
        val container = (application as MoldSignApp).container
        if (intent?.action == UsbManager.ACTION_USB_DEVICE_ATTACHED) container.readerMonitor.rescan()
        AppShortcuts.destination(intent)?.let { destination ->
            viewModel.receiveShortcut(destination, if (destination == AppShortcuts.Destination.Documents)
                intent?.getStringExtra(md.moldsign.app.widget.DocumentsWidget.DOCUMENT_ID) else null)
        }
        sharedUris(intent).takeIf { it.isNotEmpty() }?.let(viewModel::receiveShared)
        DemoMode.apply(container, intent, viewModel)
        if (intent?.hasExtra("demo") == true) {
            demoPage = intent.getStringExtra("demo_page")
            demoGeneration++
        }
    }

    private fun sharedUris(intent: Intent?): List<Uri> = when (intent?.action) {
        Intent.ACTION_SEND -> listOfNotNull(IntentCompat.getParcelableExtra(intent, Intent.EXTRA_STREAM, Uri::class.java))
        Intent.ACTION_SEND_MULTIPLE -> IntentCompat.getParcelableArrayListExtra(intent, Intent.EXTRA_STREAM, Uri::class.java).orEmpty()
        else -> emptyList()
    }
}
