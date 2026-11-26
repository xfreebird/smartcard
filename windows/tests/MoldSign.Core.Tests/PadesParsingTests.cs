using System.Text;

namespace MoldSign.Core.Tests;

/// <summary>PAdES incremental update over catalog syntax variants, and the failures that must stop before a signature.</summary>
public sealed class PadesParsingTests : IDisposable
{
    private readonly SigningCoreTests.TestIdentity _identity = new();
    private readonly SigningCoreTests.FakePki _pki;

    public PadesParsingTests() => _pki = new SigningCoreTests.FakePki(_identity);

    public void Dispose()
    {
        _pki.Dispose();
        _identity.Dispose();
    }

    private static byte[] Pdf(string catalog)
    {
        var text = "%PDF-1.7\n";
        string[] bodies = [catalog, "<</Type/Pages /Kids[3 0 R] /Count 1>>",
            "<</Type/Page /Parent 2 0 R /MediaBox[0 0 200 200] /Contents 4 0 R>>", "<</Length 5>>\nstream\nHello\nendstream"];
        var offsets = new List<int>();
        for (var i = 0; i < bodies.Length; i++)
        {
            offsets.Add(text.Length);
            text += $"{i + 1} 0 obj\n{bodies[i]}\nendobj\n";
        }
        var xref = text.Length;
        text += $"xref\n0 {bodies.Length + 1}\n0000000000 65535 f \n";
        foreach (var offset in offsets) text += $"{offset:D10} 00000 n \n";
        text += $"trailer\n<</Size {bodies.Length + 1} /Root 1 0 R>>\nstartxref\n{xref}\n%%EOF\n";
        return Encoding.Latin1.GetBytes(text);
    }

    [Fact]
    public void Inline_acroform_dictionaries_are_moved_to_an_object_and_flagged_for_signatures()
    {
        // Strings with escaped and nested parentheses, a comment and a hex string inside the inline dictionary.
        var pdf = Pdf("<</Type/Catalog /Pages 2 0 R /AcroForm <</Fields[] %not the end >>\n/DA(\\(Helv\\) 0 Tf (x)) /DR<</Note<48656C6C6F>>> >> /Lang(ro)>>");
        var signed = new PadesSigner(_pki.Trust).Sign(pdf, _identity.Certificate, _identity.Sign);

        var update = Encoding.Latin1.GetString(signed[pdf.Length..]);
        Assert.Equal(pdf, signed[..pdf.Length]);
        Assert.Matches(@"/AcroForm \d+ 0 R", update);
        Assert.Contains("/SigFlags 3", update);
        Assert.Contains("/DA (\\(Helv\\) 0 Tf (x))", update);
        var report = Assert.Single(Validator.ValidatePdf(signed));
        Assert.True(report.ContentIntact && report.SignatureValid, report.Notes);
    }

    [Theory]
    [InlineData("<</Type/Catalog /Pages 2 0 R /AcroForm [1 2 3]>>", "Unsupported AcroForm reference")]
    [InlineData("<</Type/Catalog /Pages 2 0 R /AcroForm <</Fields[] (unterminated", "Unterminated PDF dictionary")]
    public void Unsupported_catalogs_fail_before_the_card_signs(string catalog, string message)
    {
        var error = Assert.Throws<CardException>(() => new PadesSigner(_pki.Trust).Sign(Pdf(catalog), _identity.Certificate, _identity.Sign));
        Assert.Equal(CardErrorKind.Format, error.Kind);
        Assert.Contains(message, error.Message);
        Assert.Equal(0, _identity.SignCalls);
    }

    [Fact]
    public void Missing_trailers_and_changed_documents_fail_before_the_card_signs()
    {
        var signer = new PadesSigner(_pki.Trust);
        var noTrailer = Encoding.Latin1.GetBytes("%PDF-1.7\n1 0 obj\n<</Type/Catalog>>\nendobj\n");
        Assert.Contains("Cannot find the PDF trailer",
            Assert.Throws<CardException>(() => signer.Sign(noTrailer, _identity.Certificate, _identity.Sign)).Message);
        var stale = new PdfStampPlacement(DocumentSHA256: new string('0', 64));
        Assert.Contains("The PDF changed after stamp placement",
            Assert.Throws<CardException>(() => signer.Sign(SigningCoreTests.MinimalPdf(), _identity.Certificate, _identity.Sign, stale)).Message);
        Assert.Equal(0, _identity.SignCalls);
    }

    [Fact]
    public void A_card_signature_from_another_key_is_never_embedded()
    {
        using var other = new SigningCoreTests.TestIdentity();
        var error = Assert.Throws<CardException>(() =>
            new PadesSigner(_pki.Trust).Sign(SigningCoreTests.MinimalPdf(), _identity.Certificate, other.Sign));
        Assert.Equal(CardErrorKind.Format, error.Kind);
        Assert.Contains("The card signature does not match the signing certificate", error.Message);
        Assert.Equal(0, _pki.TimestampRequests);
    }
}
