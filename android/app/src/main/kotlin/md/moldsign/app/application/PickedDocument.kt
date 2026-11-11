package md.moldsign.app.application

import android.net.Uri
import md.moldsign.core.SignFormat

/** A document picked through the Storage Access Framework. */
data class PickedDocument(val uri: Uri, val name: String, val size: Long, val mime: String?) {
    val isPdf: Boolean get() = mime == "application/pdf" || name.endsWith(".pdf", ignoreCase = true)

    /** docs/10 / PLAN §2: PDF → PAdES-T, anything else → XAdES-T detached (the user can change it per file). */
    val defaultFormat: SignFormat get() = SignFormat.default(isPdf)
}
