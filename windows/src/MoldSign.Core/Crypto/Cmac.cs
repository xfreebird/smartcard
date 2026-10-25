using System.Security.Cryptography;

namespace MoldSign.Core;

/// <summary>
/// AES-CMAC per RFC 4493 / NIST SP 800-38B, full 16-byte tag.
/// </summary>
/// <remarks>
/// The Swift reference (<c>c_aes256_cmac</c> in <c>cpcsc.c</c>) mishandles the EMPTY message: it
/// writes the 0x80 pad byte at index 16 (out of bounds) and leaves the last block all-zero.
/// The card protocol never MACs an empty message (SM always pads), so this port follows the RFC
/// instead, and <c>spec/vectors/card-crypto.json</c> checks NIST's empty case.
/// </remarks>
public static class Cmac
{
    private const int Block = AesPrimitives.BlockSize;

    /// <summary>Full 16-byte AES-CMAC of <paramref name="message"/>.</summary>
    public static byte[] Compute(ReadOnlySpan<byte> key, ReadOnlySpan<byte> message)
    {
        using var aes = AesPrimitives.Create(key);

        // Subkeys: L = AES(K, 0^128); K1 = dbl(L); K2 = dbl(K1).
        Span<byte> l = stackalloc byte[Block];
        Span<byte> zero = stackalloc byte[Block];
        zero.Clear();
        aes.EncryptEcb(zero, l, PaddingMode.None);
        Span<byte> k1 = stackalloc byte[Block];
        Span<byte> k2 = stackalloc byte[Block];
        Double(l, k1);
        Double(k1, k2);

        var n = (message.Length + Block - 1) / Block;
        bool lastComplete;
        if (n == 0)
        {
            n = 1;
            lastComplete = false;
        }
        else
        {
            lastComplete = message.Length % Block == 0;
        }

        Span<byte> last = stackalloc byte[Block];
        last.Clear();
        var lastStart = (n - 1) * Block;
        if (lastComplete)
        {
            for (var i = 0; i < Block; i++) last[i] = (byte)(message[lastStart + i] ^ k1[i]);
        }
        else
        {
            var rem = message.Length - lastStart; // 0..15 (0 only for the empty message)
            message.Slice(lastStart, rem).CopyTo(last);
            last[rem] = 0x80;
            for (var i = 0; i < Block; i++) last[i] ^= k2[i];
        }

        Span<byte> x = stackalloc byte[Block];
        x.Clear();
        Span<byte> y = stackalloc byte[Block];
        for (var b = 0; b < n - 1; b++)
        {
            var m = message.Slice(b * Block, Block);
            for (var i = 0; i < Block; i++) y[i] = (byte)(x[i] ^ m[i]);
            aes.EncryptEcb(y, x, PaddingMode.None);
        }

        for (var i = 0; i < Block; i++) y[i] = (byte)(x[i] ^ last[i]);
        var tag = new byte[Block];
        aes.EncryptEcb(y, tag, PaddingMode.None);
        return tag;
    }

    /// <summary>GF(2^128) doubling with the R128 constant 0x87.</summary>
    internal static void Double(ReadOnlySpan<byte> input, Span<byte> output)
    {
        for (var i = 0; i < Block - 1; i++)
            output[i] = (byte)((input[i] << 1) | (input[i + 1] >> 7));
        output[Block - 1] = (byte)(input[Block - 1] << 1);
        if ((input[0] & 0x80) != 0) output[Block - 1] ^= 0x87;
    }
}
