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
        handleIntent(intent)
        setContent {
            MoldSignTheme {
                MoldSignRoot()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    /** The reader was plugged in while we were launched by the USB_DEVICE_ATTACHED filter. */
    private fun handleIntent(intent: Intent?) {
        if (intent?.action == UsbManager.ACTION_USB_DEVICE_ATTACHED) {
            (application as MoldSignApp).container.readerMonitor.rescan()
        }
    }
}
