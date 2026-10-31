package md.moldsign.core

/**
 * Card transport contract (docs/09 §3.1): raw command APDU in, raw response INCLUDING SW1 SW2 out.
 * No GET RESPONSE handling here: [CosmoXCard] loops on `61xx` itself.
 *
 * Implementations: `md.moldsign.transport.usb.CcidTransport` (Android USB host, module
 * `:transport-usb`); NFC `IsoDep` is research item R-03 / AND-09.
 */
interface ApduTransport : java.io.Closeable {
    val readerName: String

    /** Throws [CardError] (NoReader / NoCard / CardNotResponding) on transport failure. */
    fun transmit(apdu: ByteArray): ByteArray
}

/** Response APDU split into data and status word. */
class ApduResponse(val data: ByteArray, val sw: Int) {
    val sw1: Int get() = sw ushr 8
    val sw2: Int get() = sw and 0xFF
    val isOk: Boolean get() = sw == 0x9000

    override fun toString(): String = "ApduResponse(data=${data.size}B, sw=%04X)".format(sw)

    companion object {
        /** Splits a raw transport response (data ‖ SW1 SW2). */
        fun parse(raw: ByteArray): ApduResponse {
            if (raw.size < 2) throw CardError.CardNotResponding("Response shorter than a status word (${raw.size} B)")
            val sw = (raw.u8(raw.size - 2) shl 8) or raw.u8(raw.size - 1)
            return ApduResponse(raw.copyOfRange(0, raw.size - 2), sw)
        }
    }
}
