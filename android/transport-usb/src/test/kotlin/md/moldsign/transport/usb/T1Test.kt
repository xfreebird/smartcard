package md.moldsign.transport.usb

import java.io.ByteArrayOutputStream
import md.moldsign.core.CardError
import md.moldsign.core.decodeHex
import md.moldsign.core.toHex
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** A T=1 card that answers whole APDUs through [handler] and chains with the IFSD the host negotiated. */
private class FakeT1Card(private val handler: (ByteArray) -> ByteArray) {
    var ifsd = 32
    var corruptNextReply = false
    var wtxBeforeReply = 0
    val wtxBwi = mutableListOf<Int>()
    val receivedBlocks = mutableListOf<ByteArray>()

    private var hostNs = 0 // N(S) expected from the host
    private var cardNs = 0 // N(S) of the card's next I-block
    private val command = ByteArrayOutputStream()
    private val pending = ArrayDeque<ByteArray>()
    private var lastReply: ByteArray = ByteArray(0)
    private var sentNs = 0

    fun transceive(block: ByteArray, bwi: Int): ByteArray {
        receivedBlocks += block
        require(T1.lrc(block, block.size - 1) == block.last()) { "host sent a bad LRC" }
        val pcb = block[1].toInt() and 0xFF
        val inf = block.copyOfRange(3, block.size - 1)
        return when {
            pcb == 0xC1 -> { ifsd = inf[0].toInt() and 0xFF; send(0xE1, inf, plain = true) }
            pcb == 0xE3 -> { wtxBwi += bwi; nextChunk() }
            pcb and 0x80 == 0 -> { // I-block
                require((pcb ushr 6) and 1 == hostNs) { "host N(S) out of sequence" }
                command.write(inf)
                hostNs = hostNs xor 1
                if (pcb and 0x20 != 0) {
                    send(0x80 or (hostNs shl 4), ByteArray(0), plain = true)
                } else {
                    val response = handler(command.toByteArray())
                    command.reset()
                    response.asList().chunked(ifsd).map { it.toByteArray() }.forEach { pending.addLast(it) }
                    if (wtxBeforeReply > 0) {
                        send(0xC3, byteArrayOf(wtxBeforeReply.toByte()), plain = true).also { wtxBeforeReply = 0 }
                    } else {
                        nextChunk()
                    }
                }
            }
            else -> { // R-block from the host
                val nr = (pcb ushr 4) and 1
                if (nr == cardNs && pending.isNotEmpty()) nextChunk() else lastReply // ack, or repeat on NAK
            }
        }
    }

    private fun nextChunk(): ByteArray {
        val chunk = pending.removeFirst()
        sentNs = cardNs
        cardNs = cardNs xor 1
        val more = pending.isNotEmpty()
        return send((sentNs shl 6) or (if (more) 0x20 else 0), chunk, plain = false)
    }

    private fun send(pcb: Int, inf: ByteArray, plain: Boolean): ByteArray {
        val b = ByteArray(4 + inf.size)
        b[1] = pcb.toByte()
        b[2] = inf.size.toByte()
        System.arraycopy(inf, 0, b, 3, inf.size)
        b[b.size - 1] = T1.lrc(b, b.size - 1)
        lastReply = b.copyOf()
        if (!plain && corruptNextReply) {
            corruptNextReply = false
            b[b.size - 1] = (b.last().toInt() xor 0x55).toByte()
        }
        return b
    }
}

class T1Test {
    private fun t1For(card: FakeT1Card, ifsc: Int = 254) = T1(card::transceive, ifsc)

    @Test
    fun shortApduInOneBlockEachWay() {
        val card = FakeT1Card { "6F00".decodeHex() }
        assertArrayEquals("6F00".decodeHex(), t1For(card).transmit("00A4000C".decodeHex()))
        // NAD 00 | PCB 00 (I-block, N(S)=0) | LEN 04 | INF | LRC = 04 ^ A4 ^ 0C = AC
        assertEquals("000004" + "00A4000C" + "AC", card.receivedBlocks[0].toHex())
    }

    @Test
    fun commandLongerThanIfscIsChainedAndAcknowledged() {
        val command = ByteArray(300) { (it * 7).toByte() }
        var seen: ByteArray? = null
        val card = FakeT1Card { seen = it; "9000".decodeHex() }
        val t1 = t1For(card, ifsc = 254)
        assertArrayEquals("9000".decodeHex(), t1.transmit(command))
        assertArrayEquals(command, seen)
        assertEquals(2, card.receivedBlocks.size) // 254 + 46 bytes, the first with M=1
        assertEquals(0x20, card.receivedBlocks[0][1].toInt() and 0xFF) // I-block, N(S)=0, more
        assertEquals(0x40, card.receivedBlocks[1][1].toInt() and 0xFF) // I-block, N(S)=1, last
    }

    @Test
    fun responseChainedByTheCardIsReassembledWithRBlocks() {
        val response = ByteArray(549) { it.toByte() } + "9000".decodeHex()
        val card = FakeT1Card { response }
        card.ifsd = 254
        val t1 = t1For(card)
        assertArrayEquals(response, t1.transmit("0088000033".decodeHex()))
        // I-block, then R(N(R)=1) and R(N(R)=0) acknowledging the card's first two chained blocks
        assertEquals(0x90, card.receivedBlocks[1][1].toInt() and 0xFF)
        assertEquals(0x80, card.receivedBlocks[2][1].toInt() and 0xFF)
    }

    @Test
    fun defaultIfsdChainsInThirtyTwoByteBlocks() {
        val response = ByteArray(100) { it.toByte() } + "9000".decodeHex()
        val card = FakeT1Card { response }
        assertArrayEquals(response, t1For(card).transmit("00B0000000".decodeHex()))
        assertEquals(1 + 3, card.receivedBlocks.size) // 102 bytes at IFSD 32: 4 blocks, 3 acknowledged
    }

    @Test
    fun ifsdNegotiationIsAcceptedAndRaisesTheCardChunkSize() {
        val card = FakeT1Card { ByteArray(200) + "9000".decodeHex() }
        val t1 = t1For(card)
        assertTrue(t1.negotiateIfsd(254))
        assertEquals(254, card.ifsd)
        t1.transmit("00".decodeHex())
        assertEquals(2, card.receivedBlocks.size) // S(IFS) + one I-block: the 202 bytes fit a single block
    }

    @Test
    fun waitingTimeExtensionIsAnsweredAndExtendsTheReaderTimeout() {
        val card = FakeT1Card { "9000".decodeHex() }
        card.wtxBeforeReply = 5
        assertArrayEquals("9000".decodeHex(), t1For(card).transmit("00880000".decodeHex()))
        assertEquals(listOf(5), card.wtxBwi) // bBWI carried the multiplier on the XfrBlock holding S(WTX response)
    }

    @Test
    fun damagedReplyIsRepeatedAfterAnRBlockWithErrorBit() {
        val card = FakeT1Card { "6A82".decodeHex() }
        card.corruptNextReply = true
        assertArrayEquals("6A82".decodeHex(), t1For(card).transmit("00A4040C".decodeHex()))
        assertEquals(0x81, card.receivedBlocks[1][1].toInt() and 0xFF) // R(N(R)=0, EDC error)
    }

    @Test
    fun sequenceBitsToggleAcrossApdus() {
        val card = FakeT1Card { "9000".decodeHex() }
        val t1 = t1For(card)
        t1.transmit("00A4000C".decodeHex())
        t1.transmit("00A4000C".decodeHex())
        t1.transmit("00A4000C".decodeHex())
        assertEquals(listOf(0x00, 0x40, 0x00), card.receivedBlocks.map { it[1].toInt() and 0xFF })
    }

    @Test
    fun unexpectedSBlockFails() {
        val t1 = T1({ _, _ -> byteArrayOf(0, 0xC2.toByte(), 0, 0xC2.toByte()) }, 254) // S(ABORT request)
        try {
            t1.transmit("00".decodeHex())
            throw AssertionError("expected CardError")
        } catch (e: CardError) {
            assertTrue(e.message!!.contains("S-block"))
        }
    }

    @Test
    fun atrOfTheCosmoXCardOffersT1WithIfsc254() {
        val atr = "3BDF96008131FE45807384" + "21E0574D44415F415350810F78"
        val info = Atr.parse(atr.decodeHex())
        assertEquals(1, info.firstProtocol)
        assertEquals(254, info.ifsc)
        assertEquals(0x00, info.guardTime) // TC1
        assertEquals(0x45, info.bwiCwi) // TB3: BWI 4, CWI 5
        assertFalse(info.crc)
        assertFalse(info.inverse)
    }

    @Test
    fun atrWithCrcAndInverseConvention() {
        // TS=3F, TD1=81 (T=1), TD2=71 (T=1): TA3=20 IFSC, TB3=45, TC3=01 = CRC
        val info = Atr.parse("3F80817120" .decodeHex() + "4501".decodeHex())
        assertEquals(32, info.ifsc)
        assertEquals(0x45, info.bwiCwi)
        assertTrue(info.crc)
        assertTrue(info.inverse)
    }

    @Test
    fun atrWithoutInterfaceBytesIsT0WithoutIfsc() {
        val info = Atr.parse("3B00".decodeHex())
        assertEquals(0, info.firstProtocol)
        assertNull(info.ifsc)
    }
}
