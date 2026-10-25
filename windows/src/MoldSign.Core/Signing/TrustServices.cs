namespace MoldSign.Core;

/// <summary>
/// Network side of signing: RFC 3161 timestamps (MDQTSA), CRLs and OCSP against the public MD PKI
/// (docs/06-infrastructure.md). Core rule: all network goes through here (docs/09 §1).
/// Failures surface as <see cref="CardErrorKind.Network"/>.
/// </summary>
public sealed class TrustServices
{
    /// <summary>MDQTSA (HTTP only).</summary>
    public static readonly Uri TsaUri = new("http://tsp.pki.gov.md/moldsign2/");

    public static readonly Uri MdqSignCrlUri = new("http://pki.md/crl/mdqsign.crl");
    public static readonly Uri MdTrustCaCrlUri = new("http://pki.md/crl/mdtrustca.crl");
    public static readonly Uri MdqSignOcspUri = new("http://mdqsign.ocsp.pki.md");

    public TrustServices(HttpClient? http = null) => Http = http ?? new HttpClient { Timeout = TimeSpan.FromSeconds(30) };

    internal HttpClient Http { get; }

    /// <summary>RFC 3161 TimeStampToken (DER) over a SHA-256 <paramref name="digest"/>, <c>certReq TRUE</c>.</summary>
    public byte[] GetTimestampToken(byte[] digest) =>
        // TODO(WIN-01): port TimestampRequest.swift + PAdESSigner.fetchTimestampToken (Content-Type application/timestamp-query).
        throw new NotImplementedException("TODO(WIN-01): TSA client not ported yet.");

    /// <summary>DER CRL from <paramref name="uri"/>.</summary>
    public byte[] FetchCrl(Uri uri) =>
        // TODO(WIN-01): CRL fetch + parse (issuer, thisUpdate, number) for XAdES-C refs.
        throw new NotImplementedException("TODO(WIN-01): CRL fetch not ported yet.");

    /// <summary>DER OCSPResponse for <paramref name="certificateDer"/> issued by <paramref name="issuerDer"/>.</summary>
    public byte[] FetchOcsp(byte[] certificateDer, byte[] issuerDer) =>
        // TODO(WIN-01): native OCSPRequest builder (no openssl process), POST to MdqSignOcspUri.
        throw new NotImplementedException("TODO(WIN-01): OCSP client not ported yet.");
}
