using System.Security.Cryptography;
using System.Text;

namespace MoldSign.Core.Protection;

/// <summary>MoldSign Desktop AES password envelope. Legacy CBC is unauthenticated.</summary>
public static class PasswordFileProtection
{
    public const int MaximumSize = 64 * 1024 * 1024 - 128;
    public const string Suffix = ".symmetric.p7m";
    private static byte[] Marker(int bits) => SHA512.HashData(Encoding.ASCII.GetBytes(bits.ToString(System.Globalization.CultureInfo.InvariantCulture)));
    public static byte[] Encrypt(byte[] plaintext, ReadOnlySpan<char> password)
    {
        if (password.IsEmpty) throw new ArgumentException("Enter a password.");
        if (plaintext.Length > MaximumSize) throw new ArgumentException("Choose a file smaller than 64 MB.");
        var salt = RandomNumberGenerator.GetBytes(16);
        salt[1] = 0xff; // Vendor ASN.1 fallback guard; remaining 120 salt bits are random.
        var iv = RandomNumberGenerator.GetBytes(16);
        var content = Crypt(plaintext, password, salt, iv, 256, true);
        return [..salt, ..iv, ..Marker(256), ..content];
    }
    public static byte[] Decrypt(byte[] envelope, ReadOnlySpan<char> password)
    {
        if (envelope.Length > MaximumSize + 8192) throw new ArgumentException("Choose a file smaller than 64 MB.");
        if (envelope.Length < 112 || (envelope.Length - 96) % 16 != 0) return Legacy(envelope,password);
        var bits = new[] {128, 192, 256}.FirstOrDefault(b => CryptographicOperations.FixedTimeEquals(Marker(b), envelope.AsSpan(32, 64)));
        if (bits == 0) return Legacy(envelope,password);
        return Crypt(envelope[96..], password, envelope[..16], envelope[16..32], bits, false);
    }
    private static byte[] Legacy(byte[] envelope, ReadOnlySpan<char> password) {
        if(envelope.Length<2 || envelope[0]!=0x30) throw new ArgumentException("Unsupported or damaged encrypted file.");
        try { return LegacyPasswordProtection.Decrypt(envelope,password); }
        catch(System.Formats.Asn1.AsnContentException error) { throw new ArgumentException("Unsupported or damaged encrypted file.",error); }
    }
    private static byte[] Crypt(byte[] input, ReadOnlySpan<char> password, byte[] salt, byte[] iv, int bits, bool encrypt)
    {
        var key = Derive(password, salt, bits / 8);
        try
        {
            using var aes = Aes.Create();
            aes.Key = key;
            return encrypt ? aes.EncryptCbc(input, iv, PaddingMode.PKCS7) : aes.DecryptCbc(input, iv, PaddingMode.PKCS7);
        }
        catch (CryptographicException) { throw new CryptographicException("Unable to decrypt. Check the password and the file."); }
        finally { CryptographicOperations.ZeroMemory(key); }
    }
    private static byte[] Derive(ReadOnlySpan<char> password, byte[] salt, int length)
    {
        if (password.Length >= 2048) throw new ArgumentException("Password is too long.");
        var p = password.IsEmpty ? [] : new byte[(password.Length + 1) * 2];
        for (var i = 0; i < password.Length; i++) { p[i*2] = (byte)(password[i] >> 8); p[i*2+1] = (byte)password[i]; }
        var expanded = p.Length == 0 ? 0 : 64 * ((p.Length + 63) / 64);
        var material = new byte[128 + expanded];
        Array.Fill(material, (byte)1, 0, 64);
        for (var i = 0; i < 64; i++) material[64+i] = salt[i % 16];
        for (var i = 0; i < expanded; i++) material[128+i] = p[i % p.Length];
        var a = SHA256.HashData(material);
        try
        {
            for (var i = 1; i < 65537; i++) { var next = SHA256.HashData(a); CryptographicOperations.ZeroMemory(a); a = next; }
            return a[..length];
        }
        finally { CryptographicOperations.ZeroMemory(a); CryptographicOperations.ZeroMemory(p); CryptographicOperations.ZeroMemory(material); }
    }
}
