namespace MoldSign.Cli;

/// <summary>Bad command line; exit code 1.</summary>
internal sealed class UsageException(string message) : Exception(message);

/// <summary>Parsed command line (hand-rolled: no reflection, NativeAOT-friendly).</summary>
internal sealed record CliOptions
{
    public static readonly string[] Commands =
        ["readers", "cert", "sign", "xades", "verify", "server", "sign-hex", "cms-for-hash", "help"];

    public static readonly string[] XadesFormats = ["XAdES-BES", "XAdES-T", "XAdES-C"];

    public string Command { get; init; } = "help";
    public IReadOnlyList<string> Arguments { get; init; } = [];
    public string? Reader { get; init; }
    public bool Quiet { get; init; }
    public bool PinStdin { get; init; }
    public string? Out { get; init; }
    public bool Enveloping { get; init; }

    public static CliOptions Parse(IReadOnlyList<string> args)
    {
        var positionals = new List<string>();
        string? reader = null, output = null;
        bool quiet = false, pinStdin = false, enveloping = false, help = false, endOfOptions = false;

        for (var i = 0; i < args.Count; i++)
        {
            var arg = args[i];
            if (endOfOptions || !arg.StartsWith('-') || arg == "-")
            {
                positionals.Add(arg);
                continue;
            }

            var (name, inlineValue) = SplitOption(arg);
            switch (name)
            {
                case "--":
                    endOfOptions = true;
                    break;
                case "--help" or "-h" or "-?":
                    help = true;
                    break;
                case "--quiet" or "-q":
                    quiet = true;
                    break;
                case "--pin-stdin":
                    pinStdin = true;
                    break;
                case "--enveloping":
                    enveloping = true;
                    break;
                case "--reader":
                    reader = inlineValue ?? Next(args, ref i, name);
                    break;
                case "--out":
                    output = inlineValue ?? Next(args, ref i, name);
                    break;
                case "--pin" or "-p":
                    throw new UsageException(
                        "the PIN is never accepted on the command line; use --pin-stdin or the MSIGN_PIN variable");
                default:
                    throw new UsageException($"unknown option '{arg}'");
            }
        }

        if (help || positionals.Count == 0)
            return new CliOptions { Command = "help", Quiet = quiet };

        string command;
        IReadOnlyList<string> rest;
        if (Commands.Contains(positionals[0], StringComparer.Ordinal))
        {
            command = positionals[0];
            rest = positionals.Skip(1).ToArray();
        }
        else if (positionals.Count == 2 && positionals[0].EndsWith(".pdf", StringComparison.OrdinalIgnoreCase))
        {
            command = "sign"; // legacy form: moldsign <in.pdf> <out.pdf>
            rest = positionals;
        }
        else
        {
            throw new UsageException($"unknown command '{positionals[0]}'");
        }

        var options = new CliOptions
        {
            Command = command,
            Arguments = rest,
            Reader = reader,
            Quiet = quiet,
            PinStdin = pinStdin,
            Out = output,
            Enveloping = enveloping,
        };
        options.Validate();
        return options;
    }

    private void Validate()
    {
        var (min, max) = Command switch
        {
            "readers" or "cert" or "help" => (0, 0),
            "sign" => (1, 2),
            "xades" => (3, 3),
            "verify" => (1, 2),
            "server" => (0, 1),
            "sign-hex" or "cms-for-hash" => (1, 1),
            _ => (0, int.MaxValue),
        };
        if (Arguments.Count < min || Arguments.Count > max)
            throw new UsageException($"wrong number of arguments for '{Command}'");
        if (Out is not null && Command != "cert")
            throw new UsageException("--out only applies to 'cert'");
        if (Enveloping && Command != "xades")
            throw new UsageException("--enveloping only applies to 'xades'");
        if (Command == "xades" && !XadesFormats.Contains(Arguments[0], StringComparer.Ordinal))
            throw new UsageException($"format must be one of {string.Join(", ", XadesFormats)}");
        if (Command == "server" && Arguments.Count == 1 &&
            (!int.TryParse(Arguments[0], out var port) || port is < 1 or > 65535))
            throw new UsageException("port must be 1-65535");
    }

    private static (string Name, string? Value) SplitOption(string arg)
    {
        var eq = arg.IndexOf('=');
        return eq > 2 && arg.StartsWith("--", StringComparison.Ordinal) ? (arg[..eq], arg[(eq + 1)..]) : (arg, null);
    }

    private static string Next(IReadOnlyList<string> args, ref int i, string name)
    {
        if (i + 1 >= args.Count) throw new UsageException($"{name} needs a value");
        return args[++i];
    }
}
