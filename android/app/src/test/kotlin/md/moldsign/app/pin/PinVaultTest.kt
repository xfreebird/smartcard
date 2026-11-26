package md.moldsign.app.pin

import android.app.Application
import android.util.Base64
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.fragment.app.FragmentActivity
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import md.moldsign.app.testing.testCertificate
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * The vault's record handling without the Keystore: Robolectric has no AndroidKeyStore or biometric hardware, so
 * the encrypt/decrypt round trip stays a device check. Damaged records must be deleted, never tried as a PIN.
 */
@RunWith(RobolectricTestRunner::class)
@Config(application = Application::class)
class PinVaultTest {
    private val app = ApplicationProvider.getApplicationContext<Application>()
    private val vault = PinVault(app)
    private val activity = Robolectric.buildActivity(FragmentActivity::class.java).setup().get()

    @org.junit.Before fun clear() = runBlocking { app.pinStore.edit { it.clear() }; Unit }

    private suspend fun store(id: String, value: String) = app.pinStore.edit { it[stringPreferencesKey("pin_v2_$id")] = value }

    @Test fun damagedRecordsAreDeletedInsteadOfUsed() = runBlocking {
        val biometrics = org.robolectric.shadow.api.Shadow.extract<org.robolectric.shadows.ShadowBiometricManager>(app.getSystemService(android.hardware.biometrics.BiometricManager::class.java)!!)
        biometrics.setCanAuthenticate(false)
        assertFalse(vault.isAvailable())
        biometrics.setCanAuthenticate(true)
        assertTrue(vault.isAvailable())
        assertNull(vault.load(activity, "absent", "title", "subtitle"))

        store("bad64", "%%% not base64 %%%")
        store("short", Base64.encodeToString(ByteArray(8), Base64.NO_WRAP))
        assertEquals(setOf("bad64", "short"), vault.accounts.first())
        assertNull(vault.load(activity, "bad64", "title", "subtitle"))
        assertNull(vault.load(activity, "short", "title", "subtitle"))
        assertTrue(vault.accounts.first().isEmpty())
    }

    @Test fun deletingOneAccountKeepsTheOthers() = runBlocking {
        store("A", "x")
        store("B", "y")
        app.pinStore.edit { it[stringPreferencesKey("pin_A")] = "legacy" }
        vault.delete("A")
        assertEquals(setOf("B"), vault.accounts.first())
        vault.delete("B")
        assertTrue(vault.accounts.first().isEmpty())
    }

    @Test fun recordBindingNamesTheCertificate() {
        assertEquals("moldsign.pinvault.v2:${testCertificate().sha1Hex}", String(pinRecordBinding(testCertificate().sha1Hex)))
    }
}
