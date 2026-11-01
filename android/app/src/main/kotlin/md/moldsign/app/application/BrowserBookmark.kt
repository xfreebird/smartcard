package md.moldsign.app.application

import java.net.URI
import java.util.Locale

/** A locally saved shortcut. Built-in entries retain their website image; custom entries use a native icon. */
data class BrowserBookmark(
    val id: String,
    val title: String,
    val url: String,
    val icon: BookmarkIcon = BookmarkIcon.Globe,
    val builtinImage: Int? = null,
)

enum class BookmarkIcon(val key: String) {
    Globe("globe"), Bookmark("bookmark"), Document("document"), Person("person"), Building("building"), Star("star");

    companion object {
        fun fromKey(key: String): BookmarkIcon = entries.firstOrNull { it.key == key } ?: Globe
    }
}

/** Accepts ordinary web addresses only. Credentials, scripts, files and malformed hostnames are rejected. */
object BookmarkUrl {
    fun normalize(input: String): String? {
        val trimmed = input.trim()
        if (trimmed.isEmpty() || trimmed.any(Char::isWhitespace)) return null
        val value = if (trimmed.contains("://")) trimmed else "https://$trimmed"
        val uri = runCatching { URI(value) }.getOrNull() ?: return null
        return value.takeIf {
            uri.scheme?.lowercase(Locale.ROOT) in setOf("http", "https") &&
                !uri.host.isNullOrBlank() && uri.rawUserInfo == null &&
                (uri.port == -1 || uri.port in 1..65535)
        }
    }
}
