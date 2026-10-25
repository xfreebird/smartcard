using System.Formats.Asn1;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using static MoldSign.Core.Tests.VectorFile;

namespace MoldSign.Core.Tests;

/// <summary>CosmoXCard over fake transports: exact APDU sequence, SW mapping, 61xx loop, certificate read.</summary>
public class CosmoXCardTests
{
    /// <summary>The reference mutual-authentication exchange (10 APDUs) from spec/vectors.</summary>
    internal static (string Apdu, string Response)[] AuthenticationScript()
    {
        var serial = Ascii("kdf", "serial_ascii");
        var seed = Ascii("kdf", "seed_ascii");
        var expectedEa = Hex.Encode([.. Bytes("external_auth", "ciphertext"), .. Bytes("external_auth", "cmac")]);
        return
        [
            ("00A4040010A000000077030C60000000FE0000050000", "9000"),          // SELECT IAS AID
            ("00A4000C023F0000", "9000"),                                      // SELECT MF
            ("00A4020402D00300", "9000"),                                      // SELECT EF D003
            ("00B0000000", "0410" + Hex.Encode(serial) + "9000"),              // serial (tag/len + 16 ASCII)
            ("00A4020402D00400", "9000"),                                      // SELECT EF D004
            ("00B0000010", Hex.Encode(seed) + "9000"),                         // seed
            ("0022C1A4098004FF40108C830104", "9000"),                          // MSE SET (SM)
            ("0084000010", String("external_auth", "rnd_icc") + "9000"),       // GET CHALLENGE
            ("0082000060" + expectedEa, "6160"),                               // EXTERNAL AUTHENTICATE → 61 60
            ("00C0000060", String("response_decode", "response") + "9000"),   // GET RESPONSE (96 bytes)
        ];
    }

    /// <summary>
    /// The session the card side holds after <see cref="AuthenticationScript"/>: K_ICC from the vector response
    /// (opened with the vector admin keys) → session keys, SSC = plain[8..&lt;16] || rnd_ifd[8..&lt;16].
    /// Feeds <see cref="SimulatedSmCard"/> when a test runs the full Authenticate() first.
    /// </summary>
    internal static (byte[] SessEnc, byte[] SessMac, byte[] Ssc) SessionAfterAuthentication()
    {
        var (kenc, kmac) = IasEcc.DeriveAdminKeys(Ascii("kdf", "seed_ascii"), Ascii("kdf", "serial_ascii"));
        var plain = IasEcc.OpenExternalAuthenticateResponse(kenc, kmac, Bytes("response_decode", "response"));
        var (sessEnc, sessMac) = IasEcc.DeriveSessionKeys(plain.AsSpan(48, 32));
        return (sessEnc, sessMac, IasEcc.InitialSsc(plain));
    }

    [Fact]
    public void Authenticate_sends_the_reference_sequence_and_opens_the_channel()
    {
        var serial = Ascii("kdf", "serial_ascii");
        var seed = Ascii("kdf", "seed_ascii");
        var transport = new ScriptedTransport(AuthenticationScript());

        var card = new CosmoXCard(transport);
        card.Authenticate();

        transport.AssertDone();
        Assert.True(card.HasSecureChannel);
        Assert.Equal(serial, card.SerialNumber);
        Assert.Equal(seed, card.RandomSeed);

        // SSC = plain[8..<16] || rnd_ifd[8..<16]; plain[0..<16] is the documented challenge.
        var challenge = Bytes("response_decode", "challenge");
        Assert.Equal([.. challenge[8..16], .. IasEcc.RndIfd[8..16]], card.Channel!.Ssc);
    }

    [Fact]
    public void Authenticate_with_a_bad_card_cryptogram_is_sm_out_of_sync()
    {
        var response = Bytes("response_decode", "response");
        response[0] ^= 0xFF;
        var transport = new ScriptedTransport(
            ("*", "9000"), ("*", "9000"), ("*", "9000"),
            ("*", "0410" + Hex.Encode(Ascii("kdf", "serial_ascii")) + "9000"),
            ("*", "9000"), ("*", Hex.Encode(Ascii("kdf", "seed_ascii")) + "9000"),
            ("*", "9000"), ("*", String("external_auth", "rnd_icc") + "9000"),
            ("*", Hex.Encode(response) + "9000"));

        var card = new CosmoXCard(transport);
        var e = Assert.Throws<CardException>(card.Authenticate);
        Assert.Equal(CardErrorKind.SmOutOfSync, e.Kind);
        Assert.False(card.HasSecureChannel);
    }

    [Fact]
    public void Verify_pin_sends_the_vector_apdu()
    {
        var wrapped = Root.GetProperty("sm").GetProperty("wrap").EnumerateArray()
            .Single(c => c.GetProperty("apdu").GetString() == "00200003083132333435363738")
            .GetProperty("wrapped").GetString()!;
        var transport = new ScriptedTransport((wrapped, "9000"));
        var card = new CosmoXCard(transport) { Channel = SecureChannelVectorTests.FreshChannel() };

        card.VerifyPin("12345678");

        transport.AssertDone();
        // SW-only answer: SSC still advanced for the response (initial + 2).
        var expected = Bytes("sm", "ssc_initial");
        SecureChannelVectorTests.Increment(expected);
        SecureChannelVectorTests.Increment(expected);
        Assert.Equal(expected, card.Channel!.Ssc);
    }

    [Theory]
    [InlineData("63C2", CardErrorKind.WrongPin, 2)]
    [InlineData("63C0", CardErrorKind.WrongPin, 0)]
    [InlineData("6983", CardErrorKind.PinBlocked, 0)]
    [InlineData("6985", CardErrorKind.CardStateStuck, null)]
    [InlineData("6988", CardErrorKind.SmOutOfSync, null)]
    [InlineData("6A82", CardErrorKind.UnexpectedStatus, null)]
    public void Verify_pin_maps_status_words(string sw, CardErrorKind kind, int? remaining)
    {
        var transport = new ScriptedTransport(("*", sw));
        var card = new CosmoXCard(transport) { Channel = SecureChannelVectorTests.FreshChannel() };

        var e = Assert.Throws<CardException>(() => card.VerifyPin("1234"));

        Assert.Equal(kind, e.Kind);
        Assert.Equal(remaining, e.RemainingAttempts);
        Assert.Equal(Convert.ToUInt16(sw, 16), e.StatusWord);
        // 6988 drops the session; the others keep it in sync for the next command.
        Assert.Equal(kind != CardErrorKind.SmOutOfSync, card.HasSecureChannel);
    }

    [Theory]
    [InlineData("123")]
    [InlineData("123456789")]
    [InlineData("12ă4")]
    public void Verify_pin_rejects_bad_formats_without_touching_the_card(string pin)
    {
        var transport = new ScriptedTransport();
        var card = new CosmoXCard(transport) { Channel = SecureChannelVectorTests.FreshChannel() };
        var e = Assert.Throws<CardException>(() => card.VerifyPin(pin));
        Assert.Equal(CardErrorKind.InvalidPinFormat, e.Kind);
        transport.AssertDone();
    }

    [Fact]
    public void Sign_sends_mse_set_then_internal_authenticate()
    {
        var sm = Root.GetProperty("sm").GetProperty("wrap").EnumerateArray().ToList();
        var mse = sm.Single(c => c.GetProperty("name").GetString() == "MSE SET sign template").GetProperty("wrapped").GetString()!;
        var sim = new SimulatedSmCard(Bytes("sm", "sess_enc"), Bytes("sm", "sess_mac"), Bytes("sm", "ssc_initial"))
        {
            InternalAuthenticate = digestInfo => SHA256.HashData(digestInfo).Concat(new byte[480]).ToArray(),
        };
        var card = new CosmoXCard(sim) { Channel = SecureChannelVectorTests.FreshChannel() };
        var digestInfo = Bytes("digest_info", "digest_info");

        var signature = card.Sign(digestInfo);

        Assert.Equal(512, signature.Length);
        Assert.Equal(SHA256.HashData(digestInfo), signature[..32]);
        Assert.Equal(mse, Hex.Encode(sim.Commands[0]));
        Assert.Equal(0x88, sim.Commands[1][1]);
        Assert.True(sim.GetResponseCount > 0, "a 512-byte SM response must come back through GET RESPONSE");
    }

    [Fact]
    public void Read_certificate_returns_the_full_outer_sequence_and_survives_chunks_ending_in_00_or_80()
    {
        // DER-shaped EF content: 30 82 LLLL 30 82 ..., 1799 bytes like the reference card, with the bytes
        // at the 128-byte chunk boundaries forced to 00 / 80 (the Swift double-unpad would truncate them).
        var file = new byte[1799];
        RandomNumberGenerator.Fill(file);
        file[0] = 0x30; file[1] = 0x82; file[2] = (1799 - 4) >> 8; file[3] = (1799 - 4) & 0xFF;
        file[4] = 0x30; file[5] = 0x82;
        file[15] = 0x00;            // end of the 16-byte header read
        file[4 + 128 - 1] = 0x00;   // end of chunk 1
        file[4 + 256 - 2] = 0x80;   // "80 00" tail at the end of chunk 2
        file[4 + 256 - 1] = 0x00;
        file[4 + 384 - 1] = 0x80;   // end of chunk 3

        var sim = new SimulatedSmCard(Bytes("sm", "sess_enc"), Bytes("sm", "sess_mac"), Bytes("sm", "ssc_initial"))
        {
            EfContent = file,
        };
        var card = new CosmoXCard(sim) { Channel = SecureChannelVectorTests.FreshChannel() };

        var der = card.ReadCertificate();

        Assert.Equal(file, der);
        // SELECT MF, SELECT ADF (P2=04), SELECT EF 0001, then READ BINARY 0/16 and 4/128 chunks.
        Assert.Equal("A4000C", Hex.Encode(sim.Commands[0].AsSpan(1, 3)));
        Assert.Equal("A40404", Hex.Encode(sim.Commands[1].AsSpan(1, 3)));
        Assert.Equal("A40204", Hex.Encode(sim.Commands[2].AsSpan(1, 3)));
        Assert.Equal((0, 16), sim.Reads[0]);
        Assert.Equal((4, 128), sim.Reads[1]);
        Assert.Equal((4 + 14 * 128, 1795 - 14 * 128), sim.Reads[^1]);
        Assert.Equal(1 + 15, sim.Reads.Count);
    }

    [Fact]
    public void Read_certificate_rejects_a_file_that_is_not_a_sequence()
    {
        var sim = new SimulatedSmCard(Bytes("sm", "sess_enc"), Bytes("sm", "sess_mac"), Bytes("sm", "ssc_initial"))
        {
            EfContent = Enumerable.Repeat((byte)0xFF, 64).ToArray(),
        };
        var card = new CosmoXCard(sim) { Channel = SecureChannelVectorTests.FreshChannel() };
        var e = Assert.Throws<CardException>(() => card.ReadCertificate());
        Assert.Equal(CardErrorKind.UnexpectedResponse, e.Kind);
    }

    [Fact]
    public void Sm_transmit_without_authentication_fails_cleanly()
    {
        var card = new CosmoXCard(new ScriptedTransport());
        var e = Assert.Throws<CardException>(card.SelectMF);
        Assert.Equal(CardErrorKind.SmOutOfSync, e.Kind);
    }

    [Fact]
    public void Certificate_summary_reads_cn_and_sha1()
    {
        using var rsa = RSA.Create(2048);
        var request = new CertificateRequest("CN=ION POPESCU, C=MD", rsa, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        using var cert = request.CreateSelfSigned(DateTimeOffset.UtcNow.AddDays(-1), DateTimeOffset.UtcNow.AddYears(1));
        var der = cert.Export(X509ContentType.Cert);

        var summary = CertificateSummary.FromDer(der);

        Assert.Equal("ION POPESCU", summary.CommonName);
        Assert.Equal(Hex.Encode(SHA1.HashData(der)), summary.Sha1);
        Assert.Equal(40, summary.Sha1.Length);
    }

    [Fact]
    public void Certificate_summary_reads_surname_and_given_name_with_diacritics()
    {
        using var rsa = RSA.Create(2048);
        var subject = new X500DistinguishedNameBuilder();
        subject.AddCountryOrRegion("MD");
        subject.Add("2.5.4.4", "Mîndru", UniversalTagNumber.UTF8String);   // SN
        subject.Add("2.5.4.42", "Ștefan", UniversalTagNumber.UTF8String);  // GN
        subject.AddCommonName("Ștefan Mîndru");
        var request = new CertificateRequest(subject.Build(), rsa, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        using var cert = request.CreateSelfSigned(DateTimeOffset.UtcNow.AddDays(-1), DateTimeOffset.UtcNow.AddYears(1));

        var summary = CertificateSummary.FromDer(cert.Export(X509ContentType.Cert));

        Assert.Equal("Mîndru", summary.Surname);
        Assert.Equal("Ștefan", summary.GivenName);
        Assert.Equal(("Mîndru", "Ștefan"), summary.NameParts());
    }

    [Theory]
    [InlineData("POPESCU ION", "POPESCU", "ION")]
    [InlineData("Rusu Ana Maria", "Rusu", "Ana Maria")]
    [InlineData("RUSU", "RUSU", "")]
    public void Name_parts_fall_back_to_the_common_name(string commonName, string surname, string given)
    {
        var summary = new CertificateSummary
        {
            CommonName = commonName, Subject = $"CN={commonName}", Issuer = "CN=MDQSign", SerialNumber = "01",
            NotBefore = DateTimeOffset.UnixEpoch, NotAfter = DateTimeOffset.UnixEpoch, Sha1 = "00", Der = [],
        };
        Assert.Equal((surname, given), summary.NameParts());
    }

    [Fact]
    public void Default_output_path_never_overwrites()
    {
        var dir = Directory.CreateTempSubdirectory("moldsign-test-");
        try
        {
            var input = Path.Combine(dir.FullName, "contract.pdf");
            File.WriteAllText(input, "x");
            var first = SigningService.DefaultOutputPath(input);
            Assert.Equal(Path.Combine(dir.FullName, "contract-semnat.pdf"), first);
            File.WriteAllText(first, "y");
            Assert.Equal(Path.Combine(dir.FullName, "contract-semnat (2).pdf"), SigningService.DefaultOutputPath(input));
        }
        finally
        {
            dir.Delete(recursive: true);
        }
    }

    // MARK: - Fakes

    /// <summary>Expects an exact APDU sequence ("*" = any) and replays canned responses.</summary>
    internal sealed class ScriptedTransport(params (string Apdu, string Response)[] script) : ICardTransport
    {
        private int _next;

        public string ReaderName => "Fake Reader 0";

        public byte[] Transmit(byte[] apdu)
        {
            Assert.True(_next < script.Length, $"unexpected extra APDU {Hex.Encode(apdu)}");
            var (expected, response) = script[_next++];
            if (expected != "*") Assert.Equal(expected, Hex.Encode(apdu));
            return Hex.Decode(response);
        }

        public void AssertDone() => Assert.Equal(script.Length, _next);

        public void Dispose() { }
    }

    /// <summary>
    /// Card side of IAS/ECC SM for one session: checks each command's MAC, decrypts its data, and answers
    /// with 87/99/8E objects (SW-only 9000 for SELECTs), splitting long answers into 61xx + GET RESPONSE.
    /// </summary>
    internal sealed class SimulatedSmCard(byte[] sessEnc, byte[] sessMac, byte[] ssc) : ICardTransport
    {
        private readonly byte[] _ssc = (byte[])ssc.Clone();
        private byte[] _pending = [];

        public byte[] EfContent { get; init; } = [];
        public Func<byte[], byte[]>? InternalAuthenticate { get; init; }
        public List<byte[]> Commands { get; } = [];
        public List<(int Offset, int Length)> Reads { get; } = [];
        public int GetResponseCount { get; private set; }

        public string ReaderName => "Simulated CosmoX";

        public byte[] Transmit(byte[] apdu)
        {
            if (apdu[1] == 0xC0) // GET RESPONSE
            {
                GetResponseCount++;
                return NextChunk(apdu[4] == 0 ? 256 : apdu[4]);
            }

            Commands.Add(apdu);
            Assert.Equal(0x0C, apdu[0] & 0x0C);
            Assert.Equal(0x00, apdu[^1]); // Le=00 always appended
            Increment(_ssc);
            var (data, le) = OpenCommand(apdu);

            byte[]? answer = apdu[1] switch
            {
                0xB0 => Read((apdu[2] << 8) | apdu[3], le ?? 0),
                0x88 => InternalAuthenticate!(data),
                _ => null, // SELECT, MSE SET: SW-only 9000
            };
            Increment(_ssc); // the card counts its response, SW-only or not
            if (answer is null) return [0x90, 0x00];

            _pending = SealResponse(answer);
            return NextChunk(200);
        }

        public void Dispose() { }

        private byte[] Read(int offset, int length)
        {
            Reads.Add((offset, length));
            return EfContent.Skip(offset).Take(length).ToArray();
        }

        private byte[] NextChunk(int max)
        {
            var n = Math.Min(max, _pending.Length);
            var chunk = _pending[..n];
            _pending = _pending[n..];
            byte[] sw = _pending.Length == 0 ? [0x90, 0x00] : [0x61, (byte)Math.Min(_pending.Length, 255)];
            return [.. chunk, .. sw];
        }

        private (byte[] Data, int? Le) OpenCommand(byte[] apdu)
        {
            var body = apdu.AsSpan(5, apdu[4]);
            var macInput = new List<byte>(_ssc);
            macInput.AddRange(Iso9797.Pad([apdu[0], apdu[1], apdu[2], apdu[3]]));
            byte[] data = [];
            int? le = null;
            byte[] mac = [];
            var pos = 0;
            while (pos < body.Length)
            {
                var tag = body[pos];
                int len = body[pos + 1], hdr = 2;
                if (len == 0x81) { len = body[pos + 2]; hdr = 3; }
                var content = body.Slice(pos + hdr, len);
                if (tag == 0x8E)
                {
                    mac = content.ToArray();
                }
                else
                {
                    macInput.AddRange(body.Slice(pos, hdr + len).ToArray());
                    if (tag == 0x87)
                        data = Iso9797.Unpad(AesPrimitives.DecryptCbc(sessEnc, AesPrimitives.EncryptEcb(sessEnc, _ssc), content[1..]));
                    if (tag == 0x97) le = content[0] == 0 ? 256 : content[0];
                }
                pos += hdr + len;
            }
            Assert.Equal(Hex.Encode(Cmac.Compute(sessMac, Iso9797.Pad(macInput.ToArray())).AsSpan(0, 8)), Hex.Encode(mac));
            return (data, le);
        }

        private byte[] SealResponse(byte[] plain)
        {
            var enc = AesPrimitives.EncryptCbc(sessEnc, AesPrimitives.EncryptEcb(sessEnc, _ssc), Iso9797.Pad(plain));
            var do87 = SecureChannel.BuildTlv(0x87, [0x01, .. enc]);
            byte[] do99 = [0x99, 0x02, 0x90, 0x00];
            var mac = Cmac.Compute(sessMac, Iso9797.Pad([.. _ssc, .. do87, .. do99])).AsSpan(0, 8);
            return [.. do87, .. do99, 0x8E, 0x08, .. mac];
        }

        private static void Increment(byte[] counter) => SecureChannelVectorTests.Increment(counter);
    }
}
