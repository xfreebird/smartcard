package md.moldsign.transport.usb

import md.moldsign.core.CardError
import md.moldsign.core.decodeHex
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

/** T=1 recovery limits and rarely used S-blocks, against scripted reply blocks. */
class T1EdgeCasesTest {
    private fun block(pcb: Int, inf: ByteArray = ByteArray(0)): ByteArray {
        val out = ByteArray(4 + inf.size)
        out[1] = pcb.toByte(); out[2] = inf.size.toByte()
        inf.copyInto(out, 3)
        out[out.size - 1] = T1.lrc(out, out.size - 1)
        return out
    }

    private fun scripted(vararg replies: ByteArray): Pair<T1, MutableList<ByteArray>> {
        val sent = mutableListOf<ByteArray>()
        val queue = ArrayDeque(replies.toList())
        return T1({ b, _ -> sent += b; queue.removeFirstOrNull() ?: replies.last() }, ifsc = 254) to sent
    }

    @Test fun ifsdNegotiationFailuresLeaveTheDefault() {
        assertFalse(T1({ _, _ -> throw CardError.CardNotResponding("mute") }).negotiateIfsd(254))
        assertFalse(T1({ _, _ -> block(0xE1, byteArrayOf(32)) }).negotiateIfsd(254))
        assertFalse(T1({ _, _ -> byteArrayOf(0, 0xE1.toByte()) }).negotiateIfsd(254))
    }

    @Test fun repeatedBlocksAndRetransmissionRequestsAreBounded() {
        // The card keeps sending the I-block the host already accepted.
        val (outOfSequence, _) = scripted(block(0x20, "90".decodeHex()), block(0x00, "00".decodeHex()))
        try { outOfSequence.transmit("00A4".decodeHex()); fail("out of sequence") }
        catch (error: CardError.CardNotResponding) { assertTrue(error.message!!.contains("out-of-sequence")) }

        // The card keeps asking for the same block.
        val (nak, sent) = scripted(block(0x81))
        try { nak.transmit("00A4".decodeHex()); fail("retransmission") }
        catch (error: CardError.CardNotResponding) { assertTrue(error.message!!.contains("retransmission")) }
        assertTrue(sent.size > 3)

        // Damaged replies only.
        val (damaged, _) = scripted(byteArrayOf(0, 0, 9))
        try { damaged.transmit("00A4".decodeHex()); fail("damaged") }
        catch (error: CardError.CardNotResponding) { assertTrue(error.message!!.contains("damaged")) }
    }

    @Test fun cardInitiatedIfsAndEmptyWaitingTimeExtension() {
        val (t1, sent) = scripted(block(0xC1, byteArrayOf(0x40)), block(0xC3), block(0x00, "9000".decodeHex()))
        assertArrayEquals("9000".decodeHex(), t1.transmit("00A4".decodeHex()))
        assertEquals(0xE1, sent[1][1].toInt() and 0xFF) // S(IFS response) echoes the card's value
        assertEquals(0xE3, sent[2][1].toInt() and 0xFF) // S(WTX response)
    }

    @Test fun cardMustNotAnswerBeforeTheChainIsSent() {
        val (t1, _) = scripted(block(0x00, "9000".decodeHex()))
        try { t1.transmit(ByteArray(300)); fail("early answer") }
        catch (error: CardError.CardNotResponding) { assertTrue(error.message!!.contains("before the command")) }
    }

    @Test fun descriptorLevelsAndMissingDescriptor() {
        assertEquals(Ccid.ExchangeLevel.ExtendedApdu, Ccid.Descriptor(0, 2, 0x00040000, 271).exchangeLevel)
        assertEquals(Ccid.ExchangeLevel.Character, Ccid.Descriptor(0, 2, 0, 271).exchangeLevel)
        assertEquals(Ccid.VOLTAGE_1_8V, Ccid.Descriptor(0, 2, 0, 271, voltageSupport = 4).powerSelect)
        assertEquals(Ccid.VOLTAGE_AUTO, Ccid.Descriptor(0, 2, 0, 271).powerSelect)
        assertEquals(null, Ccid.parseDescriptor("0904000002FF0000".decodeHex() + "00".decodeHex()))
    }

    @Test fun inactiveSlotIsReported() {
        val reader = object : CcidLink {
            private var reply = ByteArray(0)
            override fun send(message: ByteArray, timeoutMs: Int): Int {
                reply = Ccid.command(Ccid.RDR_TO_PC_SLOT_STATUS, 0, message[6].toInt() and 0xFF, b7 = Ccid.ICC_PRESENT_INACTIVE)
                return message.size
            }
            override fun receive(buffer: ByteArray, timeoutMs: Int): Int { reply.copyInto(buffer); return reply.size }
            override fun release() = Unit
        }
        assertEquals(CcidTransport.SlotState.Inactive, CcidTransport(reader, null, "r", null, 100).slotStatus())
    }
}
