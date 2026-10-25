using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;

namespace MoldSign.Core;

/// <summary>Reader/card state shown by the StatusCard (docs/09 §3.4, docs/10 §3).</summary>
public abstract record ReaderState
{
    private ReaderState() { }

    /// <summary>No PC/SC reader. UI: "Conectează cititorul".</summary>
    public sealed record NoReader : ReaderState;

    /// <summary>Reader present, no card. UI: "Introdu cardul în cititor".</summary>
    public sealed record Empty(string Reader) : ReaderState;

    /// <summary>Card present; <see cref="Holder"/> is null until the PIN-less certificate read finishes.</summary>
    public sealed record CardPresent(string Reader, string? Holder, CertificateSummary? Certificate = null) : ReaderState;

    /// <summary>A card operation is running.</summary>
    public sealed record Busy(string Reader, SigningStep Step) : ReaderState;

    /// <summary>Last operation failed; one-line fix chosen from <see cref="Kind"/>.</summary>
    public sealed record Error(CardErrorKind Kind, string Message, string? Reader = null) : ReaderState;
}

/// <summary>Progress steps (StepProgress: Card → PIN → Semnătură → Marcă temporală → Salvare).</summary>
public enum SigningStep
{
    Connecting,
    Authenticating,
    ReadingCertificate,
    VerifyingPin,
    Signing,
    Timestamping,
    Revocation,
    Writing,
    Done,
}

/// <summary>Public certificate facts; no PIN needed to obtain them.</summary>
public sealed record CertificateSummary
{
    public required string CommonName { get; init; }
    public required string Subject { get; init; }
    public required string Issuer { get; init; }
    public required DateTimeOffset NotBefore { get; init; }
    public required DateTimeOffset NotAfter { get; init; }
    /// <summary>Serial number, upper-case hex.</summary>
    public required string SerialNumber { get; init; }
    /// <summary>SHA-1 of the DER, upper-case hex: the bridge <c>certificateId</c> and the PinVault key.</summary>
    public required string Sha1 { get; init; }
    public required byte[] Der { get; init; }

    public static CertificateSummary FromDer(byte[] der)
    {
        ArgumentNullException.ThrowIfNull(der);
        using var cert = X509CertificateLoader.LoadCertificate(der);
        return new CertificateSummary
        {
            CommonName = cert.GetNameInfo(X509NameType.SimpleName, forIssuer: false),
            Subject = cert.Subject,
            Issuer = cert.Issuer,
            NotBefore = new DateTimeOffset(cert.NotBefore.ToUniversalTime(), TimeSpan.Zero),
            NotAfter = new DateTimeOffset(cert.NotAfter.ToUniversalTime(), TimeSpan.Zero),
            SerialNumber = cert.SerialNumber,
            Sha1 = Hex.Encode(SHA1.HashData(der)),
            Der = der,
        };
    }
}

/// <summary>What the consent UI is asked to approve (ConsentSheet: what, for whom, which certificate).</summary>
public sealed record ConsentRequest
{
    /// <summary>"Tu" for local actions, or the bridge Origin host (e.g. msign.gov.md).</summary>
    public required string Requester { get; init; }
    public required IReadOnlyList<string> Documents { get; init; }
    /// <summary>PAdES-T, XAdES-T…</summary>
    public required string Format { get; init; }
    public required CertificateSummary Certificate { get; init; }
    /// <summary>Tries left reported by the previous wrong PIN, if any.</summary>
    public int? RemainingAttempts { get; init; }
}

/// <summary>Either a PIN or "cancelled". Never logged (SEC-04).</summary>
public sealed record ConsentResult
{
    private ConsentResult(string? pin) => Pin = pin;

    public string? Pin { get; }
    public bool IsCancelled => Pin is null;

    public static ConsentResult Cancelled { get; } = new((string?)null);
    public static ConsentResult WithPin(string pin) => new(pin ?? throw new ArgumentNullException(nameof(pin)));

    public override string ToString() => IsCancelled ? "ConsentResult(cancelled)" : "ConsentResult(pin: ***)";
}

/// <summary>
/// The single place where the platform shows UI (PIN sheet, Windows Hello for the stored PIN, or the
/// bridge consent window). Called on a worker thread; it may block until the user answers.
/// </summary>
public delegate ConsentResult ConsentProvider(ConsentRequest request);

/// <summary>Outcome of a signing operation.</summary>
public sealed record SignResult(IReadOnlyList<string> OutputFiles, CertificateSummary Certificate, string Format);
