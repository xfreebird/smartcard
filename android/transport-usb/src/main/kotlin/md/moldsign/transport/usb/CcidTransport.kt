package md.moldsign.transport.usb

import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.util.Log
import md.moldsign.core.ApduTransport
import md.moldsign.core.CardError

/**
 * [ApduTransport] over a USB CCID reader using the Android USB host API (AND-02).
 *
 * Owns the [UsbDeviceConnection] and the claimed CCID interface. At short/extended-APDU exchange level an APDU goes
 * as one PC_to_RDR_XfrBlock. At TPDU level (the miniLector POCKET EVO: `dwFeatures` 0x000100B6) the reader only
 * handles the physical layer, so [T1] frames the APDU into T=1 blocks, each sent as an XfrBlock. Responses are
 * RDR_to_PC_DataBlock; time-extension replies (bmCommandStatus = 2) are skipped by re-reading.
 *
 * Thread-safe at the message level: every CCID command/response pair holds [lock], so status
 * polling from [UsbReaderMonitor] cannot interleave with an APDU exchange.
 */
class CcidTransport private constructor(
    private val connection: UsbDeviceConnection,
    private val ccidInterface: UsbInterface,
    private val bulkIn: UsbEndpoint,
    private val bulkOut: UsbEndpoint,
    /** Interrupt IN for RDR_to_PC_NotifySlotChange. TODO(AND-02): read it instead of polling GetSlotStatus. */
    val interruptIn: UsbEndpoint?,
    override val readerName: String,
    val descriptor: Ccid.Descriptor?,
    private val timeoutMs: Int,
) : ApduTransport {
    private val lock = Any()
    private var seq = 0
    private val readBuffer = ByteArray(maxOf(READ_BUFFER, (descriptor?.maxMessageLength ?: 0).coerceAtMost(MAX_MESSAGE)))
    private val powerSelect: Int get() = descriptor?.powerSelect ?: Ccid.VOLTAGE_AUTO

    @Volatile private var closed = false

    /** T=1 engine of the current card session; only at TPDU level, null otherwise or while the card is off. */
    private var t1: T1? = null

    /** ATR of the last successful power-on, or null when the card is not powered. */
    @Volatile var atr: ByteArray? = null
        private set

    enum class SlotState { Active, Inactive, Absent }

    /** PC_to_RDR_GetSlotStatus → card presence. */
    fun slotStatus(): SlotState {
        val r = exchange { Ccid.getSlotStatus(SLOT, it) }
        return when (r.iccStatus) {
            Ccid.ICC_PRESENT_ACTIVE -> SlotState.Active
            Ccid.ICC_PRESENT_INACTIVE -> SlotState.Inactive
            else -> SlotState.Absent
        }
    }

    /**
     * Cold reset: IccPowerOff then IccPowerOn → ATR. The CCID analogue of
     * `SCardReconnect(SCARD_RESET_CARD)`, which clears stale SM state from a crashed session (docs/01).
     * TODO(AND-02): verify on the miniLector EVO that power-cycling is enough (vs. warm reset).
     */
    fun resetCard(): ByteArray = synchronized(lock) {
        runCatching { exchange { Ccid.iccPowerOff(SLOT, it) } }
        atr = null
        t1 = null
        val r = exchange { Ccid.iccPowerOn(SLOT, it, powerSelect) }
        if (r.isFailed || r.data.isEmpty()) {
            throw when {
                r.iccStatus == Ccid.ICC_ABSENT -> CardError.NoCard()
                r.error == Ccid.ERR_ICC_MUTE -> CardError.NoCard("Card does not answer (ICC mute)")
                else -> CardError.CardNotResponding("IccPowerOn failed: $r")
            }
        }
        if (descriptor?.exchangeLevel == Ccid.ExchangeLevel.Tpdu) t1 = openT1(r.data)
        r.data.also { atr = it }
    }

    /** T=1 for a TPDU-level reader: the card's IFSC comes from the ATR, then the host IFSD is raised from 32. */
    private fun openT1(atr: ByteArray): T1 {
        val info = try {
            Atr.parse(atr)
        } catch (e: IllegalArgumentException) {
            throw CardError.CardNotResponding("Unreadable ATR")
        }
        if (info.firstProtocol != 1) {
            throw CardError.CardNotResponding("TPDU reader with a T=${info.firstProtocol} card: only T=1 is supported")
        }
        // a block (NAD, PCB, LEN, INF, LRC) must fit one CCID message
        val blockCap = (descriptor?.maxMessageLength ?: 0).let { if (it > Ccid.HEADER_SIZE + 4) it - Ccid.HEADER_SIZE - 4 else 254 }
        if (info.crc) throw CardError.CardNotResponding("T=1 with CRC error detection is not supported")
        // A reader without automatic parameter negotiation (dwFeatures 0x40) must be told the protocol, or it keeps its
        // T=0 default and takes every T=1 block for a malformed TPDU (libccid IFDHSetProtocolParameters does the same).
        if (((descriptor?.features ?: 0) and 0x00000040) == 0) {
            val parameters = byteArrayOf(
                0x11, // Fi/Di: default rate, no PPS
                (0x10 or (if (info.inverse) 0x02 else 0x00)).toByte(), // bmTCCKST1: LRC + convention
                (info.guardTime ?: 0).toByte(),
                (info.bwiCwi ?: 0x4D).toByte(),
                0x00, // clock stop
                (info.ifsc ?: T1.DEFAULT_IFS).toByte(),
                0x00, // NAD
            )
            val r = exchange { Ccid.setParameters(SLOT, it, protocol = 1, parameters) }
            if (r.isFailed) throw CardError.CardNotResponding("SetParameters failed: $r")
        }
        val engine = T1(::transceiveBlock, ifsc = minOf(info.ifsc ?: T1.DEFAULT_IFS, blockCap))
        engine.negotiateIfsd(minOf(descriptor?.maxIfsd?.takeIf { it > 0 } ?: 254, 254, blockCap))
        return engine
    }

    /** One T=1 block as PC_to_RDR_XfrBlock (bBWI extends the block waiting time for an S(WTX) answer). */
    private fun transceiveBlock(block: ByteArray, bwi: Int): ByteArray {
        val r = exchange { Ccid.xfrBlock(SLOT, it, block, bwi = bwi) }
        if (r.isFailed) {
            throw when {
                r.iccStatus == Ccid.ICC_ABSENT -> CardError.NoCard()
                r.error == Ccid.ERR_ICC_MUTE -> CardError.CardNotResponding("Card mute (T=1 block)")
                else -> CardError.CardNotResponding("XfrBlock failed: $r")
            }
        }
        if (r.type != Ccid.RDR_TO_PC_DATA_BLOCK) throw CardError.CardNotResponding("Unexpected CCID reply $r")
        return r.data
    }

    fun powerOff() {
        synchronized(lock) {
            if (closed) return
            runCatching { exchange { Ccid.iccPowerOff(SLOT, it) } }
            atr = null
            t1 = null
        }
    }

    override fun transmit(apdu: ByteArray): ByteArray = synchronized(lock) {
        if (atr == null) resetCard()
        t1?.let { engine ->
            val response = try {
                engine.transmit(apdu)
            } catch (e: CardError) {
                atr = null
                t1 = null
                throw e
            }
            if (response.size < 2) throw CardError.CardNotResponding("Response without status word")
            return@synchronized response
        }
        val r = exchange { Ccid.xfrBlock(SLOT, it, apdu) }
        if (r.isFailed) {
            atr = null
            throw when {
                r.iccStatus == Ccid.ICC_ABSENT -> CardError.NoCard()
                r.error == Ccid.ERR_ICC_MUTE -> CardError.CardNotResponding("Card mute (XfrBlock)")
                else -> CardError.CardNotResponding("XfrBlock failed: $r")
            }
        }
        if (r.type != Ccid.RDR_TO_PC_DATA_BLOCK) throw CardError.CardNotResponding("Unexpected CCID reply $r")
        if (r.data.size < 2) throw CardError.CardNotResponding("Response without status word")
        r.data
    }

    /**
     * A card session for one SigningService operation: resets the card on open and powers it off on
     * close, but keeps the USB interface claimed (the monitor keeps polling through this transport).
     */
    fun session(): ApduTransport {
        resetCard()
        return object : ApduTransport {
            override val readerName: String get() = this@CcidTransport.readerName
            override fun transmit(apdu: ByteArray): ByteArray = this@CcidTransport.transmit(apdu)
            override fun close() = powerOff()
        }
    }

    override fun close() {
        synchronized(lock) {
            if (closed) return
            runCatching { exchange { Ccid.iccPowerOff(SLOT, it) } }
            closed = true
            atr = null
        }
        connection.releaseInterface(ccidInterface)
        connection.close()
    }

    /** Sends one CCID message (built with the next bSeq) and returns the matching, final response. */
    private fun exchange(build: (seq: Int) -> ByteArray): Ccid.Response = synchronized(lock) {
        if (closed) throw CardError.NoReader("Reader closed")
        val expectedSeq = seq
        seq = Ccid.nextSeq(seq)
        val command = build(expectedSeq)
        val sent = connection.bulkTransfer(bulkOut, command, command.size, timeoutMs)
        if (sent != command.size) throw CardError.CardNotResponding("USB bulk OUT failed ($sent of ${command.size} B)")

        var extensions = 0
        var r = readMessage()
        // Skip stale replies (other bSeq) and time-extension requests (bmCommandStatus = 2; bError holds
        // the BWT multiplier while the card keeps working, e.g. during the RSA-4096 signature).
        while (r.seq != expectedSeq || r.isTimeExtension) {
            if (r.seq == expectedSeq && ++extensions > MAX_TIME_EXTENSIONS) {
                throw CardError.CardNotResponding("Too many CCID time extensions")
            }
            r = readMessage()
        }
        r
    }

    /** Reads one complete RDR_to_PC message, accumulating USB transfers until dwLength is satisfied. */
    private fun readMessage(): Ccid.Response {
        var total = 0
        var needed = Ccid.HEADER_SIZE
        var message = ByteArray(0)
        while (total < needed) {
            val n = connection.bulkTransfer(bulkIn, readBuffer, readBuffer.size, timeoutMs)
            if (n < 0) throw CardError.CardNotResponding("USB bulk IN timeout")
            if (n == 0) continue
            message += readBuffer.copyOf(n)
            total += n
            if (total >= Ccid.HEADER_SIZE) {
                needed = Ccid.HEADER_SIZE + Ccid.messageLength(message)
                if (needed > Ccid.HEADER_SIZE + MAX_MESSAGE) throw CardError.CardNotResponding("CCID message too long ($needed B)")
            }
        }
        return Ccid.parse(message, needed)
    }

    companion object {
        const val SLOT = 0
        private const val READ_BUFFER = 16 * 1024 // bulkTransfer limit before API 28
        private const val MAX_MESSAGE = 65_536 + Ccid.HEADER_SIZE
        private const val MAX_TIME_EXTENSIONS = 200
        const val DEFAULT_TIMEOUT_MS = 10_000

        /** The first interface with class 0x0B (CCID), or a vendor-class one carrying a CCID descriptor. */
        fun findCcidInterface(device: UsbDevice): UsbInterface? {
            val all = (0 until device.interfaceCount).map { device.getInterface(it) }
            return all.firstOrNull { it.interfaceClass == UsbConstants.USB_CLASS_CSCID }
                ?: all.firstOrNull { it.interfaceClass == UsbConstants.USB_CLASS_VENDOR_SPEC && hasBulkPair(it) }
        }

        fun isCcidReader(device: UsbDevice): Boolean = findCcidInterface(device) != null

        fun displayName(device: UsbDevice): String =
            device.productName?.takeIf { it.isNotBlank() } ?: "USB reader %04X:%04X".format(device.vendorId, device.productId)

        private fun hasBulkPair(i: UsbInterface): Boolean {
            val eps = (0 until i.endpointCount).map { i.getEndpoint(it) }
            return eps.any { it.type == UsbConstants.USB_ENDPOINT_XFER_BULK && it.direction == UsbConstants.USB_DIR_IN } &&
                eps.any { it.type == UsbConstants.USB_ENDPOINT_XFER_BULK && it.direction == UsbConstants.USB_DIR_OUT }
        }

        /**
         * Opens and claims the reader. The caller must already hold USB permission for [device]
         * (see [UsbReaderMonitor.requestPermission]). Does not power the card yet.
         */
        fun open(usbManager: UsbManager, device: UsbDevice, timeoutMs: Int = DEFAULT_TIMEOUT_MS): CcidTransport {
            if (!usbManager.hasPermission(device)) throw CardError.NoReader("USB permission not granted for ${displayName(device)}")
            val iface = findCcidInterface(device) ?: throw CardError.NoReader("${displayName(device)} is not a CCID reader")
            val eps = (0 until iface.endpointCount).map { iface.getEndpoint(it) }
            val bulkIn = eps.firstOrNull { it.type == UsbConstants.USB_ENDPOINT_XFER_BULK && it.direction == UsbConstants.USB_DIR_IN }
            val bulkOut = eps.firstOrNull { it.type == UsbConstants.USB_ENDPOINT_XFER_BULK && it.direction == UsbConstants.USB_DIR_OUT }
            val intIn = eps.firstOrNull { it.type == UsbConstants.USB_ENDPOINT_XFER_INT && it.direction == UsbConstants.USB_DIR_IN }
            if (bulkIn == null || bulkOut == null) throw CardError.NoReader("CCID interface without bulk endpoints")

            val connection = usbManager.openDevice(device) ?: throw CardError.NoReader("Cannot open ${displayName(device)}")
            if (!connection.claimInterface(iface, true)) {
                connection.close()
                throw CardError.NoReader("Cannot claim the CCID interface of ${displayName(device)}")
            }
            val descriptor = connection.rawDescriptors?.let { Ccid.parseDescriptor(it) }
            Log.i(
                "MoldSignUsb",
                "${displayName(device)}: CCID descriptor " + (descriptor?.let {
                    "features=0x%08X level=%s protocols=0x%X maxMessage=%d maxSlot=%d voltages=0x%X powerSelect=%d".format(
                        it.features, it.exchangeLevel, it.protocols, it.maxMessageLength, it.maxSlotIndex, it.voltageSupport, it.powerSelect,
                    )
                } ?: "not found"),
            )
            if (descriptor != null && descriptor.exchangeLevel < Ccid.ExchangeLevel.Tpdu) {
                // character-level readers would need the host to do the byte-wise T=0/T=1 timing and parity
                connection.releaseInterface(iface)
                connection.close()
                throw CardError.NoReader("${displayName(device)} needs ${descriptor.exchangeLevel} exchange, not supported")
            }
            return CcidTransport(connection, iface, bulkIn, bulkOut, intIn, displayName(device), descriptor, timeoutMs)
        }
    }
}
