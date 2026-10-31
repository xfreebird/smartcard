using System.Security.Cryptography;
using System.Text;

namespace MoldSign.Core.Tests;

public sealed class BatchConsentSessionTests
{
    private const string FixturePin = "0000"; // fictional simulator PIN only
    private static readonly CertificateSummary Certificate = new()
    {
        CommonName = "FICTIONAL HOLDER", Subject = "CN=Fixture", Issuer = "CN=Fixture CA",
        NotBefore = DateTimeOffset.UnixEpoch, NotAfter = DateTimeOffset.UnixEpoch.AddYears(100),
        SerialNumber = "01", Sha1 = new string('A', 40), Der = [],
    };

    private static ConsentRequest Request(string document, string format = "PAdES-T") => new()
    {
        Requester = "Tu", Documents = [document], Format = format, Certificate = Certificate,
    };

    [Fact]
    public void One_prompt_covers_frozen_ordered_batch_and_reuses_only_its_pin()
    {
        var documents = new List<BatchConsentDocument> { new("a.pdf", "PAdES-T"), new("b.txt", "XAdES-BES") };
        ConsentRequest? shown = null;
        var calls = 0;
        using var batch = new BatchConsentSession(Certificate.Sha1, "Tu", documents, request =>
        {
            calls++;
            shown = request;
            return ConsentResult.WithPin(FixturePin);
        });
        documents.Clear(); // subsequent edits to the UI queue cannot change the consent scope
        Assert.Equal(FixturePin, batch.Request(Request("a.pdf")).Pin);
        Assert.Equal(FixturePin, batch.Request(Request("b.txt", "XAdES-BES")).Pin);
        Assert.Equal(1, calls);
        Assert.NotNull(shown);
        Assert.Equal(["a.pdf · PAdES-T", "b.txt · XAdES-BES"], shown.Documents);
        Assert.Equal("PAdES-T / XAdES-BES", shown.Format);
        Assert.True(batch.Request(Request("a.pdf")).IsCancelled); // no operations beyond the frozen batch
    }

    [Fact]
    public void A_different_certificate_ends_the_session_before_releasing_a_cached_pin()
    {
        using var batch = Session(_ => ConsentResult.WithPin(FixturePin));
        batch.Request(Request("a.pdf"));
        var error = Assert.Throws<CardException>(() => batch.Request(Request("b.pdf") with
        {
            Certificate = Certificate with { Sha1 = new string('B', 40) },
        }));
        Assert.Equal(CardErrorKind.CardChanged, error.Kind);
        Assert.True(batch.Request(Request("b.pdf")).IsCancelled);
    }

    [Theory]
    [InlineData("origin")]
    [InlineData("document")]
    [InlineData("format")]
    public void Changed_scope_rejects_reuse_and_ends_the_session(string change)
    {
        var calls = 0;
        using var batch = Session(_ => { calls++; return ConsentResult.WithPin(FixturePin); });
        batch.Request(Request("a.pdf"));
        var request = Request("b.pdf");
        request = change switch
        {
            "origin" => request with { Requester = "https://other.example" },
            "document" => request with { Documents = ["outside.pdf"] },
            _ => request with { Format = "XAdES-BES" },
        };
        Assert.True(batch.Request(request).IsCancelled);
        Assert.True(batch.Request(Request("b.pdf")).IsCancelled);
        Assert.Equal(1, calls);
    }

    [Fact]
    public void Cancellation_and_disposal_never_prompt_again()
    {
        var calls = 0;
        var batch = Session(_ => { calls++; return ConsentResult.Cancelled; });
        Assert.True(batch.Request(Request("a.pdf")).IsCancelled);
        Assert.True(batch.Request(Request("a.pdf")).IsCancelled);
        batch.Dispose();
        batch.Dispose();
        Assert.True(batch.Request(Request("b.pdf")).IsCancelled);
        Assert.Equal(1, calls);
        var approved = Session(_ => ConsentResult.WithPin(FixturePin));
        approved.Request(Request("a.pdf"));
        approved.Dispose();
        Assert.True(approved.Request(Request("b.pdf")).IsCancelled);
    }

    [Fact]
    public void Provider_failure_ends_scope_without_retrying()
    {
        var calls = 0;
        using var batch = Session(_ => { calls++; throw new IOException("Fixture failure"); });
        Assert.Throws<IOException>(() => batch.Request(Request("a.pdf")));
        Assert.True(batch.Request(Request("a.pdf")).IsCancelled);
        Assert.Equal(1, calls);
    }

    [Fact]
    public void Disposal_during_the_provider_callback_cannot_resurrect_a_pin()
    {
        BatchConsentSession? session = null;
        using var batch = session = Session(_ =>
        {
            session!.Dispose();
            return ConsentResult.WithPin(FixturePin);
        });
        Assert.True(batch.Request(Request("a.pdf")).IsCancelled);
        Assert.True(batch.Request(Request("b.pdf")).IsCancelled);
    }

    [Fact]
    public void Mixed_pdf_xml_batch_has_one_consent_and_identity_check_for_each_signature()
    {
        using var identity = new SigningCoreTests.TestIdentity();
        using var pki = new SigningCoreTests.FakePki(identity);
        using var files = new SigningCoreTests.TestFiles();
        var pdf = files.Write("first.pdf", SigningCoreTests.MinimalPdf());
        var text = files.Write("second.txt", Encoding.UTF8.GetBytes("Fictional batch document"));
        var simulations = new List<CosmoXCardTests.SimulatedSmCard>();
        var service = new SigningService(reader =>
        {
            var sim = IdentityGuardTests.Simulator(identity.Certificate, CosmoXCardTests.SessionAfterAuthentication());
            sim.InternalAuthenticate = identity.Sign;
            simulations.Add(sim);
            return new IdentityGuardTests.AuthenticatingTransport(sim, reader ?? "fixture");
        }, pki.Trust);
        var expected = Convert.ToHexString(SHA1.HashData(identity.Certificate));
        var calls = 0;
        using var batch = new BatchConsentSession(expected, "Tu",
            [new(pdf, "PAdES-T"), new(text, "XAdES-BES")], _ => { calls++; return ConsentResult.WithPin(FixturePin); });
        var first = service.Sign(pdf, SignatureFormat.PadesT, XadesPackaging.Detached, batch.Request,
            reader: "fixture", expectedCertificateSha1: expected);
        var second = service.Sign(text, SignatureFormat.XadesBes, XadesPackaging.Detached, batch.Request,
            reader: "fixture", expectedCertificateSha1: expected);
        Assert.Equal(1, calls);
        Assert.Equal(2, simulations.Count);
        Assert.All(simulations, sim => Assert.Single(sim.Commands, command => command[1] == 0x20));
        Assert.True(Assert.Single(service.Verify(first.OutputFiles[0])).SignatureValid);
        Assert.True(Assert.Single(service.Verify(second.OutputFiles[0], [text])).SignatureValid);
    }

    [Fact]
    public void Wrong_pin_stops_batch_after_one_verify_and_scope_is_disposed()
    {
        using var identity = new SigningCoreTests.TestIdentity();
        using var files = new SigningCoreTests.TestFiles();
        var first = files.Write("first.txt", [1]);
        var second = files.Write("second.txt", [2]);
        var connects = 0;
        var verifies = 0;
        var service = new SigningService(reader =>
        {
            connects++;
            var sim = IdentityGuardTests.Simulator(identity.Certificate, CosmoXCardTests.SessionAfterAuthentication());
            return new RejectPinTransport(new IdentityGuardTests.AuthenticatingTransport(sim, reader ?? "fixture"), () => verifies++);
        });
        var expected = Convert.ToHexString(SHA1.HashData(identity.Certificate));
        var prompts = 0;
        var batch = new BatchConsentSession(expected, "Tu", [new(first, "XAdES-BES"), new(second, "XAdES-BES")],
            _ => { prompts++; return ConsentResult.WithPin(FixturePin); });
        var error = Assert.Throws<CardException>(() =>
        {
            using (batch)
                foreach (var input in new[] { first, second })
                    service.Sign(input, SignatureFormat.XadesBes, XadesPackaging.Detached, batch.Request,
                        reader: "fixture", expectedCertificateSha1: expected);
        });
        Assert.Equal(CardErrorKind.WrongPin, error.Kind);
        Assert.Equal(1, connects);
        Assert.Equal(1, verifies);
        Assert.Equal(1, prompts);
        Assert.True(batch.Request(Request("second.txt", "XAdES-BES")).IsCancelled);
        Assert.False(File.Exists(SignatureFormats.OutputPath(second, SignatureFormat.XadesBes)));
    }

    private static BatchConsentSession Session(ConsentProvider provider) =>
        new(Certificate.Sha1, "Tu", [new("a.pdf", "PAdES-T"), new("b.pdf", "PAdES-T")], provider);

    private sealed class RejectPinTransport(ICardTransport inner, Action verified) : ICardTransport
    {
        public string ReaderName => inner.ReaderName;
        public byte[] Transmit(byte[] apdu)
        {
            if (apdu[1] != 0x20) return inner.Transmit(apdu);
            verified();
            return [0x63, 0xC2];
        }
        public void Dispose() => inner.Dispose();
    }
}
