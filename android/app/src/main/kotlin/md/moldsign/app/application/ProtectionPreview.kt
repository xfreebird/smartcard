package md.moldsign.app.application

/** Values supplied by a preview provider; no real file is selected by this presentation state. */
data class ProtectionPreview(
    val sourceName: String,
    val completionSourceName: String,
    val decrypt: Boolean,
    val completed: Boolean,
    val certificate: Boolean = false,
)
