using System.Globalization;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.RegularExpressions;

namespace MoldSign.Core;

/// <summary>
/// PAdES-B-T signer: detached CMS (signingCertificateV2!) + iText-style incremental update, RFC 3161
/// token from MDQTSA (docs/02-pades-signing.md). Port target: <c>apple/Sources/MoldSignKit/Signing.swift</c>.
/// </summary>
public sealed class PadesSigner
{
    public PadesSigner(TrustServices trust) => Trust = trust ?? throw new ArgumentNullException(nameof(trust));

    /// <summary>TSA client for the signature timestamp (PAdES-T is what the portal requires).</summary>
    public TrustServices Trust { get; }
    internal Action<SigningStep>? Progress { get; init; }

    /// <summary>
    /// Signs <paramref name="pdf"/> (or counter-signs it when it already carries signatures).
    /// <paramref name="signDigestInfo"/> receives the DigestInfo(SHA-256) of the signed attributes and
    /// returns the card's 512-byte RSA signature; it is where consent + VERIFY happen.
    /// Mirrors Swift <c>PAdESSigner.signPDF(_:certDER:tsaUnsignedAttr:signBlock:)</c>.
    /// </summary>
    public byte[] Sign(byte[] pdf, byte[] certificateDer, Func<byte[], byte[]> signDigestInfo)
    {
        ArgumentNullException.ThrowIfNull(pdf);
        ArgumentNullException.ThrowIfNull(signDigestInfo);
        var text = Encoding.Latin1.GetString(pdf);
        if (!text.StartsWith("%PDF-", StringComparison.Ordinal)) throw Format("Not a PDF");
        if (Regex.IsMatch(text, @"/Encrypt\b")) throw Format("Encrypted PDFs are not supported");
        var end = text.LastIndexOf("%%EOF", StringComparison.Ordinal);
        var start = text.LastIndexOf("startxref", StringComparison.Ordinal);
        if (end < 0 || start < 0 || start > end ||
            !long.TryParse(text[(start + 9)..end].Trim(), NumberStyles.None, CultureInfo.InvariantCulture, out var previousXref))
            throw Format("Cannot find the PDF trailer");
        var roots = Regex.Matches(text, @"/Root\s+(\d+)\s+0\s+R\b");
        if (roots.Count == 0) throw Format("No uncompressed PDF root (object streams are not supported)");
        var root = int.Parse(roots[^1].Groups[1].Value, CultureInfo.InvariantCulture);
        var catalog = ObjectDictionary(text, root);
        var objects = Regex.Matches(text, @"(?<!\d)(\d+)\s+0\s+obj\b");
        var max = objects.Max(m => int.Parse(m.Groups[1].Value, CultureInfo.InvariantCulture));
        var declaredSizes = Regex.Matches(text, @"/Size\s+(\d+)\b");
        if (declaredSizes.Count > 0)
            max = Math.Max(max, declaredSizes.Max(m => int.Parse(m.Groups[1].Value, CultureInfo.InvariantCulture)) - 1);
        var sig = checked(max + 1);
        var acro = checked(max + 2);
        var field = checked(max + 3);
        var names = Regex.Matches(text, @"/T\s*\(\s*Signature(\d+)");
        var next = names.Count == 0 ? 1 : names.Max(m => int.Parse(m.Groups[1].Value, CultureInfo.InvariantCulture)) + 1;
        const int reserve = 37960;
        const string dummy = "/ByteRange [0 0000000000 0000000000 0000000000 ]";
        var chunks = new List<(int Number, string Body)>();
        var date = DateTimeOffset.UtcNow.ToString("'D:'yyyyMMddHHmmss'Z'", CultureInfo.InvariantCulture);
        chunks.Add((sig, $"<< /Type/Sig /Filter/Adobe.PPKLite /SubFilter/ETSI.CAdES.detached {dummy} " +
            $"/Contents<{new string('0', reserve)}> /M({date}) /Reason(MoldSign Signature) /Location(Moldova) " +
            "/ContactInfo() /Prop_Build<</App<</Name/>>>> >>"));
        chunks.Add((field, $"<< /FT/Sig /T(Signature{next}) /Type/Annot /Subtype/Widget /Rect[0 0 0 0] /F 0 /V {sig} 0 R >>"));
        var existing = Regex.Match(catalog, @"/AcroForm\s+(\d+)\s+0\s+R\b");
        string? acroDictionary = null;
        if (existing.Success)
        {
            acro = int.Parse(existing.Groups[1].Value, CultureInfo.InvariantCulture);
            acroDictionary = ObjectDictionary(text, acro);
        }
        else
        {
            var inline = Regex.Match(catalog, @"/AcroForm\s*(?=<<)");
            if (inline.Success)
            {
                var at = inline.Index + inline.Length;
                acroDictionary = ReadDictionary(catalog, at);
                catalog = catalog[..inline.Index] + $"/AcroForm {acro} 0 R " + catalog[(at + acroDictionary.Length)..];
            }
            else if (Regex.IsMatch(catalog, @"/AcroForm\b"))
                throw Format("Unsupported AcroForm reference");
        }
        if (acroDictionary is not null)
        {
            var fields = Regex.Match(acroDictionary, @"/Fields\s*\[([^\]]*)\]");
            if (!fields.Success) throw Format("AcroForm must have a direct /Fields array");
            acroDictionary = acroDictionary[..fields.Index] +
                $"/Fields[{fields.Groups[1].Value} {field} 0 R]" + acroDictionary[(fields.Index + fields.Length)..];
            var flags = Regex.Match(acroDictionary, @"/SigFlags\s+(\d+)\b");
            if (flags.Success)
                acroDictionary = acroDictionary[..flags.Index] +
                    FormattableString.Invariant($"/SigFlags {int.Parse(flags.Groups[1].Value, CultureInfo.InvariantCulture) | 3}") +
                    acroDictionary[(flags.Index + flags.Length)..];
            else if (!Regex.IsMatch(acroDictionary, @"/SigFlags\b")) acroDictionary = Insert(acroDictionary, "/SigFlags 3");
        }
        else
        {
            acroDictionary = $"<< /Fields[{field} 0 R] /SigFlags 3 >>";
            catalog = Insert(catalog, $"/AcroForm {acro} 0 R");
        }
        chunks.Add((acro, acroDictionary));
        if (!existing.Success)
        {
            if (!Regex.IsMatch(catalog, @"/Extensions\b"))
                catalog = Insert(catalog, "/Extensions<</ESIC<</BaseVersion/1.7/ExtensionLevel 2>>>>");
            chunks.Add((root, catalog));
        }
        var append = new StringBuilder("\n");
        var offsets = new List<(int Number, long Offset)>();
        foreach (var (number, body) in chunks)
        {
            offsets.Add((number, pdf.LongLength + append.Length));
            append.Append(CultureInfo.InvariantCulture, $"{number} 0 obj\n{body}\nendobj\n");
        }
        var xref = pdf.LongLength + append.Length;
        append.Append("xref\n0 1\n0000000000 65535 f \n");
        foreach (var (number, offset) in offsets.OrderBy(o => o.Number))
            append.Append(CultureInfo.InvariantCulture, $"{number} 1\n{offset:D10} 00000 n \n");
        var ids = Regex.Matches(text, @"/ID\s*\[\s*<[0-9A-Fa-f]+>\s*<[0-9A-Fa-f]+>\s*\]");
        var infos = Regex.Matches(text, @"/Info\s+\d+\s+\d+\s+R\b");
        append.Append(CultureInfo.InvariantCulture, $"trailer\n<</Size {max + 4} /Root {root} 0 R /Prev {previousXref} ");
        if (ids.Count > 0) append.Append(ids[^1].Value);
        if (infos.Count > 0) append.Append(' ').Append(infos[^1].Value);
        append.Append(CultureInfo.InvariantCulture, $">>\nstartxref\n{xref}\n%%EOF\n");
        var update = append.ToString();
        var hexStart = pdf.Length + update.IndexOf("/Contents<", StringComparison.Ordinal) + 10;
        var hexEnd = hexStart + reserve;
        var total = pdf.Length + update.Length;
        var range = FormattableString.Invariant($"/ByteRange [0 {hexStart - 1:D10} {hexEnd + 1:D10} {total - hexEnd - 1:D10} ]");
        if (range.Length != dummy.Length) throw Format("PDF is too large");
        update = update.Replace(dummy, range, StringComparison.Ordinal);
        var result = new byte[total];
        pdf.CopyTo(result, 0);
        Encoding.Latin1.GetBytes(update).CopyTo(result, pdf.Length);
        using var hash = IncrementalHash.CreateHash(HashAlgorithmName.SHA256);
        hash.AppendData(result.AsSpan(0, hexStart - 1));
        hash.AppendData(result.AsSpan(hexEnd + 1));
        var cms = BuildCms(hash.GetHashAndReset(), certificateDer, signDigestInfo);
        var hex = Convert.ToHexString(cms).ToLowerInvariant();
        if (hex.Length > reserve) throw Format("CMS exceeds the reserved signature size");
        Encoding.ASCII.GetBytes(hex).CopyTo(result, hexStart);
        return result;
    }

    internal byte[] BuildCms(byte[] contentDigest, byte[] certificateDer, Func<byte[], byte[]> signer)
    {
        var (issuer, serial) = SigningAsn.IssuerSerial(certificateDer);
        var attrs = SigningAsn.Set(
            SigningAsn.Attribute("1.2.840.113549.1.9.3", SigningAsn.Oid(SigningAsn.DataOid)),
            SigningAsn.Attribute("1.2.840.113549.1.9.5", SigningAsn.Encode(w => w.WriteUtcTime(DateTimeOffset.UtcNow))),
            SigningAsn.Attribute("1.2.840.113549.1.9.4", SigningAsn.Octet(contentDigest)),
            SigningAsn.Attribute("1.2.840.113549.1.9.16.2.47",
                SigningAsn.Sequence(SigningAsn.Sequence(SigningAsn.Sequence(SigningAsn.Octet(SHA256.HashData(certificateDer)))))));
        var signature = signer(DigestInfo.Sha256(attrs));
        using var certificate = SigningAsn.Certificate(certificateDer);
        using var rsa = certificate.GetRSAPublicKey();
        if (rsa is null || !rsa.VerifyData(attrs, signature, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1))
            throw Format("The card signature does not match the signing certificate");
        Progress?.Invoke(SigningStep.Timestamping);
        var token = Trust.GetTimestampToken(SHA256.HashData(signature));
        var info = SigningAsn.Sequence(SigningAsn.Integer(1), SigningAsn.Sequence(issuer, serial),
            SigningAsn.Algorithm(SigningAsn.Sha256Oid), SigningAsn.Retag(attrs, 0xa0),
            SigningAsn.Algorithm("1.2.840.113549.1.1.1"), SigningAsn.Octet(signature),
            SigningAsn.Retag(SigningAsn.Set(SigningAsn.Attribute(SigningAsn.TimestampOid, token)), 0xa1));
        var certificates = SigningAsn.Retag(SigningAsn.Set(
            [certificateDer, .. ChainCertificates.All]), 0xa0);
        return SigningAsn.Sequence(SigningAsn.Oid(SigningAsn.SignedDataOid),
            SigningAsn.Context(0, SigningAsn.Sequence(SigningAsn.Integer(1),
                SigningAsn.Set(SigningAsn.Algorithm(SigningAsn.Sha256Oid)), SigningAsn.Sequence(SigningAsn.Oid(SigningAsn.DataOid)),
                certificates, SigningAsn.Set(info))));
    }

    private static CardException Format(string message) => new(CardErrorKind.Format, message);
    private static string Insert(string dictionary, string entries) => dictionary[..^2] + " " + entries + " >>";
    private static string ObjectDictionary(string text, int number)
    {
        var matches = Regex.Matches(text, FormattableString.Invariant($@"(?<!\d){number}\s+0\s+obj\b"));
        if (matches.Count == 0) throw Format("PDF dictionary is compressed or missing");
        var at = matches[^1].Index + matches[^1].Length;
        while (at < text.Length && char.IsWhiteSpace(text[at])) at++;
        return ReadDictionary(text, at);
    }

    private static string ReadDictionary(string text, int start)
    {
        if (!text.AsSpan(start).StartsWith("<<", StringComparison.Ordinal)) throw Format("Expected PDF dictionary");
        var depth = 0;
        var literal = 0;
        for (var i = start; i < text.Length - 1; i++)
        {
            if (literal > 0)
            {
                if (text[i] == '\\') i++;
                else if (text[i] == '(') literal++;
                else if (text[i] == ')') literal--;
                continue;
            }
            if (text[i] == '(') { literal++; continue; }
            if (text[i] == '%')
            {
                while (i < text.Length - 1 && text[i] is not '\n' and not '\r') i++;
                continue;
            }
            if (text[i] == '<' && text[i + 1] != '<')
            {
                i = text.IndexOf('>', i + 1);
                if (i < 0) break;
                continue;
            }
            if (text[i] == '<' && text[i + 1] == '<') { depth++; i++; }
            else if (text[i] == '>' && text[i + 1] == '>')
            {
                i++;
                if (--depth == 0) return text[start..(i + 1)];
            }
        }
        throw Format("Unterminated PDF dictionary");
    }
}
