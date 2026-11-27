namespace MoldSign.Core;

/// <summary>
/// USB signing tokens recognized by ATR (Phase TOK, experimental, off by default). Port of the Swift
/// <c>TokenRecognition.swift</c>; the table mirrors <c>spec/tokens/token-families.json</c>, whose ATRs come from the
/// token modules of MoldSign Desktop Suite 2.4.12 and are not yet confirmed on a real token. Recognition only: no
/// token driver exists yet, so a recognized token fails with <see cref="CardErrorKind.UnsupportedToken"/> before
/// any APDU.
/// </summary>
public enum TokenFamily
{
    EPass2003,
    SafeNetJava,
    IdPrime,
}

public static class TokenFamilies
{
    /// <summary>Identifier used by the spec file.</summary>
    public static string Id(this TokenFamily family) => family switch
    {
        TokenFamily.EPass2003 => "epass2003",
        TokenFamily.SafeNetJava => "safenet-etoken-java",
        TokenFamily.IdPrime => "idprime",
        _ => throw new ArgumentOutOfRangeException(nameof(family)),
    };

    /// <summary>Product name for the UI (not translated).</summary>
    public static string DisplayName(this TokenFamily family) => family switch
    {
        TokenFamily.EPass2003 => "Feitian ePass2003",
        TokenFamily.SafeNetJava => "SafeNet eToken",
        TokenFamily.IdPrime => "SafeNet IDPrime",
        _ => throw new ArgumentOutOfRangeException(nameof(family)),
    };
}

/// <summary>A candidate of the same length matches when <c>(candidate &amp; mask) == (atr &amp; mask)</c> byte by byte.</summary>
public sealed class AtrPattern(string atrHex, string maskHex)
{
    private readonly byte[] _atr = Hex.Decode(atrHex);
    private readonly byte[] _mask = Hex.Decode(maskHex);

    public ReadOnlySpan<byte> Atr => _atr;
    public ReadOnlySpan<byte> Mask => _mask;

    public bool Matches(ReadOnlySpan<byte> candidate)
    {
        if (candidate.Length != _atr.Length || _mask.Length != _atr.Length) return false;
        for (var i = 0; i < candidate.Length; i++)
        {
            if ((candidate[i] & _mask[i]) != (_atr[i] & _mask[i])) return false;
        }
        return true;
    }
}

public static class TokenRecognizer
{
    private const string Exact14 = "FFFFFFFFFFFFFFFFFFFFFFFFFFFF";

    /// <summary>Keep in sync with the spec file (TokenRecognitionTests compares them).</summary>
    public static IReadOnlyList<(TokenFamily Family, AtrPattern Pattern)> Patterns { get; } = new (TokenFamily, AtrPattern)[]
    {
        (TokenFamily.EPass2003, new AtrPattern("3B9F958131FE9F006646530500000071DF000000000000",
                                               "FFFFFFFFFFFFFFFFFFFFFFFF000000FFFFFFFFFFFFFF00")),
        (TokenFamily.SafeNetJava, new AtrPattern("3BD518008131FE7D8073C82110F4", Exact14)),
        (TokenFamily.SafeNetJava, new AtrPattern("3BD5180081313A7D8073C8211030", Exact14)),
        (TokenFamily.SafeNetJava, new AtrPattern("3BD518008131FE7D68BF81AA4547", Exact14)),
        (TokenFamily.SafeNetJava, new AtrPattern("3BD5180081313A7D68BF81AA4583", Exact14)),
        (TokenFamily.SafeNetJava, new AtrPattern("3BD518008131FE7DDE2D8E7400F7", Exact14)),
        (TokenFamily.SafeNetJava, new AtrPattern("3BD5180081313A7DDE2D8E740033", Exact14)),
        (TokenFamily.SafeNetJava, new AtrPattern("3BD518008131FE7D9DAB4639D661", Exact14)),
        (TokenFamily.SafeNetJava, new AtrPattern("3BD5180081313A7D9DAB4639D6A5", Exact14)),
        (TokenFamily.IdPrime, new AtrPattern("3BFF9600008131FE4380318065B00000000012917882900069",
                                             "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF")),
        (TokenFamily.IdPrime, new AtrPattern("3BFF0000008131004380318065B00000000012021082900000",
                                             "FFFF00FFFFFFFF00FFFFFFFFFFFF00000000FFFFFFFFFFFF00")),
    };

    /// <summary>The token family for this ATR, or null (an eID card, another card, or no ATR).</summary>
    public static TokenFamily? Family(byte[]? atr)
    {
        if (atr is null || atr.Length == 0) return null;
        foreach (var (family, pattern) in Patterns)
        {
            if (pattern.Matches(atr)) return family;
        }
        return null;
    }
}
