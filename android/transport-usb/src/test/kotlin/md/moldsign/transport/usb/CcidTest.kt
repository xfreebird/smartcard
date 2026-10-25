package md.moldsign.transport.usb

import md.moldsign.core.decodeHex
import md.moldsign.core.toHex
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class CcidTest {
    @Test
    fun commandHeaders() {
        assertEquals("62000000000003000000", Ccid.iccPowerOn(slot = 0, seq = 3).toHex())
        assertEquals("63000000000004000000", Ccid.iccPowerOff(0, 4).toHex())
        assertEquals("650000000000FF000000", Ccid.getSlotStatus(0, 255).toHex())
        // 6F | dwLength=8 (LE) | slot 0 | seq 7 | bBWI 0 | wLevelParameter 0000 | APDU
        assertEquals("6F" + "08000000" + "00" + "07" + "00" + "0000" + "00A4000C023F0000", Ccid.xfrBlock(0, 7, "00A4000C023F0000".decodeHex()).toHex())
    }

    @Test
    fun sequenceWrapsAt255() {
        assertEquals(0, Ccid.nextSeq(255))
        assertEquals(1, Ccid.nextSeq(0))
    }

    @Test
    fun parseDataBlockWithAtr() {
        val atr = "3BDF96008131FE45807384 21E0574D44415F415350810F78".replace(" ", "")
        val msg = ("80" + "18000000" + "00" + "05" + "00" + "00" + "00" + atr).decodeHex()
        val r = Ccid.parse(msg)
        assertEquals(Ccid.RDR_TO_PC_DATA_BLOCK, r.type)
        assertEquals(5, r.seq)
        assertEquals(Ccid.CMD_OK, r.commandStatus)
        assertEquals(Ccid.ICC_PRESENT_ACTIVE, r.iccStatus)
        assertEquals(atr, r.data.toHex())
    }

    @Test
    fun timeExtensionAndFailureStatus() {
        val ext = Ccid.parse("80000000000009800100".decodeHex())
        assertTrue(ext.isTimeExtension)
        val mute = Ccid.parse("81000000000002 41 FE 00".replace(" ", "").decodeHex())
        assertTrue(mute.isFailed)
        assertEquals(Ccid.ICC_PRESENT_INACTIVE, mute.iccStatus)
        assertEquals(Ccid.ERR_ICC_MUTE, mute.error)
        val absent = Ccid.parse("81000000000003420000".decodeHex())
        assertEquals(Ccid.ICC_ABSENT, absent.iccStatus)
    }

    @Test(expected = IllegalArgumentException::class)
    fun truncatedMessageRejected() {
        Ccid.parse("8005000000000100009000".decodeHex())
    }

    @Test
    fun notifySlotChange() {
        assertEquals(true, Ccid.notifySlotPresent("5003".decodeHex()))
        assertEquals(false, Ccid.notifySlotPresent("5002".decodeHex()))
        assertNull(Ccid.notifySlotPresent("8100".decodeHex()))
    }

    @Test
    fun parsesCcidClassDescriptor() {
        val config = "09022D00010100A032"                       // configuration
        val iface = "0904000003 0B 0000 00".replace(" ", "")      // interface, class 0x0B
        val ccid = StringBuilder("3621" + "1001" + "00" + "07" + "03000000") // bLength..dwProtocols (T=0|T=1)
            .append("A00F0000").append("A00F0000").append("00")          // clocks
            .append("80250000").append("80250000").append("00")          // data rates
            .append("FE000000").append("00000000").append("00000000")    // IFSD, synch, mechanical
            .append("BA040200")                                            // dwFeatures: short APDU + auto flags
            .append("0F010000")                                            // dwMaxCCIDMessageLength = 271
            .append("FF").append("FF").append("0000").append("00").append("01")
            .toString()
        val d = Ccid.parseDescriptor((config + iface + ccid).decodeHex())!!
        assertEquals(Ccid.ExchangeLevel.ShortApdu, d.exchangeLevel)
        assertEquals(271, d.maxMessageLength)
        assertEquals(254, d.maxIfsd)
        assertEquals(0x07, d.voltageSupport)
        assertTrue(d.supportsT1)
    }

    @Test
    fun powerSelectFollowsLibccid() {
        fun descriptor(features: Int, voltages: Int) = Ccid.Descriptor(0, 3, features, 271, voltageSupport = voltages)
        // miniLector EVO (0x000100B6, 3 V only): the reader activates the card itself, so automatic selection
        assertEquals(Ccid.VOLTAGE_AUTO, descriptor(0x000100B6, 0x02).powerSelect)
        assertEquals(Ccid.VOLTAGE_AUTO, descriptor(0x00010008, 0x07).powerSelect)
        assertEquals(Ccid.VOLTAGE_5V, descriptor(0x00010000, 0x07).powerSelect)
        assertEquals(Ccid.VOLTAGE_3V, descriptor(0x00010000, 0x06).powerSelect)
        assertEquals(Ccid.VOLTAGE_1_8V, descriptor(0x00010000, 0x04).powerSelect)
    }

    @Test
    fun setParametersCarriesTheProtocolInTheHeader() {
        // 61 | dwLength=7 | slot 0 | seq 9 | bProtocolNum 1 | RFU RFU | T=1 parameter block
        assertEquals(
            "61" + "07000000" + "00" + "09" + "01" + "0000" + "1110004500FE00",
            Ccid.setParameters(0, 9, 1, "1110004500FE00".decodeHex()).toHex(),
        )
    }
}
