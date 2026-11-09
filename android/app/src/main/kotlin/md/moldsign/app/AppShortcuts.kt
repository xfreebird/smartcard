package md.moldsign.app

import android.content.Intent

/** Public entry points carry navigation only: never a file path, PIN or signing authorization. */
object AppShortcuts {
    const val ACTION = "md.esemnbun.app.OPEN_FEATURE"
    const val FEATURE = "esemnbun_feature"
    enum class Destination(val id: String) {
        Verify("verify_pdf"), PrepareSigning("prepare_signing"), Documents("documents");
        companion object {
            fun fromId(id: String?) = entries.firstOrNull { it.id == id }
        }
    }
    fun destination(intent: Intent?): Destination? {
        if (intent?.action != ACTION) return null
        return resolve(intent.action, intent.hasExtra(FEATURE), intent.getStringExtra(FEATURE))
    }
    internal fun resolve(action: String?, hasFeature: Boolean, feature: String?): Destination? {
        if (action != ACTION) return null
        // Assistant's no-parameter fallback opens Documents. Unknown values are ignored.
        return if (!hasFeature) Destination.Documents else Destination.fromId(feature)
    }
}
