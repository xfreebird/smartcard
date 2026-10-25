using System.Text.Json;
using static MoldSign.Core.Tests.VectorFile;

namespace MoldSign.Core.Tests;

/// <summary>spec/vectors/card-crypto.json: constants, kdf, external_auth, response_decode, session_keys, cmac, iso9797, digest_info.</summary>
public class CryptoVectorTests
{
    [Fact]
    public void Constants_match_the_driver()
    {
        Assert.Equal(Bytes("constants", "ias_aid"), CosmoXCard.IasAid.ToArray());
        Assert.Equal(Bytes("constants", "generic_adf"), CosmoXCard.GenericAdf.ToArray());
        Assert.Equal(Bytes("constants", "mk_class"), IasEcc.MkClass.ToArray());
        Assert.Equal(Bytes("constants", "rnd_ifd"), IasEcc.RndIfd.ToArray());
        Assert.Equal(Bytes("constants", "sn_ifd"), IasEcc.SnIfd.ToArray());
        Assert.Equal(Bytes("constants", "k_ifd"), IasEcc.KIfd.ToArray());
        Assert.Equal(Bytes("constants", "mse_sm_apdu"), CosmoXCard.MseSetSmApdu.ToArray());
        Assert.Equal(Bytes("constants", "mse_sign_data"), CosmoXCard.MseSignData.ToArray());
        Assert.Equal(Bytes("constants", "pin_reference"), new[] { CosmoXCard.PinReference });
    }

    [Fact]
    public void Kdf_derives_admin_keys()
    {
        var (kenc, kmac) = IasEcc.DeriveAdminKeys(Ascii("kdf", "seed_ascii"), Ascii("kdf", "serial_ascii"));
        Assert.Equal(String("kdf", "kenc"), Hex.Encode(kenc));
        Assert.Equal(String("kdf", "kmac"), Hex.Encode(kmac));
    }

    [Fact]
    public void External_authenticate_ciphertext_and_cmac()
    {
        var payload = IasEcc.BuildExternalAuthenticateData(
            Bytes("kdf", "kenc"), Bytes("kdf", "kmac"),
            Bytes("external_auth", "rnd_icc"), Ascii("external_auth", "sn_icc_ascii"));

        Assert.Equal(96, payload.Length);
        Assert.Equal(String("external_auth", "ciphertext"), Hex.Encode(payload.AsSpan(0, 80)));
        Assert.Equal(String("external_auth", "cmac"), Hex.Encode(payload.AsSpan(80, 16)));
    }

    [Fact]
    public void External_authenticate_ciphertext_is_cbc_with_zero_iv_over_the_documented_layout()
    {
        byte[] plain =
        [
            .. IasEcc.RndIfd, .. IasEcc.SnIfd, .. Bytes("external_auth", "rnd_icc"),
            .. Ascii("external_auth", "sn_icc_ascii"), .. IasEcc.KIfd,
        ];
        var ct = AesPrimitives.EncryptCbc(Bytes("kdf", "kenc"), new byte[16], plain);
        Assert.Equal(String("external_auth", "ciphertext"), Hex.Encode(ct));
        Assert.Equal(plain, AesPrimitives.DecryptCbc(Bytes("kdf", "kenc"), new byte[16], ct));
    }

    [Fact]
    public void Response_decode_verifies_mac_and_recovers_the_challenge()
    {
        var response = Bytes("response_decode", "response");
        Assert.Equal(96, response.Length);
        Assert.Equal(Hex.Encode(response.AsSpan(80, 16)),
                     Hex.Encode(Cmac.Compute(Bytes("kdf", "kmac"), response.AsSpan(0, 80))));

        var plain = IasEcc.OpenExternalAuthenticateResponse(Bytes("kdf", "kenc"), Bytes("kdf", "kmac"), response);
        Assert.Equal(80, plain.Length);
        Assert.Equal(String("response_decode", "challenge"), Hex.Encode(plain.AsSpan(0, 16)));
    }

    [Fact]
    public void Response_decode_rejects_a_tampered_mac()
    {
        var response = Bytes("response_decode", "response");
        response[^1] ^= 0x01;
        var e = Assert.Throws<CardException>(() =>
            IasEcc.OpenExternalAuthenticateResponse(Bytes("kdf", "kenc"), Bytes("kdf", "kmac"), response));
        Assert.Equal(CardErrorKind.SmOutOfSync, e.Kind);
    }

    [Fact]
    public void Session_keys_from_k_icc()
    {
        var (sessEnc, sessMac) = IasEcc.DeriveSessionKeys(Bytes("session_keys", "k_icc"));
        Assert.Equal(String("session_keys", "sess_enc"), Hex.Encode(sessEnc));
        Assert.Equal(String("session_keys", "sess_mac"), Hex.Encode(sessMac));
    }

    public static TheoryData<string, string> CmacCases()
    {
        var data = new TheoryData<string, string>();
        foreach (var c in Root.GetProperty("cmac").GetProperty("cases").EnumerateArray())
            data.Add(c.GetProperty("message").GetString()!, c.GetProperty("tag").GetString()!);
        return data;
    }

    [Theory]
    [MemberData(nameof(CmacCases))]
    public void Cmac_nist_sp800_38b_aes256(string message, string tag) =>
        Assert.Equal(tag, Hex.Encode(Cmac.Compute(Bytes("cmac", "key"), Hex.Decode(message))));

    /// <summary>RFC 4493 §4 (AES-128) examples: extra coverage of the 0/16/40/64-byte branches.</summary>
    [Theory]
    [InlineData("", "BB1D6929E95937287FA37D129B756746")]
    [InlineData("6BC1BEE22E409F96E93D7E117393172A", "070A16B46B4D4144F79BDD9DD04A287C")]
    [InlineData("6BC1BEE22E409F96E93D7E117393172AAE2D8A571E03AC9C9EB76FAC45AF8E5130C81C46A35CE411",
                "DFA66747DE9AE63030CA32611497C827")]
    [InlineData("6BC1BEE22E409F96E93D7E117393172AAE2D8A571E03AC9C9EB76FAC45AF8E5130C81C46A35CE411E5FBC1191A0A52EFF69F2445DF4F9B17AD2B417BE66C3710",
                "51F0BEBF7E3B9D92FC49741779363CFE")]
    public void Cmac_rfc4493_aes128(string message, string tag) =>
        Assert.Equal(tag, Hex.Encode(Cmac.Compute(Hex.Decode("2B7E151628AED2A6ABF7158809CF4F3C"), Hex.Decode(message))));

    public static TheoryData<string, string> Iso9797Cases()
    {
        var data = new TheoryData<string, string>();
        foreach (var c in Root.GetProperty("iso9797").EnumerateArray())
            data.Add(c.GetProperty("input").GetString()!, c.GetProperty("padded").GetString()!);
        return data;
    }

    [Theory]
    [MemberData(nameof(Iso9797Cases))]
    public void Iso9797_method2_padding(string input, string padded)
    {
        Assert.Equal(padded, Hex.Encode(Iso9797.Pad(Hex.Decode(input))));
        Assert.Equal(input, Hex.Encode(Iso9797.Unpad(Hex.Decode(padded))));
    }

    [Fact]
    public void Digest_info_sha256()
    {
        var di = DigestInfo.Sha256(Ascii("digest_info", "message_ascii"));
        Assert.Equal(String("digest_info", "digest_info"), Hex.Encode(di));
        Assert.Equal(51, di.Length);
    }

    [Fact]
    public void Vector_file_version_is_supported() =>
        Assert.Equal(1, Root.GetProperty("version").GetInt32());

    [Fact]
    public void Every_vector_hex_field_is_valid_hex()
    {
        // Guards against silently skipping a malformed field.
        static IEnumerable<(string Path, string Value)> Walk(JsonElement e, string path)
        {
            switch (e.ValueKind)
            {
                case JsonValueKind.Object:
                    foreach (var p in e.EnumerateObject())
                        foreach (var x in Walk(p.Value, $"{path}.{p.Name}")) yield return x;
                    break;
                case JsonValueKind.Array:
                    var i = 0;
                    foreach (var item in e.EnumerateArray())
                        foreach (var x in Walk(item, $"{path}[{i++}]")) yield return x;
                    break;
                case JsonValueKind.String:
                    yield return (path, e.GetString()!);
                    break;
            }
        }

        var hexFields = Walk(Root, "$")
            .Where(f => !f.Path.EndsWith(".comment") && !f.Path.EndsWith(".description") &&
                        !f.Path.EndsWith(".name") && !f.Path.EndsWith("_ascii"))
            .ToList();
        Assert.NotEmpty(hexFields);
        foreach (var (path, value) in hexFields)
        {
            var ex = Record.Exception(() => Hex.Decode(value));
            Assert.True(ex is null, $"{path} is not hex: {value}");
        }
    }
}
