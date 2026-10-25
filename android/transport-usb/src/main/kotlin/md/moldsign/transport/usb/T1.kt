package md.moldsign.transport.usb

import java.io.ByteArrayOutputStream
import md.moldsign.core.CardError

/**
 * ISO 7816-3 T=1 block protocol for TPDU-level CCID readers (`dwFeatures` exchange level 0x00010000).
 *
 * Such a reader only handles the physical layer: the host builds the blocks (`NAD | PCB | LEN | INF | LRC`),
 * chains an APDU longer than the card's IFSC into I-blocks, acknowledges the card's chained I-blocks with R-blocks,
 * answers S(WTX) waiting-time requests and negotiates the host's IFSD. Pure Kotlin, unit-tested on the JVM.
 *
 * One instance per card session (power-on): the N(S) sequence bits start at 0 after a reset.
 */
class T1(
    /** Sends one block through the reader and returns the card's reply block. [bwi] extends the reader's block wait. */
    private val transceive: (block: ByteArray, bwi: Int) -> ByteArray,
    /** The card's information field size (ATR TA3, default 32): the largest INF the host may send. */
    private val ifsc: Int = DEFAULT_IFS,
    private val nad: Int = 0,
) {
    private var hostNs = 0 // N(S) of the host's next I-block
    private var cardNs = 0 // N(S) expected in the card's next I-block

    private class Block(val pcb: Int, val inf: ByteArray) {
        val isI get() = pcb and 0x80 == 0
        val isR get() = pcb and 0xC0 == 0x80
        val ns get() = (pcb ushr 6) and 1
        val more get() = pcb and 0x20 != 0
        val nr get() = (pcb ushr 4) and 1
    }

    /** S(IFS request): tells the card the largest block the host accepts. Best effort: false leaves IFSD at 32. */
    fun negotiateIfsd(ifsd: Int): Boolean {
        val reply = try {
            parse(transceive(block(S_IFS_REQUEST, byteArrayOf(ifsd.toByte())), 0))
        } catch (e: CardError) {
            return false
        }
        return reply != null && reply.pcb == S_IFS_RESPONSE && reply.inf.size == 1 && (reply.inf[0].toInt() and 0xFF) == ifsd
    }

    /** Sends [apdu] and returns the card's complete response (data + SW). */
    fun transmit(apdu: ByteArray): ByteArray {
        val chunks = if (apdu.isEmpty()) listOf(apdu) else apdu.asList().chunked(ifsc).map { it.toByteArray() }
        val received = ByteArrayOutputStream()
        var index = 0
        var receiving = false
        var errors = 0
        var next = iBlock(chunks[0], more = chunks.size > 1)
        var lastNonS = next
        var bwi = 0

        while (true) {
            val reply = parse(transceive(next, bwi))
            bwi = 0
            if (reply == null) { // bad LRC or length: ask the card to repeat its block
                if (++errors > MAX_RETRIES) throw CardError.CardNotResponding("T=1: damaged blocks")
                next = rBlock(error = 1).also { lastNonS = it }
                continue
            }
            when {
                reply.isI -> {
                    if (!receiving) {
                        if (index + 1 < chunks.size) throw CardError.CardNotResponding("T=1: card answered before the command was sent")
                        hostNs = hostNs xor 1 // the first reply block acknowledges our last I-block
                        receiving = true
                    }
                    if (reply.ns == cardNs) {
                        received.write(reply.inf)
                        cardNs = cardNs xor 1
                        errors = 0
                        if (!reply.more) return received.toByteArray()
                        next = rBlock(error = 0).also { lastNonS = it }
                    } else { // a repeat of a block we already took: acknowledge it again
                        if (++errors > MAX_RETRIES) throw CardError.CardNotResponding("T=1: out-of-sequence blocks")
                        next = rBlock(error = 0).also { lastNonS = it }
                    }
                }
                reply.isR -> {
                    if (!receiving && index + 1 < chunks.size && reply.nr == (hostNs xor 1)) {
                        hostNs = hostNs xor 1 // chained I-block acknowledged
                        index++
                        errors = 0
                        next = iBlock(chunks[index], more = index + 1 < chunks.size).also { lastNonS = it }
                    } else { // the card asks to repeat
                        if (++errors > MAX_RETRIES) throw CardError.CardNotResponding("T=1: card keeps requesting retransmission")
                        next = lastNonS
                    }
                }
                else -> when (reply.pcb) {
                    S_WTX_REQUEST -> {
                        bwi = reply.inf.firstOrNull()?.toInt()?.and(0xFF) ?: 1
                        next = block(S_WTX_RESPONSE, reply.inf)
                    }
                    S_IFS_REQUEST -> next = block(S_IFS_RESPONSE, reply.inf)
                    else -> throw CardError.CardNotResponding("T=1: unexpected S-block %02X".format(reply.pcb))
                }
            }
        }
    }

    private fun iBlock(inf: ByteArray, more: Boolean) = block((hostNs shl 6) or (if (more) 0x20 else 0), inf)

    private fun rBlock(error: Int) = block(0x80 or (cardNs shl 4) or error, ByteArray(0))

    private fun block(pcb: Int, inf: ByteArray): ByteArray {
        val out = ByteArray(4 + inf.size)
        out[0] = nad.toByte()
        out[1] = pcb.toByte()
        out[2] = inf.size.toByte()
        System.arraycopy(inf, 0, out, 3, inf.size)
        out[out.size - 1] = lrc(out, out.size - 1)
        return out
    }

    /** Null when the block is shorter than a header, its LEN disagrees with its size, or the LRC is wrong. */
    private fun parse(raw: ByteArray): Block? {
        if (raw.size < 4) return null
        val len = raw[2].toInt() and 0xFF
        if (raw.size != 4 + len) return null
        if (lrc(raw, raw.size - 1) != raw[raw.size - 1]) return null
        return Block(raw[1].toInt() and 0xFF, raw.copyOfRange(3, 3 + len))
    }

    companion object {
        const val DEFAULT_IFS = 32
        private const val MAX_RETRIES = 3
        private const val S_IFS_REQUEST = 0xC1
        private const val S_IFS_RESPONSE = 0xE1
        private const val S_WTX_REQUEST = 0xC3
        private const val S_WTX_RESPONSE = 0xE3

        fun lrc(bytes: ByteArray, length: Int = bytes.size): Byte {
            var x = 0
            for (i in 0 until length) x = x xor (bytes[i].toInt() and 0xFF)
            return x.toByte()
        }
    }
}

/** What the host needs from an ATR (ISO 7816-3 §8): the first offered protocol and the T=1 parameters. */
object Atr {
    class Info(
        val firstProtocol: Int,
        /** TA(i>=3) of a T=1 group: the card's IFSC. */
        val ifsc: Int?,
        /** TC1: extra guard time. */
        val guardTime: Int? = null,
        /** TB(i>=3) of a T=1 group: BWI (high nibble) and CWI (low nibble). */
        val bwiCwi: Int? = null,
        /** TC(i>=3) of a T=1 group, bit 0: the card wants a CRC instead of the LRC. */
        val crc: Boolean = false,
        /** TS = 0x3F: inverse convention. */
        val inverse: Boolean = false,
    )

    fun parse(atr: ByteArray): Info {
        require(atr.size >= 2 && (atr[0].toInt() and 0xFF).let { it == 0x3B || it == 0x3F }) { "Not an ATR" }
        var y = (atr[1].toInt() and 0xFF) ushr 4
        var pos = 2
        var group = 1
        var firstProtocol = 0 // T=0 unless TD1 says otherwise
        var protocol = 0 // protocol announced by the previous TD
        var ifsc: Int? = null
        var guardTime: Int? = null
        var bwiCwi: Int? = null
        var checksum: Int? = null
        fun next(): Int? = atr.getOrNull(pos++)?.toInt()?.and(0xFF)
        while (true) {
            val ta = if (y and 1 != 0) next() else null
            val tb = if (y and 2 != 0) next() else null
            val tc = if (y and 4 != 0) next() else null
            val td = if (y and 8 != 0) next() else null
            if (group == 1) guardTime = tc
            // TA3, TB3, TC3 onwards belong to the protocol announced by TD(i-1); for T=1: IFSC, BWI/CWI, EDC type
            if (group >= 3 && protocol == 1) {
                if (ifsc == null) ifsc = ta
                if (bwiCwi == null) bwiCwi = tb
                if (checksum == null) checksum = tc
            }
            if (td == null) break
            if (group == 1) firstProtocol = td and 0x0F
            protocol = td and 0x0F
            y = td ushr 4
            group++
        }
        return Info(firstProtocol, ifsc, guardTime, bwiCwi, crc = (checksum ?: 0) and 1 == 1, inverse = atr[0].toInt() and 0xFF == 0x3F)
    }
}
