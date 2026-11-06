import Foundation

/// Human-readable signature names at the presentation boundary.
func signatureLabels(_ text: String) -> String {
    let names: [(String, L10n.Key)] = [
        ("PAdES-B-T", .format_pdf_time), ("PAdES-B-B", .format_pdf),
        ("PAdES-T", .format_pdf_time), ("XAdES-BES", .format_xml),
        ("XAdES-T", .format_xml_time), ("XAdES-C", .format_xml_data),
        ("PAdES", .format_pdf), ("XAdES", .format_xml)
    ]
    return names.reduce(text) { $0.replacingOccurrences(of: $1.0, with: L10n.text($1.1)) }
}
