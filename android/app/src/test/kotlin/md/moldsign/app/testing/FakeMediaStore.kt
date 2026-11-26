package md.moldsign.app.testing

import android.content.ContentProvider
import android.content.ContentUris
import android.content.ContentValues
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.MediaStore
import android.provider.OpenableColumns
import org.robolectric.Robolectric
import java.io.File

/** Downloads as MediaStore would keep them: one row and one file per inserted item. */
class FakeMediaStore : ContentProvider() {
    class Item(val name: String, val mime: String?, val relativePath: String?, val file: File) {
        var pending = true
    }

    override fun onCreate() = true

    override fun insert(uri: Uri, values: ContentValues?): Uri {
        val id = (items.keys.maxOrNull() ?: 0L) + 1
        val name = values?.getAsString(MediaStore.MediaColumns.DISPLAY_NAME) ?: "item$id"
        val file = File(requireNotNull(context).cacheDir, "media-$id").apply { createNewFile() }
        items[id] = Item(name, values?.getAsString(MediaStore.MediaColumns.MIME_TYPE), values?.getAsString(MediaStore.MediaColumns.RELATIVE_PATH), file)
        return ContentUris.withAppendedId(uri, id)
    }

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        val item = items[ContentUris.parseId(uri)] ?: throw java.io.FileNotFoundException(uri.toString())
        return ParcelFileDescriptor.open(item.file, ParcelFileDescriptor.parseMode(mode))
    }

    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int {
        val item = items[ContentUris.parseId(uri)] ?: return 0
        values?.getAsInteger(MediaStore.MediaColumns.IS_PENDING)?.let { item.pending = it == 1 }
        return 1
    }

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int =
        if (items.remove(ContentUris.parseId(uri)) != null) 1 else 0

    override fun query(uri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?, sortOrder: String?): Cursor {
        val cursor = MatrixCursor(arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE))
        items[runCatching { ContentUris.parseId(uri) }.getOrDefault(-1)]?.let { cursor.addRow(arrayOf<Any>(it.name, it.file.length())) }
        return cursor
    }

    override fun getType(uri: Uri): String? = items[ContentUris.parseId(uri)]?.mime

    companion object {
        val items = LinkedHashMap<Long, Item>()

        /** Registers the provider for the media authority of the current Robolectric application. */
        fun install() {
            items.clear()
            Robolectric.setupContentProvider(FakeMediaStore::class.java, MediaStore.AUTHORITY)
        }

        fun names(): List<String> = items.values.map { it.name }
    }
}
