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

    override fun delete(uri: Uri): Boolean = runCatching {
        when (uri.scheme) {
            "file" -> File(requireNotNull(uri.path)).let { file -> !file.exists() || (file.isFile && file.delete()) }
            "content" -> if (android.provider.DocumentsContract.isDocumentUri(app, uri)) {
                android.provider.DocumentsContract.deleteDocument(app.contentResolver, uri)
            } else app.contentResolver.delete(uri, null, null) > 0
            else -> false
        }
    }.getOrDefault(false)

    override fun keepAccess(uri: Uri) {
        runCatching {
            app.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    override fun readBytes(uri: Uri): ByteArray =
        app.contentResolver.openInputStream(uri)?.use { it.readBytes() }
            ?: throw CardError.Format("Cannot open the document")

    override fun readBytes(uri: Uri, maximumSize: Int): ByteArray =
        app.contentResolver.openInputStream(uri)?.use { input ->
            val output = java.io.ByteArrayOutputStream()
            val buffer = ByteArray(65536)
            while (true) {
                val count = input.read(buffer)
                if (count < 0) break
                require(count <= maximumSize - output.size()) { "Document exceeds the size limit" }
                output.write(buffer, 0, count)
            }
            output.toByteArray()
        } ?: throw CardError.Format("Cannot open the document")

    override fun readPrefix(uri: Uri, size: Int): ByteArray =
        app.contentResolver.openInputStream(uri)?.use { input ->
            val buffer = ByteArray(size)
            var offset = 0
            while (offset < size) {
                val count = input.read(buffer, offset, size - offset)
                if (count <= 0) break
                offset += count
            }
            buffer.copyOf(offset)
        } ?: throw CardError.Format("Cannot open the document")

    override suspend fun describe(uri: Uri): PickedDocument = withContext(Dispatchers.IO) {
        val resolver = app.contentResolver
        var name = uri.lastPathSegment ?: "document"
        var size = -1L
        val localFile = if (uri.scheme == "file") uri.path?.let(::File) else null
        if (localFile != null) {
            name = localFile.name
            if (localFile.isFile) size = runCatching { java.nio.file.Files.size(localFile.toPath()) }.getOrDefault(-1L)
        } else resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { c ->
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
    override fun writeBytes(target: Uri, bytes: ByteArray): Boolean = runCatching {
        (app.contentResolver.openOutputStream(target,"wt") ?: error("unwritable")).use { it.write(bytes) }
    }.isSuccess
}
