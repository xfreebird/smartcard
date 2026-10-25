using System.Security.Cryptography;

namespace MoldSign.Core;

/// <summary>
/// AES block primitives without padding, mirroring the Swift <c>AES</c> struct (CommonCrypto shim):
/// single/multi-block ECB encrypt, CBC encrypt/decrypt. Inputs must be a multiple of 16 bytes.
/// </summary>
public static class AesPrimitives
{
    public const int BlockSize = 16;

    /// <summary>AES-ECB encrypt (used for the SM IV: <c>IV = AES-ECB(sessENC, SSC)</c>).</summary>
    public static byte[] EncryptEcb(ReadOnlySpan<byte> key, ReadOnlySpan<byte> data)
    {
        RequireBlocks(data, nameof(data));
        using var aes = Create(key);
        return aes.EncryptEcb(data, PaddingMode.None);
    }

    /// <summary>AES-CBC encrypt, no padding.</summary>
    public static byte[] EncryptCbc(ReadOnlySpan<byte> key, ReadOnlySpan<byte> iv, ReadOnlySpan<byte> data)
    {
        RequireBlocks(data, nameof(data));
        RequireIv(iv);
        using var aes = Create(key);
        return aes.EncryptCbc(data, iv, PaddingMode.None);
    }

    /// <summary>AES-CBC decrypt, no padding.</summary>
    public static byte[] DecryptCbc(ReadOnlySpan<byte> key, ReadOnlySpan<byte> iv, ReadOnlySpan<byte> data)
    {
        RequireBlocks(data, nameof(data));
        RequireIv(iv);
        using var aes = Create(key);
        return aes.DecryptCbc(data, iv, PaddingMode.None);
    }

    /// <summary>XOR of the common prefix of two buffers (Swift <c>AES.xorBytes</c>).</summary>
    public static byte[] Xor(ReadOnlySpan<byte> a, ReadOnlySpan<byte> b)
    {
        var n = Math.Min(a.Length, b.Length);
        var output = new byte[n];
        for (var i = 0; i < n; i++) output[i] = (byte)(a[i] ^ b[i]);
        return output;
    }

    internal static Aes Create(ReadOnlySpan<byte> key)
    {
        if (key.Length is not (16 or 24 or 32))
            throw new ArgumentException($"AES key must be 16, 24 or 32 bytes (got {key.Length}).", nameof(key));
        var aes = Aes.Create();
        aes.Key = key.ToArray();
        return aes;
    }

    private static void RequireBlocks(ReadOnlySpan<byte> data, string name)
    {
        if (data.Length % BlockSize != 0)
            throw new ArgumentException($"Input length {data.Length} is not a multiple of {BlockSize}.", name);
    }

    private static void RequireIv(ReadOnlySpan<byte> iv)
    {
        if (iv.Length != BlockSize)
            throw new ArgumentException($"IV must be {BlockSize} bytes (got {iv.Length}).", nameof(iv));
    }
}
