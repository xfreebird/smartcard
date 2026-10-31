package md.moldsign.app.infrastructure

import android.content.Context
import android.net.Uri
import androidx.core.content.edit
import androidx.core.net.toUri
import android.provider.MediaStore
import android.provider.OpenableColumns
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import md.moldsign.core.ActivityEntry
import md.moldsign.core.ActivityHistory
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.UUID

/**
 * The activity list (docs/10 ActivityRow), persisted as JSON in private SharedPreferences (no document content,
 * only names, outcomes and URIs). Document entries are shown only while their file is still reachable: a
 * `content://` URI needs a still-persisted read permission and a document that still answers a query; a `file://`
 * path must exist. Browser-request entries always stay. [prune] runs at start and whenever the list is shown.
 */
class ActivityLog(context: Context, private val scope: CoroutineScope, preferencesName: String = "activity") {
    private val appContext = context.applicationContext
    private val prefs = appContext.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
    private val _entries = MutableStateFlow(load())
    val entries: StateFlow<List<ActivityEntry>> = _entries.asStateFlow()

    fun add(entry: ActivityEntry) {
        _entries.update { ActivityHistory.add(it, entry) }
        save()
    }

    fun document(name: String, uri: Uri, ok: Boolean, subtitle: String) = add(
        ActivityEntry(UUID.randomUUID().toString(), ActivityEntry.Kind.Document, name, subtitle, ok, System.currentTimeMillis(), uri.toString()),
    )

    /** A signing request from a website: no file, the entry stays in the list. */
    fun browser(site: String, ok: Boolean, subtitle: String) = add(
        ActivityEntry(UUID.randomUUID().toString(), ActivityEntry.Kind.Browser, site, subtitle, ok, System.currentTimeMillis()),
    )

    /** "Golește lista" (after the user confirmed). */
    fun clear() {
        _entries.value = emptyList()
        save()
    }

    /** Drops document entries whose file is gone or whose permission was revoked. Off the main thread. */
    fun prune() = scope.launch(Dispatchers.IO) {
        val current = _entries.value
        val kept = ActivityHistory.pruned(current, ::isReachable).map { it.id }.toSet()
        val removed = current.map { it.id }.filterNot { it in kept }.toSet()
        if (removed.isNotEmpty()) {
            _entries.update { list -> list.filterNot { it.id in removed } }
            save()
        }
    }

    /** Debug demo mode only: replaces the list (then [prune] applies the same rules as for real entries). */
    internal fun replaceForDemo(entries: List<ActivityEntry>) {
        _entries.value = entries
        save()
        prune()
    }

    private fun isReachable(uriString: String): Boolean {
        val uri = uriString.toUri()
        return when (uri.scheme) {
            "file" -> uri.path?.let { File(it).isFile } == true
            "content" -> {
                val resolver = appContext.contentResolver
                // a file this app saved to MediaStore belongs to it: no persisted permission exists or is needed
                val permitted = uri.authority == MediaStore.AUTHORITY ||
                    resolver.persistedUriPermissions.any { it.uri == uri && it.isReadPermission }
                permitted && runCatching {
                    resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { it.moveToFirst() } == true
                }.getOrDefault(false)
            }
            else -> false
        }
    }

    private fun load(): List<ActivityEntry> = runCatching {
        val array = JSONArray(prefs.getString(KEY, "[]"))
        (0 until array.length()).map { i ->
            val o = array.getJSONObject(i)
            ActivityEntry(
                id = o.getString("id"),
                kind = ActivityEntry.Kind.valueOf(o.getString("kind")),
                title = o.getString("title"),
                subtitle = o.optString("subtitle"),
                ok = o.optBoolean("ok", true),
                timeMillis = o.optLong("time"),
                documentUri = o.optString("uri").takeIf { it.isNotEmpty() },
            )
        }
    }.getOrDefault(emptyList())

    private fun save() {
        val array = JSONArray()
        _entries.value.forEach { e ->
            array.put(
                JSONObject()
                    .put("id", e.id).put("kind", e.kind.name).put("title", e.title).put("subtitle", e.subtitle)
                    .put("ok", e.ok).put("time", e.timeMillis).put("uri", e.documentUri ?: ""),
            )
        }
        prefs.edit { putString(KEY, array.toString()) }
    }

    private companion object {
        const val PREFS = "activity"
        const val KEY = "entries"
    }
}
