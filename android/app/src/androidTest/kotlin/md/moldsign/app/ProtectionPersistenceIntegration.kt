package md.moldsign.app

import android.content.Context
import android.net.Uri
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import md.moldsign.app.infrastructure.ActivityLog
import md.moldsign.app.infrastructure.ProtectedFileStore

/** Each phase is invoked in a separate instrumentation process. */
internal class ProtectionPersistenceIntegration(private val context: Context) {
    fun run(phase: String): String {
        require(phase == "prepare" || phase == "verify") { "Unknown persistence phase: $phase" }
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        val preferences = "protection-relaunch-integration"
        val state = context.getSharedPreferences(preferences, 0)
        val log = ActivityLog(context, scope, preferences)
        try {
            if (phase == "prepare") {
                check(log.signedDocuments.value.isEmpty()) { "Persistence fixture was not cleaned up" }
                val uri = ProtectedFileStore(context).save("Relaunch.txt", "Relaunch proof".toByteArray())
                log.document("Relaunch.txt", uri, true, "Decrypted", protectionOperation = "decrypt")
                // Flush preceding apply() writes before this process exits.
                check(state.edit().putBoolean("prepared", true).commit())
                return "PASS: prepared persisted protected output for process relaunch"
            }
            check(state.getBoolean("prepared", false)) { "Missing preparation from previous process" }
            val item = log.signedDocuments.value.single()
            check(item.protectionOperation == "decrypt" && !item.signedOutput)
            val uri = Uri.parse(item.documentUri)
            check(context.contentResolver.openInputStream(uri)!!.use { String(it.readBytes()) } == "Relaunch proof")
            check(context.contentResolver.delete(uri, null, null) == 1)
            log.removeSignedDocuments(setOf(item.id))
            check(state.edit().clear().commit())
            return "PASS: protected Documents output survived process restart and remained readable/deletable"
        } finally {
            scope.cancel()
        }
    }
}
