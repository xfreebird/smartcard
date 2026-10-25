namespace MoldSign.Core;

/// <summary>ISO/IEC 9797-1 padding method 2 (0x80 then zeros), as used by IAS/ECC secure messaging.</summary>
public static class Iso9797
{
    /// <summary>Appends 0x80 and zero bytes up to the next block boundary (always adds at least one byte).</summary>
    public static byte[] Pad(ReadOnlySpan<byte> data, int blockSize = AesPrimitives.BlockSize)
    {
        var paddedLength = (data.Length / blockSize + 1) * blockSize;
        var output = new byte[paddedLength];
        data.CopyTo(output);
        output[data.Length] = 0x80;
        return output;
    }

    /// <summary>
    /// Strips trailing zeros, then one 0x80 if present. Lenient on purpose, exactly like the Swift
    /// reference (<c>AES.iso9797Unpad</c>): input without a 0x80 marker loses its trailing zeros.
    /// </summary>
    public static byte[] Unpad(ReadOnlySpan<byte> data)
    {
        var end = data.Length;
        while (end > 0 && data[end - 1] == 0x00) end--;
        if (end > 0 && data[end - 1] == 0x80) end--;
        return data[..end].ToArray();
    }
}
