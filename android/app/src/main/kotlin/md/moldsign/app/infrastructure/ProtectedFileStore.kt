package md.moldsign.app.infrastructure

import android.content.Context
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File
import java.util.UUID

/** Private, non-backed-up outputs; sharing grants access to a single file only. */
class ProtectedFileStore(private val context: Context) {
    fun save(name: String, bytes: ByteArray): Uri {
        val directory = File(context.filesDir, "protected/${UUID.randomUUID()}")
        check(directory.mkdirs())
        val file = File(directory, name.replace('/', '_').replace('\\', '_').takeIf { it != "." && it != ".." && it.isNotBlank() } ?: "document")
        try {
            file.outputStream().use { it.write(bytes) }
            return FileProvider.getUriForFile(context, "${context.packageName}.protected-files", file)
        } catch (failure: Exception) {
            file.delete(); directory.delete()
            throw failure
        }
    }
}
