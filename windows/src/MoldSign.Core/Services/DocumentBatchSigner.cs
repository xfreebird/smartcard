namespace MoldSign.Core;

/// <summary>Document signing boundary for desktop orchestration and hardware-free scenarios.</summary>
public interface IDocumentSigner
{
    SignResult Sign(string input, SignatureFormat format, XadesPackaging packaging, ConsentProvider consent,
                    string requester = "Tu", string? reader = null, string? expectedCertificateSha1 = null);
}

public sealed record SigningDocumentJob(string Path, SignatureFormat Format);
public sealed record DocumentBatchResult(IReadOnlyList<SignResult> Completed, Exception? Error);
public sealed class DocumentBatchBusyException() : InvalidOperationException("A document batch is already running.");

/// <summary>One frozen local batch: concurrency, scoped authorization, partial results and stop-on-first-failure.</summary>
public sealed class DocumentBatchSigner(IDocumentSigner signer)
{
    private int _active;

    public DocumentBatchResult Sign(IReadOnlyList<SigningDocumentJob> jobs, string reader, string certificateSha1,
                                    XadesPackaging packaging, ConsentProvider authorize,
                                    Action<SigningDocumentJob, SignResult>? completed = null,
                                    CancellationToken cancellationToken = default)
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
                var result = signer.Sign(job.Path, job.Format, packaging, consent.Request,
                    reader: reader, expectedCertificateSha1: certificateSha1);
                results.Add(result);
                completed?.Invoke(job, result);
            }
            return new DocumentBatchResult(results.AsReadOnly(), null);
        }
        catch (Exception error) { return new DocumentBatchResult(results.AsReadOnly(), error); }
        finally { Interlocked.Exchange(ref _active, 0); }
    }
}
