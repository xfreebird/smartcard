using System.Security.Cryptography;

namespace MoldSign.Core;

/// <summary>PKCS#1 v1.5 DigestInfo builders. The card's INTERNAL AUTHENTICATE signs a DigestInfo.</summary>
public static class DigestInfo
{
    /// <summary>DER prefix of <c>DigestInfo { AlgorithmIdentifier sha256 NULL, OCTET STRING(32) }</c>.</summary>
    public static ReadOnlySpan<byte> Sha256Prefix =>
    [
        0x30, 0x31, 0x30, 0x0D, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01,
        0x65, 0x03, 0x04, 0x02, 0x01, 0x05, 0x00, 0x04, 0x20,
    ];

    /// <summary>DigestInfo(SHA-256) of <paramref name="message"/> (hashes it first).</summary>
    public static byte[] Sha256(ReadOnlySpan<byte> message) => ForSha256Hash(SHA256.HashData(message));

    /// <summary>DigestInfo(SHA-256) around an already computed 32-byte hash.</summary>
    public static byte[] ForSha256Hash(ReadOnlySpan<byte> hash)
    {
        if (hash.Length != SHA256.HashSizeInBytes)
            throw new ArgumentException($"SHA-256 hash must be 32 bytes (got {hash.Length}).", nameof(hash));
        var output = new byte[Sha256Prefix.Length + hash.Length];
        Sha256Prefix.CopyTo(output);
        hash.CopyTo(output.AsSpan(Sha256Prefix.Length));
        return output;
    }
}
