package md.moldsign.app.infrastructure

import md.moldsign.app.application.SHARED_DOCUMENT_CACHE

import md.moldsign.app.application.DocumentAccess
import md.moldsign.app.application.PickedDocument

import android.app.Application
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import androidx.core.net.toUri
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import md.moldsign.core.CardError
import java.io.File
import java.util.UUID

/** Storage Access Framework adapter; no UI or signing policy. */
class AndroidDocumentAccess(private val app: Application) : DocumentAccess {
    override fun copyToCache(uri: Uri): Uri? = runCatching {
        val context = app
        var name = uri.lastPathSegment ?: "document"
        context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
            if (c.moveToFirst() && !c.isNull(0)) name = c.getString(0)
        }
        val dir = File(context.cacheDir, "${SHARED_DOCUMENT_CACHE}/${UUID.randomUUID()}").apply { mkdirs() }
        val file = File(dir, name.replace('/', '_'))
        context.contentResolver.openInputStream(uri)?.use { input -> file.outputStream().use { input.copyTo(it) } } ?: return null
        file.toUri()
    }.getOrNull()

    override fun keepAccess(uri: Uri) {
        runCatching {
            app.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    override fun readBytes(uri: Uri): ByteArray =
        app.contentResolver.openInputStream(uri)?.use { it.readBytes() }
            ?: throw CardError.Format("Cannot open the document")

    override suspend fun describe(uri: Uri): PickedDocument = withContext(Dispatchers.IO) {
        val resolver = app.contentResolver
        var name = uri.lastPathSegment ?: "document"
        var size = -1L
        resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { c ->
            if (c.moveToFirst()) {
                c.getColumnIndex(OpenableColumns.DISPLAY_NAME).takeIf { it >= 0 && !c.isNull(it) }?.let { name = c.getString(it) }
                c.getColumnIndex(OpenableColumns.SIZE).takeIf { it >= 0 && !c.isNull(it) }?.let { size = c.getLong(it) }
            }
        }
        PickedDocument(uri, name, size, resolver.getType(uri))
    }

    override fun copy(source: Uri, target: Uri): Boolean = runCatching {
        val resolver = app.contentResolver
        (resolver.openInputStream(source) ?: error("unreadable")).use { input ->
            (resolver.openOutputStream(target) ?: error("unwritable")).use { output -> input.copyTo(output) }
        }
    }.isSuccess
}
