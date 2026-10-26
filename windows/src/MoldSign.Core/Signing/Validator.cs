using System.Formats.Asn1;
using System.Globalization;
using System.Security.Cryptography;
using System.Security.Cryptography.Pkcs;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.RegularExpressions;
using System.Xml;

namespace MoldSign.Core;

/// <summary>Overall verdict shown by the VerdictBadge (docs/10 §3).</summary>
public enum Verdict
{
    Valid,
    Invalid,
    /// <summary>"Nu poate fi confirmată": integrity OK but chain/time could not be established.</summary>
    Indeterminate,
}

/// <summary>One signature's report; mirrors Swift <c>Validator.Report</c>.</summary>
public sealed record VerificationReport
{
    /// <summary>"PAdES" or "XAdES".</summary>
    public required string Kind { get; init; }
    /// <summary>Signature field name or Signature Id.</summary>
    public required string Name { get; init; }
    public required string Signer { get; init; }
    public bool ContentIntact { get; init; }
    public bool SignatureValid { get; init; }
    public bool ChainTrusted { get; init; }
    public string SigningTime { get; init; } = "";
    public string? TimestampTime { get; init; }
    /// <summary>"PAdES-B-T", "XAdES-C"…</summary>
    public string Level { get; init; } = "";
    /// <summary>Null when absent; only the RFC3161 message imprint is checked offline.</summary>
    public bool? TimestampImprintValid { get; init; }
    /// <summary>False: TSA signature/path validation is not implemented by this offline validator.</summary>
    public bool TimestampSignatureValidated { get; init; }
    /// <summary>False: embedded/referenced CRL and OCSP evidence is not authenticated offline.</summary>
    public bool RevocationValidated { get; init; }
    public string Notes { get; init; } = "";

    public Verdict Verdict => !(ContentIntact && SignatureValid) || TimestampImprintValid == false
        ? Verdict.Invalid
        : ChainTrusted ? Verdict.Valid : Verdict.Indeterminate;
}

/// <summary>Offline validator (docs/05-offline-validation.md). Port target: <c>Validation.swift</c>.</summary>
public sealed class Validator
{
    public static Verdict? OverallVerdict(IReadOnlyList<VerificationReport> reports)
    {
        if (reports.Count == 0) return null;
        if (reports.Any(report => report.Verdict == Verdict.Invalid)) return Verdict.Invalid;
        return reports.All(report => report.Verdict == Verdict.Valid) ? Verdict.Valid : Verdict.Indeterminate;
    }

    /// <summary>Every signature in a PDF (ByteRange, CMS, RSA, manual chain to mdtrustca).</summary>
    public IReadOnlyList<VerificationReport> ValidatePdf(byte[] pdf)
    {
        ArgumentNullException.ThrowIfNull(pdf);
        var text = Encoding.Latin1.GetString(pdf);
        if (!text.StartsWith("%PDF-", StringComparison.Ordinal)) return [Failed("PAdES", "", "Not a PDF")];
        var objects = Regex.Matches(text, @"(?<!\d)(\d+)\s+0\s+obj\b(?<body>.*?)endobj", RegexOptions.Singleline);
        var fields = new Dictionary<int, string>();
        foreach (Match obj in objects)
        {
            var body = obj.Groups["body"].Value;
            var name = Regex.Match(body, @"/T\s*\(([^)]*)\)");
            var value = Regex.Match(body, @"/V\s+(\d+)\s+0\s+R\b");
            if (name.Success && value.Success) fields[int.Parse(value.Groups[1].Value, CultureInfo.InvariantCulture)] = name.Groups[1].Value;
        }
        var signatures = objects.Cast<Match>().Where(obj => Regex.IsMatch(obj.Groups["body"].Value, @"/ByteRange\b")).ToList();
        var reports = new List<VerificationReport>();
        foreach (var obj in signatures)
        {
            var number = int.Parse(obj.Groups[1].Value, CultureInfo.InvariantCulture);
            var name = fields.GetValueOrDefault(number, $"Signature{reports.Count + 1}");
            try
            {
                var body = obj.Groups["body"];
                var range = Regex.Match(body.Value, @"/ByteRange\s*\[\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*\]");
                var contents = Regex.Match(body.Value, @"/Contents\s*<([0-9a-fA-F\s]+)>");
                if (!range.Success || !contents.Success) throw new FormatException("Invalid PDF signature dictionary");
                var values = Enumerable.Range(1, 4).Select(i => long.Parse(range.Groups[i].Value, CultureInfo.InvariantCulture)).ToArray();
                var a = values[1];
                var b = values[2];
                var end = checked(b + values[3]);
                var hexOpen = body.Index + contents.Index + contents.Value.IndexOf('<');
                var hexClose = body.Index + contents.Index + contents.Length;
                if (values[0] != 0 || a != hexOpen || b != hexClose || a <= 0 || b <= a || end > pdf.Length || end < b)
                    throw new FormatException("PDF ByteRange does not exactly exclude Contents");
                var content = new byte[checked((int)(a + values[3]))];
                pdf.AsSpan(0, (int)a).CopyTo(content);
                pdf.AsSpan((int)b, (int)values[3]).CopyTo(content.AsSpan((int)a));
                var padded = Convert.FromHexString(Regex.Replace(contents.Groups[1].Value, @"\s", ""));
                AsnDecoder.ReadEncodedValue(padded, AsnEncodingRules.BER, out _, out _, out var length);
                if (padded.AsSpan(length).ContainsAnyExcept((byte)0)) throw new FormatException("Nonzero CMS padding");
                var cms = new SignedCms(new ContentInfo(content), detached: true);
                var encoded = padded.AsSpan(0, length).ToArray();
                cms.Decode(encoded);
                var signedData = SigningAsn.Read(encoded).Children()[1].Children()[0].Children();
                var infos = signedData[^1].Children();
                if (cms.SignerInfos.Count == 0 || infos.Count != cms.SignerInfos.Count) throw new FormatException("Missing CMS signer");
                for (var i = 0; i < cms.SignerInfos.Count; i++)
                {
                    var signer = cms.SignerInfos[i];
                    var certificate = signer.Certificate ?? throw new FormatException("Missing CMS signer certificate");
                    var info = infos[i].Children();
                    if (info.Count < 6 || info[3].Tag != 0xa0) throw new FormatException("Missing CMS signed attributes");
                    var digestOid = info[2].Children()[0].ObjectIdentifier();
                    var hashName = HashName(digestOid);
                    var attrs = Attributes(info[3]);
                    var intact = attrs.TryGetValue("1.2.840.113549.1.9.4", out var messageDigest) &&
                        messageDigest.Tag == 4 && CryptographicOperations.FixedTimeEquals(messageDigest.Value, Hash(content, hashName));
                    intact &= attrs.TryGetValue("1.2.840.113549.1.9.3", out var type) &&
                        type.ObjectIdentifier() == SigningAsn.DataOid;
                    if (attrs.TryGetValue("1.2.840.113549.1.9.16.2.47", out var ess))
                    {
                        var essCert = ess.Children()[0].Children()[0].Children();
                        var essHashAlgorithm = essCert[0].Tag == 0x30
                            ? HashName(essCert[0].Children()[0].ObjectIdentifier()) : HashAlgorithmName.SHA256;
                        var essHash = essCert[essCert[0].Tag == 0x30 ? 1 : 0];
                        intact &= CryptographicOperations.FixedTimeEquals(essHash.Value, Hash(certificate.RawData, essHashAlgorithm));
                    }
                    using var rsa = certificate.GetRSAPublicKey();
                    var signatureAlgorithm = info[4].Children()[0].ObjectIdentifier();
                    var signatureAlgorithmMatches = signatureAlgorithm == "1.2.840.113549.1.1.1" ||
                        (signatureAlgorithm == "1.2.840.113549.1.1.11" && hashName == HashAlgorithmName.SHA256) ||
                        (signatureAlgorithm == "1.2.840.113549.1.1.12" && hashName == HashAlgorithmName.SHA384) ||
                        (signatureAlgorithm == "1.2.840.113549.1.1.13" && hashName == HashAlgorithmName.SHA512) ||
                        (signatureAlgorithm == "1.2.840.113549.1.1.5" && hashName == HashAlgorithmName.SHA1);
                    var valid = rsa is not null &&
                        signatureAlgorithmMatches &&
                        rsa.VerifyData(SigningAsn.Retag(info[3].Encoded, 0x31), info[5].Value, hashName, RSASignaturePadding.Pkcs1);
                    string? timestampTime = null;
                    bool? timestampValid = null;
                    if (info.Count > 6 && info[6].Tag == 0xa1)
                    {
                        var unsigned = Attributes(info[6]);
                        if (unsigned.TryGetValue(SigningAsn.TimestampOid, out var token))
                            timestampValid = CheckTimestamp(token.Encoded, info[5].Value, out timestampTime);
                    }
                    // Earlier signed revisions may be followed by another signature. The newest must cover the file.
                    if (obj == signatures[^1] && text[(int)end..].Any(c => !char.IsWhiteSpace(c))) intact = false;
                    reports.Add(new VerificationReport
                    {
                        Kind = "PAdES", Name = name, Signer = certificate.GetNameInfo(X509NameType.SimpleName, false),
                        ContentIntact = intact, SignatureValid = valid, ChainTrusted = Trusted(certificate, cms.Certificates),
                        SigningTime = attrs.TryGetValue("1.2.840.113549.1.9.5", out var signingTime) ? signingTime.Time().ToString("O", CultureInfo.InvariantCulture) : "",
                        TimestampTime = timestampTime, TimestampImprintValid = timestampValid,
                        Level = timestampValid.HasValue ? "PAdES-B-T" : "PAdES-B-B", Notes = OfflineLimits,
                    });
                }
            }
            catch (Exception e) when (IsFormatFailure(e))
            {
                reports.Add(Failed("PAdES", name, e.Message));
            }
        }
        return reports;
    }

    /// <summary>XAdES signature with its referenced files (basename → bytes) for detached references.</summary>
    public IReadOnlyList<VerificationReport> ValidateXades(byte[] xml, IReadOnlyDictionary<string, byte[]> referencedFiles)
    {
        ArgumentNullException.ThrowIfNull(referencedFiles);
        XmlDocument document;
        try { document = XadesXml.Parse(xml); }
        catch (Exception e) when (IsFormatFailure(e)) { return [Failed("XAdES", "", e.Message)]; }
        var reports = new List<VerificationReport>();
        var signatures = document.GetElementsByTagName("Signature", XadesXml.Ds).OfType<XmlElement>().ToArray();
        // Never resolve arbitrary URLs or ambiguous IDs. Only caller-supplied bytes may satisfy detached references.
        var ids = new Dictionary<string, XmlElement>(StringComparer.Ordinal);
        var duplicateId = false;
        foreach (var element in document.GetElementsByTagName("*").OfType<XmlElement>())
            foreach (var attribute in element.Attributes.OfType<XmlAttribute>().Where(a =>
                a.LocalName is "Id" or "ID" or "id"))
                if (!ids.TryAdd(attribute.Value, element)) duplicateId = true;
        foreach (var signature in signatures)
        {
            var name = signature.GetAttribute("Id");
            try
            {
                if (duplicateId) throw new FormatException("Duplicate XML ID");
                var info = XadesXml.Child(signature, "SignedInfo");
                var value = XadesXml.Child(signature, "SignatureValue");
                var certificateElement = XadesXml.Child(XadesXml.Child(XadesXml.Child(signature, "KeyInfo"), "X509Data"), "X509Certificate");
                using var cert = SigningAsn.Certificate(Convert.FromBase64String(certificateElement.InnerText));
                var canonicalization = XadesXml.Child(info, "CanonicalizationMethod").GetAttribute("Algorithm");
                if (canonicalization != XadesXml.C14n && canonicalization != XadesXml.C14n + "#WithComments")
                    throw new FormatException("Unsupported SignedInfo canonicalization");
                var signatureAlgorithm = XadesXml.Child(info, "SignatureMethod").GetAttribute("Algorithm");
                var signatureHash = signatureAlgorithm switch
                {
                    XadesXml.RsaSha256 => HashAlgorithmName.SHA256, XadesXml.RsaSha1 => HashAlgorithmName.SHA1,
                    _ => throw new FormatException("Unsupported XML signature algorithm"),
                };
                var intact = true;
                var references = XadesXml.Children(info, "Reference").ToArray();
                var propertyReferenceCount = 0;
                var dataReferenceCount = 0;
                XmlElement? signedProperties = null;
                foreach (var reference in references)
                {
                    var uri = reference.GetAttribute("URI");
                    byte[] data;
                    if (uri.StartsWith('#'))
                    {
                        if (!ids.TryGetValue(uri[1..], out var target) || !IsDescendant(target, signature))
                            throw new FormatException("Missing or external XML reference target");
                        var comments = false;
                        var transforms = XadesXml.Children(reference, "Transforms").ToArray();
                        if (transforms.Length > 1) throw new FormatException("Ambiguous reference transforms");
                        if (transforms.Length == 1)
                        {
                            var list = XadesXml.Children(transforms[0], "Transform").ToArray();
                            if (list.Length != 1 || (list[0].GetAttribute("Algorithm") != XadesXml.C14n &&
                                list[0].GetAttribute("Algorithm") != XadesXml.C14n + "#WithComments"))
                                throw new FormatException("Unsupported XML reference transform");
                            comments = list[0].GetAttribute("Algorithm").EndsWith("#WithComments", StringComparison.Ordinal);
                        }
                        data = XadesXml.Canonical(target, comments);
                        if (reference.GetAttribute("Type") == "http://uri.etsi.org/01903#SignedProperties")
                        {
                            if (target.LocalName != "SignedProperties" || target.NamespaceURI != XadesXml.Xades)
                                throw new FormatException("Invalid SignedProperties target");
                            signedProperties = target;
                            propertyReferenceCount++;
                        }
                        else dataReferenceCount++;
                    }
                    else
                    {
                        if (XadesXml.Children(reference, "Transforms").Any())
                            throw new FormatException("Detached transforms are not supported");
                        if (!uri.StartsWith("file:/", StringComparison.Ordinal)) throw new FormatException("Unsupported detached URI");
                        var path = Uri.UnescapeDataString(uri["file:/".Length..]).Replace('\\', '/');
                        var basename = path[(path.LastIndexOf('/') + 1)..];
                        if (!referencedFiles.TryGetValue(basename, out var bytes))
                        {
                            intact = false;
                            dataReferenceCount++;
                            continue;
                        }
                        data = bytes;
                        dataReferenceCount++;
                    }
                    var digest = XadesXml.Child(reference, "DigestMethod").GetAttribute("Algorithm");
                    intact &= CryptographicOperations.FixedTimeEquals(XadesXml.Hash(data, digest),
                        Convert.FromBase64String(XadesXml.Child(reference, "DigestValue").InnerText));
                }
                if (propertyReferenceCount != 1 || dataReferenceCount == 0 || signedProperties is null)
                    throw new FormatException("XAdES requires signed properties and document references");
                var qualifying = signedProperties.ParentNode as XmlElement;
                if (qualifying is null || qualifying.LocalName != "QualifyingProperties" ||
                    qualifying.NamespaceURI != XadesXml.Xades || qualifying.GetAttribute("Target") != "#" + name)
                    throw new FormatException("SignedProperties is not bound to this signature");
                var signedSignature = XadesXml.Child(signedProperties, "SignedSignatureProperties", XadesXml.Xades);
                var signingCertificate = XadesXml.Child(XadesXml.Child(signedSignature, "SigningCertificate", XadesXml.Xades), "Cert", XadesXml.Xades);
                var certificateDigest = XadesXml.Child(signingCertificate, "CertDigest", XadesXml.Xades);
                intact &= CryptographicOperations.FixedTimeEquals(
                    XadesXml.Hash(cert.RawData, XadesXml.Child(certificateDigest, "DigestMethod").GetAttribute("Algorithm")),
                    Convert.FromBase64String(XadesXml.Child(certificateDigest, "DigestValue").InnerText));
                using var rsa = cert.GetRSAPublicKey();
                var valid = rsa is not null && rsa.VerifyData(
                    XadesXml.Canonical(info, canonicalization.EndsWith("#WithComments", StringComparison.Ordinal)),
                    Convert.FromBase64String(value.InnerText), signatureHash, RSASignaturePadding.Pkcs1);
                var unsigned = qualifying.GetElementsByTagName("UnsignedSignatureProperties", XadesXml.Xades).OfType<XmlElement>().SingleOrDefault();
                var timestamps = unsigned?.GetElementsByTagName("SignatureTimeStamp", XadesXml.Xades).OfType<XmlElement>().ToArray() ?? [];
                bool? timestampValid = null;
                string? timestampTime = null;
                foreach (var timestamp in timestamps)
                {
                    var cm = XadesXml.Children(timestamp, "CanonicalizationMethod").SingleOrDefault()?.GetAttribute("Algorithm") ?? XadesXml.C14n;
                    if (cm != XadesXml.C14n && cm != XadesXml.C14n + "#WithComments")
                        throw new FormatException("Unsupported timestamp canonicalization");
                    var token = Convert.FromBase64String(XadesXml.Child(timestamp, "EncapsulatedTimeStamp", XadesXml.Xades).InnerText);
                    var matches = CheckTimestamp(token, XadesXml.Canonical(value, cm.EndsWith("#WithComments", StringComparison.Ordinal)), out var time);
                    timestampValid = (timestampValid ?? true) && matches;
                    timestampTime ??= time;
                }
                var complete = unsigned is not null &&
                    unsigned.GetElementsByTagName("CompleteRevocationRefs", XadesXml.Xades).Count > 0 &&
                    unsigned.GetElementsByTagName("CompleteCertificateRefs", XadesXml.Xades).Count > 0;
                reports.Add(new VerificationReport
                {
                    Kind = "XAdES", Name = name, Signer = cert.GetNameInfo(X509NameType.SimpleName, false),
                    ContentIntact = intact, SignatureValid = valid, ChainTrusted = Trusted(cert, new X509Certificate2Collection()),
                    SigningTime = XadesXml.Child(signedSignature, "SigningTime", XadesXml.Xades).InnerText,
                    TimestampTime = timestampTime, TimestampImprintValid = timestampValid,
                    Level = complete && timestamps.Length > 0 ? "XAdES-C" : timestamps.Length > 0 ? "XAdES-T" : "XAdES-BES",
                    Notes = OfflineLimits,
                });
            }
            catch (Exception e) when (IsFormatFailure(e)) { reports.Add(Failed("XAdES", name, e.Message)); }
        }
        return reports;
    }

    private const string OfflineLimits = "Offline integrity/RSA and current-time pinned CA path only. " +
        "Timestamp imprint checked when present; TSA signature/path and revocation evidence are not validated.";

    private static bool Trusted(X509Certificate2 leaf, X509Certificate2Collection certificates)
    {
        using var root = SigningAsn.Certificate(ChainCertificates.MdTrustCa);
        using var issuer = SigningAsn.Certificate(ChainCertificates.MdqSign);
        using var chain = new X509Chain();
        chain.ChainPolicy.TrustMode = X509ChainTrustMode.CustomRootTrust;
        chain.ChainPolicy.CustomTrustStore.Add(root);
        chain.ChainPolicy.ExtraStore.Add(issuer);
        chain.ChainPolicy.ExtraStore.AddRange(certificates);
        chain.ChainPolicy.RevocationMode = X509RevocationMode.NoCheck;
        chain.ChainPolicy.DisableCertificateDownloads = true;
        chain.ChainPolicy.VerificationFlags = X509VerificationFlags.NoFlag;
        return chain.Build(leaf);
    }

    private static Dictionary<string, SigningAsn.Node> Attributes(SigningAsn.Node node)
    {
        var values = new Dictionary<string, SigningAsn.Node>(StringComparer.Ordinal);
        foreach (var attribute in node.Children())
        {
            var fields = attribute.Children();
            if (fields.Count != 2 || fields[1].Tag != 0x31 || fields[1].Children().Count != 1 ||
                !values.TryAdd(fields[0].ObjectIdentifier(), fields[1].Children()[0]))
                throw new FormatException("Ambiguous CMS attribute");
        }
        return values;
    }

    private static bool CheckTimestamp(byte[] token, byte[] data, out string? time)
    {
        try { return TrustServices.TimestampMatchesData(token, data, out time); }
        catch (Exception e) when (IsFormatFailure(e)) { time = null; return false; }
    }
    private static HashAlgorithmName HashName(string oid) => oid switch
    {
        SigningAsn.Sha256Oid => HashAlgorithmName.SHA256, SigningAsn.Sha1Oid => HashAlgorithmName.SHA1,
        "2.16.840.1.101.3.4.2.2" => HashAlgorithmName.SHA384, "2.16.840.1.101.3.4.2.3" => HashAlgorithmName.SHA512,
        _ => throw new FormatException("Unsupported digest algorithm"),
    };
    private static byte[] Hash(byte[] bytes, HashAlgorithmName hash) => hash.Name switch
    {
        "SHA256" => SHA256.HashData(bytes), "SHA1" => SHA1.HashData(bytes),
        "SHA384" => SHA384.HashData(bytes), "SHA512" => SHA512.HashData(bytes),
        _ => throw new FormatException("Unsupported digest algorithm"),
    };
    private static bool IsDescendant(XmlElement child, XmlElement ancestor)
    {
        for (XmlNode? node = child; node is not null; node = node.ParentNode)
            if (node == ancestor) return true;
        return false;
    }
    private static bool IsFormatFailure(Exception e) => e is FormatException or XmlException or CryptographicException
        or ArgumentException or InvalidOperationException or AsnContentException or OverflowException or IndexOutOfRangeException;
    private static VerificationReport Failed(string kind, string name, string message) => new()
    {
        Kind = kind, Name = name, Signer = "", ContentIntact = false, SignatureValid = false,
        ChainTrusted = false, Notes = message + ". " + OfflineLimits,
    };
}
