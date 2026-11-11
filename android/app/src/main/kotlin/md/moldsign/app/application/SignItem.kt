package md.moldsign.app.application

import md.moldsign.core.SignFormat

/** One row of the Semnează list: the document and its (auto-chosen, editable) format. */
data class SignItem(
    val doc: PickedDocument,
    val format: SignFormat = doc.defaultFormat,
    val error: Throwable? = null,
    val stamp: md.moldsign.core.PdfStampPlacement? = null,
)
