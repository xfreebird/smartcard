package md.moldsign.app.application

import md.moldsign.core.ActivityEntry

/** Confirmation is bound to the stored URI; presentation cannot substitute another file. */
class DeleteSavedDocuments(private val deleteFile: (String) -> Boolean) {
    data class Result(val deletedIds: Set<String>, val failed: Boolean)

    fun execute(selected: List<ActivityEntry>, saved: List<ActivityEntry>): Result {
        val current = saved.associateBy { it.id }
        val deleted = mutableSetOf<String>()
        var failed = false
        for (item in selected.distinctBy { it.id }) {
            val stored = current[item.id] ?: continue
            val uri = stored.documentUri
            if (uri == null || uri != item.documentUri || !deleteFile(uri)) failed = true
            else deleted += stored.id
        }
        return Result(deleted, failed)
    }
}
