using System.Text.Json.Serialization;

namespace MoldSign.Core;

/// <summary>Wire constants of the MoldSign Server protocol replica (docs/04-server-replica.md, docs/09 §3.6).</summary>
public static class BridgeProtocol
{
    /// <summary>Plain HTTP listener (vendor default), loopback only.</summary>
    public const int HttpPort = 18480;

    /// <summary>TLS listener; the portal's <c>moldSignDesktopServerUrlPrefix</c> is <c>https://localhost.cts.md:18443</c>.</summary>
    public const int HttpsPort = 18443;

    public const string AllowMethods = "GET, POST, OPTIONS";

    /// <summary>Allowed and exposed headers, verbatim from the vendor CORSFilter.</summary>
    public const string AllowHeaders = "Origin, x-requested-with, content-type, accept, error, Location";

    public const string MaxAgeSeconds = "3600";

    /// <summary>Request body cap (SEC-03).</summary>
    public const long MaxRequestBodyBytes = 64L * 1024 * 1024;
}

/// <summary><c>CertificateModel</c> from <c>re/decompiled/TransferObjects-2.0</c> (JSON field names are load-bearing).</summary>
public sealed record CertificateModel
{
    [JsonPropertyName("certificateId")] public string CertificateId { get; init; } = "";
    [JsonPropertyName("label")] public string Label { get; init; } = "";
    [JsonPropertyName("providerId")] public string ProviderId { get; init; } = "";
    [JsonPropertyName("policy")] public string? Policy { get; init; }
    [JsonPropertyName("certificateName")] public string CertificateName { get; init; } = "";
    [JsonPropertyName("subjectDN")] public string SubjectDN { get; init; } = "";
    [JsonPropertyName("issuerDN")] public string IssuerDN { get; init; } = "";
    [JsonPropertyName("authority")] public string? Authority { get; init; }
    [JsonPropertyName("trusted")] public bool Trusted { get; init; }
    [JsonPropertyName("verified")] public int Verified { get; init; }
    [JsonPropertyName("privateKeyPresent")] public bool PrivateKeyPresent { get; init; }
    [JsonPropertyName("certificateBase64")] public string CertificateBase64 { get; init; } = "";
}

/// <summary><c>GET /certificates</c> response: <c>{"certificateModel":[…]}</c>.</summary>
public sealed record CertificateListResponse(
    [property: JsonPropertyName("certificateModel")] IReadOnlyList<CertificateModel> CertificateModel);
