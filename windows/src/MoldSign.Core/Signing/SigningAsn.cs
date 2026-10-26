using System.Formats.Asn1;
using System.Numerics;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;

namespace MoldSign.Core;

internal static class SigningAsn
{
    internal const string Sha256Oid = "2.16.840.1.101.3.4.2.1";
    internal const string Sha1Oid = "1.3.14.3.2.26";
    internal const string DataOid = "1.2.840.113549.1.7.1";
    internal const string SignedDataOid = "1.2.840.113549.1.7.2";
    internal const string TimestampOid = "1.2.840.113549.1.9.16.2.14";

    internal static byte[] Encode(Action<AsnWriter> action)
    {
        var writer = new AsnWriter(AsnEncodingRules.DER);
        action(writer);
        return writer.Encode();
    }

    internal static byte[] Sequence(params byte[][] parts) => Encode(w =>
    {
        using (w.PushSequence()) foreach (var p in parts) w.WriteEncodedValue(p);
    });
    internal static byte[] Set(params byte[][] parts) => Encode(w =>
    {
        using (w.PushSetOf()) foreach (var p in parts) w.WriteEncodedValue(p);
    });
    internal static byte[] Oid(string oid) => Encode(w => w.WriteObjectIdentifier(oid));
    internal static byte[] Integer(BigInteger value) => Encode(w => w.WriteInteger(value));
    internal static byte[] Octet(byte[] value) => Encode(w => w.WriteOctetString(value));
    internal static byte[] Algorithm(string oid) => Sequence(Oid(oid), [5, 0]);
    internal static byte[] Attribute(string oid, byte[] value) => Sequence(Oid(oid), Set(value));
    internal static byte[] Context(int tag, params byte[][] values) => Encode(w =>
    {
        var t = new Asn1Tag(TagClass.ContextSpecific, tag, true);
        using (w.PushSequence(t)) foreach (var value in values) w.WriteEncodedValue(value);
    });
    internal static byte[] Retag(byte[] value, byte tag)
    {
        var result = (byte[])value.Clone();
        result[0] = tag;
        return result;
    }

    internal sealed class Node
    {
        internal readonly byte[] Encoded;
        internal readonly byte[] Value;
        internal byte Tag => Encoded[0];
        internal Node(byte[] encoded)
        {
            Encoded = encoded;
            AsnDecoder.ReadEncodedValue(encoded, AsnEncodingRules.BER, out var offset, out var length, out var consumed);
            if (consumed != encoded.Length) throw new AsnContentException("Trailing ASN.1 data");
            Value = encoded.AsSpan(offset, length).ToArray();
        }
        internal List<Node> Children()
        {
            var reader = new AsnReader(Value, AsnEncodingRules.BER);
            var values = new List<Node>();
            while (reader.HasData) values.Add(new Node(reader.ReadEncodedValue().ToArray()));
            return values;
        }
        internal string ObjectIdentifier() => new AsnReader(Encoded, AsnEncodingRules.BER).ReadObjectIdentifier();
        internal BigInteger Number() => new AsnReader(Encoded, AsnEncodingRules.BER).ReadInteger();
        internal DateTimeOffset Time() => Tag == 0x17
            ? new AsnReader(Encoded, AsnEncodingRules.BER).ReadUtcTime()
            : new AsnReader(Encoded, AsnEncodingRules.BER).ReadGeneralizedTime();
    }

    internal static Node Read(byte[] encoded) => new(encoded);
    internal static (byte[] Issuer, byte[] Serial) IssuerSerial(byte[] certificate)
    {
        var fields = Read(certificate).Children()[0].Children();
        var offset = fields[0].Tag == 0xa0 ? 1 : 0;
        return (fields[offset + 2].Encoded, fields[offset].Encoded);
    }
    internal static X509Certificate2 Certificate(byte[] der) => X509CertificateLoader.LoadCertificate(der);
    internal static string Serial(byte[] der) => Read(IssuerSerial(der).Serial).Number().ToString(System.Globalization.CultureInfo.InvariantCulture);

    // RFC2253 reverses DER RDN order. The vendor escapes non-ASCII UTF-8 bytes, not Unicode scalars.
    internal static string DistinguishedName(byte[] der, bool namedOrganization = false)
    {
        var names = new Dictionary<string, string>(StringComparer.Ordinal)
        {
            ["2.5.4.3"] = "CN", ["2.5.4.6"] = "C", ["2.5.4.7"] = "L", ["2.5.4.8"] = "ST",
            ["2.5.4.10"] = "O", ["2.5.4.11"] = "OU", ["2.5.4.5"] = "serialNumber", ["2.5.4.20"] = "T",
            ["2.5.4.97"] = namedOrganization ? "organizationIdentifier" : "2.5.4.97",
            ["0.9.2342.19200300.100.1.25"] = "DC",
        };
        return string.Join(",", Read(der).Children().AsEnumerable().Reverse().Select(rdn =>
            string.Join("+", rdn.Children().Select(pair =>
            {
                var fields = pair.Children();
                var oid = fields[0].ObjectIdentifier();
                var value = fields[1];
                var reader = new AsnReader(value.Encoded, AsnEncodingRules.DER);
                string text;
                try { text = reader.ReadCharacterString((UniversalTagNumber)value.Tag); }
                catch (AsnContentException) { return $"{names.GetValueOrDefault(oid, oid)}=#{Convert.ToHexString(value.Encoded)}"; }
                var escaped = new StringBuilder();
                var bytes = Encoding.UTF8.GetBytes(text);
                for (var i = 0; i < bytes.Length; i++)
                {
                    var b = bytes[i];
                    if (b >= 0x7f || b < 0x20) escaped.Append('\\').Append(b.ToString("X2"));
                    else
                    {
                        var c = (char)b;
                        if (",+\"\\<>;=".Contains(c) || (i == 0 && c is '#' or ' ') || (i == bytes.Length - 1 && c == ' '))
                            escaped.Append('\\');
                        escaped.Append(c);
                    }
                }
                return $"{names.GetValueOrDefault(oid, oid)}={escaped}";
            }))));
    }
}

internal static class ChainCertificates
{
    internal static byte[] MdqSign => Load("mdqsign");
    internal static byte[] MdTrustCa => Load("mdtrustca");
    internal static IReadOnlyList<byte[]> All => [MdqSign, MdTrustCa];
    private static byte[] Load(string name)
    {
        using var stream = typeof(ChainCertificates).Assembly.GetManifestResourceStream(
            $"MoldSign.Core.Signing.Certificates.{name}.der") ?? throw new InvalidOperationException("Missing public CA certificate");
        using var buffer = new MemoryStream();
        stream.CopyTo(buffer);
        return buffer.ToArray();
    }
}
