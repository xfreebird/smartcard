using System.Text;
using MoldSign.Core;

namespace MoldSign.Cli;

/// <summary>Process surroundings, injectable for tests.</summary>
internal sealed class CliHost
{
    public required TextReader In { get; init; }
    public required TextWriter Out { get; init; }
    public required TextWriter Error { get; init; }
    public required Func<string, string?> GetEnvironmentVariable { get; init; }
    public required Func<bool> IsInputRedirected { get; init; }
    /// <summary>Shows the prompt and reads a secret WITHOUT echo; null = cancelled.</summary>
    public required Func<string, string?> PromptHidden { get; init; }
    public required ICardAccess Cards { get; init; }

    public static CliHost FromConsole() => new()
    {
        In = Console.In,
        Out = Console.Out,
        Error = Console.Error,
        GetEnvironmentVariable = Environment.GetEnvironmentVariable,
        IsInputRedirected = () => Console.IsInputRedirected,
        PromptHidden = prompt => ReadHidden(prompt, Console.Error, () => Console.ReadKey(intercept: true)), // no echo
        Cards = new WinSCardAccess(),
    };

    /// <summary>Line editor for a secret typed on <paramref name="readKey"/>: Enter ends, Escape (or nothing) cancels.</summary>
    internal static string? ReadHidden(string prompt, TextWriter error, Func<ConsoleKeyInfo> readKey)
    {
        error.Write(prompt);
        var pin = new StringBuilder();
        while (true)
        {
            var key = readKey();
            if (key.Key == ConsoleKey.Enter) break;
            if (key.Key == ConsoleKey.Escape)
            {
                error.WriteLine();
                return null;
            }
            if (key.Key == ConsoleKey.Backspace)
            {
                if (pin.Length > 0) pin.Length--;
                continue;
            }
            if (!char.IsControl(key.KeyChar)) pin.Append(key.KeyChar);
        }
        error.WriteLine();
        return pin.Length == 0 ? null : pin.ToString();
    }
}

/// <summary>spec/cli.md PIN order: --pin-stdin → MSIGN_PIN → interactive prompt without echo. Never from argv.</summary>
internal static class PinSource
{
    public const string EnvironmentVariable = "MSIGN_PIN";

    public static ConsentResult Obtain(CliHost host, CliOptions options, ConsentRequest request)
    {
        if (options.PinStdin)
        {
            var line = host.In.ReadLine()?.TrimEnd('\r', '\n');
            if (string.IsNullOrEmpty(line)) throw new UsageException("--pin-stdin given but stdin had no PIN line");
            return ConsentResult.WithPin(line);
        }

        var fromEnvironment = host.GetEnvironmentVariable(EnvironmentVariable);
        if (!string.IsNullOrEmpty(fromEnvironment)) return ConsentResult.WithPin(fromEnvironment);

        if (host.IsInputRedirected())
            throw new UsageException($"no PIN: stdin is not a terminal; use --pin-stdin or set {EnvironmentVariable}");

        var pin = host.PromptHidden($"PIN QSCD for {request.Certificate.CommonName}: ");
        return pin is null ? ConsentResult.Cancelled : ConsentResult.WithPin(pin);
    }
}
