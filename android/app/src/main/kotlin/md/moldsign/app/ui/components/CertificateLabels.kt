package md.moldsign.app.ui.components

import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import md.moldsign.app.R

/** Display labels only: certificate data and validator keys remain unchanged. */
object CertificateLabels {
    private val labels = mapOf(
        "Subject" to R.string.cert_label_subject,
        "Issuer" to R.string.cert_label_issuer,
        "Certificate" to R.string.cert_label_certificate,
        "Certificate details" to R.string.cert_label_certificate_details,
        "Name" to R.string.cert_label_name,
        "Surname" to R.string.cert_label_surname,
        "Given names" to R.string.cert_label_given_names,
        "Personal identifier" to R.string.cert_label_personal_identifier,
        "Country" to R.string.cert_label_country,
        "City" to R.string.cert_label_city,
        "Region" to R.string.cert_label_region,
        "Organization" to R.string.cert_label_organization,
        "Department" to R.string.cert_label_department,
        "Organization identifier" to R.string.cert_label_organization_identifier,
        "Telephone" to R.string.cert_label_telephone,
        "Title" to R.string.cert_label_title,
        "Serial number" to R.string.cert_label_serial_number,
        "SHA-256 fingerprint" to R.string.cert_label_sha_256_fingerprint,
        "Valid from" to R.string.cert_label_valid_from,
        "Valid until" to R.string.cert_label_valid_until,
        "Public key" to R.string.cert_label_public_key,
        "Certificate signature algorithm" to R.string.cert_label_certificate_signature_algorithm,
        "Revocation lists" to R.string.cert_label_revocation_lists,
        "Authority information" to R.string.cert_label_authority_information,
        "Alternative names" to R.string.cert_label_alternative_names,
        "Certificate policies" to R.string.cert_label_certificate_policies,
        "OCSP responder" to R.string.cert_label_ocsp_responder,
        "Issuer certificate URL" to R.string.cert_label_issuer_certificate_url,
        "Qualified certificate statements" to R.string.cert_label_qualified_certificate_statements,
        "Subject key identifier" to R.string.cert_label_subject_key_identifier,
        "Authority key identifier" to R.string.cert_label_authority_key_identifier,
        "Key usage" to R.string.cert_label_key_usage,
        "Extended key usage" to R.string.cert_label_extended_key_usage,
        "Basic constraints" to R.string.cert_label_basic_constraints,
        "Authority" to R.string.cert_label_authority,
        "Certificate policy" to R.string.cert_label_certificate_policy,
        "Extension" to R.string.cert_label_extension
    )
    @Composable
    fun label(raw: String): String {
        labels[raw]?.let { return stringResource(it) }
        if (raw.contains(" · ")) {
            val parts = mutableListOf<String>()
            for (part in raw.split(" · ")) parts.add(label(part))
            return parts.joinToString(" · ")
        }
        for (prefix in listOf("Certificate policy", "Authority", "Extension")) {
            if (raw.startsWith("$prefix ")) return label(prefix) + raw.removePrefix(prefix)
        }
        return raw
    }
}
