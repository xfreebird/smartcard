package md.moldsign.app

import md.moldsign.app.presentation.MainViewModel

import android.content.Intent
import android.hardware.usb.UsbManager
import android.net.Uri
import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.runtime.mutableStateOf
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.core.content.IntentCompat
import androidx.fragment.app.FragmentActivity
import md.moldsign.app.ui.MoldSignRoot
import md.moldsign.app.ui.theme.MoldSignTheme

/** FragmentActivity (not ComponentActivity) so PinVault can host a BiometricPrompt. */
class MainActivity : FragmentActivity() {
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

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        // The launch window is cosmetic; the running activity keeps its regular theme.
        setTheme(R.style.Theme_MoldSign)
        if (savedInstanceState == null && android.os.Build.VERSION.SDK_INT >= 31) {
            configureLaunchTransition()
        }
        // A recreated activity (rotation, dark mode, locale) must not replay the launch intent.
        if (savedInstanceState == null) handleIntent(intent)
        setContent {
            MoldSignTheme {
                MoldSignRoot(demoPage = demoPage, demoGeneration = demoGeneration)
            }
        }
    }

    @androidx.annotation.RequiresApi(31)
    private fun configureLaunchTransition() {
        splashScreen.setOnExitAnimationListener { splash ->
            // Reuse the system splash surface: no second activity or startup timer.
            splash.removeAllViews()
            splash.setBackgroundResource(R.drawable.launch_gradient)
            val artwork = android.widget.ImageView(this).apply {
                setImageResource(R.drawable.launch_branding)
                scaleType = android.widget.ImageView.ScaleType.FIT_CENTER
                importantForAccessibility = android.view.View.IMPORTANT_FOR_ACCESSIBILITY_NO
            }
            val density = resources.displayMetrics.density
            splash.addView(artwork, android.widget.FrameLayout.LayoutParams(
                (160 * density).toInt(), (220 * density).toInt(), android.view.Gravity.CENTER))
            splash.animate().alpha(0f)
                .setDuration(if (android.animation.ValueAnimator.areAnimatorsEnabled()) 350 else 0)
                .withEndAction { splash.remove() }.start()
        }
    }

    override fun onStart() {
        super.onStart()
        (application as MoldSignApp).container.inForeground = true
    }

    override fun onStop() {
        (application as MoldSignApp).container.inForeground = false
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
