package md.moldsign.app.pin

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import androidx.fragment.app.FragmentActivity
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.suspendCancellableCoroutine
import java.nio.ByteBuffer
import java.nio.CharBuffer
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import kotlin.coroutines.resume

private val Context.pinStore by preferencesDataStore(name = "pin_vault")

/**
 * PinVault (docs/09 §3.5, AND-06): the PIN QSCD encrypted with an AES-256-GCM key that lives in the
 * Android Keystore and needs user authentication for EVERY use (BiometricPrompt + CryptoObject).
 * Only the ciphertext (IV ‖ ct, Base64) is stored, in DataStore, keyed by the card certificate SHA-1,
 * so another card never receives this card's PIN. The PIN is never logged.
 *
 * TODO(AND-06): wire into the signing flow: "Ține minte PIN-ul" → [save] after a successful VERIFY,
 *  [load] before showing the PIN sheet, [delete] on CardError.WrongPin; device-credential fallback on API 30+.
 */
class PinVault(context: Context) {
    private val appContext = context.applicationContext

    /** True when a class-3 (strong) biometric is enrolled, which the CryptoObject flow requires. */
    fun isAvailable(): Boolean =
        BiometricManager.from(appContext).canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) ==
            BiometricManager.BIOMETRIC_SUCCESS

    suspend fun has(certId: String): Boolean = appContext.pinStore.data.first()[prefKey(certId)] != null

    /** Encrypts and stores [pin] after a biometric confirmation. Returns false if the user cancelled. */
    suspend fun save(activity: FragmentActivity, certId: String, pin: CharArray, title: String, subtitle: String): Boolean {
        val cipher = Cipher.getInstance(TRANSFORMATION).apply { init(Cipher.ENCRYPT_MODE, getOrCreateKey()) }
        val authed = authenticate(activity, cipher, title, subtitle) ?: return false
        val plain = encodeUtf8(pin)
        try {
            val ct = authed.doFinal(plain)
            val blob = authed.iv + ct
            appContext.pinStore.edit { it[prefKey(certId)] = Base64.encodeToString(blob, Base64.NO_WRAP) }
            return true
        } finally {
            plain.fill(0)
        }
    }

    /** Decrypts the stored PIN after a biometric confirmation; null if none, cancelled, or the key was invalidated. */
    suspend fun load(activity: FragmentActivity, certId: String, title: String, subtitle: String): CharArray? {
        val stored = appContext.pinStore.data.first()[prefKey(certId)] ?: return null
        val blob = Base64.decode(stored, Base64.NO_WRAP)
        val cipher = Cipher.getInstance(TRANSFORMATION)
        try {
            cipher.init(Cipher.DECRYPT_MODE, getOrCreateKey(), GCMParameterSpec(128, blob, 0, IV_SIZE))
        } catch (e: KeyPermanentlyInvalidatedException) {
            // New biometric enrolled: the key is gone for good, so are the stored PINs.
            deleteAll()
            return null
        }
        val authed = authenticate(activity, cipher, title, subtitle) ?: return null
        val plain = authed.doFinal(blob, IV_SIZE, blob.size - IV_SIZE)
        return try {
            decodeUtf8(plain)
        } finally {
            plain.fill(0)
        }
    }

    suspend fun delete(certId: String) {
        appContext.pinStore.edit { it.remove(prefKey(certId)) }
    }

    suspend fun deleteAll() {
        appContext.pinStore.edit { it.clear() }
        KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }.deleteEntry(KEY_ALIAS)
    }

    private fun getOrCreateKey(): SecretKey {
        val ks = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
        (ks.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
        val spec = KeyGenParameterSpec.Builder(KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setKeySize(256)
            .setUserAuthenticationRequired(true) // auth-per-use: every PIN read needs the biometric
            .setInvalidatedByBiometricEnrollment(true)
            .build()
        return KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE).run {
            init(spec)
            generateKey()
        }
    }

    private suspend fun authenticate(activity: FragmentActivity, cipher: Cipher, title: String, subtitle: String): Cipher? =
        suspendCancellableCoroutine { cont ->
            val prompt = BiometricPrompt(
                activity,
                ContextCompat.getMainExecutor(activity),
                object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                        if (cont.isActive) cont.resume(result.cryptoObject?.cipher)
                    }

                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                        if (cont.isActive) cont.resume(null)
                    }
                },
            )
            val info = BiometricPrompt.PromptInfo.Builder()
                .setTitle(title)
                .setSubtitle(subtitle)
                .setNegativeButtonText(activity.getString(android.R.string.cancel))
                .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
                .build()
            prompt.authenticate(info, BiometricPrompt.CryptoObject(cipher))
            cont.invokeOnCancellation { prompt.cancelAuthentication() }
        }

    private fun prefKey(certId: String) = stringPreferencesKey("pin_$certId")

    private fun encodeUtf8(chars: CharArray): ByteArray {
        val bb = Charsets.UTF_8.encode(CharBuffer.wrap(chars))
        return ByteArray(bb.remaining()).also { bb.get(it); bb.array().fill(0) }
    }

    private fun decodeUtf8(bytes: ByteArray): CharArray {
        val cb = Charsets.UTF_8.decode(ByteBuffer.wrap(bytes))
        return CharArray(cb.remaining()).also { cb.get(it); cb.array().fill('\u0000') }
    }

    private companion object {
        const val ANDROID_KEYSTORE = "AndroidKeyStore"
        const val KEY_ALIAS = "moldsign.pinvault.v1"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val IV_SIZE = 12
    }
}
