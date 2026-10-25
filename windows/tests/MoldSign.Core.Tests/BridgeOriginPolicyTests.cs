namespace MoldSign.Core.Tests;

/// <summary>SEC-01: vendor allow-list semantics (docs/09 §3.6).</summary>
public class BridgeOriginPolicyTests
{
    private static readonly BridgeOriginPolicy Policy = BridgeOriginPolicy.Default;

    [Fact]
    public void Portal_origin_is_allowed() => Assert.True(Policy.IsAllowed("https://msign.gov.md", null));

    [Fact]
    public void Foreign_origin_is_denied() => Assert.False(Policy.IsAllowed("https://evil.example", null));

    [Fact]
    public void No_origin_with_desktop_header_is_allowed() =>
        Assert.True(Policy.IsAllowed(null, "DesktopSuiteClient"));

    [Fact]
    public void No_origin_without_desktop_header_is_denied() => Assert.False(Policy.IsAllowed(null, null));

    [Theory]
    [InlineData("desktopsuiteclient")]
    [InlineData("DesktopSuiteClient ")]
    [InlineData("")]
    public void Desktop_header_must_match_exactly(string header) => Assert.False(Policy.IsAllowed(null, header));

    [Fact]
    public void Desktop_header_does_not_rescue_a_foreign_origin() =>
        Assert.False(Policy.IsAllowed("https://evil.example", "DesktopSuiteClient"));

    [Theory]
    [InlineData("https://testmsign.gov.md")]
    [InlineData("https://mpass.gov.md")]
    [InlineData("https://edocs.gov.md")]
    [InlineData("https://anything.gov.md")]          // *.gov.md
    [InlineData("http://anything.gov.md")]           // '*' also swallows the scheme
    [InlineData("https://sgre.micb.md")]             // https://*.micb.md
    [InlineData("https://localhost.cts.md:18443")]   // *.cts.md does NOT cover a port: see below
    [InlineData("http://localhost")]
    public void Allow_list_samples(string origin)
    {
        var expected = origin != "https://localhost.cts.md:18443";
        Assert.Equal(expected, Policy.IsAllowed(origin, null));
    }

    [Theory]
    [InlineData("http://localhost:3000")]               // full match: ports are not wildcarded
    [InlineData("HTTPS://MSIGN.GOV.MD")]                // Java String.matches is case-sensitive
    [InlineData("https://msign.gov.md.evil.example")]   // anchored at both ends
    [InlineData("https://msignXgov.md")]                // '.' is escaped
    [InlineData("null")]                                // opaque origin
    [InlineData("")]
    public void Near_misses_are_denied(string origin) => Assert.False(Policy.IsAllowed(origin, null));

    [Fact]
    public void Every_value_is_read_including_the_duplicate_gov_key()
    {
        Assert.Equal(73, Policy.Patterns.Count);
        Assert.Contains("https://msign.gov.md", Policy.Patterns);
        Assert.Contains("*.gov.md", Policy.Patterns);
        Assert.Equal("*.cts.md", Policy.Patterns[0]);
        Assert.Equal("*.bnm.md", Policy.Patterns[^1]);
    }

    [Theory]
    [InlineData("*.gov.md", @".*\.gov\.md")]
    [InlineData("https://msign.gov.md", @"https://msign\.gov\.md")]
    [InlineData("http://a?b", @"http://a.?b")]
    public void Vendor_regex_conversion(string pattern, string regex) =>
        Assert.Equal(regex, BridgeOriginPolicy.ToRegex(pattern));

    [Fact]
    public void Properties_parser_handles_separators_and_comments()
    {
        const string text = "# comment\n! bang comment\n\na=one\nb:two\nc three\nd = four\r\ne\t:\tfive\nf=\n";
        Assert.Equal(new[] { "one", "two", "three", "four", "five" }, BridgeOriginPolicy.ParsePropertyValues(text));
    }
}
