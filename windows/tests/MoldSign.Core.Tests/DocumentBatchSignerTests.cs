namespace MoldSign.Core.Tests;

public sealed class DocumentBatchSignerTests
{
    private static readonly CertificateSummary Certificate = new()
    {
        CommonName = "FICTIONAL HOLDER", Subject = "CN=Fixture", Issuer = "CN=Fixture",
        NotBefore = DateTimeOffset.UnixEpoch, NotAfter = DateTimeOffset.UnixEpoch.AddYears(100),
        SerialNumber = "01", Sha1 = new string('A', 40), Der = [],
    };

    [Fact]
    public void Frozen_batch_forwards_selected_identity_and_prompts_once()
    {
        var signer = new FakeSigner();
        var runner = new DocumentBatchSigner(signer);
        var jobs = new List<SigningDocumentJob> { new("a.pdf", SignatureFormat.PadesT), new("b.pdf", SignatureFormat.PadesT) };
        var prompts = 0;
        signer.BeforeSign = _ => jobs.Clear();
        var result = runner.Sign(jobs, "selected reader", Certificate.Sha1, XadesPackaging.Detached,
            _ => { prompts++; return ConsentResult.WithPin("0000"); }); // simulator-only
        Assert.Null(result.Error);
        Assert.Equal(2, result.Completed.Count);
        Assert.Equal(1, prompts);
        Assert.All(signer.Identities, identity => Assert.Equal(("selected reader", Certificate.Sha1), identity));
        Assert.True(signer.LastConsent!(Request("b.pdf")).IsCancelled); // runner disposed its scoped PIN session
    }

    [Fact]
    public void Duplicate_start_is_rejected_and_first_failure_stops_remaining_jobs()
    {
        var signer = new FakeSigner();
        var runner = new DocumentBatchSigner(signer);
        signer.BeforeSign = count =>
        {
            Assert.Throws<DocumentBatchBusyException>(() => runner.Sign([], "fixture", Certificate.Sha1,
                XadesPackaging.Detached, _ => ConsentResult.Cancelled));
            if (count == 2) throw new CardException(CardErrorKind.WrongPin, "Fixture rejection");
        };
        var result = runner.Sign([new("a.pdf", SignatureFormat.PadesT), new("b.pdf", SignatureFormat.PadesT), new("c.pdf", SignatureFormat.PadesT)],
            "fixture", Certificate.Sha1, XadesPackaging.Detached, _ => ConsentResult.WithPin("0000"));
        Assert.Single(result.Completed);
        Assert.Equal(CardErrorKind.WrongPin, Assert.IsType<CardException>(result.Error).Kind);
        Assert.Equal(2, signer.Identities.Count);
        Assert.True(signer.LastConsent!(Request("b.pdf")).IsCancelled);
    }

    [Fact]
    public void Cancellation_before_first_file_does_not_request_a_pin()
    {
        using var cancellation = new CancellationTokenSource(); cancellation.Cancel();
        var signer = new FakeSigner();
        var result = new DocumentBatchSigner(signer).Sign([new("a.pdf", SignatureFormat.PadesT)],
            "fixture", Certificate.Sha1, XadesPackaging.Detached,
            _ => throw new InvalidOperationException("No consent expected"), cancellationToken: cancellation.Token);
        Assert.IsAssignableFrom<OperationCanceledException>(result.Error);
        Assert.Empty(signer.Identities);
    }

    [Fact]
    public void Document_failure_is_reported_and_later_documents_continue()
    {
        var signer = new FakeSigner { BeforeSign = count => { if (count == 2) throw new CardException(CardErrorKind.Format, "Unsupported PDF"); } };
        var failures = new List<string>();
        var result = new DocumentBatchSigner(signer).Sign(
            [new("a.pdf", SignatureFormat.PadesT), new("bad.pdf", SignatureFormat.PadesT), new("c.pdf", SignatureFormat.PadesT)],
            "fixture", Certificate.Sha1, XadesPackaging.Detached, _ => ConsentResult.WithPin("0000"),
            failed: (job, _) => failures.Add(job.Path));
        Assert.Null(result.Error);
        Assert.Equal(2, result.Completed.Count);
        Assert.Equal(["bad.pdf"], failures);
        Assert.Equal(3, signer.Identities.Count);
    }

    private static ConsentRequest Request(string file) => new()
    { Certificate = Certificate, Documents = [file], Format = "PAdES-T", Requester = "Tu" };

    private sealed class FakeSigner : IDocumentSigner
    {
        public List<(string?, string?)> Identities { get; } = [];
        public Action<int>? BeforeSign { get; set; }
        public ConsentProvider? LastConsent { get; private set; }
        public SignResult Sign(string input, SignatureFormat format, XadesPackaging packaging, ConsentProvider consent,
                               string requester = "Tu", string? reader = null, string? expectedCertificateSha1 = null)
        {
            LastConsent = consent;
            Identities.Add((reader, expectedCertificateSha1));
            BeforeSign?.Invoke(Identities.Count);
            var decision = consent(Request(Path.GetFileName(input)));
            if (decision.IsCancelled) throw new CardException(CardErrorKind.Cancelled, "Fixture cancellation");
            return new SignResult([input + ".signed"], Certificate, "PAdES-T");
        }
    }
}
