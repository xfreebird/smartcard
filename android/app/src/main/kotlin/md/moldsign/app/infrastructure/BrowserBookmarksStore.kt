package md.moldsign.app.infrastructure

import android.content.Context
import md.moldsign.app.application.BookmarkIcon
import md.moldsign.app.application.BookmarkUrl
import md.moldsign.app.application.BrowserBookmark
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/** Bookmarks stay in private preferences, independently of browser cookies/history. An empty list stays empty. */
class BrowserBookmarksStore(context: Context, private val builtins: List<BrowserBookmark>) {
    private val preferences = context.applicationContext.getSharedPreferences("browser-bookmarks", Context.MODE_PRIVATE)

    fun load(): List<BrowserBookmark> {
        if (!preferences.contains("items")) return builtins
        return runCatching {
            val stored = JSONArray(preferences.getString("items", "[]"))
            (0 until stored.length()).mapNotNull { index ->
                val value = stored.optJSONObject(index) ?: return@mapNotNull null
                val id = value.optString("id").takeIf { it.isNotBlank() } ?: return@mapNotNull null
                val title = value.optString("title").trim().takeIf { it.isNotEmpty() } ?: return@mapNotNull null
                val url = BookmarkUrl.normalize(value.optString("url")) ?: return@mapNotNull null
                val image = if (value.optBoolean("websiteImage")) builtins.firstOrNull { it.id == id }?.builtinImage else null
                BrowserBookmark(id, title, url, BookmarkIcon.fromKey(value.optString("icon")), image)
            }.distinctBy { it.id }
        }.getOrDefault(builtins)
    }

    fun addOrUpdate(existing: BrowserBookmark?, title: String, url: String, icon: BookmarkIcon, keepWebsiteImage: Boolean): Boolean {
        val cleanTitle = title.trim().takeIf { it.isNotEmpty() } ?: return false
        val cleanUrl = BookmarkUrl.normalize(url) ?: return false
        val item = BrowserBookmark(existing?.id ?: "custom:${UUID.randomUUID()}", cleanTitle, cleanUrl, icon,
            existing?.builtinImage.takeIf { keepWebsiteImage })
        val items = load().toMutableList()
        val index = items.indexOfFirst { it.id == item.id }
        if (index >= 0) items[index] = item else items += item
        save(items)
        return true
    }

    fun remove(bookmark: BrowserBookmark) = save(load().filterNot { it.id == bookmark.id })

    private fun save(bookmarks: List<BrowserBookmark>) {
        val values = JSONArray()
        bookmarks.forEach { bookmark ->
            values.put(JSONObject().put("id", bookmark.id).put("title", bookmark.title)
                .put("url", bookmark.url).put("icon", bookmark.icon.key).put("websiteImage", bookmark.builtinImage != null))
        }
        preferences.edit().putString("items", values.toString()).apply()
    }
}
