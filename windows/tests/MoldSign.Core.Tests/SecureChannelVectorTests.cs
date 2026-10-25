using static MoldSign.Core.Tests.VectorFile;

namespace MoldSign.Core.Tests;

/// <summary>spec/vectors/card-crypto.json "sm": every wrap case from a FRESH channel, then unwrap.</summary>
public class SecureChannelVectorTests
{
    internal static SecureChannel FreshChannel() =>
        new(Bytes("sm", "sess_enc"), Bytes("sm", "sess_mac"), Bytes("sm", "ssc_initial"));

    [Fact]
    public void Sm_keys_are_the_session_keys_vector()
    {
        Assert.Equal(String("session_keys", "sess_enc"), String("sm", "sess_enc"));
        Assert.Equal(String("session_keys", "sess_mac"), String("sm", "sess_mac"));
    }

    [Fact]
    public void Iv_for_ssc_initial_is_ecb_of_the_ssc()
    {
        var iv = AesPrimitives.EncryptEcb(Bytes("sm", "sess_enc"), Bytes("sm", "ssc_initial"));
        Assert.Equal(String("sm", "iv_for_ssc_initial"), Hex.Encode(iv));
    }

    public static TheoryData<string, string, string> WrapCases()
    {
        var data = new TheoryData<string, string, string>();
        foreach (var c in Root.GetProperty("sm").GetProperty("wrap").EnumerateArray())
            data.Add(c.GetProperty("name").GetString()!, c.GetProperty("apdu").GetString()!, c.GetProperty("wrapped").GetString()!);
        return data;
    }

    [Theory]
    [MemberData(nameof(WrapCases))]
    public void Wrap_matches_the_reference(string name, string apdu, string wrapped)
    {
        var channel = FreshChannel();
        var actual = channel.Wrap(Hex.Decode(apdu));
        Assert.True(wrapped == Hex.Encode(actual), $"{name}: expected {wrapped}, got {Hex.Encode(actual)}");

        // SSC advanced exactly once; CLA got the SM bits; Le=00 always appended.
        var expectedSsc = Bytes("sm", "ssc_initial");
        Increment(expectedSsc);
        Assert.Equal(expectedSsc, channel.Ssc);
        Assert.Equal(0x0C, actual[0] & 0x0C);
        Assert.Equal(0x00, actual[^1]);
    }

    [Fact]
    public void Unwrap_checks_mac_with_ssc_plus_two_and_decrypts()
    {
        var channel = FreshChannel();
        channel.Wrap(Hex.Decode(String("sm", "unwrap", "command_before")));
        var response = channel.Unwrap(Bytes("sm", "unwrap", "response"));

        Assert.Equal(String("sm", "unwrap", "data"), Hex.Encode(response.Data));
        Assert.Equal(String("sm", "unwrap", "sw"), Hex.Encode(response.Sw));
        Assert.Equal(0x9000, response.StatusWord);

        var expectedSsc = Bytes("sm", "ssc_initial");
        Increment(expectedSsc);
        Increment(expectedSsc);
        Assert.Equal(expectedSsc, channel.Ssc);
    }

    [Fact]
    public void Unwrap_with_the_wrong_ssc_is_sm_out_of_sync()
    {
        var channel = FreshChannel(); // no command wrapped: SSC is one behind
        var e = Assert.Throws<CardException>(() => channel.Unwrap(Bytes("sm", "unwrap", "response")));
        Assert.Equal(CardErrorKind.SmOutOfSync, e.Kind);
    }

    [Fact]
    public void Unwrap_of_a_tampered_cryptogram_is_sm_out_of_sync()
    {
        var channel = FreshChannel();
        channel.Wrap(Hex.Decode(String("sm", "unwrap", "command_before")));
        var response = Bytes("sm", "unwrap", "response");
        response[5] ^= 0x80;
        var e = Assert.Throws<CardException>(() => channel.Unwrap(response));
        Assert.Equal(CardErrorKind.SmOutOfSync, e.Kind);
    }

    [Fact]
    public void Sw_only_response_is_returned_without_touching_the_ssc()
    {
        var channel = FreshChannel();
        var before = channel.Ssc;
        var response = channel.Unwrap([0x69, 0x85]);
        Assert.Empty(response.Data);
        Assert.Equal(0x6985, response.StatusWord);
        Assert.Equal(before, channel.Ssc);
    }

    [Fact]
    public void Ssc_increment_carries_across_bytes()
    {
        byte[] ssc = [.. new byte[14], 0x00, 0xFF];
        var channel = new SecureChannel(Bytes("sm", "sess_enc"), Bytes("sm", "sess_mac"), ssc);
        Assert.Equal(Hex.Decode("0000000000000000000000000000" + "0100"), channel.IncrementSsc());

        var wrap = new SecureChannel(Bytes("sm", "sess_enc"), Bytes("sm", "sess_mac"), Enumerable.Repeat((byte)0xFF, 16).ToArray());
        Assert.Equal(new byte[16], wrap.IncrementSsc());
    }

    [Fact]
    public void Wrap_rejects_a_truncated_body()
    {
        var channel = FreshChannel();
        Assert.Throws<ArgumentException>(() => channel.Wrap(Hex.Decode("00A4000C043F00")));
    }

    internal static void Increment(byte[] ssc)
    {
        for (var i = ssc.Length - 1; i >= 0; i--)
        {
            if (++ssc[i] != 0) break;
        }
    }
}
