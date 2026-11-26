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
import kotlinx.coroutines.CoroutineDispatcher
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
class UsbReaderMonitor internal constructor(
    private val host: UsbHost,
    private val scope: CoroutineScope,
    private val pollIntervalMs: Long = 1_000,
    /** Where USB transfers run; tests pass a virtual-time dispatcher. */
    private val io: CoroutineDispatcher = Dispatchers.IO,
) {
    constructor(context: Context, scope: CoroutineScope, pollIntervalMs: Long = 1_000) :
        this(AndroidUsbHost(context.applicationContext), scope, pollIntervalMs)

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

    private inner class Slot(val device: UsbHost.Reader) {
        val id: String = device.id
        val productName: String = device.name

        @Volatile var transport: CcidTransport? = null

        @Volatile var presence: ReaderSlot.State = ReaderSlot.State.PermissionRequired

        @Volatile var generation: Long = 0

        @Volatile var sessionActive = false
        var pollJob: Job? = null
    }

    private val events = object : UsbHost.Events {
        override fun attached(reader: UsbHost.Reader) = onAttached(reader)
        override fun detached(id: String) = onDetached(id)
        override fun permission(reader: UsbHost.Reader, granted: Boolean) = onPermissionResult(reader, granted)
    }

    @Synchronized
    fun start() {
        if (registered) return
        host.listen(events)
        registered = true
        rescan()
    }

    @Synchronized
    fun stop() {
        if (registered) {
            host.stopListening()
            registered = false
        }
        val all = synchronized(lock) { slots.keys.toList() }
        all.forEach(::onDetached)
    }

    /** Syncs with the attached devices (app start, or the activity's USB_DEVICE_ATTACHED intent). */
    fun rescan() {
        val attached = host.readers()
        val gone = synchronized(lock) { slots.keys.filter { id -> attached.none { it.id == id } } }
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
        host.requestPermission(slot.device)
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
        scope.launch(io) { poll(slot, t) }
    }

    private fun onAttached(dev: UsbHost.Reader) {
        val slot = synchronized(lock) {
            slots[dev.id]?.let { existing -> if (existing.transport != null || existing.pollJob != null) return }
            slots.getOrPut(dev.id) { Slot(dev) }
        }
        if (host.hasPermission(dev)) {
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
        slot.transport?.let { t -> scope.launch(io) { runCatching { t.close() } } }
        slot.transport = null
        generations.forget(readerId)
        publish()
    }

    private fun onPermissionResult(dev: UsbHost.Reader, granted: Boolean) {
        val slot = synchronized(lock) { slots.getOrPut(dev.id) { Slot(dev) } }
        if (granted) {
            openAndPoll(slot)
        } else {
            slot.presence = ReaderSlot.State.PermissionRequired
            publish()
        }
    }

    private fun openAndPoll(slot: Slot) {
        slot.pollJob?.cancel()
        slot.pollJob = scope.launch(io) {
            val t = try {
                host.open(slot.device)
            } catch (e: CardError) {
                Log.w(TAG, "${slot.productName}: open failed: ${e.javaClass.simpleName}: ${e.message}")
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
            Log.w(TAG, "${slot.productName}: slot status failed: ${e.javaClass.simpleName}: ${e.message}")
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

/** The Android USB host as the monitor uses it; tests substitute simulated readers. */
internal interface UsbHost {
    /** An attached CCID reader: [id] is the USB device path, [device] the platform object. */
    class Reader(val id: String, val name: String, val device: Any? = null)

    interface Events {
        fun attached(reader: Reader)
        fun detached(id: String)
        fun permission(reader: Reader, granted: Boolean)
    }

    /** Attached devices that expose a CCID interface. */
    fun readers(): List<Reader>
    fun hasPermission(reader: Reader): Boolean
    /** Opens and claims the reader; throws [CardError] when it cannot. */
    fun open(reader: Reader): CcidTransport
    /** Shows the system "allow access" dialog; the answer arrives as [Events.permission]. */
    fun requestPermission(reader: Reader)
    fun listen(events: Events)
    fun stopListening()
}

internal class AndroidUsbHost(private val context: Context) : UsbHost {
    private val usbManager: UsbManager = context.getSystemService(UsbManager::class.java)
    private var receiver: BroadcastReceiver? = null

    private fun reader(device: UsbDevice) = UsbHost.Reader(device.deviceName, CcidTransport.displayName(device), device)
    private val UsbHost.Reader.usbDevice get() = device as UsbDevice

    override fun readers() = usbManager.deviceList.values.filter { CcidTransport.isCcidReader(it) }.map(::reader)
    override fun hasPermission(reader: UsbHost.Reader) = usbManager.hasPermission(reader.usbDevice)
    override fun open(reader: UsbHost.Reader) = CcidTransport.open(usbManager, reader.usbDevice)

    override fun requestPermission(reader: UsbHost.Reader) {
        // FLAG_MUTABLE is required on API 31+: the system fills in EXTRA_DEVICE / EXTRA_PERMISSION_GRANTED.
        // The intent is explicit (setPackage), which API 34+ requires for mutable PendingIntents.
        val mutable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
        val intent = Intent(UsbReaderMonitor.ACTION_USB_PERMISSION).setPackage(context.packageName)
        val pi = PendingIntent.getBroadcast(context, reader.id.hashCode(), intent, mutable or PendingIntent.FLAG_UPDATE_CURRENT)
        usbManager.requestPermission(reader.usbDevice, pi)
    }

    override fun listen(events: UsbHost.Events) {
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                val dev = IntentCompat.getParcelableExtra(intent, UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                when (intent.action) {
                    UsbManager.ACTION_USB_DEVICE_ATTACHED -> dev?.takeIf { CcidTransport.isCcidReader(it) }?.let { events.attached(reader(it)) }
                    UsbManager.ACTION_USB_DEVICE_DETACHED -> dev?.let { events.detached(it.deviceName) }
                    UsbReaderMonitor.ACTION_USB_PERMISSION -> {
                        val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                        if (dev != null) events.permission(reader(dev), granted)
                    }
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
            addAction(UsbReaderMonitor.ACTION_USB_PERMISSION)
        }
        // System USB broadcasts still reach a NOT_EXPORTED receiver; the permission result is our own PendingIntent.
        ContextCompat.registerReceiver(context, receiver, filter, ContextCompat.RECEIVER_NOT_EXPORTED)
        this.receiver = receiver
    }

    override fun stopListening() {
        receiver?.let(context::unregisterReceiver)
        receiver = null
    }
}
