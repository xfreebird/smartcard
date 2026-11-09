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
import md.moldsign.core.SignedDocumentLibrary
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
class ActivityLog(context: Context, private val scope: CoroutineScope, private val preferencesName: String = "activity") {
    private val appContext = context.applicationContext
    private val prefs = appContext.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
    private val _entries = MutableStateFlow(load(KEY))
    val entries: StateFlow<List<ActivityEntry>> = _entries.asStateFlow()
    // A durable library, independent of capped/clearable activity history. Missing permissions/files are
    // reported when opening a document; pruning history must never silently remove a library record.
    private val _signedDocuments = MutableStateFlow(
        if (prefs.contains(DOCUMENTS_KEY)) load(DOCUMENTS_KEY) else SignedDocumentLibrary.migrate(_entries.value),
    )
    val signedDocuments: StateFlow<List<ActivityEntry>> = _signedDocuments.asStateFlow()

    init {
        // Persist migration together with history before a later clear can remove the legacy source.
        if (!prefs.contains(DOCUMENTS_KEY)) save()
    }

    @Synchronized
    fun add(entry: ActivityEntry) {
        _entries.update { ActivityHistory.add(it, entry) }
        _signedDocuments.update { SignedDocumentLibrary.add(it, entry) }
        save()
    }

    fun document(name: String, uri: Uri, ok: Boolean, subtitle: String, signedOutput: Boolean = false) = add(
        ActivityEntry(UUID.randomUUID().toString(), ActivityEntry.Kind.Document, name, subtitle, ok, System.currentTimeMillis(), uri.toString(), signedOutput),
    )

    /** A signing request from a website: no file, the entry stays in the list. */
    fun browser(site: String, ok: Boolean, subtitle: String) = add(
        ActivityEntry(UUID.randomUUID().toString(), ActivityEntry.Kind.Browser, site, subtitle, ok, System.currentTimeMillis()),
    )

    /** "Golește lista" (after the user confirmed). */
    @Synchronized
    fun clear() {
        _entries.value = emptyList()
        save()
    }

    /** Drops document entries whose file is gone or whose permission was revoked. Off the main thread. */
    fun prune() = scope.launch(Dispatchers.IO) {
        val current = _entries.value
        val kept = ActivityHistory.pruned(current, ::isReachable).map { it.id }.toSet()
        val removed = current.map { it.id }.filterNot { it in kept }.toSet()
        if (removed.isNotEmpty()) synchronized(this@ActivityLog) {
            _entries.update { list -> list.filterNot { it.id in removed } }
            save()
        }
    }

    /** Debug demo mode only: replaces the list (then [prune] applies the same rules as for real entries). */
    @Synchronized
    internal fun replaceForDemo(entries: List<ActivityEntry>) {
        _entries.value = entries
        _signedDocuments.value = SignedDocumentLibrary.migrate(entries)
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

    private fun load(key: String): List<ActivityEntry> = runCatching {
        val array = JSONArray(prefs.getString(key, "[]"))
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
                signedOutput = o.optBoolean("signedOutput", o.optString("title").contains("-semnat")),
            )
        }
    }.getOrDefault(emptyList())

    @Synchronized
    private fun save() {
        prefs.edit {
            putString(KEY, encode(_entries.value))
            putString(DOCUMENTS_KEY, encode(_signedDocuments.value))
        }
        if (preferencesName == "activity") md.moldsign.app.widget.DocumentsWidget.refresh(appContext, _signedDocuments.value)
    }

    private fun encode(entries: List<ActivityEntry>): String {
        val array = JSONArray()
        entries.forEach { e ->
            array.put(
                JSONObject()
                    .put("id", e.id).put("kind", e.kind.name).put("title", e.title).put("subtitle", e.subtitle)
                    .put("signedOutput", e.signedOutput).put("ok", e.ok).put("time", e.timeMillis).put("uri", e.documentUri ?: ""),
            )
        }
        return array.toString()
    }

    private companion object {
        const val KEY = "entries"
        const val DOCUMENTS_KEY = "signedDocuments"
    }
}
