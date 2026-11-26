using System.Diagnostics;

namespace MoldSign.Core.Tests;

/// <summary>Untrusted documents and origins hit bounded regex work and fail closed instead of hanging the app.</summary>
public sealed class ProcessingLimitTests
{
    // Nested unbounded wildcards backtrack polynomially on a long run without the final 'b'.
    private const string Backtracking = "(?:.*a){12}b";
    private static readonly string s_adversarial = new('a', 20_000);

    [Theory]
    [InlineData("match")]
    [InlineData("is-match")]
    [InlineData("matches")]
    [InlineData("replace")]
    public void Document_regexes_that_exceed_their_time_budget_report_a_format_limit(string operation)
    {
        var watch = Stopwatch.StartNew();
        var error = Assert.Throws<CardException>(() =>
        {
            _ = operation switch
            {
                "match" => DocumentRegex.Match(s_adversarial, Backtracking).Success,
                "is-match" => DocumentRegex.IsMatch(s_adversarial, Backtracking),
                "matches" => DocumentRegex.Matches(s_adversarial, Backtracking).Count > 0,
                _ => DocumentRegex.Replace(s_adversarial, Backtracking, "") is not null,
            };
        });
        Assert.Equal(CardErrorKind.Format, error.Kind);
        Assert.Equal("Document exceeds safe processing limits", error.Message);
        Assert.True(watch.Elapsed < TimeSpan.FromSeconds(30), $"took {watch.Elapsed}");
    }

    [Fact]
    public void Ordinary_document_patterns_stay_within_the_budget()
    {
        Assert.Equal("7", DocumentRegex.Match("/Root 7 0 R", @"/Root\s+(\d+)\s+0\s+R\b").Groups[1].Value);
        Assert.Equal(2, DocumentRegex.Matches("1 0 obj 2 0 obj", @"(\d+)\s+0\s+obj").Count);
        Assert.Equal("ABCD", DocumentRegex.Replace("A B\nC D", @"\s", ""));
    }

    [Fact]
    public void An_origin_that_makes_an_allow_list_pattern_backtrack_is_refused()
    {
        var policy = new BridgeOriginPolicy(["https://*a*a*a*a*a*a*a*a*a*a*a*a*b.md"]);
        Assert.True(policy.IsAllowed("https://aaaaaaaaaaaab.md", null));

        var watch = Stopwatch.StartNew();
        Assert.False(policy.IsAllowed("https://" + new string('a', 4000) + ".md", null));
        Assert.True(watch.Elapsed < TimeSpan.FromSeconds(30), $"took {watch.Elapsed}");
    }

    [Fact]
    public void Verification_refuses_documents_above_the_size_limit_before_reading_them()
    {
        var path = Path.Combine(Path.GetTempPath(), $"moldsign-oversized-{Guid.NewGuid():N}.pdf");
        try
        {
            using (var file = new FileStream(path, FileMode.CreateNew)) file.SetLength(DocumentRegex.MaximumDocumentBytes + 1L);
            var service = new SigningService(() => throw new InvalidOperationException("verification never opens a card"));
            var error = Assert.Throws<CardException>(() => service.Verify(path));
            Assert.Equal(CardErrorKind.Format, error.Kind);
            Assert.Equal("Document exceeds safe processing limits", error.Message);
        }
        finally { File.Delete(path); }
    }
}
