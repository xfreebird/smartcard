using System.Text.Json;
using MoldSign.Desktop;

namespace MoldSign.Core.Tests;

/// <summary>Phase TOK: the C# table equals spec/tokens/token-families.json, its vectors hold, and the gate sends no APDU.</summary>
public class TokenRecognitionTests
{
    private const string EPass2003Atr = "3B9F958131FE9F006646530500000071DF000000000000";
    private const string CosmoXAtr = "3BDF96008131FE4580738421E0574D44415F415350810F78";

    private static JsonElement Spec() => JsonDocument.Parse(
        File.ReadAllText(Path.Combine(VectorFile.RepoRoot, "spec", "tokens", "token-families.json"))).RootElement;

    [Fact]
    public void Table_matches_the_spec()
    {
        var fromSpec = new List<string>();
        foreach (var family in Spec().GetProperty("families").EnumerateArray())
        {
            var id = family.GetProperty("id").GetString()!;
            var known = Enum.GetValues<TokenFamily>().Single(f => f.Id() == id);
            Assert.Equal(family.GetProperty("name").GetString(), known.DisplayName());
            foreach (var pattern in family.GetProperty("patterns").EnumerateArray())
                fromSpec.Add($"{id} {pattern.GetProperty("atr").GetString()} {pattern.GetProperty("mask").GetString()}");
        }
        var table = TokenRecognizer.Patterns
            .Select(p => $"{p.Family.Id()} {Hex.Encode(p.Pattern.Atr)} {Hex.Encode(p.Pattern.Mask)}").ToList();
        Assert.Equal(fromSpec, table);
    }

    [Fact]
    public void Vectors_hold()
    {
        var vectors = Spec().GetProperty("vectors").EnumerateArray().ToList();
        Assert.NotEmpty(vectors);
        foreach (var vector in vectors)
        {
            var expected = vector.GetProperty("family").ValueKind == JsonValueKind.Null ? null : vector.GetProperty("family").GetString();
            var actual = TokenRecognizer.Family(Hex.Decode(vector.GetProperty("atr").GetString()!))?.Id();
            Assert.Equal(expected, actual);
        }
        Assert.Null(TokenRecognizer.Family(null));
    }

    [Fact]
    public void A_recognized_token_gets_no_apdu_when_enabled()
    {
        var token = new RecordingTransport(Hex.Decode(EPass2003Atr));
        var service = new SigningService(() => token) { ExperimentalTokens = true };

        var e = Assert.Throws<CardException>(() => service.Certificate());

        Assert.Equal(CardErrorKind.UnsupportedToken, e.Kind);
        Assert.Contains("Feitian ePass2003", e.Message);
        Assert.Empty(token.Sent);
        Assert.True(token.Disposed);
    }

    [Fact]
    public void Disabled_keeps_the_eid_path()
    {
        var token = new RecordingTransport(Hex.Decode(EPass2003Atr));
        var service = new SigningService(() => token);

        Assert.False(service.ExperimentalTokens);
        var e = Assert.Throws<CardException>(() => service.Certificate());

        Assert.NotEqual(CardErrorKind.UnsupportedToken, e.Kind);
        Assert.NotEmpty(token.Sent);
    }

    [Fact]
    public void The_eid_is_never_a_token()
    {
        var eid = new RecordingTransport(Hex.Decode(CosmoXAtr));
        var service = new SigningService(() => eid) { ExperimentalTokens = true };

        var e = Assert.Throws<CardException>(() => service.Certificate());

        Assert.NotEqual(CardErrorKind.UnsupportedToken, e.Kind);
        Assert.NotEmpty(eid.Sent);
    }

    [Fact]
    public void Derived_preferences_survive_a_save()
    {
        var path = Path.Combine(Path.GetTempPath(), $"esemnbun-prefs-{Guid.NewGuid():N}.json");
        try
        {
            var store = new DesktopPreferenceStore(path);
            store.Save(new AppLikePreferences { ExperimentalTokensEnabled = true });

            Assert.True(store.Load<AppLikePreferences>().ExperimentalTokensEnabled);
            Assert.NotNull(store.Load<DesktopPreferences>());
        }
        finally
        {
            File.Delete(path);
        }
    }

    private sealed class AppLikePreferences : DesktopPreferences
    {
        public bool ExperimentalTokensEnabled { get; set; }
    }

    /// <summary>Answers every APDU with 6A82, like a token asked for the IAS/ECC application.</summary>
    private sealed class RecordingTransport(byte[] atr) : ICardTransport
    {
        public List<byte[]> Sent { get; } = [];
        public bool Disposed { get; private set; }
        public string ReaderName => "Recording reader";
        public byte[]? Atr => atr;

        public byte[] Transmit(byte[] apdu)
        {
            Sent.Add(apdu);
            return [0x6A, 0x82];
        }

        public void Dispose() => Disposed = true;
    }
}
