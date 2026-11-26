using System.Security.Cryptography;
using MoldSign.Cli;

namespace MoldSign.Core.Tests;

/// <summary>spec/cli.md card commands (cert, sign-hex) end to end over the SM card simulator: output, PIN order, exit codes.</summary>
public class CliCardCommandTests
{
    private static readonly byte[] s_certificate = IdentityGuardTests.TestCertificate("CN=ION POPESCU, SN=POPESCU, G=ION, C=MD");
    private const string DigestInfo = "3031300D060960864801650304020105000420" +
                                      "0000000000000000000000000000000000000000000000000000000000000000";

    [Fact]
    public void Cert_prints_the_certificate_and_saves_its_der()
    {
        var directory = Directory.CreateTempSubdirectory("esemnbun-cli-");
        try
        {
            var path = Path.Combine(directory.FullName, "leaf.der");
            var cards = new SimulatedCards();
            var (code, output, error) = Run(["cert", "--quiet", "--reader", "Simulated", "--out", path], cards);

            Assert.Equal(0, code);
            Assert.Equal("", error);
            Assert.Equal(["Simulated"], cards.Connections);
            Assert.Contains("Holder:  ION POPESCU", output);
            Assert.Contains("Subject: CN=ION POPESCU", output);
            Assert.Contains($"SHA-1:   {Convert.ToHexString(SHA1.HashData(s_certificate))}", output);
            Assert.Matches(@"Valid:   \d{4}-\d{2}-\d{2} to \d{4}-\d{2}-\d{2}", output);
            Assert.Contains($"Saved:   {path}", output);
            Assert.Equal(s_certificate, File.ReadAllBytes(path));
        }
        finally { directory.Delete(true); }
    }

    [Fact]
    public void Cert_traces_protocol_steps_unless_quiet_and_reports_unwritable_output()
    {
        var missing = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString("N"), "leaf.der");
        var (code, output, error) = Run(["cert", "--out", missing], new SimulatedCards());

        Assert.Equal(1, code);
        Assert.Contains("Holder:  ION POPESCU", output);
        Assert.DoesNotContain("Saved:", output);
        Assert.Contains("  ", error); // indented protocol traces
        Assert.Contains("error: ", error);
        Assert.False(File.Exists(missing));
    }

    [Fact]
    public void Sign_hex_uses_the_environment_pin_and_prints_the_raw_signature()
    {
        var cards = new SimulatedCards();
        var (code, output, error) = Run(["sign-hex", DigestInfo, "--quiet"], cards, environmentPin: "1234");

        Assert.Equal(0, code);
        Assert.Equal("", error);
        var signature = Hex.Decode(output.Trim());
        Assert.Equal(512, signature.Length);
        Assert.Equal(SHA256.HashData(Hex.Decode(DigestInfo)), signature[..32]);
        var verify = Assert.Single(cards.Last!.Commands, command => command[1] == 0x20);
        Assert.Equal(0x03, verify[3]); // VERIFY ref 03
    }

    [Fact]
    public void Sign_hex_reads_the_first_stdin_line_before_the_environment()
    {
        var prompted = false;
        var (code, output, _) = Run(["sign-hex", DigestInfo, "--pin-stdin", "--quiet"], new SimulatedCards(),
            stdin: "4321\r\nignored\n", environmentPin: "1234", prompt: _ => { prompted = true; return "0000"; });

        Assert.Equal(0, code);
        Assert.Equal(1024, output.Trim().Length);
        Assert.False(prompted);
    }

    [Fact]
    public void Sign_hex_prompts_on_a_terminal_and_a_cancelled_prompt_signs_nothing()
    {
        string? prompt = null;
        var cards = new SimulatedCards();
        var (code, output, error) = Run(["sign-hex", DigestInfo, "--quiet"], cards, redirected: false,
            prompt: text => { prompt = text; return null; });

        Assert.Equal(1, code);
        Assert.Equal("", output);
        Assert.Equal("error: cancelled", error.Trim());
        Assert.Equal("PIN QSCD for ION POPESCU: ", prompt);
        Assert.DoesNotContain(cards.Last!.Commands, command => command[1] is 0x20 or 0x88);
    }

    [Fact]
    public void Sign_hex_without_any_pin_source_is_a_usage_error()
    {
        var cards = new SimulatedCards();
        var (code, _, error) = Run(["sign-hex", DigestInfo, "--quiet"], cards);

        Assert.Equal(1, code);
        Assert.Contains("use --pin-stdin or set MSIGN_PIN", error);
        Assert.DoesNotContain(cards.Last!.Commands, command => command[1] == 0x20);
    }

    [Theory]
    [InlineData((ushort)0x63C2, 3, "wrong PIN, 2 attempt(s) remaining. Not retried automatically.")]
    [InlineData((ushort)0x6983, 4, "PIN blocked. Unblock it at CEV (PUK).")]
    public void Sign_hex_maps_pin_failures_once_without_retrying(ushort status, int exit, string message)
    {
        var cards = new SimulatedCards { VerifyStatus = status };
        var (code, output, error) = Run(["sign-hex", DigestInfo, "--quiet"], cards, environmentPin: "1234");

        Assert.Equal(exit, code);
        Assert.Equal("", output);
        Assert.Equal($"error: {message}", error.Trim());
        Assert.Single(cards.Connections);
        Assert.Single(cards.Last!.Commands, command => command[1] == 0x20);
        Assert.DoesNotContain(cards.Last.Commands, command => command[1] == 0x88);
    }

    [Theory]
    [InlineData("zz", "error: sign-hex needs a hex DigestInfo")]
    [InlineData("", "error: DigestInfo must be 1-255 bytes")]
    public void Sign_hex_rejects_malformed_digest_info_before_the_card(string digestInfo, string message)
    {
        var cards = new SimulatedCards();
        var (code, _, error) = Run(["sign-hex", digestInfo], cards, environmentPin: "1234");

        Assert.Equal(1, code);
        Assert.Equal(message, error.Trim());
        Assert.Empty(cards.Connections);
    }

    [Fact]
    public void Sign_hex_rejects_an_oversized_digest_info_before_the_card()
    {
        var cards = new SimulatedCards();
        var (code, _, error) = Run(["sign-hex", new string('A', 512)], cards, environmentPin: "1234");

        Assert.Equal(1, code);
        Assert.Equal("error: DigestInfo must be 1-255 bytes", error.Trim());
        Assert.Empty(cards.Connections);
    }

    [Theory]
    [InlineData(CardErrorKind.CardStateStuck, "the card is in a stuck state (6985): remove and re-insert the card; do not retry.")]
    [InlineData(CardErrorKind.SmOutOfSync, "secure messaging out of sync (6988); re-insert the card and retry once.")]
    [InlineData(CardErrorKind.Cancelled, "cancelled")]
    [InlineData(CardErrorKind.WrongPin, "wrong PIN. Not retried automatically.")]
    [InlineData(CardErrorKind.Format, "6988")]
    public void Card_errors_are_described_for_people(CardErrorKind kind, string expected) =>
        Assert.Equal(expected, CliApp.Describe(new CardException(kind, "6988")));

    [Fact]
    public void The_console_host_reads_the_process_environment_and_uses_pcsc()
    {
        var host = CliHost.FromConsole();

        Assert.Same(Console.Out, host.Out);
        Assert.Same(Console.Error, host.Error);
        Assert.Same(Console.In, host.In);
        Assert.Equal(Environment.GetEnvironmentVariable("PATH"), host.GetEnvironmentVariable("PATH"));
        Assert.Equal(Console.IsInputRedirected, host.IsInputRedirected());
        Assert.IsType<WinSCardAccess>(host.Cards);
    }

    [Fact]
    public void Pcsc_access_off_windows_fails_with_exit_5_for_every_card_command()
    {
        if (OperatingSystem.IsWindows()) return; // the real PC/SC stack is exercised on device
        var access = new WinSCardAccess();
        Assert.Equal(CardErrorKind.NoReader, Assert.Throws<CardException>(() => access.Connect("any")).Kind);
        var (code, _, error) = Run(["cert", "--quiet"], access);
        Assert.Equal(5, code);
        Assert.Contains(WinSCardAccess.NotWindowsMessage, error);
    }

    private static (int Code, string Out, string Err) Run(string[] args, ICardAccess cards, string stdin = "",
        string? environmentPin = null, bool redirected = true, Func<string, string?>? prompt = null)
    {
        var output = new StringWriter();
        var error = new StringWriter();
        var host = new CliHost
        {
            In = new StringReader(stdin),
            Out = output,
            Error = error,
            GetEnvironmentVariable = name => name == PinSource.EnvironmentVariable ? environmentPin : null,
            IsInputRedirected = () => redirected,
            PromptHidden = prompt ?? (_ => null),
            Cards = cards,
        };
        var code = CliApp.Run(args, host);
        return (code, output.ToString(), error.ToString());
    }

    /// <summary>A fresh authenticated SM simulator per connection, like a real reader session.</summary>
    private sealed class SimulatedCards : ICardAccess
    {
        public ushort VerifyStatus { get; init; } = 0x9000;
        public List<string?> Connections { get; } = [];
        public CosmoXCardTests.SimulatedSmCard? Last { get; private set; }

        public IReadOnlyList<SmartCardReaderInfo> ListReaders() => [new("Simulated", true)];

        public ICardTransport Connect(string? readerName)
        {
            Connections.Add(readerName);
            Last = IdentityGuardTests.Simulator(s_certificate, CosmoXCardTests.SessionAfterAuthentication());
            Last.VerifyStatus = VerifyStatus;
            return new IdentityGuardTests.AuthenticatingTransport(Last, readerName ?? "Simulated");
        }
    }
}
