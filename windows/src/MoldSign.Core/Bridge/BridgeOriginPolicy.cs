using System.Text;
using System.Text.RegularExpressions;

namespace MoldSign.Core;

/// <summary>
/// Bridge origin enforcement (SEC-01, docs/09 §3.6), a faithful port of the vendor's
/// <c>AllowedSites.java</c> + <c>Certificates.java</c> check:
/// <list type="bullet">
/// <item>Every VALUE of <c>spec/bridge/allowed-origins.properties</c> is used (the file repeats the
/// <c>gov</c> key; Java keeps only the last, <c>*.gov.md</c>, which covers the first anyway).</item>
/// <item>Each value becomes a regex the vendor way: <c>.</c> → <c>\.</c>, <c>?</c> → <c>.?</c>,
/// <c>*</c> → <c>.*</c>; the WHOLE Origin header must match (Java <c>String.matches</c>, case-sensitive).</item>
/// <item>The <c>moldSign: DesktopSuiteClient</c> header is accepted ONLY when there is no Origin.</item>
/// </list>
/// </summary>
public sealed class BridgeOriginPolicy
{
    public const string DesktopClientHeaderName = "moldSign";
    public const string DesktopClientHeaderValue = "DesktopSuiteClient";
    private const string ResourceName = "MoldSign.Core.Bridge.allowed-origins.properties";

    private static readonly Lazy<BridgeOriginPolicy> s_default = new(LoadDefault);
    private readonly Regex[] _regexes;

    public BridgeOriginPolicy(IEnumerable<string> patterns)
    {
        ArgumentNullException.ThrowIfNull(patterns);
        Patterns = patterns.ToArray();
        _regexes = Patterns
            .Select(p => new Regex(@"\A(?:" + ToRegex(p) + @")\z", RegexOptions.CultureInvariant))
            .ToArray();
    }

    /// <summary>The vendor allow-list embedded from <c>spec/bridge/allowed-origins.properties</c>.</summary>
    public static BridgeOriginPolicy Default => s_default.Value;

    /// <summary>Raw allow-list values, in file order, duplicates kept.</summary>
    public IReadOnlyList<string> Patterns { get; }

    /// <summary>
    /// True when the request may use the bridge. <paramref name="origin"/> is the Origin header
    /// (null = absent); <paramref name="moldSignHeader"/> is the <c>moldSign</c> header (null = absent).
    /// </summary>
    public bool IsAllowed(string? origin, string? moldSignHeader)
    {
        if (origin is not null)
        {
            foreach (var regex in _regexes)
            {
                if (regex.IsMatch(origin)) return true;
            }
            return false;
        }
        return string.Equals(moldSignHeader, DesktopClientHeaderValue, StringComparison.Ordinal);
    }

    /// <summary>The vendor's conversion: <c>url.replaceAll("\\.", "\\\\.").replaceAll("\\?", ".?").replaceAll("\\*", ".*")</c>.</summary>
    public static string ToRegex(string pattern)
    {
        ArgumentNullException.ThrowIfNull(pattern);
        return pattern.Replace(".", @"\.").Replace("?", ".?").Replace("*", ".*");
    }

    /// <summary>Policy from Java-properties text (all values, comments and blank lines skipped).</summary>
    public static BridgeOriginPolicy FromProperties(string text) => new(ParsePropertyValues(text));

    /// <summary>
    /// Values of a simple Java <c>.properties</c> file: <c>#</c>/<c>!</c> comments, key and value split at the
    /// first <c>=</c>, <c>:</c> or whitespace, leading whitespace of the value dropped. Every line counts,
    /// so duplicate keys keep all their values. Line continuations and escapes are not used by the
    /// allow-list and are not supported.
    /// </summary>
    public static IReadOnlyList<string> ParsePropertyValues(string text)
    {
        ArgumentNullException.ThrowIfNull(text);
        var values = new List<string>();
        foreach (var rawLine in text.Split('\n'))
        {
            var line = rawLine.TrimEnd('\r').TrimStart();
            if (line.Length == 0 || line[0] is '#' or '!') continue;

            // Key ends at the first '=', ':' or whitespace (Java Properties.load).
            var i = line.IndexOfAny(['=', ':', ' ', '\t', '\f']);
            if (i < 0) continue; // key without value
            var terminatorWasSeparator = line[i] is '=' or ':';
            i++;
            while (i < line.Length && IsPropertiesWhitespace(line[i])) i++;
            // "key = value": whitespace ended the key, the '=' / ':' still belongs to the separator.
            if (!terminatorWasSeparator && i < line.Length && line[i] is '=' or ':')
            {
                i++;
                while (i < line.Length && IsPropertiesWhitespace(line[i])) i++;
            }
            var value = line[i..].TrimEnd();
            if (value.Length > 0) values.Add(value);
        }
        return values;
    }

    private static bool IsPropertiesWhitespace(char c) => c is ' ' or '\t' or '\f';

    private static BridgeOriginPolicy LoadDefault()
    {
        using var stream = typeof(BridgeOriginPolicy).Assembly.GetManifestResourceStream(ResourceName)
            ?? throw new InvalidOperationException($"Embedded resource {ResourceName} is missing");
        using var reader = new StreamReader(stream, Encoding.UTF8);
        return FromProperties(reader.ReadToEnd());
    }
}
