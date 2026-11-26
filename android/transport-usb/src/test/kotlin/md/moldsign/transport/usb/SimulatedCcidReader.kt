package md.moldsign.transport.usb

import md.moldsign.core.decodeHex

/**
 * A CCID reader on the far side of the bulk pipes. Short-APDU readers pass APDUs to [apdu]; TPDU readers
 * pass T=1 blocks to [t1]. Replies can be split across USB transfers, preceded by stale messages or
 * time extensions, or replaced by failures.
 */
internal class SimulatedCcidReader(
    private val apdu: (ByteArray) -> ByteArray = { "9000".decodeHex() },
    /** Builds the T=1 card state at every power-on, like a real card reset. */
    private val t1Card: (() -> FakeT1Card)? = null,
) : CcidLink {
    var t1: FakeT1Card? = null
        private set
    var failParameters = false
    @Volatile var cardPresent = true
    var atr: ByteArray = COSMOX_ATR
    /** bError for the next IccPowerOn/XfrBlock failure, or null for success. */
    @Volatile var failNext: Int? = null
    var failSend = false
    var timeExtensions = 0
    var staleBeforeReply = false
    @Volatile var receiveTimeout = false
    var emptyTransferFirst = false
    /** Split every reply into USB transfers of this size. */
    var transferSize = Int.MAX_VALUE
    @Volatile var released = false
    var replyType: Int? = null
    var shortReply = false
    var hugeLength = false
    val commands = mutableListOf<Int>()
    val parameters = mutableListOf<ByteArray>()
    private val pending = ArrayDeque<ByteArray>()

    override fun send(message: ByteArray, timeoutMs: Int): Int {
        if (failSend) return -1
        val type = message[0].toInt() and 0xFF
        val seq = message[6].toInt() and 0xFF
        val data = message.copyOfRange(Ccid.HEADER_SIZE, message.size)
        commands += type
        if (staleBeforeReply) { staleBeforeReply = false; queue(reply(0x81, (seq + 7) and 0xFF, 0, 0, ByteArray(0))) }
        repeat(timeExtensions) { queue(reply(0x80, seq, 0x80, 1, ByteArray(0))) }
        timeExtensions = 0
        val icc = if (!cardPresent) Ccid.ICC_ABSENT else Ccid.ICC_PRESENT_ACTIVE
        val failure = failNext
        queue(when (type) {
            Ccid.PC_TO_RDR_GET_SLOT_STATUS -> reply(0x81, seq, icc, 0, ByteArray(0))
            Ccid.PC_TO_RDR_ICC_POWER_OFF -> reply(0x81, seq, if (cardPresent) Ccid.ICC_PRESENT_INACTIVE else Ccid.ICC_ABSENT, 0, ByteArray(0))
            Ccid.PC_TO_RDR_SET_PARAMETERS -> {
                parameters += data
                if (failParameters) reply(0x82, seq, 0x40 or icc, Ccid.ERR_HW_ERROR, ByteArray(0))
                else reply(0x82, seq, icc, 0, ByteArray(0))
            }
            Ccid.PC_TO_RDR_ICC_POWER_ON -> when {
                !cardPresent -> reply(0x80, seq, 0x40 or Ccid.ICC_ABSENT, Ccid.ERR_ICC_MUTE, ByteArray(0))
                failure != null -> { failNext = null; reply(0x80, seq, 0x40 or Ccid.ICC_PRESENT_INACTIVE, failure, ByteArray(0)) }
                else -> { t1 = t1Card?.invoke(); reply(0x80, seq, 0, 0, atr) }
            }
            Ccid.PC_TO_RDR_XFR_BLOCK -> when {
                !cardPresent -> reply(0x80, seq, 0x40 or Ccid.ICC_ABSENT, Ccid.ERR_ICC_MUTE, ByteArray(0))
                failure != null -> { failNext = null; reply(0x80, seq, 0x40, failure, ByteArray(0)) }
                else -> {
                    val answer = t1?.transceive(data, message[7].toInt() and 0xFF) ?: apdu(data)
                    reply(replyType ?: 0x80, seq, 0, 0, if (shortReply) answer.copyOf(1) else answer)
                }
            }
            else -> error("unexpected CCID command %02X".format(type))
        })
        return message.size
    }

    override fun receive(buffer: ByteArray, timeoutMs: Int): Int {
        if (receiveTimeout) return -1
        if (emptyTransferFirst) { emptyTransferFirst = false; return 0 }
        val next = pending.removeFirstOrNull() ?: return -1
        val n = minOf(next.size, transferSize, buffer.size)
        next.copyInto(buffer, 0, 0, n)
        if (n < next.size) pending.addFirst(next.copyOfRange(n, next.size))
        return n
    }

    override fun release() { released = true }

    private fun queue(message: ByteArray) { pending.addLast(message) }

    private fun reply(type: Int, seq: Int, status: Int, error: Int, data: ByteArray): ByteArray {
        val out = Ccid.command(type, 0, seq, data, b7 = status, b8 = error)
        if (hugeLength) { hugeLength = false; out[3] = 0x7F }
        return out
    }

    companion object {
        /** The CosmoX ID-A ATR: T=1, IFSC 254, BWI 4 / CWI 5, LRC. */
        val COSMOX_ATR = "3BDF96008131FE45807384" .decodeHex() + "21E0574D44415F415350810F78".decodeHex()
        /** A T=0 ATR for APDU-level readers. */
        val T0_ATR = "3B00".decodeHex()
        /** A miniLector-like descriptor: TPDU level, no automatic parameter negotiation, 271-byte messages. */
        val TPDU = Ccid.Descriptor(maxSlotIndex = 0, protocols = 3, features = 0x000100B6, maxMessageLength = 271, maxIfsd = 254, voltageSupport = 2)
        val SHORT_APDU = Ccid.Descriptor(maxSlotIndex = 0, protocols = 3, features = 0x00020040, maxMessageLength = 271)
    }
}
