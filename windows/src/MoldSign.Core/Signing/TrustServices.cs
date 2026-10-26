using System.Formats.Asn1;
using System.Net;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Security.Cryptography.Pkcs;

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

    public TrustServices(HttpClient? http = null) => Http = http ?? new HttpClient(
        new HttpClientHandler { UseProxy = false, AllowAutoRedirect = false })
        { Timeout = TimeSpan.FromSeconds(30), MaxResponseContentBufferSize = 16 * 1024 * 1024 };

    internal HttpClient Http { get; }

    /// <summary>RFC 3161 TimeStampToken (DER) over a SHA-256 <paramref name="digest"/>, <c>certReq TRUE</c>.</summary>
    public byte[] GetTimestampToken(byte[] digest)
    {
        ArgumentNullException.ThrowIfNull(digest);
        if (digest.Length != 32) throw new ArgumentException("Expected a SHA-256 digest", nameof(digest));
        var request = SigningAsn.Sequence(SigningAsn.Integer(1),
            SigningAsn.Sequence(SigningAsn.Algorithm(SigningAsn.Sha256Oid), SigningAsn.Octet(digest)),
            SigningAsn.Encode(w => w.WriteBoolean(true)));
        try
        {
            var response = Send(HttpMethod.Post, TsaUri, request, "application/timestamp-query");
            var token = ParseTimestampResponse(response);
            if (!TimestampMatches(token, digest, out _))
                throw new AsnContentException("Timestamp message imprint does not match the request");
            return token;
        }
        catch (Exception e) when (e is AsnContentException or CryptographicException or InvalidOperationException or ArgumentException or IndexOutOfRangeException)
        {
            throw new CardException(CardErrorKind.Network, "Invalid MDQTSA response", innerException: e);
        }
    }

    /// <summary>DER CRL from <paramref name="uri"/>.</summary>
    public byte[] FetchCrl(Uri uri)
    {
        var response = Send(HttpMethod.Get, uri, null, null);
        try { _ = RevocationData.CrlInfo(response); }
        catch (Exception e) when (e is AsnContentException or ArgumentException or InvalidOperationException)
        {
            throw new CardException(CardErrorKind.Network, "Invalid CRL response", innerException: e);
        }
        return response;
    }

    /// <summary>DER OCSPResponse for <paramref name="certificateDer"/> issued by <paramref name="issuerDer"/>.</summary>
    public byte[] FetchOcsp(byte[] certificateDer, byte[] issuerDer)
    {
        var response = Send(HttpMethod.Post, MdqSignOcspUri,
            RevocationData.OcspRequest(certificateDer, issuerDer), "application/ocsp-request");
        try { _ = RevocationData.OcspInfo(response); }
        catch (Exception e) when (e is AsnContentException or ArgumentException or InvalidOperationException)
        {
            throw new CardException(CardErrorKind.Network, "Invalid OCSP response", innerException: e);
        }
        return response;
    }

    internal static byte[] ParseTimestampResponse(byte[] response)
    {
        var values = SigningAsn.Read(response).Children();
        if (values.Count != 2) throw new AsnContentException("Missing timestamp token");
        var status = values[0].Children()[0].Number();
        if (status != 0 && status != 1) throw new AsnContentException($"Timestamp service status {status}");
        var token = values[1].Encoded;
        var cms = new SignedCms();
        cms.Decode(token);
        if (cms.ContentInfo.ContentType.Value != "1.2.840.113549.1.9.16.1.4" || cms.SignerInfos.Count != 1)
            throw new AsnContentException("Not a TSTInfo token");
        return token;
    }

    // Checks only the RFC3161 imprint; this does NOT authenticate the TSA signature or revocation status.
    internal static bool TimestampMatches(byte[] token, byte[] sha256, out string? time)
    {
        var info = TimestampInfo(token);
        time = info.Time;
        return info.Algorithm == SigningAsn.Sha256Oid && CryptographicOperations.FixedTimeEquals(info.Digest, sha256);
    }

    internal static bool TimestampMatchesData(byte[] token, byte[] data, out string? time)
    {
        var info = TimestampInfo(token);
        time = info.Time;
        var hash = info.Algorithm switch
        {
            SigningAsn.Sha1Oid => SHA1.HashData(data),
            SigningAsn.Sha256Oid => SHA256.HashData(data),
            "2.16.840.1.101.3.4.2.2" => SHA384.HashData(data),
            "2.16.840.1.101.3.4.2.3" => SHA512.HashData(data),
            _ => throw new AsnContentException("Unsupported timestamp imprint algorithm"),
        };
        return CryptographicOperations.FixedTimeEquals(info.Digest, hash);
    }

    private static (string Algorithm, byte[] Digest, string Time) TimestampInfo(byte[] token)
    {
        var cms = new SignedCms();
        cms.Decode(token);
        if (cms.ContentInfo.ContentType.Value != "1.2.840.113549.1.9.16.1.4" || cms.SignerInfos.Count != 1)
            throw new AsnContentException("Not a timestamp token with one signer");
        var info = SigningAsn.Read(cms.ContentInfo.Content).Children();
        if (info.Count < 5 || info[0].Number() != 1) throw new AsnContentException("Invalid TSTInfo");
        var imprint = info[2].Children();
        if (imprint.Count != 2 || imprint[1].Tag != 4) throw new AsnContentException("Invalid message imprint");
        return (imprint[0].Children()[0].ObjectIdentifier(), imprint[1].Value,
            info[4].Time().ToString("O", System.Globalization.CultureInfo.InvariantCulture));
    }

    private byte[] Send(HttpMethod method, Uri uri, byte[]? body, string? contentType)
    {
        if (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps)
            throw new ArgumentException("PKI endpoint must use HTTP(S)", nameof(uri));
        for (var attempt = 0; ; attempt++)
        {
            try
            {
                using var request = new HttpRequestMessage(method, uri);
                request.Headers.Accept.ParseAdd("*/*");
                if (body is not null)
                {
                    request.Content = new ByteArrayContent(body);
                    request.Content.Headers.ContentType = new MediaTypeHeaderValue(contentType!);
                }
                using var response = Http.SendAsync(request).GetAwaiter().GetResult();
                if (response.StatusCode != HttpStatusCode.OK)
                    throw new HttpRequestException($"PKI HTTP {(int)response.StatusCode}", null, response.StatusCode);
                var bytes = response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult();
                if (bytes.Length == 0 || bytes.Length > 16 * 1024 * 1024)
                    throw new CardException(CardErrorKind.Network, "Empty or oversized PKI response");
                return bytes;
            }
            catch (Exception e) when (e is HttpRequestException or OperationCanceledException or IOException)
            {
                var transient = e is not HttpRequestException h || h.StatusCode is null
                    or HttpStatusCode.BadGateway or HttpStatusCode.ServiceUnavailable or HttpStatusCode.GatewayTimeout;
                if (attempt != 0 || !transient)
                    throw new CardException(CardErrorKind.Network, $"PKI request failed: {uri.Host}", innerException: e);
                Thread.Sleep(200);
            }
        }
    }
}
