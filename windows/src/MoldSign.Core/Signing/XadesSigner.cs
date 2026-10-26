using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Xml;

namespace MoldSign.Core;

/// <summary>XAdES level (docs/03-xades-signing.md).</summary>
public enum XadesFormat
{
    /// <summary>XAdES-BES.</summary>
    Bes,
    /// <summary>XAdES-T: + SignatureTimeStamp over the c14n SignatureValue.</summary>
    T,
    /// <summary>XAdES-C: + CompleteCertificateRefs / CompleteRevocationRefs (CRL + OCSP).</summary>
    C,
}

/// <summary>Where the signed data lives relative to the signature.</summary>
public enum XadesPackaging
{
    /// <summary><c>URI="file:/&lt;basename&gt;"</c> references (vendor quirk: ObjectReference uses the full path).</summary>
    Detached,
    /// <summary>Base64 data in <c>ds:Object</c>, C14N WithComments.</summary>
    Enveloping,
}

/// <summary>
/// Middleware-faithful XAdES builder. Port target: <c>apple/Sources/MoldSignKit/XAdES.swift</c>.
/// </summary>
public sealed class XadesSigner
{
    public XadesSigner(TrustServices trust) => Trust = trust ?? throw new ArgumentNullException(nameof(trust));

    /// <summary>TSA (-T) and CRL/OCSP (-C) client.</summary>
    public TrustServices Trust { get; }
    internal Action<SigningStep>? Progress { get; init; }

    /// <summary>
    /// XAdES document for <paramref name="files"/>. Mirrors Swift
    /// <c>XAdESSigner.sign(files:format:type:certDER:chainDER:signBlock:tsaBlock:ocspDerBlock:)</c>.
    /// </summary>
    public byte[] Sign(IReadOnlyList<string> files, XadesFormat format, XadesPackaging packaging,
                       byte[] certificateDer, IReadOnlyList<byte[]> chainDer, Func<byte[], byte[]> signDigestInfo,
                       string? digestAlgorithm = null)
    {
        ArgumentNullException.ThrowIfNull(files);
        ArgumentNullException.ThrowIfNull(chainDer);
        ArgumentNullException.ThrowIfNull(signDigestInfo);
        if (files.Count == 0) throw new ArgumentException("Nothing to sign", nameof(files));
        if (!Enum.IsDefined(format) || !Enum.IsDefined(packaging)) throw new ArgumentOutOfRangeException(nameof(format));
        if (files.Select(Path.GetFileName).Distinct(StringComparer.Ordinal).Count() != files.Count)
            throw new ArgumentException("Detached names must be unique", nameof(files));
        var sha1 = string.Equals(digestAlgorithm?.Replace("-", "", StringComparison.Ordinal), "SHA1", StringComparison.OrdinalIgnoreCase);
        if (digestAlgorithm is not null && !sha1 &&
            !string.Equals(digestAlgorithm.Replace("-", "", StringComparison.Ordinal), "SHA256", StringComparison.OrdinalIgnoreCase))
            throw new ArgumentException("Only SHA-1 and SHA-256 are supported", nameof(digestAlgorithm));
        var digest = sha1 ? XadesXml.Sha1 : XadesXml.Sha256;
        var u = Guid.NewGuid().ToString().ToUpperInvariant();
        var document = new XmlDocument { PreserveWhitespace = true, XmlResolver = null };
        var signature = document.CreateElement("ds", "Signature", XadesXml.Ds);
        document.AppendChild(signature);
        signature.SetAttribute("xmlns:ds", XadesXml.Ds);
        signature.SetAttribute("Id", $"Signature-{u}");
        var signedInfo = XadesXml.Add(signature, "ds", "SignedInfo");
        signedInfo.SetAttribute("Id", $"SignedInfo-{u}");
        XadesXml.Add(signedInfo, "ds", "CanonicalizationMethod").SetAttribute("Algorithm",
            XadesXml.C14n + (packaging == XadesPackaging.Enveloping ? "#WithComments" : ""));
        XadesXml.Add(signedInfo, "ds", "SignatureMethod").SetAttribute("Algorithm", sha1 ? XadesXml.RsaSha1 : XadesXml.RsaSha256);
        var signatureValue = XadesXml.Add(signature, "ds", "SignatureValue");
        signatureValue.SetAttribute("Id", $"SignatureValue-{u}");
        var key = XadesXml.Add(signature, "ds", "KeyInfo");
        key.SetAttribute("Id", $"KeyInfo-{u}");
        XadesXml.Add(XadesXml.Add(key, "ds", "X509Data"), "ds", "X509Certificate", Convert.ToBase64String(certificateDer));
        var qualifying = XadesXml.Add(XadesXml.Add(signature, "ds", "Object"), "xades", "QualifyingProperties");
        qualifying.SetAttribute("xmlns:xades", XadesXml.Xades);
        qualifying.SetAttribute("Target", $"#Signature-{u}");
        var props = XadesXml.Add(qualifying, "xades", "SignedProperties");
        props.SetAttribute("Id", $"SignedProperties-{u}");
        var signedSignature = XadesXml.Add(props, "xades", "SignedSignatureProperties");
        XadesXml.Add(signedSignature, "xades", "SigningTime",
            DateTimeOffset.Now.ToString("yyyy-MM-dd'T'HH:mm:sszzz", System.Globalization.CultureInfo.InvariantCulture));
        var signingCert = XadesXml.Add(XadesXml.Add(signedSignature, "xades", "SigningCertificate"), "xades", "Cert");
        CertificateReference(signingCert, certificateDer, digest, false);
        var objectProperties = XadesXml.Add(props, "xades", "SignedDataObjectProperties");
        objectProperties.SetAttribute("Id", $"SignedDataObjectProperties-{u}");
        var dataReferences = new List<(string Id, string Uri, byte[] Digest)>();
        for (var index = 0; index < files.Count; index++)
        {
            var path = files[index];
            var basename = Path.GetFileName(path);
            var id = $"SignedFile-Reference-{u}-{basename}";
            var bytes = File.ReadAllBytes(path);
            string uri;
            byte[] dataDigest;
            if (packaging == XadesPackaging.Enveloping)
            {
                var objectId = $"FileObject-{u}" + (index == 0 ? "" : $"-{index}");
                var obj = XadesXml.Add(signature, "ds", "Object", Convert.ToBase64String(bytes));
                obj.SetAttribute("Encoding", "UTF-8");
                obj.SetAttribute("Id", objectId);
                uri = "#" + objectId;
                dataDigest = XadesXml.Hash(XadesXml.Canonical(obj), digest);
            }
            else
            {
                uri = "file:/" + basename;
                dataDigest = XadesXml.Hash(bytes, digest);
            }
            dataReferences.Add((id, uri, dataDigest));
            var objectFormat = XadesXml.Add(objectProperties, "xades", "DataObjectFormat");
            // The middleware uses a basename in Reference/@Id, but the full path here.
            objectFormat.SetAttribute("ObjectReference", $"SignedFile-Reference-{u}-{Path.GetFullPath(path)}");
            XadesXml.Add(objectFormat, "xades", "Description", path);
            XadesXml.Add(objectFormat, "xades", "MimeType", Path.GetExtension(path).Equals(".txt", StringComparison.OrdinalIgnoreCase)
                ? "text/plain" : "application/octet-stream");
        }
        Reference(signedInfo, $"SignedProperties-Reference-{u}", $"#SignedProperties-{u}",
            XadesXml.Hash(XadesXml.Canonical(props), digest), digest, "http://uri.etsi.org/01903#SignedProperties");
        foreach (var reference in dataReferences) Reference(signedInfo, reference.Id, reference.Uri, reference.Digest, digest);
        var canonical = XadesXml.Canonical(signedInfo, packaging == XadesPackaging.Enveloping);
        var hash = XadesXml.Hash(canonical, digest);
        var info = sha1 ? SigningAsn.Sequence(SigningAsn.Algorithm(SigningAsn.Sha1Oid), SigningAsn.Octet(hash)) : DigestInfo.ForSha256Hash(hash);
        var raw = signDigestInfo(info);
        using var certificate = SigningAsn.Certificate(certificateDer);
        using var rsa = certificate.GetRSAPublicKey();
        if (rsa is null || !rsa.VerifyHash(hash, raw, sha1 ? HashAlgorithmName.SHA1 : HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1))
            throw new CardException(CardErrorKind.Format, "The card signature does not match the signing certificate");
        signatureValue.InnerText = Convert.ToBase64String(raw);
        if (format != XadesFormat.Bes)
        {
            var unsigned = XadesXml.Add(XadesXml.Add(qualifying, "xades", "UnsignedProperties"), "xades", "UnsignedSignatureProperties");
            var timestamp = XadesXml.Add(unsigned, "xades", "SignatureTimeStamp");
            timestamp.SetAttribute("Id", $"SignatureTimeStamp-{u}");
            XadesXml.Add(timestamp, "ds", "CanonicalizationMethod").SetAttribute("Algorithm", XadesXml.C14n);
            Progress?.Invoke(SigningStep.Timestamping);
            var token = Trust.GetTimestampToken(SHA256.HashData(XadesXml.Canonical(signatureValue)));
            XadesXml.Add(timestamp, "xades", "EncapsulatedTimeStamp", Convert.ToBase64String(token))
                .SetAttribute("Encoding", "http://uri.etsi.org/01903/v1.2.2#DER");
            if (format == XadesFormat.C)
            {
                Progress?.Invoke(SigningStep.Revocation);
                CompleteReferences(unsigned, u, certificateDer, chainDer);
            }
        }
        using var stream = new MemoryStream();
        using (var writer = XmlWriter.Create(stream, new XmlWriterSettings { Encoding = new UTF8Encoding(false), Indent = false }))
            document.Save(writer);
        return stream.ToArray();
    }

    private static void Reference(XmlElement parent, string id, string uri, byte[] hash, string digest, string? type = null)
    {
        var reference = XadesXml.Add(parent, "ds", "Reference");
        reference.SetAttribute("Id", id);
        reference.SetAttribute("URI", uri);
        if (type is not null) reference.SetAttribute("Type", type);
        DigestValue(reference, hash, digest);
    }

    private static void DigestValue(XmlElement parent, byte[] hash, string digest)
    {
        XadesXml.Add(parent, "ds", "DigestMethod").SetAttribute("Algorithm", digest);
        XadesXml.Add(parent, "ds", "DigestValue", Convert.ToBase64String(hash));
    }

    private static void CertificateReference(XmlElement parent, byte[] der, string digest, bool namedOrganization)
    {
        DigestValue(XadesXml.Add(parent, "xades", "CertDigest"), XadesXml.Hash(der, digest), digest);
        var serial = XadesXml.Add(parent, "xades", "IssuerSerial");
        XadesXml.Add(serial, "ds", "X509IssuerName",
            SigningAsn.DistinguishedName(SigningAsn.IssuerSerial(der).Issuer, namedOrganization));
        XadesXml.Add(serial, "ds", "X509SerialNumber", SigningAsn.Serial(der));
    }

    private void CompleteReferences(XmlElement unsigned, string u, byte[] leaf, IReadOnlyList<byte[]> chain)
    {
        var certs = new List<byte[]> { leaf };
        foreach (var der in chain)
        {
            using var cert = SigningAsn.Certificate(der);
            if (!cert.SubjectName.RawData.AsSpan().SequenceEqual(cert.IssuerName.RawData)) certs.Add(der);
        }
        var certificateRefs = XadesXml.Add(unsigned, "xades", "CompleteCertificateRefs");
        certificateRefs.SetAttribute("Id", $"CompleteCertificateRefs-{u}");
        var certRefs = XadesXml.Add(certificateRefs, "xades", "CertRefs");
        var revocationRefs = XadesXml.Add(unsigned, "xades", "CompleteRevocationRefs");
        revocationRefs.SetAttribute("Id", $"CompleteRevocationRefs-{u}");
        var crlRefs = XadesXml.Add(revocationRefs, "xades", "CRLRefs");
        var ocspRefs = XadesXml.Add(revocationRefs, "xades", "OCSPRefs");
        var issuerDer = chain.FirstOrDefault(der =>
        {
            using var cert = SigningAsn.Certificate(der);
            using var signer = SigningAsn.Certificate(leaf);
            return cert.SubjectName.RawData.AsSpan().SequenceEqual(signer.IssuerName.RawData);
        });
        if (issuerDer is null) throw new CardException(CardErrorKind.Format, "XAdES-C requires the signing certificate issuer");
        var ocsp = Trust.FetchOcsp(leaf, issuerDer);
        var ocspInfo = RevocationData.OcspInfo(ocsp);
        foreach (var der in certs)
        {
            CertificateReference(XadesXml.Add(certRefs, "xades", "Cert"), der, XadesXml.Sha256, true);
            if (RevocationData.CrlUri(der) is { } uri)
            {
                var crl = Trust.FetchCrl(uri);
                var metadata = RevocationData.CrlInfo(crl);
                var crlRef = XadesXml.Add(crlRefs, "xades", "CRLRef");
                DigestValue(XadesXml.Add(crlRef, "xades", "DigestAlgAndValue"), SHA256.HashData(crl), XadesXml.Sha256);
                var identifier = XadesXml.Add(crlRef, "xades", "CRLIdentifier");
                identifier.SetAttribute("URI", uri.AbsoluteUri);
                XadesXml.Add(identifier, "xades", "Issuer", metadata.Issuer);
                XadesXml.Add(identifier, "xades", "IssueTime", metadata.IssueTime);
                XadesXml.Add(identifier, "xades", "Number", metadata.Number);
            }
            // Vendor quirk: repeat the same signer OCSP response for every non-root certificate.
            var ocspRef = XadesXml.Add(ocspRefs, "xades", "OCSPRef");
            var ocspIdentifier = XadesXml.Add(ocspRef, "xades", "OCSPIdentifier");
            ocspIdentifier.SetAttribute("URI", TrustServices.MdqSignOcspUri.AbsoluteUri.TrimEnd('/'));
            XadesXml.Add(XadesXml.Add(ocspIdentifier, "xades", "ResponderID"), "xades", "ByName", ocspInfo.Responder);
            XadesXml.Add(ocspIdentifier, "xades", "ProducedAt", ocspInfo.ProducedAt);
            DigestValue(XadesXml.Add(ocspRef, "xades", "DigestAlgAndValue"), SHA256.HashData(ocsp), XadesXml.Sha256);
        }
    }
}
