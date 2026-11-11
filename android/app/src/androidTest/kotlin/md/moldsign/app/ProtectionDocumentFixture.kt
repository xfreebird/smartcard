package md.moldsign.app

import android.net.Uri
import md.moldsign.app.application.DocumentAccess
import md.moldsign.app.application.PickedDocument

/** Synthetic document provider that records buffer disposal and enforces bounded reads. */
internal class ProtectionDocumentFixture(
    private val bytes: ByteArray,
    private val name: String = "contract.txt",
    private val rejectRead: Boolean = false,
) : DocumentAccess {
    var lastRead = byteArrayOf()
    override fun keepAccess(uri: Uri) = Unit
    override suspend fun describe(uri: Uri) = PickedDocument(uri, name, bytes.size.toLong(), "application/octet-stream")
    override fun readBytes(uri: Uri): ByteArray = error("Protection must use a bounded read")
    override fun readBytes(uri: Uri, maximumSize: Int): ByteArray {
        if (rejectRead) throw java.io.IOException("Synthetic revoked input")
        check(maximumSize == md.moldsign.core.protection.PasswordFileProtection.MAXIMUM_SIZE + 8192)
        return bytes.copyOf().also { lastRead = it }
    }
    override fun copyToCache(uri: Uri): Uri? = error("Not an import")
    override fun copy(source: Uri, target: Uri): Boolean = error("Not a copy")
}
