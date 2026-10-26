namespace MoldSign.Core.Tests;

/// <summary>Per-document signature format (Sign page picker): rules, output names, and routing to the right signer.</summary>
public class SignatureFormatTests
{
    [Fact]
    public void Pdf_offers_pades_and_xades_and_defaults_to_pades_t()
    {
        Assert.Equal([SignatureFormat.PadesT, SignatureFormat.XadesBes, SignatureFormat.XadesT, SignatureFormat.XadesC],
                     SignatureFormats.Allowed("contract.PDF"));
        Assert.Equal(SignatureFormat.PadesT, SignatureFormats.Default("contract.pdf"));
    }

    [Fact]
    public void Other_files_offer_xades_only_and_default_to_xades_t()
    {
        Assert.Equal([SignatureFormat.XadesBes, SignatureFormat.XadesT, SignatureFormat.XadesC], SignatureFormats.Allowed("act.docx"));
        Assert.Equal(SignatureFormat.XadesT, SignatureFormats.Default("act.docx"));
        Assert.Equal(["XAdES-BES", "XAdES-T", "XAdES-C"], SignatureFormats.Allowed("x.txt").Select(SignatureFormats.Label));
    }

    [Fact]
    public void Output_is_semnat_pdf_for_pades_and_semnat_xml_for_xades_over_a_pdf()
    {
        using var dir = new SigningCoreTests.TestFiles();
        {
            var pdf = Path.Combine(dir.DirectoryPath, "contract.pdf");
            File.WriteAllText(pdf, "%PDF-1.7");
            Assert.Equal(Path.Combine(dir.DirectoryPath, "contract-semnat.pdf"), SignatureFormats.OutputPath(pdf, SignatureFormat.PadesT));
            Assert.Equal(Path.Combine(dir.DirectoryPath, "contract-semnat.xml"), SignatureFormats.OutputPath(pdf, SignatureFormat.XadesC));
            File.WriteAllText(Path.Combine(dir.DirectoryPath, "contract-semnat.xml"), "<x/>");
            Assert.Equal(Path.Combine(dir.DirectoryPath, "contract-semnat (2).xml"), SignatureFormats.OutputPath(pdf, SignatureFormat.XadesT));
        }
    }

    [Theory]
    [InlineData(SignatureFormat.PadesT, "PAdES")]
    [InlineData(SignatureFormat.XadesBes, "XAdES")]
    [InlineData(SignatureFormat.XadesT, "XAdES")]
    [InlineData(SignatureFormat.XadesC, "XAdES")]
    public void Sign_routes_a_pdf_to_the_chosen_signer(SignatureFormat format, string signer)
    {
        using var dir = new SigningCoreTests.TestFiles();
        using var identity = new SigningCoreTests.TestIdentity();
        using var pki = new SigningCoreTests.FakePki(identity);
        {
            var pdf = dir.Write("contract.pdf", SigningCoreTests.MinimalPdf());
            var sim = IdentityGuardTests.Simulator(identity.Certificate, CosmoXCardTests.SessionAfterAuthentication());
            sim.InternalAuthenticate = identity.Sign;
            var service = new SigningService(reader => new IdentityGuardTests.AuthenticatingTransport(sim, reader ?? "R"), pki.Trust);
            // C uses the national chain in SigningService, so test routing by cancelling at the single consent.
            ConsentRequest? asked = null;
            var e = Assert.Throws<CardException>(() => service.Sign(pdf, format, XadesPackaging.Detached, request =>
            {
                asked = request;
                return ConsentResult.Cancelled;
            }));
            Assert.Equal(CardErrorKind.Cancelled, e.Kind);
            Assert.StartsWith(signer, asked!.Format);
            Assert.DoesNotContain(sim.Commands, c => c[1] == 0x20);
            Assert.Equal(0, pki.TimestampRequests);
        }
    }

    [Fact]
    public void Pades_on_a_non_pdf_is_rejected_before_touching_the_card()
    {
        var service = new SigningService(_ => throw new InvalidOperationException("the card must not be opened"));
        Assert.Throws<ArgumentException>(() => service.Sign("act.docx", SignatureFormat.PadesT, XadesPackaging.Detached,
            _ => ConsentResult.WithPin("1234")));
    }
}
