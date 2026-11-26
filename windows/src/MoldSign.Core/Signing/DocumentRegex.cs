using System.Diagnostics;
using System.Text.RegularExpressions;

namespace MoldSign.Core;

// Document text is untrusted. Bound both one match and enumeration of many cheap matches.
internal static class DocumentRegex
{
    internal const int MaximumDocumentBytes = 64 * 1024 * 1024;
    private const int MaximumMatches = 100_000;
    private static readonly TimeSpan Timeout = TimeSpan.FromSeconds(2);
    private static readonly AsyncLocal<ProcessingScope?> Current = new();

    internal sealed class ProcessingScope : IDisposable
    {
        private readonly ProcessingScope? previous = Current.Value;
        private readonly Stopwatch watch;
        internal ProcessingScope()
        {
            watch = previous?.watch ?? Stopwatch.StartNew();
            Current.Value = this;
        }
        internal void Check()
        {
            if (watch.Elapsed > TimeSpan.FromSeconds(10)) throw Limit();
        }
        public void Dispose() => Current.Value = previous;
    }

    internal static ProcessingScope BeginProcessing() => new();

    internal static void CheckLength(int length)
    {
        Current.Value?.Check();
        if (length > MaximumDocumentBytes) throw Limit();
    }

    internal static Match Match(string input, string pattern, RegexOptions options = RegexOptions.None)
    {
        CheckLength(input.Length);
        try
        {
            var result = Regex.Match(input, pattern, options, Timeout);
            Current.Value?.Check();
            return result;
        }
        catch (RegexMatchTimeoutException) { throw Limit(); }
    }

    internal static bool IsMatch(string input, string pattern, RegexOptions options = RegexOptions.None)
        => Match(input, pattern, options).Success;

    internal static MatchCollection Matches(string input, string pattern, RegexOptions options = RegexOptions.None)
    {
        CheckLength(input.Length);
        try
        {
            var watch = Stopwatch.StartNew();
            var matches = Regex.Matches(input, pattern, options, Timeout);
            var count = 0;
            foreach (Match _ in matches)
                if (++count > MaximumMatches || watch.Elapsed > Timeout) throw Limit();
            Current.Value?.Check();
            return matches;
        }
        catch (RegexMatchTimeoutException) { throw Limit(); }
    }

    internal static string Replace(string input, string pattern, string replacement)
    {
        CheckLength(input.Length);
        try
        {
            var result = Regex.Replace(input, pattern, replacement, RegexOptions.None, Timeout);
            Current.Value?.Check();
            return result;
        }
        catch (RegexMatchTimeoutException) { throw Limit(); }
    }

    private static CardException Limit() => new(CardErrorKind.Format, "Document exceeds safe processing limits");
}
