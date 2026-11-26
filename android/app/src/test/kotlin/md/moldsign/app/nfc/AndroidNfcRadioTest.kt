package md.moldsign.app.nfc

import android.app.Activity
import android.app.Application
import android.content.Context
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.IsoDep
import android.os.Bundle
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowNfcAdapter
import java.lang.reflect.Proxy

/** AndroidNfcRadio against Robolectric's NfcAdapter and IsoDep: reader-mode flags, tags, ISO-DEP and ignore. */
@RunWith(RobolectricTestRunner::class)
@Config(application = Application::class)
class AndroidNfcRadioTest {
    private val context = ApplicationProvider.getApplicationContext<Application>()
    private val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    private lateinit var adapter: NfcAdapter
    private val ignored = mutableListOf<Int>()

    @Before fun nfcHardware() {
        ShadowNfcAdapter.setNfcHardwareExists(true)
        shadowOf(context.packageManager).setSystemFeature(android.content.pm.PackageManager.FEATURE_NFC, true)
        adapter = NfcAdapter::class.java.getDeclaredMethod("getNfcAdapter", Context::class.java)
            .apply { isAccessible = true }.invoke(null, context) as NfcAdapter
        // NfcAdapter.ignore talks to the NFC service; a stand-in records the debounce it receives.
        val service = Class.forName("android.nfc.INfcAdapter")
        val proxy = Proxy.newProxyInstance(service.classLoader, arrayOf(service)) { _, method, args ->
            when (method.name) {
                "ignore" -> { ignored += args[1] as Int; args[0] as Int != STALE_HANDLE }
                else -> when (method.returnType) { java.lang.Boolean.TYPE -> false; Integer.TYPE -> 0; else -> null }
            }
        }
        NfcAdapter::class.java.getDeclaredField("sService").apply { isAccessible = true }.set(null, proxy)
    }

    @After fun noHardware() {
        NfcAdapter::class.java.getDeclaredField("sService").apply { isAccessible = true }.set(null, null)
        ShadowNfcAdapter.setNfcHardwareExists(false)
    }

    private fun tag(techs: IntArray, handle: Int = 1): Tag =
        Tag::class.java.getMethod("createMockTag", ByteArray::class.java, IntArray::class.java, Array<Bundle>::class.java, java.lang.Long.TYPE)
            .invoke(null, byteArrayOf(1, 2, 3, 4), techs, Array(techs.size) { Bundle() }, 0L).let { mock ->
                // Give the mock the service handle Android would assign.
                Tag::class.java.getDeclaredField("mServiceHandle").apply { isAccessible = true }.setInt(mock, handle)
                mock as Tag
            }

    @Test fun readerModeUsesTheCardFlagsAndRoutesTags() {
        val radio = AndroidNfcRadio(adapter)
        assertTrue(radio.available)
        shadowOf(adapter).setEnabled(false)
        assertFalse(radio.enabled)
        shadowOf(adapter).setEnabled(true)
        assertTrue(radio.enabled)

        val seen = mutableListOf<NfcTagHandle>()
        radio.enable(activity) { seen += it }
        assertTrue(shadowOf(adapter).isInReaderMode)
        assertEquals(AndroidNfcRadio.PRESENCE_CHECK_MS, shadowOf(adapter).readerModeExtras.getInt(NfcAdapter.EXTRA_READER_PRESENCE_CHECK_DELAY))

        shadowOf(adapter).dispatchTagDiscovered(tag(intArrayOf(ISO_DEP)))
        shadowOf(adapter).dispatchTagDiscovered(tag(intArrayOf(NFC_A)))
        assertEquals(2, seen.size)
        assertNull("not an ISO-DEP card", seen[1].isoDep())

        val link = requireNotNull(seen[0].isoDep())
        val iso = link.javaClass.getDeclaredField("iso").apply { isAccessible = true }.get(link) as IsoDep
        shadowOf(iso).setMaxTransceiveLength(261)
        shadowOf(iso).setTransceiveResponse(byteArrayOf(0x90.toByte(), 0))
        link.connect()
        link.timeout = 8_000
        assertEquals(8_000, link.timeout)
        assertEquals(261, link.maxTransceiveLength)
        assertArrayEquals(byteArrayOf(0x90.toByte(), 0), link.transceive(byteArrayOf(0, 0xA4.toByte(), 4, 0)))
        link.close()

        radio.disable(activity)
        assertFalse(shadowOf(adapter).isInReaderMode)
        assertEquals(READER_FLAGS_EXPECTED, AndroidNfcRadio.READER_FLAGS)
    }

    @Test fun ignoreHandsTheTagBackWithTheDebounce() {
        val radio = AndroidNfcRadio(adapter)
        val handles = mutableListOf<NfcTagHandle>()
        radio.enable(activity) { handles += it }
        shadowOf(adapter).dispatchTagDiscovered(tag(intArrayOf(ISO_DEP)))
        shadowOf(adapter).dispatchTagDiscovered(tag(intArrayOf(ISO_DEP), handle = STALE_HANDLE))
        assertTrue(radio.ignore(handles[0]))
        assertFalse("the card has left the field", radio.ignore(handles[1]))
        assertEquals(listOf(AndroidNfcRadio.IGNORE_DEBOUNCE_MS, AndroidNfcRadio.IGNORE_DEBOUNCE_MS), ignored)
        // Handles from another radio are not Android tags.
        assertFalse(radio.ignore(object : NfcTagHandle { override fun isoDep(): IsoDepLink? = null }))
        assertFalse(AndroidNfcRadio(null).ignore(handles[0]))
    }

    private companion object {
        const val NFC_A = 1
        const val ISO_DEP = 3
        const val STALE_HANDLE = 99
        const val READER_FLAGS_EXPECTED = NfcAdapter.FLAG_READER_NFC_A or NfcAdapter.FLAG_READER_NFC_B or
            NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK or NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS
    }
}
