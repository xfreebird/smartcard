package md.moldsign.app.application

import android.net.Uri
import md.moldsign.core.SignFormat
import md.moldsign.core.ValidationReport
import md.moldsign.core.Verdict

/** A document picked through the Storage Access Framework. */
data class PickedDocument(val uri: Uri, val name: String, val size: Long, val mime: String?) {
    val isPdf: Boolean get() = mime == "application/pdf" || name.endsWith(".pdf", ignoreCase = true)

    /** docs/10 / PLAN §2: PDF → PAdES-T, anything else → XAdES-T detached (the user can change it per file). */
    val defaultFormat: SignFormat get() = SignFormat.default(isPdf)
}

/** Result of "Verifică": one report per signature found. */
data class VerifyOutcome(val reports: List<ValidationReport>) {
    val verdict: Verdict get() = Verdict.of(reports)

    /** Documents a detached XAdES refers to and that the user still has to pick. */
    val missingDocuments: List<String> get() = reports.flatMap { it.missingDocuments }.distinct()
}

/** One row of the Semnează list: the document and its (auto-chosen, editable) format. */
data class SignItem(
    val doc: PickedDocument,
    val format: SignFormat = doc.defaultFormat,
    val error: Throwable? = null,
    val stamp: md.moldsign.core.PdfStampPlacement? = null,
)


/** Session-only imported documents; shared by the composition and SAF adapter. */
const val SHARED_DOCUMENT_CACHE = "shared"
