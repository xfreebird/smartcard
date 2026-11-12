package md.moldsign.app.ui.components

/** Values ready to draw; no certificate, device or service objects cross this boundary. */
data class IdentityCardContent(
    val readerId: String,
    val readerName: String,
    val holder: String,
    val surname: String,
    val givenNames: String,
    val validUntil: String,
    val issuer: String,
    val hasIdentity: Boolean,
    val problem: String?,
    val hueShift: Float,
    val description: String,
)
