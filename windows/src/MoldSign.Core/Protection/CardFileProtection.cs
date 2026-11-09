using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
namespace MoldSign.Core.Protection;

public sealed class CardEncryptionIdentity
{
    private readonly byte[] _certificate;
    internal EncryptionKey Key { get; }
    public byte[] Certificate => _certificate.ToArray();
    public string Label => Key.Label;
    public string Fingerprint { get; }
    internal CardEncryptionIdentity(EncryptionKey key,byte[] certificate) {
        Key=key;_certificate=certificate.ToArray();Fingerprint=Convert.ToHexString(SHA256.HashData(certificate));
    }
}
internal sealed record EncryptionKey(string Id,string Label,int Reference,int ModulusBytes,int Minimum,int Maximum,int CertificateFile);
internal sealed record DirectoryNode(byte Tag,byte[] Content,List<DirectoryNode> Children)
{
    public int Integer() {
        if(Content.Length is <1 or >3 || (Content[0]&128)!=0) throw new CryptographicException("Invalid card metadata integer.");
        return Content.Aggregate(0,(n,b)=>n*256+b);
    }
    public static List<DirectoryNode> Records(byte[] input) {
        if(input.Length>32768) throw new CryptographicException("Card metadata exceeds limit.");
        var position=0;var budget=4096;
        DirectoryNode Read(int end,int depth) {
            if(depth>16 || budget--<=0 || position+2>end) throw new CryptographicException("Invalid card metadata.");
            var tag=input[position++];var first=input[position++];long length=first;
            if(tag==0 || (tag&31)==31) throw new CryptographicException("Unknown card metadata tag.");
            if(first>=128) {
                var count=first&127;if(count is <1 or >4 || position+count>end) throw new CryptographicException("Invalid card metadata length.");
                length=0;for(var i=0;i<count;i++) length=length*256+input[position++];
            }
            if(length>end-position) throw new CryptographicException("Truncated card metadata.");
            var start=position;var boundary=position+(int)length;List<DirectoryNode> children=[];
            if((tag&32)!=0) {while(position<boundary) children.Add(Read(boundary,depth+1));} else position=boundary;
            return new(tag,input[start..boundary],children);
        }
        List<DirectoryNode> result=[];
        while(position<input.Length) {
            if(input[position]==0) {if(input[position..].Any(b=>b!=0)) throw new CryptographicException("Invalid directory padding.");break;}
            result.Add(Read(input.Length,0));if(result.Count>128) throw new CryptographicException("Too many card objects.");
        }
        return result;
    }
}
internal static class EncryptionDirectory
{
    private static DirectoryNode? First(IEnumerable<DirectoryNode> list,byte tag)=>list.FirstOrDefault(n=>n.Tag==tag);
    public static IReadOnlyList<EncryptionKey> Keys(byte[] privateKeys,byte[] certificates,byte[] authentication) {
        var certs=DirectoryNode.Records(certificates);var pins=DirectoryNode.Records(authentication);List<EncryptionKey> result=[];
        DirectoryNode? Match(IEnumerable<DirectoryNode> nodes,byte[] id) {
            var matches=nodes.Where(n=>n.Tag==0x30 && n.Children.Count>=3 && n.Children[1].Tag==0x30 && n.Children[1].Children.FirstOrDefault() is {Tag:4} item && item.Content.AsSpan().SequenceEqual(id)).ToArray();
            return matches.Length==1 ? matches[0] : null;
        }
        foreach(var record in DirectoryNode.Records(privateKeys)) {
            var f=record.Children;if(record.Tag!=0x30 || f.Count<3 || f[0].Tag!=0x30 || f[1].Tag!=0x30) continue;
            var common=f[0].Children;var a=f[1].Children;
            if(common.Any(n=>n.Tag==2 && n.Content.Any(b=>b!=0))) continue;
            var auth=First(common,4)?.Content;
            if(auth==null || a.Count<3 || a[0].Tag!=4 || a[1].Tag!=3 || a[1].Content.Length<2 || (a[1].Content[1]&0x40)==0) continue;
            var reference=First(a.Skip(2),2)?.Integer();var type=First(f,0xa1)?.Children.FirstOrDefault();
            if(reference is null or <1 or >255 || type is not {Tag:0x30} || type.Children.Count<2 || type.Children[0].Tag!=0x30 || type.Children[0].Children.FirstOrDefault()?.Tag!=4 || type.Children[1].Tag!=2) continue;
            var bits=type.Children[1].Integer();if(bits is not (2048 or 3072 or 4096 or 8192)) continue;
            var cert=Match(certs,a[0].Content);var certType=cert==null ? null : First(cert.Children,0xa1)?.Children.FirstOrDefault();
            var path=certType?.Children.FirstOrDefault();
            if(certType?.Tag!=0x30 || path?.Tag!=0x30 || path.Children.Count!=1 || path.Children[0].Tag!=4 || path.Children[0].Content.Length!=2) continue;
            var pinRecord=Match(pins,auth);var pin=pinRecord==null ? null : First(pinRecord.Children,0xa1)?.Children.FirstOrDefault()?.Children;
            if(pin==null || pin.Count<4 || pin[0].Tag!=3 || pin[0].Content.Length<2 || (pin[0].Content[1]&7)!=0 || pin[1].Tag!=10 || pin[1].Integer()!=1 || pin[2].Tag!=2 || pin[3].Tag!=2 || First(pin,0x80)?.Integer()!=3) continue;
            var minimum=pin[2].Integer();var maximum=First(pin.Skip(4),2)?.Integer() ?? pin[3].Integer();
            if(minimum<4 || maximum<minimum || maximum>8) continue;
            var file=path.Children[0].Content;
            result.Add(new(Convert.ToHexString(a[0].Content),System.Text.Encoding.UTF8.GetString(First(common,12)?.Content ?? []),reference.Value,bits/8,minimum,maximum,file[0]*256+file[1]));
        }
        return result.Where(key=>result.Count(other=>other.Id==key.Id || other.Reference==key.Reference)==1).ToArray();
    }
}
public static class CardFileProtection
{
    public static IReadOnlyList<CardEncryptionIdentity> Identities(CosmoXCard card) {
        var auth=Read(card,0x7001);var keys=Read(card,0x7002);var certs=Read(card,0x7005);List<CardEncryptionIdentity> result=[];
        foreach(var key in EncryptionDirectory.Keys(keys,certs,auth)) {
            using var cert=X509CertificateLoader.LoadCertificate(Read(card,key.CertificateFile));using var rsa=cert.GetRSAPublicKey();
            if(rsa==null || (rsa.KeySize+7)/8!=key.ModulusBytes || cert.Extensions.OfType<X509KeyUsageExtension>().SingleOrDefault()?.KeyUsages.HasFlag(X509KeyUsageFlags.KeyEncipherment)!=true) continue;
            result.Add(new(key,cert.RawData));
        }
        return result;
    }
    public static byte[] Decrypt(CosmoXCard card,byte[] envelope,CardEncryptionIdentity identity,string pin) {
        using var cert=X509CertificateLoader.LoadCertificate(identity.Certificate);
        return CertificateFileProtection.Decrypt(envelope,cert,wrapped=>{
            if(wrapped.Length!=identity.Key.ModulusBytes) throw new CryptographicException("Invalid wrapped key length.");
            if(!Identities(card).Any(current=>current.Fingerprint==identity.Fingerprint && current.Key==identity.Key)) throw new CardException(CardErrorKind.CardChanged,"The selected encryption identity changed.");
            if(pin.Length<identity.Key.Minimum || pin.Length>identity.Key.Maximum || pin.Any(c=>c is <'0' or >'9')) throw new CardException(CardErrorKind.InvalidPinFormat,"Invalid PIN length or encoding.");
            card.SelectMF();card.SelectGenericAdf();card.VerifyPin(pin);
            CosmoXCard.CheckSw(card.SmTransmit([0,0x22,0x41,0xb8,6,0x80,1,0x1a,0x84,1,(byte)(identity.Key.Reference|0x80)]));
            byte[] payload=[0x81,..wrapped];var response=card.SmTransmit([0,0x2a,0x80,0x86,0,(byte)(payload.Length>>8),(byte)payload.Length,..payload,0,0]);
            CosmoXCard.CheckSw(response);if(response.Data.Length!=16) throw new CryptographicException("Invalid unwrapped key.");return response.Data;
        });
    }
    private static byte[] Read(CosmoXCard card,int file) {
        card.SelectMF();card.SelectGenericAdf();CosmoXCard.CheckSw(card.SmTransmit([0,0xa4,2,4,2,(byte)(file>>8),(byte)file,0]));
        using var output=new MemoryStream();
        while(output.Length<32768) {
            var offset=(int)output.Length;var response=card.SmTransmit([0,0xb0,(byte)(offset>>8),(byte)offset,0x80]);
            var status=response.Sw[0]*256+response.Sw[1];
            if(status==0x6b00 && output.Length>0) return output.ToArray();
            if(status is not (0x9000 or 0x6282)) CosmoXCard.CheckSw(response);
            if(response.Data.Length>128) throw new CryptographicException("Invalid metadata response.");
            output.Write(response.Data);if(response.Data.Length<128 || status==0x6282) return output.ToArray();
        }
        throw new CryptographicException("Card metadata exceeds limit.");
    }
}
