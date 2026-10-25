using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;

namespace MoldSign.Core;

/// <summary>Reader/card state of the last card operation (docs/09 §3.4); the app derives its UI from CardWallet.</summary>
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

    /// <summary>Issuer common name ("MDQSign CA"), for the card face's Emitent/Issuer field.</summary>
    public string IssuerName { get; init; } = "";

    /// <summary>Subject surname (SN, 2.5.4.4), decoded DirectoryString ("Mîndru"); null when absent.</summary>
    public string? Surname { get; init; }

    /// <summary>Subject given name(s) (GN, 2.5.4.42); null when absent.</summary>
    public string? GivenName { get; init; }

    /// <summary>
    /// The two name fields of the card face (docs/10 §0.2b): SN and GN from the certificate; without them the
    /// common name is split at the first space, read as "{surname} {given names…}" (the Moldovan certificate order,
    /// "POPESCU ION"; same rule on every platform).
    /// </summary>
    public (string Surname, string GivenNames) NameParts()
    {
        if (!string.IsNullOrWhiteSpace(Surname) || !string.IsNullOrWhiteSpace(GivenName))
            return (Surname?.Trim() ?? "", GivenName?.Trim() ?? "");
        var holder = CommonName.Trim();
        var space = holder.IndexOf(' ');
        return space < 0 ? (holder, "") : (holder[..space], holder[(space + 1)..].Trim());
    }

    public static CertificateSummary FromDer(byte[] der)
    {
        ArgumentNullException.ThrowIfNull(der);
        using var cert = X509CertificateLoader.LoadCertificate(der);
        return new CertificateSummary
        {
            CommonName = cert.GetNameInfo(X509NameType.SimpleName, forIssuer: false),
            IssuerName = cert.GetNameInfo(X509NameType.SimpleName, forIssuer: true),
            Surname = SubjectAttribute(cert.SubjectName, "2.5.4.4"),
            GivenName = SubjectAttribute(cert.SubjectName, "2.5.4.42"),
            Subject = cert.Subject,
            Issuer = cert.Issuer,
            NotBefore = new DateTimeOffset(cert.NotBefore.ToUniversalTime(), TimeSpan.Zero),
            NotAfter = new DateTimeOffset(cert.NotAfter.ToUniversalTime(), TimeSpan.Zero),
            SerialNumber = cert.SerialNumber,
            Sha1 = Hex.Encode(SHA1.HashData(der)),
            Der = der,
        };
    }

    private static string? SubjectAttribute(X500DistinguishedName name, string oid)
    {
        foreach (var rdn in name.EnumerateRelativeDistinguishedNames())
        {
            if (!rdn.HasMultipleElements && rdn.GetSingleElementType().Value == oid) return rdn.GetSingleElementValue();
        }
        return null;
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

/// <summary>
/// The signature a document gets (docs/10 §3 FormatChip). PDFs default to PAdES-T but can be signed with XAdES instead
/// (detached over the PDF bytes, written as <c>&lt;name&gt;-semnat.xml</c>); every other file is XAdES.
/// </summary>
public enum SignatureFormat
{
    PadesT,
    XadesBes,
    XadesT,
    XadesC,
}

/// <summary>Per-document format rules shared by the UI (format picker) and <see cref="SigningService.Sign"/>.</summary>
public static class SignatureFormats
{
    private static readonly SignatureFormat[] s_pdf =
        [SignatureFormat.PadesT, SignatureFormat.XadesBes, SignatureFormat.XadesT, SignatureFormat.XadesC];
    private static readonly SignatureFormat[] s_other = [SignatureFormat.XadesBes, SignatureFormat.XadesT, SignatureFormat.XadesC];

    public static bool IsPdf(string path) =>
        string.Equals(Path.GetExtension(path), ".pdf", StringComparison.OrdinalIgnoreCase);

    /// <summary>PDF: PAdES-T, XAdES-BES, XAdES-T, XAdES-C. Anything else: the three XAdES levels.</summary>
    public static IReadOnlyList<SignatureFormat> Allowed(string path) => IsPdf(path) ? s_pdf : s_other;

    /// <summary>PDF → PAdES-T (what msign.gov.md expects), everything else → XAdES-T.</summary>
    public static SignatureFormat Default(string path) => IsPdf(path) ? SignatureFormat.PadesT : SignatureFormat.XadesT;

    public static string Label(SignatureFormat format) => format switch
    {
        SignatureFormat.PadesT => "PAdES-T",
        SignatureFormat.XadesBes => "XAdES-BES",
        SignatureFormat.XadesT => "XAdES-T",
        _ => "XAdES-C",
    };

    /// <summary>The XAdES level, or null for PAdES-T.</summary>
    public static XadesFormat? ToXades(SignatureFormat format) => format switch
    {
        SignatureFormat.XadesBes => XadesFormat.Bes,
        SignatureFormat.XadesT => XadesFormat.T,
        SignatureFormat.XadesC => XadesFormat.C,
        _ => null,
    };

    /// <summary>D-06 next to the input, never overwriting: PAdES → <c>&lt;name&gt;-semnat.pdf</c>, XAdES → <c>&lt;name&gt;-semnat.xml</c>.</summary>
    public static string OutputPath(string input, SignatureFormat format) =>
        SigningService.DefaultOutputPath(input, format == SignatureFormat.PadesT ? null : ".xml");
}

/// <summary>A card and the reader it sits in (several eID cards can be connected at once, docs/09 §3.1b).</summary>
public sealed record CardEntry(string Reader, CertificateSummary Certificate);

/// <summary>Outcome of a signing operation.</summary>
public sealed record SignResult(IReadOnlyList<string> OutputFiles, CertificateSummary Certificate, string Format);
