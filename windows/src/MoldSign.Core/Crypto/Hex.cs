namespace MoldSign.Core;

/// <summary>Hex helpers. Upper-case output, no separators (the format of <c>spec/vectors</c>).</summary>
public static class Hex
{
    /// <summary>Decodes hex, ignoring ASCII whitespace. Throws <see cref="FormatException"/> on odd length or bad digits.</summary>
    public static byte[] Decode(string hex)
    {
        ArgumentNullException.ThrowIfNull(hex);
        if (hex.Length == 0) return [];
        var compact = hex.Any(char.IsWhiteSpace)
            ? string.Concat(hex.Where(c => !char.IsWhiteSpace(c)))
            : hex;
        if (compact.Length % 2 != 0) throw new FormatException("Hex string has an odd number of digits.");
        return Convert.FromHexString(compact);
    }

    /// <summary>Upper-case hex without separators.</summary>
    public static string Encode(ReadOnlySpan<byte> bytes) => Convert.ToHexString(bytes);
}
