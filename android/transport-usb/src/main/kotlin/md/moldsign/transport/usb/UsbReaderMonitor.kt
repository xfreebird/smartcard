package md.moldsign.transport.usb

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import android.util.Log
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
import md.moldsign.core.CardGenerations
import md.moldsign.core.ReaderSlot
import md.moldsign.core.ReaderState
import md.moldsign.core.TransportProvider

/**
 * Android ReaderMonitor (docs/09 §3.7, §3.1b): every attached CCID reader gets its own slot with USB
 * attach/detach broadcasts, the USB permission flow (AND-03) and CCID GetSlotStatus polling (AND-02).
 *
 * [readers] is the per-reader snapshot the app's card wallet reconciles against: each card carries a
 * generation ([CardGenerations]) that changes when a card is present after it was absent, or when the reader
 * is attached with a card. [transportProvider] opens a session on the reader the caller names (the selected
 * card), so signing and the PIN go to that card only. While a session is open on a reader, its polling pauses.
 */
class UsbReaderMonitor(
    context: Context,
    private val scope: CoroutineScope,
    private val pollIntervalMs: Long = 1_000,
) {
    private val appContext = context.applicationContext
    private val usbManager: UsbManager = appContext.getSystemService(UsbManager::class.java)
    private val generations = CardGenerations()

    /** Attached CCID readers by USB device path, in attach order. Guarded by [lock]. */
    private val slots = LinkedHashMap<String, Slot>()
    private val lock = Any()

    private val _readers = MutableStateFlow<List<ReaderSlot>>(emptyList())

    /** Per-reader state for the card wallet (empty list = no reader). */
    val readers: StateFlow<List<ReaderSlot>> = _readers.asStateFlow()

    private val _state = MutableStateFlow<ReaderState>(ReaderState.NoReader)

    /** Aggregate of [readers] for `SigningService.readerState` (one line of status). */
    val state: StateFlow<ReaderState> = _state.asStateFlow()

    private var registered = false

    private inner class Slot(val device: UsbDevice) {
        val id: String = device.deviceName
        val productName: String = CcidTransport.displayName(device)

        @Volatile var transport: CcidTransport? = null

        @Volatile var presence: ReaderSlot.State = ReaderSlot.State.PermissionRequired

        @Volatile var generation: Long = 0

        @Volatile var sessionActive = false
        var pollJob: Job? = null
    }

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(ctx: Context, intent: Intent) {
            val dev = IntentCompat.getParcelableExtra(intent, UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
            when (intent.action) {
                UsbManager.ACTION_USB_DEVICE_ATTACHED -> dev?.let(::onAttached)
                UsbManager.ACTION_USB_DEVICE_DETACHED -> dev?.let { onDetached(it.deviceName) }
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
        val all = synchronized(lock) { slots.keys.toList() }
        all.forEach(::onDetached)
    }

    /** Syncs with the attached devices (app start, or the activity's USB_DEVICE_ATTACHED intent). */
    fun rescan() {
        val attached = usbManager.deviceList.values.filter { CcidTransport.isCcidReader(it) }
        val gone = synchronized(lock) { slots.keys.filter { id -> attached.none { it.deviceName == id } } }
        gone.forEach(::onDetached)
        attached.forEach(::onAttached)
        publish()
    }

    /**
     * Shows the system "allow access" dialog for [readerId] (default: the first reader still waiting for it).
     * The UI shows the "Permite accesul la cititor" explainer first (docs/10 §4.5).
     */
    fun requestPermission(readerId: String? = null) {
        val slot = synchronized(lock) {
            readerId?.let { slots[it] } ?: slots.values.firstOrNull { it.presence == ReaderSlot.State.PermissionRequired }
        } ?: return
        // FLAG_MUTABLE is required on API 31+: the system fills in EXTRA_DEVICE / EXTRA_PERMISSION_GRANTED.
        // The intent is explicit (setPackage), which API 34+ requires for mutable PendingIntents.
        val mutable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
        val intent = Intent(ACTION_USB_PERMISSION).setPackage(appContext.packageName)
        val pi = PendingIntent.getBroadcast(appContext, slot.id.hashCode(), intent, mutable or PendingIntent.FLAG_UPDATE_CURRENT)
        usbManager.requestPermission(slot.device, pi)
    }

    /**
     * Card sessions for `CardSigningService`: power-on reset per operation on the named reader
     * (`null` = the first reader holding a card); that reader's polling pauses while the session is open.
     */
    val transportProvider = TransportProvider { readerId ->
        val slot = synchronized(lock) {
            if (readerId != null) {
                slots[readerId] ?: throw CardError.NoReader("Reader $readerId is not connected")
            } else {
                slots.values.firstOrNull { it.presence == ReaderSlot.State.Card }
                    ?: slots.values.firstOrNull { it.transport != null }
                    ?: throw CardError.NoReader()
            }
        }
        val t = slot.transport ?: throw CardError.NoReader("${slot.productName}: no USB access")
        slot.sessionActive = true
        publish()
        val session = try {
            t.session()
        } catch (e: Exception) {
            endSession(slot, t)
            throw e
        }
        object : ApduTransport {
            override val readerName: String get() = session.readerName
            override fun transmit(apdu: ByteArray): ByteArray = session.transmit(apdu)
            override fun close() {
                try {
                    session.close()
                } finally {
                    endSession(slot, t)
                }
            }
        }
    }

    private fun endSession(slot: Slot, t: CcidTransport) {
        slot.sessionActive = false
        publish()
        scope.launch(Dispatchers.IO) { poll(slot, t) }
    }

    private fun onAttached(dev: UsbDevice) {
        if (!CcidTransport.isCcidReader(dev)) return
        val slot = synchronized(lock) {
            slots[dev.deviceName]?.let { existing -> if (existing.transport != null || existing.pollJob != null) return }
            slots.getOrPut(dev.deviceName) { Slot(dev) }
        }
        if (usbManager.hasPermission(dev)) {
            openAndPoll(slot)
        } else {
            slot.presence = ReaderSlot.State.PermissionRequired
            publish()
        }
    }

    private fun onDetached(readerId: String) {
        val slot = synchronized(lock) { slots.remove(readerId) } ?: return
        slot.pollJob?.cancel()
        slot.pollJob = null
        slot.transport?.let { t -> scope.launch(Dispatchers.IO) { runCatching { t.close() } } }
        slot.transport = null
        generations.forget(readerId)
        publish()
    }

    private fun onPermissionResult(dev: UsbDevice, granted: Boolean) {
        val slot = synchronized(lock) { slots.getOrPut(dev.deviceName) { Slot(dev) } }
        if (granted) {
            openAndPoll(slot)
        } else {
            slot.presence = ReaderSlot.State.PermissionRequired
            publish()
        }
    }

    private fun openAndPoll(slot: Slot) {
        slot.pollJob?.cancel()
        slot.pollJob = scope.launch(Dispatchers.IO) {
            val t = try {
                CcidTransport.open(usbManager, slot.device)
            } catch (e: CardError) {
                Log.w(TAG, "${slot.productName}: open failed: ${e.javaClass.simpleName}")
                slot.presence = ReaderSlot.State.Error
                publish()
                return@launch
            }
            slot.transport?.close()
            slot.transport = t
            slot.presence = ReaderSlot.State.Empty
            publish()
            // TODO(AND-02): replace polling with RDR_to_PC_NotifySlotChange on t.interruptIn (Ccid.notifySlotPresent).
            while (isActive) {
                if (!slot.sessionActive) poll(slot, t)
                delay(pollIntervalMs)
            }
        }
    }

    private fun poll(slot: Slot, t: CcidTransport) {
        if (slot.sessionActive) return
        val (presence, generation) = try {
            when (t.slotStatus()) {
                CcidTransport.SlotState.Absent -> ReaderSlot.State.Empty to generations.observe(slot.id, cardPresent = false)
                else -> ReaderSlot.State.Card to generations.observe(slot.id, cardPresent = true)
            }
        } catch (e: CardError) {
            Log.w(TAG, "${slot.productName}: slot status failed: ${e.javaClass.simpleName}")
            ReaderSlot.State.Error to generations.observe(slot.id, cardPresent = false)
        }
        if (slot.sessionActive) return
        if (presence != slot.presence || generation != slot.generation) {
            slot.presence = presence
            slot.generation = generation
            publish()
        }
    }

    /** Publishes [readers] (names de-duplicated: "miniLector EVO", "miniLector EVO #2") and the aggregate [state]. */
    private fun publish() {
        val snapshot = synchronized(lock) {
            val seen = HashMap<String, Int>()
            slots.values.map { s ->
                val n = (seen[s.productName] ?: 0) + 1
                seen[s.productName] = n
                val name = if (n == 1) s.productName else "${s.productName} #$n"
                ReaderSlot(s.id, name, s.presence, s.generation) to s.sessionActive
            }
        }
        val list = snapshot.map { it.first }
        _readers.value = list
        _state.value = when {
            list.isEmpty() -> ReaderState.NoReader
            snapshot.any { it.second } -> ReaderState.Busy
            else -> list.firstOrNull { it.state == ReaderSlot.State.Card }?.let { ReaderState.CardPresent(it.name) }
                ?: list.firstOrNull { it.state == ReaderSlot.State.PermissionRequired }?.let { ReaderState.PermissionRequired(it.name) }
                ?: list.firstOrNull { it.state == ReaderSlot.State.Empty }?.let { ReaderState.Empty(it.name) }
                ?: ReaderState.Error(list.first().name)
        }
    }

    companion object {
        const val ACTION_USB_PERMISSION = "md.moldsign.transport.usb.USB_PERMISSION"
        private const val TAG = "MoldSignUsb"
    }
}
