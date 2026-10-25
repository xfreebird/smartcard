package md.moldsign.transport.usb

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import androidx.core.content.ContextCompat
import androidx.core.content.IntentCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import md.moldsign.core.ApduTransport
import md.moldsign.core.CardError
import md.moldsign.core.ReaderState
import md.moldsign.core.TransportProvider

/**
 * Android ReaderMonitor (docs/09 §3.7): USB attach/detach broadcasts + the USB permission flow
 * (AND-03), then CCID GetSlotStatus polling for card insert/remove (AND-02).
 *
 * Exposes [state] for the StatusCard and a [transportProvider] for `CardSigningService`; while a
 * card session is open the state is [ReaderState.Busy] and polling pauses.
 */
class UsbReaderMonitor(
    context: Context,
    private val scope: CoroutineScope,
    private val pollIntervalMs: Long = 1_000,
) {
    private val appContext = context.applicationContext
    private val usbManager: UsbManager = appContext.getSystemService(UsbManager::class.java)

    private val _state = MutableStateFlow<ReaderState>(ReaderState.NoReader)
    val state: StateFlow<ReaderState> = _state.asStateFlow()

    @Volatile private var device: UsbDevice? = null
    @Volatile private var transport: CcidTransport? = null
    @Volatile private var sessionActive = false
    @Volatile private var holder: String? = null
    private var pollJob: Job? = null
    private var registered = false

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, intent: Intent) {
            val dev = IntentCompat.getParcelableExtra(intent, UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
            when (intent.action) {
                UsbManager.ACTION_USB_DEVICE_ATTACHED -> dev?.let(::onAttached)
                UsbManager.ACTION_USB_DEVICE_DETACHED -> dev?.let(::onDetached)
                ACTION_USB_PERMISSION -> {
                    val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                    if (dev != null) onPermissionResult(dev, granted)
                }
            }
        }
    }

    @Synchronized
    fun start() {
        if (registered) return
        val filter = IntentFilter().apply {
            addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
            addAction(ACTION_USB_PERMISSION)
        }
        // System USB broadcasts still reach a NOT_EXPORTED receiver; the permission result is our own PendingIntent.
        ContextCompat.registerReceiver(appContext, receiver, filter, ContextCompat.RECEIVER_NOT_EXPORTED)
        registered = true
        rescan()
    }

    @Synchronized
    fun stop() {
        if (registered) {
            appContext.unregisterReceiver(receiver)
            registered = false
        }
        closeReader()
    }

    /** Looks at already attached devices (app start, or the activity's USB_DEVICE_ATTACHED intent). */
    fun rescan() {
        val reader = usbManager.deviceList.values.firstOrNull { CcidTransport.isCcidReader(it) }
        if (reader == null) {
            closeReader()
            _state.value = ReaderState.NoReader
        } else {
            onAttached(reader)
        }
    }

    /**
     * Shows the system "allow access" dialog. The UI shows the "Permite accesul la cititor"
     * explainer first (docs/10 §4.5).
     */
    fun requestPermission() {
        val dev = device ?: return
        // FLAG_MUTABLE is required on API 31+: the system fills in EXTRA_DEVICE / EXTRA_PERMISSION_GRANTED.
        // The intent is explicit (setPackage), which API 34+ requires for mutable PendingIntents.
        val mutable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
        val intent = Intent(ACTION_USB_PERMISSION).setPackage(appContext.packageName)
        val pi = PendingIntent.getBroadcast(appContext, 0, intent, mutable or PendingIntent.FLAG_UPDATE_CURRENT)
        usbManager.requestPermission(dev, pi)
    }

    /** Called after a PIN-less certificate read so the StatusCard can greet the holder. */
    fun setHolder(name: String?) {
        holder = name
        (_state.value as? ReaderState.CardPresent)?.let { _state.value = it.copy(holder = name) }
    }

    /** Card sessions for `CardSigningService`: power-on reset per operation, Busy while open. */
    val transportProvider = TransportProvider {
        val t = transport ?: throw CardError.NoReader()
        sessionActive = true
        _state.value = ReaderState.Busy
        val session = try {
            t.session()
        } catch (e: Exception) {
            sessionActive = false
            refreshNow()
            throw e
        }
        object : ApduTransport {
            override val readerName: String get() = session.readerName
            override fun transmit(apdu: ByteArray): ByteArray = session.transmit(apdu)
            override fun close() {
                try {
                    session.close()
                } finally {
                    sessionActive = false
                    refreshNow()
                }
            }
        }
    }

    private fun onAttached(dev: UsbDevice) {
        if (!CcidTransport.isCcidReader(dev)) return
        if (device?.deviceName == dev.deviceName && transport != null) return
        device = dev
        if (usbManager.hasPermission(dev)) {
            openAndPoll(dev)
        } else {
            _state.value = ReaderState.PermissionRequired(CcidTransport.displayName(dev))
        }
    }

    private fun onDetached(dev: UsbDevice) {
        if (device?.deviceName != dev.deviceName) return
        closeReader()
        rescan()
    }

    private fun onPermissionResult(dev: UsbDevice, granted: Boolean) {
        if (granted) {
            device = dev
            openAndPoll(dev)
        } else {
            _state.value = ReaderState.PermissionRequired(CcidTransport.displayName(dev))
        }
    }

    private fun openAndPoll(dev: UsbDevice) {
        pollJob?.cancel()
        pollJob = scope.launch(Dispatchers.IO) {
            val t = try {
                CcidTransport.open(usbManager, dev)
            } catch (e: CardError) {
                _state.value = ReaderState.Error(e.message ?: "USB")
                return@launch
            }
            transport?.close()
            transport = t
            _state.value = ReaderState.Empty(t.readerName)
            // TODO(AND-02): replace polling with RDR_to_PC_NotifySlotChange on t.interruptIn (Ccid.notifySlotPresent).
            while (isActive) {
                if (!sessionActive) poll(t)
                delay(pollIntervalMs)
            }
        }
    }

    private fun refreshNow() {
        transport?.let { t -> scope.launch(Dispatchers.IO) { poll(t) } }
    }

    private fun poll(t: CcidTransport) {
        if (sessionActive) return
        val next = try {
            when (t.slotStatus()) {
                CcidTransport.SlotState.Absent -> {
                    holder = null
                    ReaderState.Empty(t.readerName)
                }
                else -> ReaderState.CardPresent(t.readerName, holder)
            }
        } catch (e: CardError) {
            ReaderState.Error(e.message ?: "CCID")
        }
        if (!sessionActive) _state.value = next
    }

    private fun closeReader() {
        pollJob?.cancel()
        pollJob = null
        transport?.let { t -> scope.launch(Dispatchers.IO) { runCatching { t.close() } } }
        transport = null
        device = null
        holder = null
    }

    companion object {
        const val ACTION_USB_PERMISSION = "md.moldsign.transport.usb.USB_PERMISSION"
    }
}
