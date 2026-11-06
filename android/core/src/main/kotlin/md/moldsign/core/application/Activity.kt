package md.moldsign.core

/**
 * One line of the activity list (docs/10 ActivityRow): a document the user signed / verified, or a browser request.
 * [documentUri] is the platform URI of the file the entry points at (Android: a `content://` URI with a persisted
 * read permission, or a `file://` path).
 */
data class ActivityEntry(
    val id: String,
    val kind: Kind,
    val title: String,
    val subtitle: String,
    val ok: Boolean,
    val timeMillis: Long,
    val documentUri: String? = null,
    val signedOutput: Boolean = false,
) {
    enum class Kind { Document, Browser }
}

/** Rules of the activity list (macOS feedback, applied to every port). */
object ActivityHistory {
    const val MAX_ENTRIES = 100

    /** Newest first, capped at [MAX_ENTRIES]. */
    fun add(entries: List<ActivityEntry>, entry: ActivityEntry): List<ActivityEntry> =
        (listOf(entry) + entries).take(MAX_ENTRIES)

    /**
     * Document entries are shown only while their file is still reachable ([reachable] = permission still valid and
     * the document still exists); an entry without a URI can never be opened, so it goes too. Browser-request entries
     * always stay.
     */
    fun pruned(entries: List<ActivityEntry>, reachable: (String) -> Boolean): List<ActivityEntry> =
        entries.filter { e ->
            when (e.kind) {
                ActivityEntry.Kind.Browser -> true
                ActivityEntry.Kind.Document -> e.documentUri?.let(reachable) ?: false
            }
        }
}
