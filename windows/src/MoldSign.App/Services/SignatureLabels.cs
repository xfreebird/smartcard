namespace MoldSign.App.Services;

/// <summary>Display names only; signature and bridge identifiers remain unchanged.</summary>
internal static class SignatureLabels
{
    internal static string Human(string text)
    {
        (string Token, string Key)[] names = [
            ("PAdES-B-T", "format_pdf_time"), ("PAdES-B-B", "format_pdf"),
            ("PAdES-T", "format_pdf_time"), ("XAdES-BES", "format_xml"),
            ("XAdES-T", "format_xml_time"), ("XAdES-C", "format_xml_data"),
            ("PAdES", "format_pdf"), ("XAdES", "format_xml")];
        foreach (var (token, key) in names) text = text.Replace(token, Loc.Get(key));
        return text;
    }
}
