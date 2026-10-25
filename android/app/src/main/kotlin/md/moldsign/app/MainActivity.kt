package md.moldsign.app

import android.content.Intent
import android.hardware.usb.UsbManager
import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.fragment.app.FragmentActivity
import md.moldsign.app.ui.MoldSignRoot
import md.moldsign.app.ui.theme.MoldSignTheme

/** FragmentActivity (not ComponentActivity) so PinVault can host a BiometricPrompt. */
class MainActivity : FragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        // A recreated activity (rotation, dark mode, locale) must not replay the launch intent.
        if (savedInstanceState == null) handleIntent(intent)
        setContent {
            MoldSignTheme {
                MoldSignRoot()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    /**
     * The reader was plugged in while we were launched by the USB_DEVICE_ATTACHED filter. Debug builds also
     * accept the demo extra (DemoMode, src/debug); release builds compile a no-op DemoMode.
     */
    private fun handleIntent(intent: Intent?) {
        val container = (application as MoldSignApp).container
        if (intent?.action == UsbManager.ACTION_USB_DEVICE_ATTACHED) container.readerMonitor.rescan()
        DemoMode.apply(container, intent)
    }
}
