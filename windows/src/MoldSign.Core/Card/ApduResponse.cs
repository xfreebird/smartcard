namespace MoldSign.Core;

/// <summary>Response body plus status word bytes (normally 2 bytes: SW1 SW2).</summary>
public readonly struct ApduResponse
{
    public ApduResponse(byte[] data, byte[] sw)
    {
        Data = data ?? [];
        Sw = sw ?? [];
    }

    public byte[] Data { get; }

    /// <summary>Raw status bytes. In SM responses this is the content of tag 99 when present.</summary>
    public byte[] Sw { get; }

    /// <summary>SW1SW2 as a number, or 0 when <see cref="Sw"/> is not exactly two bytes.</summary>
    public ushort StatusWord => Sw.Length == 2 ? (ushort)((Sw[0] << 8) | Sw[1]) : (ushort)0;

    public bool IsSuccess => StatusWord == 0x9000;

    /// <summary>Splits a raw transport response (data || SW1 SW2).</summary>
    public static ApduResponse FromRaw(ReadOnlySpan<byte> raw)
    {
        if (raw.Length < 2)
            throw new CardException(CardErrorKind.CardNotResponding,
                $"Card response too short ({raw.Length} byte(s))");
        return new ApduResponse(raw[..^2].ToArray(), raw[^2..].ToArray());
    }

    public override string ToString() => $"{Hex.Encode(Data)} SW={Hex.Encode(Sw)}";
}
