using MoldSign.Core.Protection;
using System.Security.Cryptography;
using static MoldSign.Core.Tests.VectorFile;
namespace MoldSign.Core.Tests;

public sealed class CardFileProtectionTests
{
    private static byte[] W(byte tag,params byte[][] contents){var body=contents.SelectMany(b=>b).ToArray();Assert.True(body.Length<128);return [tag,(byte)body.Length,..body];}
    private static (byte[] Key,byte[] Cert,byte[] Pin) Metadata(bool consent=false,byte usage=0x40,byte pin=3,byte pinType=1) {
        var common=W(0x30,W(12,"Encryption key"u8.ToArray()),W(4,[1]),consent?W(2,[1]):[]);
        var attrs=W(0x30,W(4,[2]),W(3,[6,usage]),W(2,[2]));var type=W(0xa1,W(0x30,W(0x30,W(4,[])),W(2,[8,0])));
        return (W(0x30,common,attrs,type),W(0x30,W(0x30,[]),W(0x30,W(4,[2])),W(0xa1,W(0x30,W(0x30,W(4,[0,2]))))),
            W(0x30,W(0x30,[]),W(0x30,W(4,[1])),W(0xa1,W(0x30,W(3,[0,8]),W(10,[pinType]),W(2,[4]),W(2,[8]),W(0x80,[pin])))));
    }
    private static byte[] Fixture(string name){var directory=new DirectoryInfo(AppContext.BaseDirectory);while(directory!=null){var path=Path.Combine(directory.FullName,"spec/vectors/encryption",name);if(File.Exists(path))return File.ReadAllBytes(path);directory=directory.Parent;}throw new FileNotFoundException(name);}
    private static (CosmoXCard Card,CosmoXCardTests.SimulatedSmCard Sim,RSA Rsa) Setup(bool signingOnly=false,bool mirrorEof=false,bool paddedDirectories=false) {
        var sim=new CosmoXCardTests.SimulatedSmCard(Bytes("sm","sess_enc"),Bytes("sm","sess_mac"),Bytes("sm","ssc_initial"));
        var metadata=Metadata(pinType:2);sim.ExtraFiles.Add(0x7001,metadata.Pin);sim.ExtraFiles.Add(0x7002,metadata.Key);sim.ExtraFiles.Add(0x7005,metadata.Cert);sim.ExtraFiles.Add(2,Fixture(signingOnly?"test-signing-only.der":"test-recipient.der"));
        sim.MirrorEofStatus=mirrorEof;
        if(paddedDirectories)foreach(var file in new[]{0x7001,0x7002,0x7005}){
            var bytes=sim.ExtraFiles[file];sim.ExtraFiles[file]=[..bytes,..new byte[128-bytes.Length%128]];
        }
        var rsa=RSA.Create();rsa.ImportPkcs8PrivateKey(Fixture("test-private-key.pk8"),out _);sim.Decipher=wrapped=>rsa.Decrypt(wrapped,RSAEncryptionPadding.Pkcs1);
        return (new CosmoXCard(sim){Channel=SecureChannelVectorTests.FreshChannel()},sim,rsa);
    }
    [Fact] public void Metadata_excludes_signing_keys_and_ambiguity() {
        foreach(var item in new[]{Metadata(consent:true),Metadata(usage:0x20),Metadata(pin:4),Metadata(pinType:0)})Assert.Empty(EncryptionDirectory.Keys(item.Key,item.Cert,item.Pin));
        var m=Metadata();Assert.Single(EncryptionDirectory.Keys(m.Key,m.Cert,m.Pin));Assert.Empty(EncryptionDirectory.Keys([..m.Key,..m.Key],m.Cert,m.Pin));Assert.Empty(EncryptionDirectory.Keys(m.Key,[..m.Cert,..m.Cert],m.Pin));
    }
    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public void Public_key_policy_and_authenticated_EOF_preserve_card_admission(bool paddedDirectories) {
        var (card,sim,rsa)=Setup(signingOnly:true,mirrorEof:true,paddedDirectories:paddedDirectories);
        using(rsa){
            Assert.Empty(CardFileProtection.Identities(card));
            var identity=CardFileProtection.Identities(card,CertificateRecipientPolicy.CardPublicKey).Single();
            Assert.Equal(CertificateRecipientPolicy.CardPublicKey,identity.RecipientPolicy);
            Assert.DoesNotContain(sim.Commands,c=>c[1]==0x20);
            using var cert=System.Security.Cryptography.X509Certificates.X509CertificateLoader.LoadCertificate(identity.Certificate);
            byte[] plain=[1,0x80,0,0,255];
            var envelope=CertificateFileProtection.Encrypt(plain,cert,CertificateRecipientPolicy.CardPublicKey);
            Assert.Equal(plain,CardFileProtection.Decrypt(card,envelope,identity,"1234"));
            Assert.Single(sim.Commands,c=>c[1]==0x20);Assert.Single(sim.Commands,c=>c[1]==0x2a);
        }
    }
    [Fact] public void Vendor_envelope_through_simulated_card() {
        var (card,sim,rsa)=Setup();using(rsa){var identity=CardFileProtection.Identities(card).Single();Assert.Equal(Fixture("plain-1024.bin"),CardFileProtection.Decrypt(card,Fixture("vendor-certificate.asymmetric.p7m"),identity,"1234"));Assert.Single(sim.Commands,c=>c[1]==0x20);Assert.Single(sim.Commands,c=>c[1]==0x2a);}
    }
    [Fact] public void Wrong_pin_stops_without_retry_or_decipher() {
        var (card,sim,rsa)=Setup();using(rsa){var identity=CardFileProtection.Identities(card).Single();sim.VerifyStatus=0x63c2;var error=Assert.Throws<CardException>(()=>CardFileProtection.Decrypt(card,Fixture("vendor-certificate.asymmetric.p7m"),identity,"9999"));Assert.Equal(CardErrorKind.WrongPin,error.Kind);Assert.Single(sim.Commands,c=>c[1]==0x20);Assert.DoesNotContain(sim.Commands,c=>c[1]==0x2a);}
    }
    [Fact] public void Changed_key_capability_never_sends_pin() {
        var (card,sim,rsa)=Setup();using(rsa){var identity=CardFileProtection.Identities(card).Single();sim.ExtraFiles[0x7002]=[0];var error=Assert.Throws<CardException>(()=>CardFileProtection.Decrypt(card,Fixture("vendor-certificate.asymmetric.p7m"),identity,"1234"));Assert.Equal(CardErrorKind.CardChanged,error.Kind);Assert.DoesNotContain(sim.Commands,c=>c[1]==0x20);}
    }
}
