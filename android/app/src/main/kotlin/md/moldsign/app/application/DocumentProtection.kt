package md.moldsign.app.application

import android.net.Uri
import java.security.cert.X509Certificate

/** Feature boundary shared by live and injected protection services. */
interface DocumentProtection {
    suspend fun process(input: Uri, password: CharArray, decrypt: Boolean, keySize: Int = 256): Uri
    suspend fun encryptForRecipient(input: Uri, certificate: X509Certificate): Uri
    suspend fun decryptWithCard(input: Uri, decrypt: suspend (ByteArray) -> ByteArray): Uri
}
