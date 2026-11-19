using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using MoldSign.Core.Protection;
namespace MoldSign.Core.Tests;
public sealed class CertificateFileProtectionTests
{
    [Fact]
    public void Signing_certificate_requires_explicit_public_key_policy()
    {
        var directory=new DirectoryInfo(AppContext.BaseDirectory);
        while(directory!=null && !Directory.Exists(Path.Combine(directory.FullName,"spec/vectors/encryption")))directory=directory.Parent;
        var root=Path.Combine(directory!.FullName,"spec/vectors/encryption");
        using var cert=X509CertificateLoader.LoadCertificateFromFile(Path.Combine(root,"test-signing-only.der"));
        using var other=X509CertificateLoader.LoadCertificateFromFile(Path.Combine(root,"test-recipient.der"));
        using var key=RSA.Create();key.ImportPkcs8PrivateKey(File.ReadAllBytes(Path.Combine(root,"test-private-key.pk8")),out _);
        byte[] plain=[0,1,0x80,0,255];
        Assert.Throws<CryptographicException>(()=>CertificateFileProtection.ValidateRecipient(cert));
        Assert.Throws<CryptographicException>(()=>CertificateFileProtection.Encrypt(plain,cert));
        var envelope=CertificateFileProtection.Encrypt(plain,cert,CertificateRecipientPolicy.CardPublicKey);
        var calls=0;
        byte[] Unwrap(byte[] wrapped){calls++;return key.Decrypt(wrapped,RSAEncryptionPadding.Pkcs1);}
        Assert.Throws<CryptographicException>(()=>CertificateFileProtection.Decrypt(envelope,cert,Unwrap));
        Assert.Throws<CryptographicException>(()=>CertificateFileProtection.Decrypt(envelope,other,Unwrap,CertificateRecipientPolicy.CardPublicKey));
        Assert.Equal(0,calls);
        Assert.Equal(plain,CertificateFileProtection.Decrypt(envelope,cert,Unwrap,CertificateRecipientPolicy.CardPublicKey));
        Assert.Equal(1,calls);
    }
    [Fact]
    public void Vendor_CMS_and_native_round_trip()
    {
        var path = new DirectoryInfo(AppContext.BaseDirectory);
        while(path != null && !Directory.Exists(Path.Combine(path.FullName,"spec/vectors/encryption"))) path = path.Parent;
        var root = Path.Combine(path!.FullName,"spec/vectors/encryption");
        using var cert = X509CertificateLoader.LoadCertificateFromFile(Path.Combine(root,"test-recipient.der"));
        using var key = RSA.Create(); key.ImportPkcs8PrivateKey(File.ReadAllBytes(Path.Combine(root,"test-private-key.pk8")),out _);
        byte[] Unwrap(byte[] wrapped) => key.Decrypt(wrapped,RSAEncryptionPadding.Pkcs1);
        var plain = File.ReadAllBytes(Path.Combine(root,"plain-1024.bin"));
        var vendor = File.ReadAllBytes(Path.Combine(root,"vendor-certificate.asymmetric.p7m"));
        Assert.True(CertificateFileProtection.IsRecipientEnvelope(vendor));
        Assert.False(CertificateFileProtection.IsRecipientEnvelope(File.ReadAllBytes(Path.Combine(root,"vendor-128-0.symmetric.p7m"))));
        Assert.False(CertificateFileProtection.IsRecipientEnvelope(File.ReadAllBytes(Path.Combine(root,"vendor-legacy-DES_CBC-0.p7m"))));
        Assert.Equal(plain,CertificateFileProtection.Decrypt(vendor,cert,Unwrap));
        var native = CertificateFileProtection.Encrypt(plain,cert);
        Assert.True(CertificateFileProtection.IsRecipientEnvelope(native));
        Assert.Equal(plain,CertificateFileProtection.Decrypt(native,cert,Unwrap));
        var export = Environment.GetEnvironmentVariable("MSIGN_ENCRYPTION_ORACLE_OUTPUT");
        if(export != null) File.WriteAllBytes(Path.Combine(export,"native-certificate.asymmetric.p7m"),native);
    }
}
