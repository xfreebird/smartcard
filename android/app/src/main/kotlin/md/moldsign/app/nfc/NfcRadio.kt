package md.moldsign.app.nfc

import android.app.Activity
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.IsoDep
import android.os.Bundle

/** The NFC adapter as the signing controller uses it; tests substitute a simulated radio. */
internal interface NfcRadio : NfcReaderModeGate.Radio<Activity, NfcTagHandle> {
    val available: Boolean
    val enabled: Boolean
}

/** One discovered tag. [isoDep] gives a fresh, unconnected ISO-DEP technology object, or null for other cards. */
internal interface NfcTagHandle {
    fun isoDep(): IsoDepLink?
}

/** The subset of [IsoDep] a session uses. */
internal interface IsoDepLink : java.io.Closeable {
    val maxTransceiveLength: Int
    var timeout: Int
    fun connect()
    fun transceive(apdu: ByteArray): ByteArray
}

internal class AndroidNfcRadio(private val adapter: NfcAdapter?) : NfcRadio {
    override val available: Boolean get() = adapter != null
    override val enabled: Boolean get() = adapter?.isEnabled == true

    override fun enable(host: Activity, onTag: (NfcTagHandle) -> Unit) {
        requireNotNull(adapter).enableReaderMode(host, { tag -> onTag(AndroidTag(tag)) }, READER_FLAGS,
            Bundle().apply { putInt(NfcAdapter.EXTRA_READER_PRESENCE_CHECK_DELAY, PRESENCE_CHECK_MS) })
    }

    override fun disable(host: Activity) { adapter?.disableReaderMode(host) }

    override fun ignore(tag: NfcTagHandle): Boolean =
        adapter != null && tag is AndroidTag && adapter.ignore(tag.tag, IGNORE_DEBOUNCE_MS, null, null)

    private class AndroidTag(val tag: Tag) : NfcTagHandle {
        override fun isoDep(): IsoDepLink? = IsoDep.get(tag)?.let(::AndroidIsoDep)
    }

    private class AndroidIsoDep(private val iso: IsoDep) : IsoDepLink {
        override val maxTransceiveLength: Int get() = iso.maxTransceiveLength
        override var timeout: Int
            get() = iso.timeout
            set(value) { iso.timeout = value }
        override fun connect() = iso.connect()
        override fun transceive(apdu: ByteArray): ByteArray = iso.transceive(apdu)
        override fun close() = iso.close()
    }

    companion object {
        /** NFC-A/B ID cards only, no NDEF probing of the eID, no early system sound. */
        const val READER_FLAGS = NfcAdapter.FLAG_READER_NFC_A or NfcAdapter.FLAG_READER_NFC_B or
            NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK or NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS
        const val PRESENCE_CHECK_MS = 250
        /** How long a released card must stay out of range before Android may dispatch it again. */
        const val IGNORE_DEBOUNCE_MS = 1_000
    }
}
