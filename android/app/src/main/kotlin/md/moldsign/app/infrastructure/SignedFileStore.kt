package md.moldsign.app.infrastructure

import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import java.io.File
import java.io.IOException

/**
 * Saves a signed document where the user can find it, never over an existing file (D-06):
 * `Downloads/eSemnBun/` through MediaStore on Android 10+ (no permission needed; a name that exists gets " (1)"),
 * the app's own Documents folder below that. "Salvează ca…" (Activity rows) copies a result anywhere through the system save dialog.
 */
class SignedFileStore(private val context: Context) : md.moldsign.app.application.DocumentOutputStore {
    /** Writes [bytes] as [name] (`<name>-semnat.<ext>`) and returns the URI of the new file. */
    override fun save(name: String, mime: String, bytes: ByteArray): Uri =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) saveToDownloads(name, mime, bytes) else saveToAppFolder(name, bytes)

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun saveToDownloads(name: String, mime: String, bytes: ByteArray): Uri {
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            put(MediaStore.MediaColumns.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/$FOLDER")
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values) ?: throw IOException("Cannot create $name")
        try {
            resolver.openOutputStream(uri)?.use { it.write(bytes) } ?: throw IOException("Cannot write $name")
            resolver.update(uri, ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }, null, null)
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
        return uri
    }

    private fun saveToAppFolder(name: String, bytes: ByteArray): Uri {
        val dir = context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS) ?: context.filesDir
        val base = name.substringBeforeLast('.')
        val extension = name.substringAfterLast('.', "").let { if (it.isEmpty()) "" else ".$it" }
        var file = File(dir, name)
        var n = 1
        while (file.exists()) file = File(dir, "$base ($n)$extension").also { n++ }
        file.writeBytes(bytes)
        return Uri.fromFile(file)
    }

    companion object {
        const val FOLDER = "eSemnBun"

        /** Android 10+ saves to Downloads; older versions to the app's Documents folder. */
        val inDownloads: Boolean get() = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
    }
}
