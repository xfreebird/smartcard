namespace MoldSign.App.Services;

/// <summary>Localizes display labels; certificate values and validator keys are unchanged.</summary>
internal static class CertificateLabels
{
    private static readonly Dictionary<string, string> Labels = new(StringComparer.OrdinalIgnoreCase)
    {
        ["Subject"] = "cert_label_subject",
        ["Issuer"] = "cert_label_issuer",
        ["Certificate"] = "cert_label_certificate",
        ["Certificate details"] = "cert_label_certificate_details",
        ["Name"] = "cert_label_name",
        ["Surname"] = "cert_label_surname",
        ["Given names"] = "cert_label_given_names",
        ["Personal identifier"] = "cert_label_personal_identifier",
        ["Country"] = "cert_label_country",
        ["City"] = "cert_label_city",
        ["Region"] = "cert_label_region",
        ["Organization"] = "cert_label_organization",
        ["Department"] = "cert_label_department",
        ["Organization identifier"] = "cert_label_organization_identifier",
        ["Telephone"] = "cert_label_telephone",
        ["Title"] = "cert_label_title",
        ["Serial number"] = "cert_label_serial_number",
        ["SHA-256 fingerprint"] = "cert_label_sha_256_fingerprint",
        ["Valid from"] = "cert_label_valid_from",
        ["Valid until"] = "cert_label_valid_until",
        ["Public key"] = "cert_label_public_key",
        ["Certificate signature algorithm"] = "cert_label_certificate_signature_algorithm",
        ["Revocation lists"] = "cert_label_revocation_lists",
        ["Authority information"] = "cert_label_authority_information",
        ["Alternative names"] = "cert_label_alternative_names",
        ["Certificate policies"] = "cert_label_certificate_policies",
        ["OCSP responder"] = "cert_label_ocsp_responder",
        ["Issuer certificate URL"] = "cert_label_issuer_certificate_url",
        ["Qualified certificate statements"] = "cert_label_qualified_certificate_statements",
        ["Subject key identifier"] = "cert_label_subject_key_identifier",
        ["Authority key identifier"] = "cert_label_authority_key_identifier",
        ["Key usage"] = "cert_label_key_usage",
        ["Extended key usage"] = "cert_label_extended_key_usage",
        ["Basic constraints"] = "cert_label_basic_constraints",
        ["Authority"] = "cert_label_authority",
        ["Certificate policy"] = "cert_label_certificate_policy",
        ["Extension"] = "cert_label_extension",
        ["CRL Distribution Points"] = "cert_label_revocation_lists",
        ["Authority Information Access"] = "cert_label_authority_information",
        ["Subject Alternative Name"] = "cert_label_alternative_names",
        ["Enhanced Key Usage"] = "cert_label_extended_key_usage"
    };
    internal static string Label(string raw)
    {
        if (Labels.TryGetValue(raw, out var key)) return Loc.Get(key);
        if (raw.Contains(" · ")) return string.Join(" · ", raw.Split(" · ").Select(Label));
        foreach (var prefix in new[] { "Certificate policy", "Authority", "Extension" })
            if (raw.StartsWith(prefix + " ", StringComparison.Ordinal)) return Label(prefix) + raw[prefix.Length..];
        return raw;
    }
}
