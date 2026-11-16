package md.moldsign.app.nfc

import android.content.Context
import android.os.SystemClock
import md.moldsign.app.BuildConfig
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.UUID

/** Debug-only metadata. Never receives PINs, command bytes, tag IDs, certificates or document names. */
internal class NfcDiagnostics(private val context: Context) {
    private val start = SystemClock.elapsedRealtime()
    private val events = JSONArray()
    private val fileName = "session-${UUID.randomUUID()}.json"
    @Synchronized fun event(stage: String, value: Int? = null, category: String? = null) {
        if (!BuildConfig.DEBUG || events.length() >= 256) return
        events.put(JSONObject().put("stage", stage).put("elapsedMs", SystemClock.elapsedRealtime() - start)
            .apply { value?.let { put("value", it) }; category?.let { put("category", it) } })
    }
    @Synchronized fun command(ins: Int, response: ByteArray) {
        if (!BuildConfig.DEBUG || events.length() >= 256) return
        val status = if (response.size >= 2) "%02X%02X".format(response[response.size - 2].toInt() and 255, response.last().toInt() and 255) else "missing"
        events.put(JSONObject().put("stage", "exchange").put("ins", "%02X".format(ins))
            .put("responseBytes", response.size).put("status", status).put("elapsedMs", SystemClock.elapsedRealtime() - start))
    }
    @Synchronized fun finish(outcome: String) {
        if (!BuildConfig.DEBUG) return
        runCatching {
            val folder = File(context.cacheDir, "nfc-diagnostics").apply { mkdirs() }
            val json = JSONObject().put("schema", 1).put("build", BuildConfig.VERSION_NAME + " (" + BuildConfig.VERSION_CODE + ")")
                .put("outcome", outcome).put("events", events)
            File(folder, fileName).writeText(json.toString(2))
            folder.listFiles()?.sortedByDescending { it.lastModified() }?.drop(20)?.forEach { it.delete() }
        }
    }
}
