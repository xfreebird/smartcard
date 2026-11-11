package md.moldsign.app.application

import android.net.Uri

/** Feature boundary shared by live and injected protection services. */
interface DocumentProtection {
    suspend fun process(input: Uri, password: CharArray, decrypt: Boolean): Uri
}
