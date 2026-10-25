using MoldSign.Cli;

namespace MoldSign.Core.Tests;

/// <summary>spec/cli.md: argument parsing, PIN order, exit codes, Windows-only transport.</summary>
public class CliTests
{
    [Fact]
    public void Legacy_two_pdf_form_means_sign()
    {
        var o = CliOptions.Parse(["in.pdf", "out.pdf"]);
        Assert.Equal("sign", o.Command);
        Assert.Equal(new[] { "in.pdf", "out.pdf" }, o.Arguments);
    }

    [Fact]
    public void Global_options_anywhere()
    {
        var o = CliOptions.Parse(["cert", "--reader", "miniLector", "--quiet", "--out=c.der"]);
        Assert.Equal("cert", o.Command);
        Assert.Equal("miniLector", o.Reader);
        Assert.True(o.Quiet);
        Assert.Equal("c.der", o.Out);
    }

    [Theory]
    [InlineData("sign-hex", "--pin", "1234", "00")]
    [InlineData("sign-hex", "--pin=1234", "00")]
    [InlineData("sign-hex", "-p", "1234", "00")]
    public void Pin_is_never_accepted_as_an_argument(params string[] args)
    {
        var e = Assert.Throws<UsageException>(() => CliOptions.Parse(args));
        Assert.Contains("never accepted", e.Message);
    }

    [Theory]
    [InlineData("frobnicate")]
    [InlineData("xades", "XAdES-X", "a", "b.xml")]
    [InlineData("cert", "extra")]
    [InlineData("sign")]
    [InlineData("server", "99999")]
    [InlineData("readers", "--enveloping")]
    [InlineData("cert", "--bogus")]
    public void Usage_errors_exit_1(params string[] args)
    {
        var (code, _, err) = Run(args, new FakeCards());
        Assert.Equal(1, code);
        Assert.StartsWith("error: ", err);
    }

    [Fact]
    public void Help_exits_0()
    {
        var (code, output, _) = Run(["--help"], new FakeCards());
        Assert.Equal(0, code);
        Assert.Contains("esemnbun readers", output);
    }

    [Fact]
    public void Readers_lists_card_presence()
    {
        var cards = new FakeCards { Readers = [new("Bit4id miniLector EVO 0", true), new("Other Reader 1", false)] };
        var (code, output, _) = Run(["readers"], cards);
        Assert.Equal(0, code);
        Assert.Equal("Bit4id miniLector EVO 0: card present\nOther Reader 1: empty\n", output.ReplaceLineEndings("\n"));
    }

    [Fact]
    public void Readers_without_a_reader_exits_5() =>
        Assert.Equal(5, Run(["readers"], new FakeCards()).Code);

    [Theory]
    [InlineData(CardErrorKind.WrongPin, 3)]
    [InlineData(CardErrorKind.PinBlocked, 4)]
    [InlineData(CardErrorKind.NoReader, 5)]
    [InlineData(CardErrorKind.NoCard, 5)]
    [InlineData(CardErrorKind.Network, 6)]
    [InlineData(CardErrorKind.CardStateStuck, 1)]
    [InlineData(CardErrorKind.Cancelled, 1)]
    public void Card_errors_map_to_exit_codes(CardErrorKind kind, int expected)
    {
        var cards = new FakeCards { ConnectError = new CardException(kind, "boom", remainingAttempts: 2) };
        var (code, _, err) = Run(["cert", "--quiet"], cards);
        Assert.Equal(expected, code);
        if (kind == CardErrorKind.WrongPin) Assert.Contains("2 attempt(s) remaining", err);
    }

    [Theory]
    [InlineData("sign", "a.pdf")]
    [InlineData("xades", "XAdES-T", "a.txt", "a.xml")]
    [InlineData("verify", "a.pdf")]
    [InlineData("server")]
    [InlineData("cms-for-hash", "00")]
    public void Unported_commands_say_so_and_exit_1(params string[] args)
    {
        var (code, _, err) = Run(args, new FakeCards());
        Assert.Equal(1, code);
        Assert.Equal("error: not implemented yet (WIN-01)", err.Trim());
    }

    [Fact]
    public void Card_commands_off_windows_exit_5_with_the_platform_message()
    {
        if (OperatingSystem.IsWindows()) return; // covered on device
        var (code, _, err) = Run(["readers"], new WinSCardAccess());
        Assert.Equal(5, code);
        Assert.Equal("error: PC/SC transport is only available on Windows", err.Trim());
    }

    [Fact]
    public void Pin_order_stdin_then_environment_then_prompt()
    {
        var request = new ConsentRequest
        {
            Requester = "CLI",
            Documents = [],
            Format = "RAW",
            Certificate = new CertificateSummary
            {
                CommonName = "ION POPESCU", Subject = "", Issuer = "", SerialNumber = "", Sha1 = "", Der = [],
                NotBefore = DateTimeOffset.MinValue, NotAfter = DateTimeOffset.MaxValue,
            },
        };
        string? prompted = null;
        CliHost Host(string stdin, string? env, bool redirected) => new()
        {
            In = new StringReader(stdin),
            Out = TextWriter.Null,
            Error = TextWriter.Null,
            GetEnvironmentVariable = name => name == "MSIGN_PIN" ? env : null,
            IsInputRedirected = () => redirected,
            PromptHidden = p => { prompted = p; return "5555"; },
            Cards = new FakeCards(),
        };
        var withStdin = new CliOptions { Command = "sign-hex", PinStdin = true };
        var plain = new CliOptions { Command = "sign-hex" };

        Assert.Equal("1111", PinSource.Obtain(Host("1111\r\n", "2222", false), withStdin, request).Pin);
        Assert.Equal("2222", PinSource.Obtain(Host("", "2222", false), plain, request).Pin);
        Assert.Null(prompted);
        Assert.Equal("5555", PinSource.Obtain(Host("", null, false), plain, request).Pin);
        Assert.Equal("PIN QSCD for ION POPESCU: ", prompted);
        Assert.Throws<UsageException>(() => PinSource.Obtain(Host("", null, true), plain, request));
        Assert.Throws<UsageException>(() => PinSource.Obtain(Host("", "2222", false), withStdin, request));
    }

    private static (int Code, string Out, string Err) Run(string[] args, ICardAccess cards)
    {
        var output = new StringWriter();
        var error = new StringWriter();
        var host = new CliHost
        {
            In = new StringReader(""),
            Out = output,
            Error = error,
            GetEnvironmentVariable = _ => null,
            IsInputRedirected = () => true,
            PromptHidden = _ => null,
            Cards = cards,
        };
        var code = CliApp.Run(args, host);
        return (code, output.ToString(), error.ToString());
    }

    private sealed class FakeCards : ICardAccess
    {
        public List<SmartCardReaderInfo> Readers { get; init; } = [];
        public CardException? ConnectError { get; init; }

        public IReadOnlyList<SmartCardReaderInfo> ListReaders() => Readers;

        public ICardTransport Connect(string? readerName) =>
            throw ConnectError ?? new CardException(CardErrorKind.NoReader, "no reader");
    }
}
