using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using static MoldSign.Core.Tests.VectorFile;

namespace MoldSign.Core.Tests;

/// <summary>
/// Identity guard before VERIFY (docs/09 §3.1b): read the certificate, compare its SHA-1 with the card the PIN /
/// consent / selection is for, and only then SELECT ADF → VERIFY. Driven by the SM card simulator
/// (<see cref="CosmoXCardTests.SimulatedSmCard"/>), end to end through mutual authentication for SigningService.
/// </summary>
public class IdentityGuardTests
{
    private const byte InsVerify = 0x20;

    private static readonly byte[] s_cardA = TestCertificate("CN=ION POPESCU, C=MD");
    private static readonly byte[] s_cardB = TestCertificate("CN=MARIA POPESCU, C=MD");

    [Fact]
    public void Prepare_for_signing_refuses_a_swapped_card_before_the_pin_goes_out()
    {
        var sim = Simulator(s_cardB);
        var card = new CosmoXCard(sim) { Channel = SecureChannelVectorTests.FreshChannel() };

        var e = Assert.Throws<CardException>(() => card.PrepareForSigning("1234", Sha1(s_cardA)));

        Assert.Equal(CardErrorKind.CardChanged, e.Kind);
        Assert.DoesNotContain(sim.Commands, c => c[1] == InsVerify);
        Assert.True(card.HasSecureChannel, "the session stays usable; nothing was sent after the certificate read");
    }

    [Fact]
    public void Prepare_for_signing_reads_compares_reselects_then_verifies()
    {
        var sim = Simulator(s_cardA);
        var card = new CosmoXCard(sim) { Channel = SecureChannelVectorTests.FreshChannel() };

        // Lower-case expectation: the comparison ignores hex case.
        var certificate = card.PrepareForSigning("1234", Sha1(s_cardA).ToLowerInvariant());

        Assert.Equal(s_cardA, certificate);
        // SELECT MF, SELECT ADF, SELECT EF 0001, READ BINARY…, then SELECT ADF (P2=04) and VERIFY ref 03 last.
        Assert.Equal("A4000C", Hex.Encode(sim.Commands[0].AsSpan(1, 3)));
        Assert.Equal("A40404", Hex.Encode(sim.Commands[1].AsSpan(1, 3)));
        Assert.Equal("A40204", Hex.Encode(sim.Commands[2].AsSpan(1, 3)));
        Assert.Equal(0xB0, sim.Commands[3][1]);
        Assert.Equal("A40404", Hex.Encode(sim.Commands[^2].AsSpan(1, 3)));
        Assert.Equal("200003", Hex.Encode(sim.Commands[^1].AsSpan(1, 3)));
        Assert.Single(sim.Commands, c => c[1] == InsVerify);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    public void No_expectation_accepts_any_card(string? expected)
    {
        var error = Record.Exception(() => CosmoXCard.EnsureExpectedCard(s_cardB, expected));
        Assert.Null(error);
    }

    [Fact]
    public void Signing_service_refuses_a_swapped_card_before_consent_and_verify()
    {
        var sim = Simulator(s_cardB, CosmoXCardTests.SessionAfterAuthentication());
        string? connectedTo = null;
        var service = new SigningService(reader =>
        {
            connectedTo = reader;
            return new AuthenticatingTransport(sim, reader ?? "default");
        });
        var consentCalls = 0;

        var e = Assert.Throws<CardException>(() => service.SignDigestInfo(
            Bytes("digest_info", "digest_info"),
            _ =>
            {
                consentCalls++;
                return ConsentResult.WithPin("1234");
            },
            reader: "Reader B",
            expectedCertificateSha1: Sha1(s_cardA)));

        Assert.Equal(CardErrorKind.CardChanged, e.Kind);
        Assert.Equal("Reader B", connectedTo);
        Assert.Equal(0, consentCalls); // no PIN dialog, no stored-PIN lookup for the wrong card
        Assert.DoesNotContain(sim.Commands, c => c[1] == InsVerify);
    }

    [Fact]
    public void Signing_service_signs_with_the_expected_card()
    {
        var sim = Simulator(s_cardA, CosmoXCardTests.SessionAfterAuthentication());
        var service = new SigningService(reader => new AuthenticatingTransport(sim, reader ?? "default"));
        ConsentRequest? asked = null;

        var (signature, summary) = service.SignDigestInfo(
            Bytes("digest_info", "digest_info"),
            request =>
            {
                asked = request;
                return ConsentResult.WithPin("1234");
            },
            reader: "Reader A",
            expectedCertificateSha1: Sha1(s_cardA));

        Assert.Equal(512, signature.Length);
        Assert.Equal(Sha1(s_cardA), summary.Sha1);
        Assert.Equal("ION POPESCU", asked?.Certificate.CommonName);
        var verify = sim.Commands.FindIndex(c => c[1] == InsVerify);
        Assert.True(verify > 0);
        Assert.Equal("A40404", Hex.Encode(sim.Commands[verify - 1].AsSpan(1, 3))); // SELECT ADF right before VERIFY
        Assert.Equal(0x88, sim.Commands[^1][1]);                                   // then INTERNAL AUTHENTICATE
    }

    [Fact]
    public void List_cards_reads_every_reader_and_skips_unreadable_ones()
    {
        var cards = new Dictionary<string, byte[]> { ["Reader A"] = s_cardA, ["Reader B"] = s_cardB };
        var service = new SigningService(reader => reader switch
        {
            "Reader A" or "Reader B" => new AuthenticatingTransport(
                Simulator(cards[reader!], CosmoXCardTests.SessionAfterAuthentication()), reader),
            _ => throw new CardException(CardErrorKind.NoCard, "empty"),
        });

        var entries = service.ListCards(["Reader A", "Empty reader", "Reader B"]);

        Assert.Equal(["Reader A", "Reader B"], entries.Select(e => e.Reader));
        Assert.Equal([Sha1(s_cardA), Sha1(s_cardB)], entries.Select(e => e.Certificate.Sha1));
    }

    // MARK: - Helpers

    /// <summary>SM card holding <paramref name="certificate"/>, starting from the "sm" vector session.</summary>
    private static CosmoXCardTests.SimulatedSmCard Simulator(byte[] certificate) =>
        Simulator(certificate, (Bytes("sm", "sess_enc"), Bytes("sm", "sess_mac"), Bytes("sm", "ssc_initial")));

    /// <summary>SM card holding <paramref name="certificate"/> with an explicit session (e.g. after Authenticate()).</summary>
    internal static CosmoXCardTests.SimulatedSmCard Simulator(byte[] certificate, (byte[] Enc, byte[] Mac, byte[] Ssc) session) =>
        new(session.Enc, session.Mac, session.Ssc)
        {
            EfContent = certificate,
            InternalAuthenticate = digestInfo => [.. SHA256.HashData(digestInfo), .. new byte[480]],
        };

    private static string Sha1(byte[] der) => Hex.Encode(SHA1.HashData(der));

    internal static byte[] TestCertificate(string subject)
    {
        using var rsa = RSA.Create(2048);
        var request = new CertificateRequest(subject, rsa, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        using var cert = request.CreateSelfSigned(DateTimeOffset.UtcNow.AddDays(-1), DateTimeOffset.UtcNow.AddYears(1));
        return cert.Export(X509ContentType.Cert);
    }

    /// <summary>The reference mutual authentication (scripted), then the SM simulator with the resulting session.</summary>
    internal sealed class AuthenticatingTransport(CosmoXCardTests.SimulatedSmCard card, string readerName) : ICardTransport
    {
        private readonly CosmoXCardTests.ScriptedTransport _authentication = new(CosmoXCardTests.AuthenticationScript());
        private int _authenticationLeft = CosmoXCardTests.AuthenticationScript().Length;

        public string ReaderName => readerName;

        public byte[] Transmit(byte[] apdu) =>
            _authenticationLeft-- > 0 ? _authentication.Transmit(apdu) : card.Transmit(apdu);

        public void Dispose() { }
    }
}
