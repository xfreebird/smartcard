package md.moldsign.app.ui.components

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import md.moldsign.app.R

/** Translate display values without changing bridge or signing identifiers. */
@Composable
fun signatureLabels(text: String): String {
    val names = listOf(
        "PAdES-B-T" to R.string.format_pdf_time, "PAdES-B-B" to R.string.format_pdf,
        "PAdES-T" to R.string.format_pdf_time, "XAdES-BES" to R.string.format_xml,
        "XAdES-T" to R.string.format_xml_time, "XAdES-C" to R.string.format_xml_data,
        "PAdES" to R.string.format_pdf, "XAdES" to R.string.format_xml,
    )
    var result = text
    for ((token, key) in names) result = result.replace(token, stringResource(key))
    return result
}
