package md.moldsign.app.application

import android.net.Uri

/** Feature-owned port: tests can inject unreadable, revoked and shared-document scenarios. */
interface DocumentAccess {
    fun keepAccess(uri: Uri)
    suspend fun describe(uri: Uri): PickedDocument
    fun readBytes(uri: Uri): ByteArray
    fun copyToCache(uri: Uri): Uri?
    fun delete(uri: Uri): Boolean = false
    fun copy(source: Uri, target: Uri): Boolean
}
