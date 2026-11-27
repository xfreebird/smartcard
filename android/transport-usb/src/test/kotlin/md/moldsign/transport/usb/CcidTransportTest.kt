package md.moldsign.transport.usb

import md.moldsign.core.CardError
import md.moldsign.core.decodeHex
import md.moldsign.core.toHex
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

class CcidTransportTest {
    private fun transport(reader: SimulatedCcidReader, descriptor: Ccid.Descriptor? = SimulatedCcidReader.SHORT_APDU) =
        CcidTransport(reader, null, "miniLector EVO", descriptor, timeoutMs = 100)

    private inline fun <reified E : Throwable> expect(block: () -> Unit): E {
        try { block() } catch (error: Throwable) {
            if (error is E) return error
            throw AssertionError("expected ${E::class.simpleName}, got $error", error)
        }
        fail("expected ${E::class.simpleName}")
        throw AssertionError()
    }

    @Test fun shortApduReaderExchangesWholeApdus() {
        val reader = SimulatedCcidReader(apdu = { command -> command + "9000".decodeHex() })
        reader.atr = SimulatedCcidReader.T0_ATR
        val t = transport(reader)
        assertEquals("miniLector EVO", t.readerName)
        // The first APDU powers the card on.
        assertArrayEquals("00A4000C9000".decodeHex(), t.transmit("00A4000C".decodeHex()))
        assertArrayEquals(SimulatedCcidReader.T0_ATR, t.atr)
        assertEquals(listOf(Ccid.PC_TO_RDR_ICC_POWER_OFF, Ccid.PC_TO_RDR_ICC_POWER_ON, Ccid.PC_TO_RDR_XFR_BLOCK), reader.commands)
        assertEquals(CcidTransport.SlotState.Active, t.slotStatus())
        reader.cardPresent = false
        assertEquals(CcidTransport.SlotState.Absent, t.slotStatus())
    }

    @Test fun answerToResetIsThePowerOnAtr() {
        val reader = SimulatedCcidReader(apdu = { command -> command + "9000".decodeHex() })
        val t = transport(reader)
        assertNull("not powered yet", t.answerToReset())
        val session = t.session()
        assertArrayEquals(SimulatedCcidReader.COSMOX_ATR, session.answerToReset())
        assertArrayEquals(SimulatedCcidReader.COSMOX_ATR, t.answerToReset())
        session.close()
        assertNull("powered off", t.answerToReset())
    }

    @Test fun repliesSplitAcrossTransfersAndTimeExtensionsAreReassembled() {
        val big = ByteArray(600) { it.toByte() } + "9000".decodeHex()
        val reader = SimulatedCcidReader(apdu = { big })
        reader.atr = SimulatedCcidReader.T0_ATR
        val t = transport(reader)
        t.resetCard()
        reader.transferSize = 64
        reader.timeExtensions = 3
        reader.staleBeforeReply = true
        reader.emptyTransferFirst = true
        assertArrayEquals(big, t.transmit("00B0000000".decodeHex()))
    }

    @Test fun tpduReaderNegotiatesT1AndChainsBlocks() {
        val response = ByteArray(300) { (it * 3).toByte() } + "9000".decodeHex()
        val card = FakeT1Card { command -> if (command.toHex() == "0088000033") response else "6D00".decodeHex() }
        val reader = SimulatedCcidReader(t1Card = { card })
        val t = transport(reader, SimulatedCcidReader.TPDU)
        val session = t.session()
        assertEquals("miniLector EVO", session.readerName)
        // SetParameters: default Fi/Di, LRC + direct convention, TC1, TB3 0x45, no clock stop, IFSC 254, NAD 0.
        assertEquals("1110004500FE00", reader.parameters.single().toHex())
        assertEquals(254, card.ifsd)
        assertArrayEquals(response, session.transmit("0088000033".decodeHex()))
        session.close()
        assertNull(t.atr)
        assertEquals(Ccid.PC_TO_RDR_ICC_POWER_OFF, reader.commands.last())
    }

    @Test fun powerSelectionFollowsTheDescriptor() {
        val reader = SimulatedCcidReader()
        reader.atr = SimulatedCcidReader.T0_ATR
        transport(reader, Ccid.Descriptor(0, 1, 0x00020000, 271, voltageSupport = 2)).resetCard()
        transport(reader, null).resetCard()
        assertTrue(reader.commands.count { it == Ccid.PC_TO_RDR_ICC_POWER_ON } == 2)
    }

    @Test fun powerOnFailuresMapToCardErrors() {
        val reader = SimulatedCcidReader()
        val t = transport(reader)
        reader.cardPresent = false
        expect<CardError.NoCard> { t.resetCard() }
        reader.cardPresent = true
        reader.failNext = Ccid.ERR_ICC_MUTE
        expect<CardError.NoCard> { t.resetCard() }
        reader.failNext = Ccid.ERR_HW_ERROR
        expect<CardError.CardNotResponding> { t.resetCard() }
        reader.atr = ByteArray(0)
        expect<CardError.CardNotResponding> { t.resetCard() }
    }

    @Test fun tpduReaderRejectsCardsItCannotDrive() {
        val reader = SimulatedCcidReader(t1Card = { FakeT1Card { "9000".decodeHex() } })
        val t = transport(reader, SimulatedCcidReader.TPDU)
        reader.atr = SimulatedCcidReader.T0_ATR
        expect<CardError.CardNotResponding> { t.resetCard() }.also { assertTrue(it.message!!.contains("T=0")) }
        reader.atr = "3F".decodeHex()
        expect<CardError.CardNotResponding> { t.resetCard() }
        // TS=3B, TD1=81 (T=1), TD2=71 (T=1): TA3 20, TB3 45, TC3 01 = CRC.
        reader.atr = "3B80817120".decodeHex() + "4501".decodeHex()
        expect<CardError.CardNotResponding> { t.resetCard() }.also { assertTrue(it.message!!.contains("CRC")) }
        reader.atr = SimulatedCcidReader.COSMOX_ATR
        reader.failParameters = true
        expect<CardError.CardNotResponding> { t.resetCard() }.also { assertTrue(it.message!!.contains("SetParameters")) }
    }

    @Test fun t1BlockFailuresDropTheCardSession() {
        val reader = SimulatedCcidReader(t1Card = { FakeT1Card { "9000".decodeHex() } })
        val t = transport(reader, SimulatedCcidReader.TPDU)
        t.resetCard()
        reader.failNext = Ccid.ERR_ICC_MUTE
        expect<CardError.CardNotResponding> { t.transmit("00A4000C".decodeHex()) }
        assertNull(t.atr)
        // The next APDU powers the card up again with a fresh T=1 engine.
        assertArrayEquals("9000".decodeHex(), t.transmit("00A4000C".decodeHex()))
        reader.cardPresent = false
        expect<CardError.NoCard> { t.transmit("00A4000C".decodeHex()) }
        reader.cardPresent = true
        t.resetCard()
        reader.failNext = Ccid.ERR_HW_ERROR
        expect<CardError.CardNotResponding> { t.transmit("00A4000C".decodeHex()) }
        t.resetCard()
        reader.replyType = Ccid.RDR_TO_PC_SLOT_STATUS
        expect<CardError.CardNotResponding> { t.transmit("00A4000C".decodeHex()) }
    }

    @Test fun t1ResponseWithoutStatusWordIsRejected() {
        val reader = SimulatedCcidReader(t1Card = { FakeT1Card { "90".decodeHex() } })
        val t = transport(reader, SimulatedCcidReader.TPDU)
        expect<CardError.CardNotResponding> { t.transmit("00A4000C".decodeHex()) }
    }

    @Test fun shortApduFailuresMapToCardErrors() {
        val reader = SimulatedCcidReader()
        reader.atr = SimulatedCcidReader.T0_ATR
        val t = transport(reader)
        t.resetCard()
        reader.cardPresent = false
        expect<CardError.NoCard> { t.transmit("00".decodeHex()) }
        reader.cardPresent = true
        t.resetCard()
        reader.failNext = Ccid.ERR_ICC_MUTE
        expect<CardError.CardNotResponding> { t.transmit("00".decodeHex()) }.also { assertTrue(it.message!!.contains("mute")) }
        reader.failNext = Ccid.ERR_HW_ERROR
        expect<CardError.CardNotResponding> { t.transmit("00".decodeHex()) }
        reader.replyType = Ccid.RDR_TO_PC_SLOT_STATUS
        expect<CardError.CardNotResponding> { t.transmit("00".decodeHex()) }
        reader.replyType = null
        reader.shortReply = true
        expect<CardError.CardNotResponding> { t.transmit("00".decodeHex()) }
    }

    @Test fun usbFailuresAreReported() {
        val reader = SimulatedCcidReader()
        val t = transport(reader)
        reader.failSend = true
        expect<CardError.CardNotResponding> { t.slotStatus() }
        reader.failSend = false
        reader.receiveTimeout = true
        expect<CardError.CardNotResponding> { t.slotStatus() }.also { assertTrue(it.message!!.contains("timeout")) }
        reader.receiveTimeout = false
        reader.hugeLength = true
        expect<CardError.CardNotResponding> { t.slotStatus() }.also { assertTrue(it.message!!.contains("too long")) }
    }

    @Test fun endlessTimeExtensionsGiveUp() {
        val reader = SimulatedCcidReader()
        val t = transport(reader)
        reader.timeExtensions = 201
        expect<CardError.CardNotResponding> { t.slotStatus() }
    }

    @Test fun closingPowersOffAndReleasesTheInterfaceOnce() {
        val reader = SimulatedCcidReader()
        reader.atr = SimulatedCcidReader.T0_ATR
        val t = transport(reader)
        t.resetCard()
        t.close()
        assertTrue(reader.released)
        val sent = reader.commands.size
        t.close()
        t.powerOff()
        assertEquals(sent, reader.commands.size)
        expect<CardError.NoReader> { t.slotStatus() }
    }
}
