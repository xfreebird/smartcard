using System.Formats.Asn1;
using System.Security.Cryptography;
using System.Text;
namespace MoldSign.Core.Protection;

internal static class LegacyPasswordProtection
{
    internal static byte[] Decrypt(byte[] envelope,ReadOnlySpan<char> password) {
        if(password.Length>=2048)throw new ArgumentException("Password too long.");
        var root=new AsnReader(envelope,AsnEncodingRules.BER);var outer=root.ReadSequence();root.ThrowIfNotEmpty();AsnReader body;
        if(outer.PeekTag().HasSameClassAndValue(Asn1Tag.Integer))body=outer;
        else {
            if(outer.ReadObjectIdentifier()!="1.2.840.113549.1.7.6")throw new ArgumentException("Unsupported encrypted file.");
            var explicitBody=outer.ReadSequence(new Asn1Tag(TagClass.ContextSpecific,0,true));outer.ThrowIfNotEmpty();body=explicitBody.ReadSequence();explicitBody.ThrowIfNotEmpty();
        }
        if(body.ReadInteger()!=0)throw new ArgumentException("Unsupported CMS version.");
        var content=body.ReadSequence();body.ThrowIfNotEmpty();
        if(content.ReadObjectIdentifier()!="1.2.840.113549.1.7.1")throw new ArgumentException("Unsupported content.");
        var algorithm=content.ReadSequence();var kind=algorithm.ReadObjectIdentifier() switch {
            "1.2.840.113549.1.12.1.3"=>1,"1.2.840.113549.1.5.3"=>2,"1.2.840.113549.1.12.1.6"=>3,_=>throw new ArgumentException("Unsupported legacy encryption.")};
        var parameters=algorithm.ReadSequence();algorithm.ThrowIfNotEmpty();var salt=parameters.ReadOctetString();
        if(!parameters.TryReadInt32(out var iterations) || iterations<1 || iterations>1000000 || salt.Length is <1 or >64)throw new ArgumentException("Invalid derivation parameters.");
        parameters.ThrowIfNotEmpty();var ciphertext=content.ReadOctetString(new Asn1Tag(TagClass.ContextSpecific,0));content.ThrowIfNotEmpty();
        if(ciphertext.Length==0 || ciphertext.Length%8!=0)throw new ArgumentException("Invalid encrypted content.");
        byte[] key,iv;
        if(kind==2) {
            if(salt.Length!=8 || password.ContainsAnyExceptInRange((char)0,(char)127))throw new ArgumentException("Unsupported legacy password encoding.");
            var material=new byte[password.Length+salt.Length];for(var i=0;i<password.Length;i++)material[i]=(byte)password[i];salt.CopyTo(material,password.Length);
            var hash=MD5.HashData(material);CryptographicOperations.ZeroMemory(material);
            for(var i=1;i<iterations;i++){var next=MD5.HashData(hash);CryptographicOperations.ZeroMemory(hash);hash=next;}
            key=hash[..8];iv=hash[8..];CryptographicOperations.ZeroMemory(hash);
        } else {key=Derive(password,salt,iterations,1,kind==1?24:5);iv=Derive(password,salt,iterations,2,8);}
        try {
            using SymmetricAlgorithm cipher=kind==1?TripleDES.Create():kind==2?DES.Create():RC2.Create();
            cipher.Key=key;cipher.IV=iv;cipher.Mode=CipherMode.CBC;cipher.Padding=PaddingMode.PKCS7;
            if(cipher is RC2 rc2)rc2.EffectiveKeySize=40;
            using var decryptor=cipher.CreateDecryptor();return decryptor.TransformFinalBlock(ciphertext,0,ciphertext.Length);
        }finally{CryptographicOperations.ZeroMemory(key);CryptographicOperations.ZeroMemory(iv);}
    }
    private static byte[] Derive(ReadOnlySpan<char> password,byte[] salt,int iterations,byte id,int length) {
        var p=password.IsEmpty?[]:new byte[password.Length*2+2];for(var i=0;i<password.Length;i++){p[i*2]=(byte)(password[i]>>8);p[i*2+1]=(byte)password[i];}
        var sn=64*((salt.Length+63)/64);var pn=p.Length==0?0:64*((p.Length+63)/64);var input=new byte[64+sn+pn];
        input.AsSpan(0,64).Fill(id);for(var i=0;i<sn;i++)input[64+i]=salt[i%salt.Length];for(var i=0;i<pn;i++)input[64+sn+i]=p[i%p.Length];
        var output=new byte[length];var offset=0;
        try {
            while(offset<length) {
                var hash=SHA1.HashData(input);for(var i=1;i<iterations;i++){var next=SHA1.HashData(hash);CryptographicOperations.ZeroMemory(hash);hash=next;}
                var count=Math.Min(20,length-offset);hash.AsSpan(0,count).CopyTo(output.AsSpan(offset));offset+=count;
                if(offset<length)for(var chunk=64;chunk<input.Length;chunk+=64){var carry=1;for(var j=63;j>=0;j--){var sum=input[chunk+j]+hash[j%20]+carry;input[chunk+j]=(byte)sum;carry=sum>>8;}}
                CryptographicOperations.ZeroMemory(hash);
            }
            return output;
        }finally{CryptographicOperations.ZeroMemory(p);CryptographicOperations.ZeroMemory(input);}
    }
}
