package md.moldsign.app

import android.net.Uri
import kotlinx.coroutines.runBlocking
import md.moldsign.app.application.DocumentAccess
import md.moldsign.app.application.PickedDocument
import md.moldsign.app.application.ProtectDocument
import md.moldsign.core.protection.PasswordFileProtection

/** Executes the same workflow used by Compose against replaceable document/storage ports. */
internal object ProtectionWorkflowIntegration {
    fun run(): List<String> = runBlocking {
        val input = Uri.parse("content://synthetic/contract.txt")
        val output = Uri.parse("content://synthetic/output")
        val original = "Synthetic contract".toByteArray()
        val source = ProtectionDocumentFixture(original)
        val secret = "Test-only-password".toCharArray()
        try {
            var encrypted = byteArrayOf()
            var saveBuffer: ByteArray? = null
            val encrypt = ProtectDocument(source) { name, bytes, decrypt ->
                check(name == "contract.txt" + PasswordFileProtection.SUFFIX && !decrypt)
                encrypted = bytes.copyOf()
                saveBuffer = bytes
                output
            }
            check(encrypt.process(input, secret, false) == output)
            check(source.lastRead.all { it == 0.toByte() } && requireNotNull(saveBuffer).all { it == 0.toByte() })
            val decrypt = ProtectDocument(ProtectionDocumentFixture(encrypted, "contract.txt" + PasswordFileProtection.SUFFIX)) { name, bytes, decrypt ->
                check(name == "decrypted-contract.txt" && decrypt && bytes.contentEquals(original))
                output
            }
            check(decrypt.process(output, secret, true) == output)

            val failedSave = ProtectDocument(source) { _, bytes, _ ->
                saveBuffer = bytes
                throw java.io.IOException("Synthetic revoked destination")
            }
            try { failedSave.process(input, secret, false); error("Output failure was swallowed") }
            catch (_: java.io.IOException) { }
            check(requireNotNull(saveBuffer).all { it == 0.toByte() } && source.lastRead.all { it == 0.toByte() })

            val unreadable = ProtectDocument(ProtectionDocumentFixture(byteArrayOf(), rejectRead = true)) { _, _, _ ->
                error("Rejected read must never save")
            }
            try { unreadable.process(input, secret, false); error("Read failure was swallowed") }
            catch (_: java.io.IOException) { }

            val malformed = ProtectDocument(ProtectionDocumentFixture("not encrypted".toByteArray())) { _, _, _ ->
                error("Invalid envelope must never save")
            }
            try { malformed.process(input, secret, true); error("Malformed envelope was accepted") }
            catch (_: IllegalArgumentException) { }
            listOf("protection-roundtrip:pass", "protection-save-failure:pass",
                "protection-read-failure:pass", "protection-malformed:pass")
        } finally { secret.fill('\u0000') }
    }
}
