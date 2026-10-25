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
        var dir = Directory.CreateTempSubdirectory("moldsign-format-");
        try
        {
            var pdf = Path.Combine(dir.FullName, "contract.pdf");
            File.WriteAllText(pdf, "%PDF-1.7");
            Assert.Equal(Path.Combine(dir.FullName, "contract-semnat.pdf"), SignatureFormats.OutputPath(pdf, SignatureFormat.PadesT));
            Assert.Equal(Path.Combine(dir.FullName, "contract-semnat.xml"), SignatureFormats.OutputPath(pdf, SignatureFormat.XadesC));
            File.WriteAllText(Path.Combine(dir.FullName, "contract-semnat.xml"), "<x/>");
            Assert.Equal(Path.Combine(dir.FullName, "contract-semnat (2).xml"), SignatureFormats.OutputPath(pdf, SignatureFormat.XadesT));
        }
        finally
        {
            dir.Delete(recursive: true);
        }
    }

    [Theory]
    [InlineData(SignatureFormat.PadesT, "PAdES")]
    [InlineData(SignatureFormat.XadesBes, "XAdES")]
    [InlineData(SignatureFormat.XadesT, "XAdES")]
    [InlineData(SignatureFormat.XadesC, "XAdES")]
    public void Sign_routes_a_pdf_to_the_chosen_signer(SignatureFormat format, string signer)
    {
        var dir = Directory.CreateTempSubdirectory("moldsign-format-");
        try
        {
            var pdf = Path.Combine(dir.FullName, "contract.pdf");
            File.WriteAllText(pdf, "%PDF-1.7");
            var certificate = IdentityGuardTests.TestCertificate("CN=ION POPESCU, C=MD");
            var service = new SigningService(reader => new IdentityGuardTests.AuthenticatingTransport(
                IdentityGuardTests.Simulator(certificate, CosmoXCardTests.SessionAfterAuthentication()), reader ?? "R"));

            // Signing itself is still a WIN-01 stub: the stub that throws tells which signer the format reached.
            var e = Assert.Throws<NotImplementedException>(() => service.Sign(pdf, format, XadesPackaging.Detached,
                _ => ConsentResult.WithPin("1234")));

            Assert.Contains(signer, e.Message);
        }
        finally
        {
            dir.Delete(recursive: true);
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
