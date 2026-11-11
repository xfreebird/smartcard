package md.moldsign.app.application

import android.net.Uri

/** Persists a generated output without knowledge of a screen or activity history. */
fun interface DocumentOutputStore {
    fun save(name: String, mime: String, bytes: ByteArray): Uri
}
