package md.moldsign.transport.usb

/**
 * USB CCID 1.1 message framing (pure Kotlin, no Android types, unit-tested on the JVM).
 *
 * Every bulk message has a 10-byte header:
 * `bMessageType | dwLength (LE) | bSlot | bSeq | 3 message-specific bytes`, followed by dwLength bytes.
 */
object Ccid {
    const val HEADER_SIZE = 10

    // Host → reader (bulk OUT)
    const val PC_TO_RDR_ICC_POWER_ON = 0x62
    const val PC_TO_RDR_ICC_POWER_OFF = 0x63
    const val PC_TO_RDR_GET_SLOT_STATUS = 0x65
    const val PC_TO_RDR_SET_PARAMETERS = 0x61
    const val PC_TO_RDR_XFR_BLOCK = 0x6F

    // Reader → host (bulk IN / interrupt IN)
    const val RDR_TO_PC_DATA_BLOCK = 0x80
    const val RDR_TO_PC_SLOT_STATUS = 0x81
    const val RDR_TO_PC_NOTIFY_SLOT_CHANGE = 0x50

    // bmICCStatus (bStatus bits 0..1)
    const val ICC_PRESENT_ACTIVE = 0
    const val ICC_PRESENT_INACTIVE = 1
    const val ICC_ABSENT = 2

    // bmCommandStatus (bStatus bits 6..7)
    const val CMD_OK = 0
    const val CMD_FAILED = 1
    const val CMD_TIME_EXTENSION = 2

    // bError values of interest (CCID §6.2.6)
    const val ERR_ICC_MUTE = 0xFE
    const val ERR_XFR_PARITY = 0xFD
    const val ERR_HW_ERROR = 0xFB
    const val ERR_CMD_SLOT_BUSY = 0xE0

    /** bPowerSelect: 0 = automatic voltage selection (only if the reader advertises it), else 1 = 5 V, 2 = 3 V, 3 = 1.8 V. */
    const val VOLTAGE_AUTO = 0
    const val VOLTAGE_5V = 1
    const val VOLTAGE_3V = 2
    const val VOLTAGE_1_8V = 3

    fun command(type: Int, slot: Int, seq: Int, data: ByteArray = ByteArray(0), b7: Int = 0, b8: Int = 0, b9: Int = 0): ByteArray {
        val out = ByteArray(HEADER_SIZE + data.size)
        out[0] = type.toByte()
        val len = data.size
        out[1] = len.toByte()
        out[2] = (len ushr 8).toByte()
        out[3] = (len ushr 16).toByte()
        out[4] = (len ushr 24).toByte()
        out[5] = slot.toByte()
        out[6] = seq.toByte()
        out[7] = b7.toByte()
        out[8] = b8.toByte()
        out[9] = b9.toByte()
        System.arraycopy(data, 0, out, HEADER_SIZE, data.size)
        return out
    }

    fun iccPowerOn(slot: Int, seq: Int, voltage: Int = VOLTAGE_AUTO) = command(PC_TO_RDR_ICC_POWER_ON, slot, seq, b7 = voltage)

    fun iccPowerOff(slot: Int, seq: Int) = command(PC_TO_RDR_ICC_POWER_OFF, slot, seq)

    fun getSlotStatus(slot: Int, seq: Int) = command(PC_TO_RDR_GET_SLOT_STATUS, slot, seq)

    /**
     * Tells the reader which protocol the card uses and with what parameters. A TPDU reader without
     * "automatic parameter negotiation" (dwFeatures 0x40, like the miniLector EVO) stays in its T=0 default until
     * it gets this: it then takes a T=1 block for a malformed TPDU. [protocol] is 0 (T=0) or 1 (T=1); the T=1 block
     * is `bmFindexDindex | bmTCCKST1 | bGuardTimeT1 | bmWaitingIntegersT1 | bClockStop | bIFSC | bNadValue`.
     */
    fun setParameters(slot: Int, seq: Int, protocol: Int, parameters: ByteArray) =
        command(PC_TO_RDR_SET_PARAMETERS, slot, seq, parameters, b7 = protocol)

    /** Short-APDU exchange: bBWI = 0, wLevelParameter = 0 (a complete APDU in one block). */
    fun xfrBlock(slot: Int, seq: Int, apdu: ByteArray, bwi: Int = 0, levelParameter: Int = 0) =
        command(PC_TO_RDR_XFR_BLOCK, slot, seq, apdu, b7 = bwi, b8 = levelParameter and 0xFF, b9 = levelParameter ushr 8)

    /** Next bSeq (wraps at 255). */
    fun nextSeq(seq: Int): Int = (seq + 1) and 0xFF

    /** dwLength of a (possibly partial) message whose header is complete. */
    fun messageLength(buf: ByteArray): Int {
        require(buf.size >= HEADER_SIZE) { "CCID header needs 10 bytes" }
        return (buf[1].toInt() and 0xFF) or ((buf[2].toInt() and 0xFF) shl 8) or
            ((buf[3].toInt() and 0xFF) shl 16) or ((buf[4].toInt() and 0xFF) shl 24)
    }

    class Response(
        val type: Int,
        val slot: Int,
        val seq: Int,
        val status: Int,
        val error: Int,
        /** bChainParameter (DataBlock) or bClockStatus (SlotStatus). */
        val specific: Int,
        val data: ByteArray,
    ) {
        val iccStatus: Int get() = status and 0x03
        val commandStatus: Int get() = (status ushr 6) and 0x03
        val isTimeExtension: Boolean get() = commandStatus == CMD_TIME_EXTENSION
        val isFailed: Boolean get() = commandStatus == CMD_FAILED

        override fun toString() =
            "CCID(type=%02X slot=%d seq=%d status=%02X error=%02X len=%d)".format(type, slot, seq, status, error, data.size)
    }

    /** Parses a complete RDR_to_PC message (header + dwLength bytes). */
    fun parse(buf: ByteArray, size: Int = buf.size): Response {
        require(size >= HEADER_SIZE) { "Short CCID message ($size B)" }
        val len = messageLength(buf)
        require(len in 0..(size - HEADER_SIZE)) { "Truncated CCID message: dwLength=$len, have ${size - HEADER_SIZE}" }
        return Response(
            type = buf[0].toInt() and 0xFF,
            slot = buf[5].toInt() and 0xFF,
            seq = buf[6].toInt() and 0xFF,
            status = buf[7].toInt() and 0xFF,
            error = buf[8].toInt() and 0xFF,
            specific = buf[9].toInt() and 0xFF,
            data = buf.copyOfRange(HEADER_SIZE, HEADER_SIZE + len),
        )
    }

    /**
     * RDR_to_PC_NotifySlotChange (interrupt IN): `50 bmSlotICCState…`, 2 bits per slot
     * (bit 0 = present, bit 1 = changed). Returns presence for [slot], or null if not a notification.
     */
    fun notifySlotPresent(msg: ByteArray, slot: Int = 0): Boolean? {
        if (msg.isEmpty() || (msg[0].toInt() and 0xFF) != RDR_TO_PC_NOTIFY_SLOT_CHANGE) return null
        val bitIndex = slot * 2
        val byteIndex = 1 + bitIndex / 8
        if (byteIndex >= msg.size) return null
        return ((msg[byteIndex].toInt() ushr (bitIndex % 8)) and 0x01) == 1
    }

    /** Fields of the CCID class descriptor (type 0x21, 54 bytes) that the driver needs. */
    data class Descriptor(
        val maxSlotIndex: Int,
        val protocols: Int,
        val features: Int,
        val maxMessageLength: Int,
        /** dwMaxIFSD: the largest T=1 information field the reader accepts from the card (TPDU level). */
        val maxIfsd: Int = 0,
        /** bVoltageSupport: bit 0 = 5 V, bit 1 = 3 V, bit 2 = 1.8 V. */
        val voltageSupport: Int = 0,
    ) {
        /**
         * bPowerSelect for IccPowerOn. Like libccid: automatic when the reader selects the voltage or activates the card
         * itself (dwFeatures 0x08 / 0x04), otherwise an explicit voltage, 5 V first.
         */
        val powerSelect: Int
            get() = when {
                (features and (0x00000008 or 0x00000004)) != 0 -> VOLTAGE_AUTO // auto voltage / auto activation, as libccid
                (voltageSupport and 0x01) != 0 -> VOLTAGE_5V
                (voltageSupport and 0x02) != 0 -> VOLTAGE_3V
                (voltageSupport and 0x04) != 0 -> VOLTAGE_1_8V
                else -> VOLTAGE_AUTO
            }

        val exchangeLevel: ExchangeLevel
            get() = when {
                (features and 0x00040000) != 0 -> ExchangeLevel.ExtendedApdu
                (features and 0x00020000) != 0 -> ExchangeLevel.ShortApdu
                (features and 0x00010000) != 0 -> ExchangeLevel.Tpdu
                else -> ExchangeLevel.Character
            }

        /** T=1 supported (dwProtocols bit 1). */
        val supportsT1: Boolean get() = (protocols and 0x02) != 0
    }

    enum class ExchangeLevel { Character, Tpdu, ShortApdu, ExtendedApdu }

    /**
     * Finds the CCID class descriptor in a raw configuration descriptor blob
     * (`UsbDeviceConnection.rawDescriptors`): a 0x21 descriptor following an interface with class 0x0B
     * (or vendor class 0xFF, which some readers use with a CCID-layout descriptor).
     */
    fun parseDescriptor(raw: ByteArray): Descriptor? {
        var pos = 0
        var interfaceClass = -1
        while (pos + 1 < raw.size) {
            val len = raw[pos].toInt() and 0xFF
            if (len < 2 || pos + len > raw.size) break
            when (raw[pos + 1].toInt() and 0xFF) {
                0x04 -> if (len >= 9) interfaceClass = raw[pos + 5].toInt() and 0xFF
                0x21 -> if (len >= 0x36 && (interfaceClass == 0x0B || interfaceClass == 0xFF)) {
                    fun le32(off: Int) = (raw[pos + off].toInt() and 0xFF) or ((raw[pos + off + 1].toInt() and 0xFF) shl 8) or
                        ((raw[pos + off + 2].toInt() and 0xFF) shl 16) or ((raw[pos + off + 3].toInt() and 0xFF) shl 24)
                    return Descriptor(
                        maxSlotIndex = raw[pos + 4].toInt() and 0xFF,
                        protocols = le32(6),
                        features = le32(40),
                        maxMessageLength = le32(44),
                        maxIfsd = le32(28),
                        voltageSupport = raw[pos + 5].toInt() and 0xFF,
                    )
                }
            }
            pos += len
        }
        return null
    }
}
