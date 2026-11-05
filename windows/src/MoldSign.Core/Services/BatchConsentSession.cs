namespace MoldSign.Core;

/// <summary>One frozen document/format pair in a local signing batch.</summary>
public sealed record BatchConsentDocument(string Path, string Format);

/// <summary>
/// One consent for a frozen, ordered batch, bound to the selected certificate and requester.
/// The PIN is held only until disposal/failure/cancellation; every signature still performs its card identity guard.
/// String-based core PIN APIs prevent a guarantee that managed memory is physically zeroed.
/// </summary>
public sealed class BatchConsentSession : IDisposable
{
    private readonly object _gate = new();
    private readonly string _certificateSha1;
    private readonly string _requester;
    private BatchConsentDocument[] _documents;
    private ConsentProvider? _authorize;
    private string? _pin;
    private int _next;
    private bool _ended;

    public BatchConsentSession(string certificateSha1, string requester,
                               IReadOnlyList<BatchConsentDocument> documents, ConsentProvider authorize)
    {
        ArgumentException.ThrowIfNullOrEmpty(certificateSha1);
        ArgumentException.ThrowIfNullOrEmpty(requester);
        ArgumentNullException.ThrowIfNull(documents);
        ArgumentNullException.ThrowIfNull(authorize);
        if (documents.Count == 0 || documents.Any(document => document is null ||
            string.IsNullOrEmpty(document.Path) || string.IsNullOrEmpty(document.Format)))
            throw new ArgumentException("A batch must contain valid document/format pairs.", nameof(documents));
        _certificateSha1 = certificateSha1;
        _requester = requester;
        _documents = documents.ToArray();
        _authorize = authorize;
    }

    public ConsentResult Request(ConsentRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);
        lock (_gate)
        {
            if (_ended) return ConsentResult.Cancelled;
            if (!string.Equals(request.Certificate.Sha1, _certificateSha1, StringComparison.OrdinalIgnoreCase))
            {
                End();
                throw new CardException(CardErrorKind.CardChanged, "The batch certificate changed.");
            }
            if (!string.Equals(request.Requester, _requester, StringComparison.Ordinal) ||
                _next >= _documents.Length || request.Documents.Count != 1 ||
                !string.Equals(request.Documents[0], System.IO.Path.GetFileName(_documents[_next].Path), StringComparison.Ordinal) ||
                !string.Equals(request.Format, _documents[_next].Format, StringComparison.Ordinal))
            {
                End();
                return ConsentResult.Cancelled;
            }
            try
            {
                if (_pin is null)
                {
                    // Show the whole immutable selection before the first VERIFY, including each chosen format.
                    var answer = _authorize!(request with
                    {
                        Documents = Array.AsReadOnly(_documents.Select(document => $"{document.Path} · {document.Format}").ToArray()),
                        Format = string.Join(" / ", _documents.Select(document => document.Format).Distinct(StringComparer.Ordinal)),
                    });
                    if (_ended || answer.IsCancelled) { End(); return ConsentResult.Cancelled; }
                    _pin = answer.Pin;
                }
                _next++;
                return ConsentResult.WithPin(_pin!);
            }
            catch
            {
                End();
                throw;
            }
        }
    }

    internal void SkipFailedDocument(string path)
    {
        lock (_gate)
        {
            // Failure can occur before or after Request consumed this document.
            if (!_ended && _next < _documents.Length && string.Equals(_documents[_next].Path, path, StringComparison.Ordinal)) _next++;
        }
    }

    public void Dispose()
    {
        lock (_gate) End();
    }

    private void End()
    {
        _ended = true;
        _pin = null;
        _authorize = null;
        _documents = [];
    }
}
