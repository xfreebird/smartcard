using System.Text;
using MoldSign.Core;

namespace MoldSign.Desktop;

/// <summary>Disposable sample-only sandbox. No input bytes, credentials, transports or real documents are read.</summary>
public sealed class DemoSession : IDocumentSigner, IDocumentVerifier, IDisposable
{
    private readonly HashSet<string> _owned = new(StringComparer.OrdinalIgnoreCase);
    public string DirectoryPath { get; }
    public IReadOnlyList<string> Documents { get; }
    public DemoSession()
    {
        DirectoryPath = Path.Combine(Path.GetTempPath(), "eSemnBun-Demo-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(DirectoryPath);
        var pdf = Path.Combine(DirectoryPath, "demo-contract.pdf");
        var text = Path.Combine(DirectoryPath, "demo-note.txt");
        File.WriteAllBytes(pdf, SamplePdf());
        File.WriteAllText(text, "DEMO ONLY. Fictional sample; no real document or digital signature.");
        _owned.Add(pdf); _owned.Add(text);
        Documents = [pdf, text];
    }
    public bool Owns(string path) => _owned.Contains(Path.GetFullPath(path));
    public SignResult Sign(string input, SignatureFormat format, XadesPackaging packaging, ConsentProvider consent,
        string requester = "Tu", string? reader = null, string? expectedCertificateSha1 = null)
    {
        if (!Owns(input)) throw new InvalidOperationException("Only demo fixtures are allowed.");
        var extension = format == SignatureFormat.PadesT ? ".pdf" : ".xml";
        var output = Path.Combine(DirectoryPath, Path.GetFileNameWithoutExtension(input) + "-DEMO-NOT-SIGNED" + extension);
        if (extension == ".pdf") File.WriteAllBytes(output, SamplePdf());
        else File.WriteAllText(output, "<Demonstration simulated=\"true\" legallyValid=\"false\">DEMO ONLY - NOT A DIGITAL SIGNATURE</Demonstration>");
        _owned.Add(output);
        return new SignResult([output], DemoCertificate(reader), "DEMO");
    }
    public IReadOnlyList<VerificationReport> Verify(string file, IReadOnlyList<string>? detachedDocs = null)
    {
        if (!Owns(file) || detachedDocs?.Any(path => !Owns(path)) == true)
            throw new InvalidOperationException("Only demo fixtures are allowed.");
#if DEBUG
        // Explicit, sample-owned screenshot fixtures only. This branch is absent from Release.
        if (Environment.GetEnvironmentVariable("MSIGN_SCREENSHOT_CAPTURE") == "1" &&
            Environment.GetEnvironmentVariable("MSIGN_DEMO_CARDS") is not null &&
            Environment.GetEnvironmentVariable("MSIGN_DEMO_VERIFY") is { } state)
        {
            if (state == "unsigned") return [];
            if (state is not ("valid" or "invalid" or "unknown"))
                throw new InvalidOperationException("Unknown verification screenshot fixture.");
            return [new VerificationReport
            {
                Kind = "PAdES", Name = "Signature1", Signer = "POPESCU ION", Level = "PAdES-B-T",
                ContentIntact = state != "invalid", SignatureValid = true, ChainTrusted = state != "unknown",
                SigningTime = "2026-11-07T12:00:00+02:00", TimestampTime = "2026-11-07T12:00:02+02:00",
                TimestampImprintValid = true, TimestampSignatureValidated = false, RevocationValidated = false,
                CertificateDetails = new Dictionary<string, string>
                {
                    ["Subject · Name"] = "POPESCU ION", ["Issuer · Name"] = "Autoritate de test",
                    ["Serial number"] = "01", ["Public key"] = "RSA 4096 bits",
                    ["Valid from"] = "01.01.2025", ["Valid until"] = "01.01.2030",
                },
            }];
        }
#endif
        return [new VerificationReport
        {
            Kind = "DEMO", Name = "DEMO", Signer = "FICTIONAL DEMO", Level = "DEMO",
            ContentIntact = true, SignatureValid = true, ChainTrusted = true,
            TimestampSignatureValidated = true, RevocationValidated = true, Notes = "DEMO ONLY - NOT A DIGITAL SIGNATURE",
        }];
    }
    private static CertificateSummary DemoCertificate(string? reader) => new()
    {
        CommonName = reader?.EndsWith('2') == true ? "ISTRATI ELENA" : "POPESCU ION",
        Surname = reader?.EndsWith('2') == true ? "ISTRATI" : "POPESCU",
        GivenName = reader?.EndsWith('2') == true ? "ELENA" : "ION", Subject = "CN=Fictional demo",
        Issuer = "CN=DEMO CA", IssuerName = "DEMO CA",
        Sha1 = new string(reader?.EndsWith('2') == true ? '2' : '1', 40),
        SerialNumber = reader?.EndsWith('2') == true ? "02" : "01", Der = [],
        NotBefore = new DateTimeOffset(2025, 1, 1, 0, 0, 0, TimeSpan.Zero),
        NotAfter = new DateTimeOffset(2030, 1, 1, 0, 0, 0, TimeSpan.Zero),
    };
    private static byte[] SamplePdf()
    {
        var objects = new[]
        {
            "<< /Type /Catalog /Pages 2 0 R >>", "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
            "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
            "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        };
        const string content = "BT /F1 22 Tf 36 780 Td (DEMO ONLY - NOT DIGITALLY SIGNED) Tj 0 -40 Td /F1 14 Tf (Fictional eSemnBun sample document.) Tj ET\n";
        using var stream = new MemoryStream();
        void Write(string value) => stream.Write(Encoding.ASCII.GetBytes(value));
        Write("%PDF-1.4\n");
        var offsets = new List<long> { 0 };
        for (var i = 0; i < objects.Length; i++)
        {
            offsets.Add(stream.Position); Write($"{i + 1} 0 obj\n{objects[i]}\nendobj\n");
        }
        offsets.Add(stream.Position); Write($"5 0 obj\n<< /Length {content.Length} >>\nstream\n{content}endstream\nendobj\n");
        var xref = stream.Position;
        Write("xref\n0 6\n0000000000 65535 f \n");
        foreach (var offset in offsets.Skip(1)) Write($"{offset:D10} 00000 n \n");
        Write($"trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n");
        return stream.ToArray();
    }
    public void Dispose()
    {
        try { if (Directory.Exists(DirectoryPath)) Directory.Delete(DirectoryPath, true); }
        catch (IOException) { }
        catch (UnauthorizedAccessException) { }
    }
}
