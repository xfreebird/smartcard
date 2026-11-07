import Foundation

/// Localizes presentation labels without changing certificate data or validator keys.
enum CertificateLabels {
    private static let labels: [String: L10n.Key] = [
        "Subject": .cert_label_subject,
        "Issuer": .cert_label_issuer,
        "Certificate": .cert_label_certificate,
        "Certificate details": .cert_label_certificate_details,
        "Name": .cert_label_name,
        "Surname": .cert_label_surname,
        "Given names": .cert_label_given_names,
        "Personal identifier": .cert_label_personal_identifier,
        "Country": .cert_label_country,
        "City": .cert_label_city,
        "Region": .cert_label_region,
        "Organization": .cert_label_organization,
        "Department": .cert_label_department,
        "Organization identifier": .cert_label_organization_identifier,
        "Telephone": .cert_label_telephone,
        "Title": .cert_label_title,
        "Serial number": .cert_label_serial_number,
        "SHA-256 fingerprint": .cert_label_sha_256_fingerprint,
        "Valid from": .cert_label_valid_from,
        "Valid until": .cert_label_valid_until,
        "Public key": .cert_label_public_key,
        "Certificate signature algorithm": .cert_label_certificate_signature_algorithm,
        "Revocation lists": .cert_label_revocation_lists,
        "Authority information": .cert_label_authority_information,
        "Alternative names": .cert_label_alternative_names,
        "Certificate policies": .cert_label_certificate_policies,
        "OCSP responder": .cert_label_ocsp_responder,
        "Issuer certificate URL": .cert_label_issuer_certificate_url,
        "Qualified certificate statements": .cert_label_qualified_certificate_statements,
        "Subject key identifier": .cert_label_subject_key_identifier,
        "Authority key identifier": .cert_label_authority_key_identifier,
        "Key usage": .cert_label_key_usage,
        "Extended key usage": .cert_label_extended_key_usage,
        "Basic constraints": .cert_label_basic_constraints,
        "Authority": .cert_label_authority,
        "Certificate policy": .cert_label_certificate_policy,
        "Extension": .cert_label_extension
    ]
    static func label(_ raw: String) -> String {
        if let key = labels[raw] { return L10n.text(key) }
        if raw.contains(" · ") {
            return raw.components(separatedBy: " · ").map { label($0) }.joined(separator: " · ")
        }
        for prefix in ["Certificate policy", "Authority", "Extension"] where raw.hasPrefix(prefix + " ") {
            return label(prefix) + String(raw.dropFirst(prefix.count))
        }
        return raw // Unknown OIDs and vendor field identifiers must remain intact.
    }
}
