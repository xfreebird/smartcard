package md.moldsign.app.application

import android.net.Uri

/** Feature-owned port: tests can inject unreadable, revoked and shared-document scenarios. */
interface DocumentAccess {
    fun keepAccess(uri: Uri)
    suspend fun describe(uri: Uri): PickedDocument
    fun readBytes(uri: Uri): ByteArray
    fun readBytes(uri: Uri, maximumSize: Int): ByteArray = readBytes(uri).also {
        require(it.size <= maximumSize) { "Document exceeds the size limit" }
    }
    fun readPrefix(uri: Uri, size: Int): ByteArray = readBytes(uri).let { it.copyOf(minOf(size, it.size)) }
    fun copyToCache(uri: Uri): Uri?
    fun delete(uri: Uri): Boolean = false
    fun copy(source: Uri, target: Uri): Boolean
    fun writeBytes(target: Uri, bytes: ByteArray): Boolean = false
}
