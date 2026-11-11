package md.moldsign.app.application

import android.net.Uri
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext
import md.moldsign.core.protection.PasswordFileProtection

/** Owns bounded input, transformation and output lifetime independently of Compose. */
class ProtectDocument(
    private val documents: DocumentAccess,
    private val save: suspend (String, ByteArray, Boolean) -> Uri,
) : DocumentProtection {
    override suspend fun process(input: Uri, password: CharArray, decrypt: Boolean): Uri = withContext(Dispatchers.IO) {
        val document = documents.describe(input)
        val bytes = documents.readBytes(input, PasswordFileProtection.MAXIMUM_SIZE + 8192)
        try {
            ensureActive()
            val result = if (decrypt) PasswordFileProtection.decrypt(bytes, password)
                else PasswordFileProtection.encrypt(bytes, password)
            try {
                ensureActive()
                val name = if (decrypt) "decrypted-" + document.name.removeSuffix(PasswordFileProtection.SUFFIX)
                    else document.name + PasswordFileProtection.SUFFIX
                save(name, result, decrypt)
            } finally { result.fill(0) }
        } finally { bytes.fill(0) }
    }
}
