package md.moldsign.app.application

import android.net.Uri
import md.moldsign.core.protection.CertificateFileProtection
import java.security.cert.X509Certificate
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext
import md.moldsign.core.protection.PasswordFileProtection

/** Owns bounded input, transformation and output lifetime independently of Compose. */
class ProtectDocument(
    private val documents: DocumentAccess,
    private val save: suspend (String, ByteArray, Boolean) -> Uri,
) : DocumentProtection {
    override suspend fun process(input: Uri, password: CharArray, decrypt: Boolean, keySize: Int): Uri =
        transform(input, decrypt, PasswordFileProtection.SUFFIX) { bytes ->
            if (decrypt) PasswordFileProtection.decrypt(bytes, password) else PasswordFileProtection.encrypt(bytes, password, keySize)
        }

    override suspend fun encryptForRecipient(input: Uri, certificate: X509Certificate): Uri =
        transform(input, false, CertificateFileProtection.SUFFIX) { CertificateFileProtection.encrypt(it, certificate) }

    override suspend fun decryptWithCard(input: Uri, decrypt: suspend (ByteArray) -> ByteArray): Uri =
        transform(input, true, CertificateFileProtection.SUFFIX, decrypt)

    private suspend fun transform(input: Uri, decrypt: Boolean, suffix: String, operation: suspend (ByteArray) -> ByteArray): Uri = withContext(Dispatchers.IO) {
        val document = documents.describe(input)
        val bytes = documents.readBytes(input, PasswordFileProtection.MAXIMUM_SIZE + 8192)
        try {
            ensureActive()
            val result = operation(bytes)
            try {
                ensureActive()
                val name = if (decrypt) "decrypted-" + document.name.removeSuffix(suffix)
                    else document.name + suffix
                save(name, result, decrypt)
            } finally { result.fill(0) }
        } finally { bytes.fill(0) }
    }
}
