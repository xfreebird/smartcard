using System.Formats.Asn1;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;

namespace MoldSign.Core.Protection;

/// <summary>CMS RSA key transport/AES-128, compatible with MoldSign Desktop.</summary>
public static class CertificateFileProtection
{
    public const string Suffix = ".asymmetric.p7m";
    private const string Enveloped = "1.2.840.113549.1.7.3", DataOid = "1.2.840.113549.1.7.1";
    private const string RsaOid = "1.2.840.113549.1.1.1", AesOid = "2.16.840.1.101.3.4.1.2";
    private static readonly Asn1Tag Explicit = new(TagClass.ContextSpecific,0,true);
    private static readonly Asn1Tag Content = new(TagClass.ContextSpecific,0);
    private static void CheckCertificate(X509Certificate2 certificate)
    {
        var usage = certificate.Extensions.OfType<X509KeyUsageExtension>().SingleOrDefault();
        if (usage == null || !usage.KeyUsages.HasFlag(X509KeyUsageFlags.KeyEncipherment))
            throw new CryptographicException("Choose an encryption certificate, not a signing-only certificate.");
    }
    public static byte[] Encrypt(byte[] plaintext, X509Certificate2 certificate)
    {
        CheckCertificate(certificate);
        if (plaintext.Length > PasswordFileProtection.MaximumSize) throw new ArgumentException("Choose a file smaller than 64 MB.");
        using var rsa = certificate.GetRSAPublicKey();
        if (rsa == null || rsa.KeySize < 2048 || rsa.KeySize > 8192) throw new CryptographicException("Unsupported encryption certificate.");
        var key = RandomNumberGenerator.GetBytes(16); var iv = RandomNumberGenerator.GetBytes(16);
        try
        {
            using var aes = Aes.Create(); aes.Key = key;
            var ciphertext = aes.EncryptCbc(plaintext,iv,PaddingMode.PKCS7);
            var w = new AsnWriter(AsnEncodingRules.DER);
            w.PushSequence(); w.WriteObjectIdentifier(Enveloped); w.PushSequence(Explicit); w.PushSequence();
            w.WriteInteger(0); w.PushSetOf(); w.PushSequence(); w.WriteInteger(0);
            w.WriteEncodedValue(Identity(certificate));
            w.PushSequence(); w.WriteObjectIdentifier(RsaOid); w.WriteNull(); w.PopSequence();
            w.WriteOctetString(rsa.Encrypt(key,RSAEncryptionPadding.Pkcs1)); w.PopSequence(); w.PopSetOf();
            w.PushSequence(); w.WriteObjectIdentifier(DataOid); w.PushSequence(); w.WriteObjectIdentifier(AesOid);
            w.WriteOctetString(iv); w.PopSequence(); w.WriteOctetString(ciphertext,Content); w.PopSequence();
            w.PopSequence(); w.PopSequence(Explicit); w.PopSequence(); return w.Encode();
        }
        finally { CryptographicOperations.ZeroMemory(key); }
    }
    public static byte[] Decrypt(byte[] envelope, X509Certificate2 certificate, Func<byte[],byte[]> unwrap)
    {
        CheckCertificate(certificate);
        if (envelope.Length > PasswordFileProtection.MaximumSize + 8192) throw new ArgumentException("Choose a file smaller than 64 MB.");
        using var publicKey = certificate.GetRSAPublicKey();
        if (publicKey == null || publicKey.KeySize < 2048 || publicKey.KeySize > 8192) throw new CryptographicException("Unsupported RSA certificate.");
        var root = new AsnReader(envelope,AsnEncodingRules.BER); var outer = root.ReadSequence(); root.ThrowIfNotEmpty();
        AsnReader body;
        if (outer.PeekTag().HasSameClassAndValue(Asn1Tag.Integer)) body = outer;
        else {
            if (outer.ReadObjectIdentifier() != Enveloped) throw new CryptographicException("Unsupported encrypted file.");
            var explicitBody = outer.ReadSequence(Explicit); outer.ThrowIfNotEmpty();
            body = explicitBody.ReadSequence(); explicitBody.ThrowIfNotEmpty();
        }
        if (body.ReadInteger() != 0) throw new CryptographicException("Unsupported CMS version.");
        var recipients = body.ReadSetOf(); byte[]? encryptedKey = null; var count = 0;
        while (recipients.HasData)
        {
            if (++count > 32) throw new CryptographicException("Too many recipients.");
            var r = recipients.ReadSequence();
            if (r.ReadInteger() != 0) throw new CryptographicException("Unsupported recipient.");
            var identity = r.ReadEncodedValue().ToArray(); var algorithm = r.ReadSequence();
            if (algorithm.ReadObjectIdentifier() != RsaOid) throw new CryptographicException("Unsupported key transport.");
            if (algorithm.HasData) algorithm.ReadNull(); algorithm.ThrowIfNotEmpty();
            var wrapped = r.ReadOctetString(); r.ThrowIfNotEmpty();
            if (identity.AsSpan().SequenceEqual(Identity(certificate)))
            {
                if (encryptedKey != null || wrapped.Length != (publicKey.KeySize+7)/8) throw new CryptographicException("Invalid recipient key.");
                encryptedKey = wrapped;
            }
        }
        var content = body.ReadSequence(); body.ThrowIfNotEmpty();
        if (content.ReadObjectIdentifier() != DataOid) throw new CryptographicException("Unsupported content type.");
        var cipher = content.ReadSequence();
        if (cipher.ReadObjectIdentifier() != AesOid) throw new CryptographicException("Unsupported content encryption.");
        var iv = cipher.ReadOctetString(); cipher.ThrowIfNotEmpty();
        var ciphertext = content.ReadOctetString(Content); content.ThrowIfNotEmpty();
        if (iv.Length != 16 || ciphertext.Length == 0 || ciphertext.Length % 16 != 0 || encryptedKey == null)
            throw new CryptographicException("File does not match this encryption certificate.");
        var key = unwrap(encryptedKey);
        try
        {
            if (key.Length != 16) throw new CryptographicException("Unable to decrypt.");
            using var aes = Aes.Create(); aes.Key = key;
            return aes.DecryptCbc(ciphertext,iv,PaddingMode.PKCS7);
        }
        finally { CryptographicOperations.ZeroMemory(key); }
    }
    private static byte[] Identity(X509Certificate2 certificate)
    {
        var root = new AsnReader(certificate.RawData,AsnEncodingRules.DER).ReadSequence().ReadSequence();
        if (root.PeekTag().HasSameClassAndValue(Explicit)) root.ReadEncodedValue();
        var serial = root.ReadEncodedValue(); root.ReadEncodedValue(); var issuer = root.ReadEncodedValue();
        var w = new AsnWriter(AsnEncodingRules.DER); w.PushSequence(); w.WriteEncodedValue(issuer.Span); w.WriteEncodedValue(serial.Span); w.PopSequence();
        return w.Encode();
    }
}
