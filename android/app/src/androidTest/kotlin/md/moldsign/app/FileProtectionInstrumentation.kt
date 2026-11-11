package md.moldsign.app

import android.app.Activity
import android.app.Instrumentation
import android.os.Bundle
import android.util.Base64
import md.moldsign.core.protection.PasswordFileProtection

/** Runs inside Android's runtime: legacy-provider support cannot be inferred from JVM tests. */
class FileProtectionInstrumentation : Instrumentation() {
    private var phase: String? = null
    private var suite: String? = null
    override fun onCreate(arguments: Bundle?) { super.onCreate(arguments); phase = arguments?.getString("phase"); suite = arguments?.getString("suite"); start() }
    override fun onStart() {
        val result=Bundle()
        try {
            if (suite == "journeys") {
                result.putString("result", JourneyAutomation(this).run())
                finish(Activity.RESULT_OK, result)
                return
            }
            check(suite == null) { "Unknown integration suite: $suite" }
            if (phase != null) {
                val scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.SupervisorJob() + kotlinx.coroutines.Dispatchers.Default)
                val preferences = "protection-relaunch-integration"
                val log = md.moldsign.app.infrastructure.ActivityLog(targetContext, scope, preferences)
                if (phase == "prepare") {
                    val uri = md.moldsign.app.infrastructure.ProtectedFileStore(targetContext).save("Relaunch.txt", "Relaunch proof".toByteArray())
                    log.document("Relaunch.txt", uri, true, "Decrypted", protectionOperation = "decrypt")
                    // Commit an extra marker to flush prior apply() work before this process exits.
                    targetContext.getSharedPreferences(preferences, 0).edit().putBoolean("prepared", true).commit()
                    result.putString("result", "PASS: prepared persisted protected output for process relaunch")
                } else {
                    val item = log.signedDocuments.value.single()
                    check(item.protectionOperation == "decrypt" && !item.signedOutput)
                    val uri = android.net.Uri.parse(item.documentUri)
                    check(targetContext.contentResolver.openInputStream(uri)!!.use { String(it.readBytes()) } == "Relaunch proof")
                    check(targetContext.contentResolver.delete(uri, null, null) == 1)
                    log.removeSignedDocuments(setOf(item.id))
                    targetContext.getSharedPreferences(preferences, 0).edit().clear().commit()
                    result.putString("result", "PASS: protected Documents output survived process restart and remained readable/deletable")
                }
                scope.coroutineContext[kotlinx.coroutines.Job]?.cancel()
                finish(Activity.RESULT_OK, result)
                return
            }
            val plain=ByteArray(17){(it*37).toByte()}
            val fixtures=listOf(
            "3_KeyTripleDES_CBC" to "MIACAQAwgAYJKoZIhvcNAQcBMBwGCiqGSIb3DQEMAQMwDgQIEnVHu4fZVY0CAicQoIAEGIhFojiCJLjZ5fb5VuF7tJd/X58HlH1jwQAAAAAAAA==",
            "DES_CBC" to "MIACAQAwgAYJKoZIhvcNAQcBMBsGCSqGSIb3DQEFAzAOBAixC3OQDq1IfQICJxCggAQYZxqb7mexTIJwrru5tWJgkRYd59V/+h+9AAAAAAAA",
            "RC2_CBC" to "MIACAQAwgAYJKoZIhvcNAQcBMBwGCiqGSIb3DQEMAQYwDgQITttOkXZ2v04CAicQoIAEGOk8wJWNdNeO+1j1caYFcOY0Tz99L43lgAAAAAAAAA=="
            )
            for((name,base64) in fixtures) {
                check(PasswordFileProtection.decrypt(Base64.decode(base64,Base64.DEFAULT),"Legacy-Test-2026".toCharArray()).contentEquals(plain)){"Legacy provider failed: $name"}
            }
            val password="Test-șț-🔐-2026".toCharArray()
            val encrypted=PasswordFileProtection.encrypt(plain,password)
            check(PasswordFileProtection.decrypt(encrypted,password).contentEquals(plain))
            val scope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.SupervisorJob() + kotlinx.coroutines.Dispatchers.Default)
            val preferences = "protection-integration-${java.util.UUID.randomUUID()}"
            val store = md.moldsign.app.infrastructure.ProtectedFileStore(targetContext)
            val encryptedUri = store.save("Contract.pdf.symmetric.p7m", encrypted)
            val decryptedUri = store.save("Contract.pdf", PasswordFileProtection.decrypt(encrypted, password))
            try {
                check(encryptedUri != decryptedUri)
                check(targetContext.contentResolver.openInputStream(decryptedUri)!!.use { it.readBytes() }.contentEquals(plain))
                val log = md.moldsign.app.infrastructure.ActivityLog(targetContext, scope, preferences)
                log.document("Contract.pdf.symmetric.p7m", encryptedUri, true, "Encrypted", protectionOperation = "encrypt")
                log.document("Contract.pdf", decryptedUri, true, "Decrypted", protectionOperation = "decrypt")
                log.clear()
                val reloaded = md.moldsign.app.infrastructure.ActivityLog(targetContext, scope, preferences)
                check(reloaded.entries.value.isEmpty())
                check(reloaded.signedDocuments.value.map { it.protectionOperation } == listOf("decrypt", "encrypt"))
                check(reloaded.signedDocuments.value.none { it.signedOutput })
                check(targetContext.contentResolver.delete(encryptedUri, null, null) == 1)
                reloaded.removeSignedDocuments(setOf(reloaded.signedDocuments.value.last().id))
                check(reloaded.signedDocuments.value.size == 1)
            } finally {
                runCatching { targetContext.contentResolver.delete(encryptedUri, null, null) }
                runCatching { targetContext.contentResolver.delete(decryptedUri, null, null) }
                targetContext.getSharedPreferences(preferences, 0).edit().clear().commit()
                scope.coroutineContext[kotlinx.coroutines.Job]?.cancel()
            }
            password.fill('\u0000')
            result.putString("result","PASS: Android AES/legacy crypto; private output storage; URI access; library reload after clearing history; unsigned output flags; individual deletion")
            finish(Activity.RESULT_OK,result)
        } catch(error:Throwable) {
            result.putString("result","FAIL: "+error.javaClass.simpleName+": "+error.message)
            result.putString("stack", error.stackTraceToString())
            finish(Activity.RESULT_CANCELED,result)
        }
    }
}
