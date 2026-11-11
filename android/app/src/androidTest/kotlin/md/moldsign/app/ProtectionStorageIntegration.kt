package md.moldsign.app

import android.content.Context
import android.net.Uri
import android.util.Base64
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import md.moldsign.app.infrastructure.ActivityLog
import md.moldsign.app.infrastructure.ProtectedFileStore
import md.moldsign.core.protection.PasswordFileProtection
import java.util.UUID

/** Real Android crypto providers, private files and persisted document library. */
internal class ProtectionStorageIntegration(private val context: Context) {
    fun run(): String {
        val plain = ByteArray(17) { (it * 37).toByte() }
        val legacyPassword = "Legacy-Test-2026".toCharArray()
        try {
            for ((name, encoded) in LegacyProtectionFixtures.encryptedSamples) {
                val encrypted = Base64.decode(encoded, Base64.DEFAULT)
                check(PasswordFileProtection.decrypt(encrypted, legacyPassword).contentEquals(plain)) {
                    "Legacy provider failed: $name"
                }
            }
        } finally {
            legacyPassword.fill('\u0000')
        }
        val password = "Test-șț-🔐-2026".toCharArray()
        try {
            val encrypted = PasswordFileProtection.encrypt(plain, password)
            val restored = PasswordFileProtection.decrypt(encrypted, password)
            check(restored.contentEquals(plain))
            verifyStorage(encrypted, restored)
        } finally {
            password.fill('\u0000')
        }
        return "PASS: Android AES/legacy crypto; private output storage; URI access; library reload after clearing history; unsigned output flags; individual deletion"
    }

    private fun verifyStorage(encrypted: ByteArray, restored: ByteArray) {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        val preferences = "protection-integration-${UUID.randomUUID()}"
        val store = ProtectedFileStore(context)
        val outputs = mutableListOf<Uri>()
        try {
            val encryptedUri = store.save("Contract.pdf.symmetric.p7m", encrypted).also(outputs::add)
            val decryptedUri = store.save("Contract.pdf", restored).also(outputs::add)
            check(encryptedUri != decryptedUri)
            check(context.contentResolver.openInputStream(decryptedUri)!!.use { it.readBytes() }.contentEquals(restored))
            val log = ActivityLog(context, scope, preferences)
            log.document("Contract.pdf.symmetric.p7m", encryptedUri, true, "Encrypted", protectionOperation = "encrypt")
            log.document("Contract.pdf", decryptedUri, true, "Decrypted", protectionOperation = "decrypt")
            log.clear()
            val reloaded = ActivityLog(context, scope, preferences)
            check(reloaded.entries.value.isEmpty())
            check(reloaded.signedDocuments.value.map { it.protectionOperation } == listOf("decrypt", "encrypt"))
            check(reloaded.signedDocuments.value.none { it.signedOutput })
            check(context.contentResolver.delete(encryptedUri, null, null) == 1)
            reloaded.removeSignedDocuments(setOf(reloaded.signedDocuments.value.last().id))
            check(reloaded.signedDocuments.value.size == 1)
        } finally {
            outputs.forEach { uri -> runCatching { context.contentResolver.delete(uri, null, null) } }
            context.getSharedPreferences(preferences, 0).edit().clear().commit()
            scope.cancel()
        }
    }
}
