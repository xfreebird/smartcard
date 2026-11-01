namespace MoldSign.Core;

/// <summary>Native Desktop Suite request; enabled explicitly by the installed desktop host only.</summary>
public sealed record BridgeFileSigningRequest(
    IReadOnlyList<string> Files, string Destination, string Format, XadesPackaging Packaging,
    string Algorithm, string? CertificateBase64, bool Pdf, bool XmlResponse = false);

/// <summary>Injectable file-signing boundary. The host obtains explicit consent before invoking it.</summary>
public interface IBridgeFileSigner
{
    string Sign(BridgeFileSigningRequest request, CardEntry card, ConsentProvider consent);
}

public sealed class BridgeFileSigner(SigningService signing) : IBridgeFileSigner
{
    public string Sign(BridgeFileSigningRequest request, CardEntry card, ConsentProvider consent)
    {
        if (request.Pdf)
            signing.SignPdf(request.Files.Single(), request.Destination, consent, "MoldSign Desktop Suite",
                card.Reader, card.Certificate.Sha1);
        else
        {
            var format = request.Format switch
            {
                "XAdES-BES" => XadesFormat.Bes,
                "XAdES-T" => XadesFormat.T,
                "XAdES-C" => XadesFormat.C,
                _ => throw new InvalidDataException("Unsupported signature format"),
            };
            signing.SignXades(request.Files, format, request.Packaging, request.Destination, consent,
                "MoldSign Desktop Suite", card.Reader, card.Certificate.Sha1, request.Algorithm);
        }
        return request.Destination;
    }
}
