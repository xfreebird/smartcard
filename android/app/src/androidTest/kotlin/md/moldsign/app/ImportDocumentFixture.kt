package md.moldsign.app

import android.net.Uri
import md.moldsign.app.application.DocumentAccess
import md.moldsign.app.application.PickedDocument

internal class ImportDocumentFixture : DocumentAccess {
    val grants = mutableListOf<Uri>()
    val copies = mutableListOf<Uri>()
    override fun keepAccess(uri: Uri) { grants += uri }
    override suspend fun describe(uri: Uri) = PickedDocument(uri, requireNotNull(uri.lastPathSegment), 5, "text/plain")
    override fun copyToCache(uri: Uri): Uri {
        copies += uri
        return Uri.parse("file:///test-copy/${copies.size}.txt")
    }
    override fun readBytes(uri: Uri): ByteArray = error("Import must not read data during metadata selection")
    override fun copy(source: Uri, target: Uri): Boolean = error("Import must not export a document")
}
