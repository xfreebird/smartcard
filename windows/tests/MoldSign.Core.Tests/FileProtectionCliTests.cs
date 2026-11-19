using MoldSign.Cli;
using MoldSign.Core.Protection;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;

namespace MoldSign.Core.Tests;

public sealed class FileProtectionCliTests
{
    private sealed class NoCardAccess : ICardAccess
    {
        public int Connections { get; private set; }
        public IReadOnlyList<SmartCardReaderInfo> ListReaders()=>[];
        public ICardTransport Connect(string? readerName){Connections++;throw new CardException(CardErrorKind.NoReader,"Synthetic no-reader response");}
    }
    private static (int Code,NoCardAccess Cards) Run(params string[] args)
    {
        var cards=new NoCardAccess();
        var host=new CliHost { Cards=cards,In=new StringReader(""),Out=TextWriter.Null,Error=TextWriter.Null,
            IsInputRedirected=()=>true,GetEnvironmentVariable=_=>null,
            PromptHidden=_=>throw new InvalidOperationException("No secret should be requested") };
        return (CliApp.Run(args,host),cards);
    }
    private static string Fixture(string name)
    {
        var directory=new DirectoryInfo(AppContext.BaseDirectory);
        while(directory!=null){var file=Path.Combine(directory.FullName,"spec/vectors/encryption",name);if(File.Exists(file))return file;directory=directory.Parent;}
        throw new FileNotFoundException(name);
    }
    [Theory]
    [InlineData("encrypt","missing-in","new-out","--card-public-key")]
    [InlineData("decrypt","missing-in","new-out","--card-public-key")]
    [InlineData("encryption-certs","--card-public-key","--card-public-key")]
    [InlineData("remove-file","missing-in","--confirm-removal","--card-public-key")]
    public void Invalid_compatibility_arguments_do_not_touch_card_or_prompt(params string[] args)
    {
        var result=Run(args);Assert.Equal(1,result.Code);Assert.Equal(0,result.Cards.Connections);
    }
    [Fact]
    public void Compatibility_listing_accepts_the_flag_without_asking_for_PIN()
    {
        var result=Run("encryption-certs","--card-public-key");
        Assert.Equal(5,result.Code);Assert.Equal(1,result.Cards.Connections);
    }
    [Fact]
    public void Compatibility_encrypt_is_explicit_offline_and_preserves_exclusive_output()
    {
        var directory=Path.Combine(Path.GetTempPath(),Guid.NewGuid().ToString());Directory.CreateDirectory(directory);
        try {
            var input=Path.Combine(directory,"original.bin");var output=Path.Combine(directory,"encrypted.p7m");
            byte[] plain=[0,1,0x80,0,255];File.WriteAllBytes(input,plain);
            var certPath=Fixture("test-signing-only.der");
            Assert.Equal(1,Run("encrypt",input,output,"--certificate",certPath).Code);Assert.False(File.Exists(output));
            var result=Run("encrypt",input,output,"--certificate",certPath,"--card-public-key");
            Assert.Equal(0,result.Code);Assert.Equal(0,result.Cards.Connections);
            using var cert=X509CertificateLoader.LoadCertificateFromFile(certPath);
            using var key=RSA.Create();key.ImportPkcs8PrivateKey(File.ReadAllBytes(Fixture("test-private-key.pk8")),out _);
            var envelope=File.ReadAllBytes(output);
            Assert.Equal(plain,CertificateFileProtection.Decrypt(envelope,cert,k=>key.Decrypt(k,RSAEncryptionPadding.Pkcs1),CertificateRecipientPolicy.CardPublicKey));
            Assert.Equal(1,Run("encrypt",input,output,"--certificate",certPath,"--card-public-key").Code);
            Assert.Equal(envelope,File.ReadAllBytes(output));Assert.Equal(plain,File.ReadAllBytes(input));
        } finally {Directory.Delete(directory,true);}
    }
}
