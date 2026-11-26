namespace MoldSign.Core.Tests;

/// <summary>The Desktop Suite file adapter signs the requested paths with the selected card only.</summary>
public sealed class BridgeFileSignerTests : IDisposable
{
    private readonly SigningCoreTests.TestIdentity _identity = new();
    private readonly SigningCoreTests.FakePki _pki;
    private readonly DirectoryInfo _directory = Directory.CreateTempSubdirectory("moldsign-file-signer-");
    private int _consents;

    public BridgeFileSignerTests() => _pki = new SigningCoreTests.FakePki(_identity);

    public void Dispose()
    {
        _directory.Delete(true);
        _pki.Dispose();
        _identity.Dispose();
    }

    private (BridgeFileSigner Signer, CardEntry Card) Create()
    {
        var service = new SigningService(reader =>
        {
            Assert.Equal("Desktop reader", reader);
            var sim = IdentityGuardTests.Simulator(_identity.Certificate, CosmoXCardTests.SessionAfterAuthentication());
            sim.InternalAuthenticate = _identity.Sign;
            return new IdentityGuardTests.AuthenticatingTransport(sim, reader ?? "");
        }, _pki.Trust);
        return (new BridgeFileSigner(service), new CardEntry("Desktop reader", CertificateSummary.FromDer(_identity.Certificate)));
    }

    private ConsentResult Consent(ConsentRequest request)
    {
        _consents++;
        Assert.Equal("MoldSign Desktop Suite", request.Requester);
        return ConsentResult.WithPin("1234");
    }

    [Fact]
    public void Pdf_requests_write_a_verifiable_pades_signature_to_the_destination()
    {
        var (signer, card) = Create();
        var input = Path.Combine(_directory.FullName, "contract.pdf");
        File.WriteAllBytes(input, SigningCoreTests.MinimalPdf());
        var output = Path.Combine(_directory.FullName, "contract-signed.pdf");

        var written = signer.Sign(new BridgeFileSigningRequest([input], output, "PAdES-T", XadesPackaging.Detached, "SHA-256", null, Pdf: true),
            card, Consent);

        Assert.Equal(output, written);
        var report = Assert.Single(Validator.ValidatePdf(File.ReadAllBytes(output)));
        Assert.True(report.ContentIntact && report.SignatureValid);
        Assert.Equal(1, _consents);
        Assert.Equal(1, _identity.SignCalls);
    }

    [Theory]
    [InlineData("XAdES-BES", "XAdES-BES")]
    [InlineData("XAdES-T", "XAdES-T")]
    public void Xades_requests_keep_the_requested_level(string format, string level)
    {
        var (signer, card) = Create();
        var input = Path.Combine(_directory.FullName, "cerere.txt");
        File.WriteAllText(input, "Cerere de test");
        var output = Path.Combine(_directory.FullName, $"cerere-{format}.xml");

        signer.Sign(new BridgeFileSigningRequest([input], output, format, XadesPackaging.Detached, "SHA-256", null, Pdf: false), card, Consent);

        var report = Assert.Single(Validator.ValidateXades(File.ReadAllBytes(output),
            new Dictionary<string, byte[]> { ["cerere.txt"] = File.ReadAllBytes(input) }));
        Assert.Equal(level, report.Level);
        Assert.True(report.SignatureValid, report.Notes);
    }

    [Fact]
    public void Xades_c_needs_the_issuer_from_the_pinned_chain()
    {
        var (signer, card) = Create();
        var input = Path.Combine(_directory.FullName, "cerere.txt");
        File.WriteAllText(input, "Cerere de test");
        var output = Path.Combine(_directory.FullName, "cerere-c.xml");
        var error = Assert.Throws<CardException>(() => signer.Sign(new BridgeFileSigningRequest([input], output, "XAdES-C",
            XadesPackaging.Detached, "SHA-256", null, Pdf: false), card, Consent));
        Assert.Contains("XAdES-C requires the signing certificate issuer", error.Message); // the fixture CA is not bundled
        Assert.False(File.Exists(output));
    }

    [Fact]
    public void Unknown_formats_are_refused_before_the_card()
    {
        var (signer, card) = Create();
        var input = Path.Combine(_directory.FullName, "cerere.txt");
        File.WriteAllText(input, "x");
        Assert.Throws<InvalidDataException>(() => signer.Sign(new BridgeFileSigningRequest([input],
            Path.Combine(_directory.FullName, "out.xml"), "XAdES-X", XadesPackaging.Detached, "SHA-256", null, Pdf: false), card, Consent));
        Assert.Equal(0, _consents);
        Assert.Equal(0, _identity.SignCalls);
    }
}
