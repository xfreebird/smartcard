using System.Globalization;
using MoldSign.Core;

namespace MoldSign.Cli;

/// <summary>spec/cli.md exit codes.</summary>
internal static class ExitCodes
{
    public const int Success = 0;
    public const int UsageOrUnexpected = 1;
    public const int VerifyInvalid = 2;
    public const int WrongPin = 3;
    public const int PinBlocked = 4;
    public const int NoReaderOrCard = 5;
    public const int Network = 6;

    public static int For(CardException e) => e.Kind switch
    {
        CardErrorKind.WrongPin => WrongPin,
        CardErrorKind.PinBlocked => PinBlocked,
        CardErrorKind.NoReader or CardErrorKind.NoCard => NoReaderOrCard,
        CardErrorKind.Network => Network,
        _ => UsageOrUnexpected,
    };
}

/// <summary>The <c>esemnbun</c> command dispatcher (CLI-03; product name eSemnBun, docs/10 §0.2b).</summary>
internal static class CliApp
{
    public const string NotImplementedMessage = "not implemented yet (WIN-01)";

    public const string Usage = """
        esemnbun: eSemnBun CLI for the Moldovan eID (IDEMIA CosmoX ID-A), Windows

        Usage:
          esemnbun readers                                   List PC/SC readers and card presence
          esemnbun cert [--out <file.der>]                   Read the signing certificate (no PIN)
          esemnbun sign <in.pdf> [<out.pdf>]                 PAdES-T (default output: <name>-semnat.pdf)
          esemnbun xades <XAdES-BES|XAdES-T|XAdES-C> <in> <out.xml> [--enveloping]
          esemnbun verify <file.pdf|sig.xml> [<docs_dir>]    Offline validation report
          esemnbun server [<port>]                           Browser bridge (http 18480, https 18443)
          esemnbun sign-hex <digestinfo_hex>                 Developer: raw card signature over a DigestInfo
          esemnbun cms-for-hash <sha256_hex>                 Developer: detached CMS for an external digest
          esemnbun <in.pdf> <out.pdf>                        Legacy form of 'sign'

        Options:
          --reader <name>   Reader name or substring (default: first reader with a card)
          --quiet           No protocol traces on stderr
          --pin-stdin       Read the PIN from the first line of stdin

        PIN: --pin-stdin, else the MSIGN_PIN variable, else a prompt without echo.
             The PIN is never accepted as an argument.
        Exit codes: 0 ok, 1 usage/unexpected, 2 verify invalid, 3 wrong PIN, 4 PIN blocked,
                    5 no reader/card, 6 network.

        """;

    public static int Run(IReadOnlyList<string> args, CliHost host)
    {
        CliOptions options;
        try
        {
            options = CliOptions.Parse(args);
        }
        catch (UsageException e)
        {
            host.Error.WriteLine($"error: {e.Message}");
            host.Error.WriteLine("run 'esemnbun --help' for usage");
            return ExitCodes.UsageOrUnexpected;
        }

        try
        {
            return options.Command switch
            {
                "help" => Help(host),
                "readers" => Readers(host),
                "cert" => Cert(host, options),
                "sign-hex" => SignHex(host, options),
                // TODO(WIN-01): sign (PAdES-T), xades, verify, cms-for-hash once the formats are ported.
                // TODO(WIN-06): server = the BridgeHost protocol without the tray app.
                "sign" or "xades" or "verify" or "server" or "cms-for-hash" => throw new NotImplementedException(),
                _ => throw new UsageException($"unknown command '{options.Command}'"),
            };
        }
        catch (CardException e)
        {
            host.Error.WriteLine($"error: {Describe(e)}");
            return ExitCodes.For(e);
        }
        catch (NotImplementedException)
        {
            host.Error.WriteLine($"error: {NotImplementedMessage}");
            return ExitCodes.UsageOrUnexpected;
        }
        catch (UsageException e)
        {
            host.Error.WriteLine($"error: {e.Message}");
            return ExitCodes.UsageOrUnexpected;
        }
        catch (Exception e) when (e is IOException or UnauthorizedAccessException or FormatException)
        {
            host.Error.WriteLine($"error: {e.Message}");
            return ExitCodes.UsageOrUnexpected;
        }
    }

    public static string Describe(CardException e) => e.Kind switch
    {
        CardErrorKind.WrongPin => e.RemainingAttempts is { } n
            ? $"wrong PIN, {n} attempt(s) remaining. Not retried automatically."
            : "wrong PIN. Not retried automatically.",
        CardErrorKind.PinBlocked => "PIN blocked. Unblock it at CEV (PUK).",
        CardErrorKind.CardStateStuck => "the card is in a stuck state (6985): remove and re-insert the card; do not retry.",
        CardErrorKind.SmOutOfSync => $"secure messaging out of sync ({e.Message}); re-insert the card and retry once.",
        CardErrorKind.Cancelled => "cancelled",
        _ => e.Message,
    };

    private static int Help(CliHost host)
    {
        host.Out.Write(Usage);
        return ExitCodes.Success;
    }

    private static int Readers(CliHost host)
    {
        var readers = host.Cards.ListReaders();
        if (readers.Count == 0) throw new CardException(CardErrorKind.NoReader, "no smart-card reader found");
        foreach (var reader in readers)
            host.Out.WriteLine($"{reader.Name}: {(reader.CardPresent ? "card present" : "empty")}");
        return ExitCodes.Success;
    }

    private static int Cert(CliHost host, CliOptions options)
    {
        var summary = Service(host, options).Certificate();
        host.Out.WriteLine($"Holder:  {summary.CommonName}");
        host.Out.WriteLine($"Subject: {summary.Subject}");
        host.Out.WriteLine($"Issuer:  {summary.Issuer}");
        host.Out.WriteLine(string.Create(CultureInfo.InvariantCulture,
            $"Valid:   {summary.NotBefore:yyyy-MM-dd} to {summary.NotAfter:yyyy-MM-dd}"));
        host.Out.WriteLine($"Serial:  {summary.SerialNumber}");
        host.Out.WriteLine($"SHA-1:   {summary.Sha1}");
        if (options.Out is { } path)
        {
            File.WriteAllBytes(path, summary.Der);
            host.Out.WriteLine($"Saved:   {path}");
        }
        return ExitCodes.Success;
    }

    private static int SignHex(CliHost host, CliOptions options)
    {
        byte[] digestInfo;
        try
        {
            digestInfo = Hex.Decode(options.Arguments[0]);
        }
        catch (FormatException)
        {
            throw new UsageException("sign-hex needs a hex DigestInfo");
        }
        if (digestInfo.Length is 0 or > 255) throw new UsageException("DigestInfo must be 1-255 bytes");

        var (signature, _) = Service(host, options).SignDigestInfo(
            digestInfo, request => PinSource.Obtain(host, options, request), requester: "CLI", format: "RAW");
        host.Out.WriteLine(Hex.Encode(signature));
        return ExitCodes.Success;
    }

    private static SigningService Service(CliHost host, CliOptions options)
    {
        Action<string>? trace = options.Quiet ? null : line => host.Error.WriteLine($"  {line}");
        return new SigningService(() => host.Cards.Connect(options.Reader), trace: trace);
    }
}
