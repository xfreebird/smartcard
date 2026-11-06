namespace MoldSign.Core;

/// <summary>Document signing boundary for desktop orchestration and hardware-free scenarios.</summary>
public interface IDocumentSigner
{
    SignResult SignVisible(string input, SignatureFormat format, XadesPackaging packaging, ConsentProvider consent,
        PdfStampPlacement placement, string requester = "Tu", string? reader = null, string? expectedCertificateSha1 = null)
        => throw new CardException(CardErrorKind.Format, "Visible signatures are not supported by this signer");
    SignResult Sign(string input, SignatureFormat format, XadesPackaging packaging, ConsentProvider consent,
                    string requester = "Tu", string? reader = null, string? expectedCertificateSha1 = null);
}

public sealed record SigningDocumentJob(string Path, SignatureFormat Format, PdfStampPlacement? Stamp = null);
public sealed record DocumentBatchResult(IReadOnlyList<SignResult> Completed, Exception? Error);
public sealed class DocumentBatchBusyException() : InvalidOperationException("A document batch is already running.");

/// <summary>One frozen local batch: concurrency, scoped authorization, partial results and per-document failure reporting.</summary>
public sealed class DocumentBatchSigner(IDocumentSigner signer)
{
    private int _active;

    public DocumentBatchResult Sign(IReadOnlyList<SigningDocumentJob> jobs, string reader, string certificateSha1,
                                    XadesPackaging packaging, ConsentProvider authorize,
                                    Action<SigningDocumentJob, SignResult>? completed = null,
                                    CancellationToken cancellationToken = default,
                                    Action<SigningDocumentJob, Exception>? failed = null)
    {
        var snapshot = jobs.ToArray();
        if (Interlocked.CompareExchange(ref _active, 1, 0) != 0) throw new DocumentBatchBusyException();
        var results = new List<SignResult>();
        try
        {
            if (snapshot.Length == 0) return new DocumentBatchResult([], null);
            using var consent = new BatchConsentSession(certificateSha1, "Tu",
                snapshot.Select(job => new BatchConsentDocument(job.Path, SignatureFormats.Label(job.Format))).ToArray(), authorize);
            foreach (var job in snapshot)
            {
                cancellationToken.ThrowIfCancellationRequested();
                try
                {
                var result = job.Stamp is not null && job.Format == SignatureFormat.PadesT
                    ? signer.SignVisible(job.Path, job.Format, packaging, consent.Request, job.Stamp, reader: reader, expectedCertificateSha1: certificateSha1)
                    : signer.Sign(job.Path, job.Format, packaging, consent.Request, reader: reader, expectedCertificateSha1: certificateSha1);
                results.Add(result);
                completed?.Invoke(job, result);
                }
                catch (Exception error) when (error is IOException || error is FormatException || error is CardException { Kind: CardErrorKind.Format or CardErrorKind.Network })
                {
                    if (failed is null) return new DocumentBatchResult(results.AsReadOnly(), error);
                    consent.SkipFailedDocument(job.Path);
                    failed(job, error);
                }
            }
            return new DocumentBatchResult(results.AsReadOnly(), null);
        }
        catch (Exception error) { return new DocumentBatchResult(results.AsReadOnly(), error); }
        finally { Interlocked.Exchange(ref _active, 0); }
    }
}
