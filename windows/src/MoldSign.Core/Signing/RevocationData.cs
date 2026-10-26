using System.Formats.Asn1;
using System.Security.Cryptography;
using System.Text;

namespace MoldSign.Core;

internal static class RevocationData
{
    internal sealed record CrlMetadata(string Issuer, string IssueTime, string Number);
    internal sealed record OcspMetadata(string Responder, string ProducedAt);

    internal static byte[] OcspRequest(byte[] certificateDer, byte[] issuerDer)
    {
        using var issuer = SigningAsn.Certificate(issuerDer);
        var id = SigningAsn.Sequence(SigningAsn.Algorithm(SigningAsn.Sha1Oid),
            SigningAsn.Octet(SHA1.HashData(issuer.SubjectName.RawData)),
            SigningAsn.Octet(SHA1.HashData(issuer.GetPublicKey())),
            SigningAsn.IssuerSerial(certificateDer).Serial);
        return SigningAsn.Sequence(SigningAsn.Sequence(SigningAsn.Sequence(SigningAsn.Sequence(id))));
    }

    internal static CrlMetadata CrlInfo(byte[] der)
    {
        var outer = SigningAsn.Read(der).Children();
        if (outer.Count != 3 || outer[2].Tag != 3) throw new AsnContentException("Not a CertificateList");
        var fields = outer[0].Children();
        var i = fields[0].Tag == 2 ? 1 : 0;
        i++; // signature AlgorithmIdentifier
        var issuer = SigningAsn.DistinguishedName(fields[i++].Encoded, true);
        var time = VendorTime(fields[i].Time());
        var number = "0";
        var extensions = fields.FirstOrDefault(n => n.Tag == 0xa0);
        if (extensions is not null)
            foreach (var extension in extensions.Children()[0].Children())
            {
                var values = extension.Children();
                if (values[0].ObjectIdentifier() == "2.5.29.20")
                    number = SigningAsn.Read(values[^1].Value).Number().ToString(System.Globalization.CultureInfo.InvariantCulture);
            }
        return new CrlMetadata(issuer, time, number);
    }

    internal static OcspMetadata OcspInfo(byte[] response)
    {
        var fields = SigningAsn.Read(response).Children();
        if (fields.Count != 2 || fields[0].Tag != 10 ||
            fields[0].Value.Length != 1 || fields[0].Value[0] != 0 || fields[1].Tag != 0xa0)
            throw new AsnContentException("OCSP response not successful");
        var responseBytes = fields[1].Children()[0].Children();
        if (responseBytes[0].ObjectIdentifier() != "1.3.6.1.5.5.7.48.1.1")
            throw new AsnContentException("OCSP response is not BasicOCSPResponse");
        var basic = SigningAsn.Read(responseBytes[1].Value).Children();
        if (basic.Count < 3) throw new AsnContentException("Incomplete OCSP response");
        var data = basic[0].Children();
        var i = data[0].Tag == 0xa0 ? 1 : 0;
        var responder = data[i++];
        // The MD responder uses ByName. ByKey cannot faithfully be expressed as the vendor's ByName.
        if (responder.Tag != 0xa1) throw new AsnContentException("OCSP ByName responder required");
        return new OcspMetadata(SigningAsn.DistinguishedName(responder.Children()[0].Encoded, true),
            VendorTime(data[i].Time()));
    }

    internal static Uri? CrlUri(byte[] certificate)
    {
        using var cert = SigningAsn.Certificate(certificate);
        var extension = cert.Extensions.FirstOrDefault(e => e.Oid?.Value == "2.5.29.31");
        if (extension is null) return null;
        return FindUri(SigningAsn.Read(extension.RawData));
    }

    private static Uri? FindUri(SigningAsn.Node node)
    {
        if (node.Tag == 0x86)
        {
            var text = Encoding.ASCII.GetString(node.Value);
            return Uri.TryCreate(text, UriKind.Absolute, out var uri) &&
                uri.Scheme is "http" or "https" ? uri : null;
        }
        if ((node.Tag & 0x20) == 0) return null;
        foreach (var child in node.Children())
            if (FindUri(child) is { } uri) return uri;
        return null;
    }

    private static string VendorTime(DateTimeOffset time) =>
        time.ToLocalTime().ToString("yyyy-MM-dd'T'HH:mm:sszzz", System.Globalization.CultureInfo.InvariantCulture);
}
