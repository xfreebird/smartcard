using System.Text.RegularExpressions;
using System.Xml.Linq;
using MoldSign.Desktop;

namespace MoldSign.Core.Tests;

/// <summary>Demo wording ("simulated", "fictional", DEMO-NOT-SIGNED) is reachable only while demo mode is on.</summary>
public partial class DemoPresentationTests
{
    private static readonly string s_app = Path.Combine(VectorFile.RepoRoot, "windows", "src", "MoldSign.App");
    private static readonly Verdict?[] s_verdicts = [Verdict.Valid, Verdict.Invalid, Verdict.Indeterminate, null];

    [GeneratedRegex(@"(?i)simulat|fictional|fictiv|\bdemo\b|not a valid|не является|демо|вымышлен")]
    private static partial Regex DemoWording();

    [GeneratedRegex(@"""(?<key>[Dd]emo_[A-Za-z_]+)""")]
    private static partial Regex DemoKeyLiteral();

    [Fact]
    public void Real_session_outcomes_never_use_demo_wording()
    {
        var keys = new List<string>
        {
            OutcomeMessages.SignedActivityKey(demo: false), OutcomeMessages.BatchSignedKey(demo: false),
            OutcomeMessages.VerifiedActivityKey(demo: false),
            OutcomeMessages.VerificationFailureKey(VerificationStatus.Unsupported),
            OutcomeMessages.VerificationFailureKey(VerificationStatus.Unreadable),
            OutcomeMessages.VerificationFailureKey(VerificationStatus.Failed),
        };
        foreach (var verdict in s_verdicts)
            foreach (var capture in new[] { false, true })
                keys.Add(OutcomeMessages.VerificationKey(demo: false, capture, verdict));

        foreach (var language in Languages())
        {
            var strings = Strings(language);
            foreach (var key in keys)
            {
                Assert.False(key.StartsWith(OutcomeMessages.DemoKeyPrefix, StringComparison.OrdinalIgnoreCase), key);
                Assert.True(strings.TryGetValue(key, out var text), $"{language}: missing {key}");
                Assert.DoesNotMatch(DemoWording(), text);
            }
        }
        Assert.Equal("Verdict_Valid", OutcomeMessages.VerificationKey(false, false, Verdict.Valid));
        Assert.Equal("Verdict_Invalid", OutcomeMessages.VerificationKey(false, false, Verdict.Invalid));
        Assert.Equal("Verdict_Unknown", OutcomeMessages.VerificationKey(false, false, Verdict.Indeterminate));
        Assert.Equal("Verdict_Unsigned", OutcomeMessages.VerificationKey(false, false, null));
    }

    [Fact]
    public void Demo_session_outcomes_say_the_result_is_simulated()
    {
        var english = Strings("en-US");
        Assert.Contains("not a valid signature", english[OutcomeMessages.SignedActivityKey(demo: true)]);
        Assert.Equal(OutcomeMessages.SignedActivityKey(demo: true), OutcomeMessages.BatchSignedKey(demo: true));
        Assert.Contains("simulated", english[OutcomeMessages.VerifiedActivityKey(demo: true)]);
        foreach (var verdict in s_verdicts)
            Assert.Equal("demo_verify_success", OutcomeMessages.VerificationKey(demo: true, screenshotCapture: false, verdict));
        // Debug screenshot fixtures show the verdict being captured, still inside the demo session.
        Assert.Equal("Verdict_Invalid", OutcomeMessages.VerificationKey(demo: true, screenshotCapture: true, Verdict.Invalid));
        foreach (var language in Languages())
            Assert.Matches(DemoWording(), Strings(language)[OutcomeMessages.SignedActivityKey(demo: true)]);
    }

    [Fact]
    public void Only_a_demo_session_rejects_selected_documents()
    {
        Assert.Equal("demo_fixture_only", OutcomeMessages.VerificationFailureKey(VerificationStatus.Rejected));
        var verifier = new StubVerifier();
        using var demo = new DemoSession();
        var outside = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString("N") + ".pdf");
        // AppServices gates real sessions with "!IsDemo || owned by the demo sandbox".
        var real = new VerifyDocument(verifier, path => true);
        var sandboxed = new VerifyDocument(demo, demo.Owns);
        Assert.Equal(VerificationStatus.Completed, real.Execute(outside).Status);
        Assert.Equal(VerificationStatus.Rejected, sandboxed.Execute(outside).Status);
        Assert.Equal(1, verifier.Calls);
    }

    [Fact]
    public void Every_demo_string_uses_the_demo_key_prefix()
    {
        var checkedStrings = 0;
        foreach (var language in Languages())
            foreach (var (key, text) in Strings(language).Where(entry => DemoWording().IsMatch(entry.Value)))
            {
                checkedStrings++;
                Assert.True(key.StartsWith(OutcomeMessages.DemoKeyPrefix, StringComparison.OrdinalIgnoreCase),
                    $"{language}: '{key}' has demo wording without the {OutcomeMessages.DemoKeyPrefix} prefix: {text}");
            }
        Assert.True(checkedStrings >= 3 * 10, "The demo strings were not found");
    }

    /// <summary>
    /// Every place that can show a demo string was reviewed to be demo-gated (or to be the demo switch itself in
    /// Settings). A new reference must be gated on demo mode, then added here.
    /// </summary>
    [Fact]
    public void Demo_strings_are_shown_only_from_reviewed_demo_gated_places()
    {
        var reviewed = new Dictionary<string, string[]>(StringComparer.Ordinal)
        {
            // Demo sandbox: only sample documents may be chosen, dropped, signed or verified.
            ["Views/SignPage.xaml.cs"] = ["demo_fixture_only"],
            ["Views/VerifyPage.xaml.cs"] = ["demo_fixture_only"],
            ["Presentation/DocumentSelectionProvider.cs"] = ["demo_fixture_only"],
            ["Services/AppServices.cs"] = ["demo_fixture_only"],
            // Banner text; MainWindow/TrayFlyoutWindow bind it to DemoBannerVisible/DemoVisibility.
            ["Services/AppState.cs"] = ["demo_mode_disclaimer"],
            // Browser connection status while the bridge is replaced by the demo preview.
            ["Services/BrowserConnectionController.cs"] = ["demo_mode_disclaimer"],
            // The switch itself, its confirmation and its busy message.
            ["Views/SettingsPage.xaml.cs"] = ["demo_mode_title", "demo_mode_description", "demo_enable_title",
                "demo_mode_confirm", "demo_mode_enable", "demo_switch_busy"],
        };
        var found = new Dictionary<string, SortedSet<string>>(StringComparer.Ordinal);
        foreach (var file in Directory.EnumerateFiles(s_app, "*.cs", SearchOption.AllDirectories))
        {
            var relative = Path.GetRelativePath(s_app, file).Replace('\\', '/');
            if (relative.StartsWith("obj/", StringComparison.Ordinal) || relative.StartsWith("bin/", StringComparison.Ordinal)) continue;
            foreach (Match match in DemoKeyLiteral().Matches(File.ReadAllText(file)))
            {
                if (!found.TryGetValue(relative, out var keys)) found[relative] = keys = new SortedSet<string>(StringComparer.Ordinal);
                keys.Add(match.Groups["key"].Value);
            }
        }
        foreach (var (file, keys) in found)
        {
            var allowed = reviewed.GetValueOrDefault(file);
            Assert.True(allowed is not null, $"{file} shows demo strings: {string.Join(", ", keys)}");
            Assert.Empty(keys.Except(allowed, StringComparer.Ordinal));
        }

        var state = File.ReadAllText(Path.Combine(s_app, "Services", "AppState.cs"));
        Assert.Contains("public bool DemoBannerVisible => _isDemo && !DemoMode.ScreenshotCapture;", state);
        Assert.Contains("public Visibility DemoVisibility => _isDemo ? Visibility.Visible : Visibility.Collapsed;", state);
        var main = File.ReadAllText(Path.Combine(s_app, "MainWindow.xaml"));
        Assert.Contains("IsOpen=\"{x:Bind State.DemoBannerVisible, Mode=OneWay}\"", main);
        var flyout = File.ReadAllText(Path.Combine(s_app, "Tray", "TrayFlyoutWindow.xaml"));
        Assert.Contains("Visibility=\"{x:Bind State.DemoVisibility, Mode=OneWay}\"", flyout);
    }

    [Fact]
    public void Only_the_demo_sandbox_names_outputs_not_signed()
    {
        using var demo = new DemoSession();
        var simulated = Assert.Single(demo.Sign(demo.Documents[0], SignatureFormat.PadesT, XadesPackaging.Detached,
            _ => throw new InvalidOperationException("Demo must not request a PIN")).OutputFiles);
        Assert.StartsWith(demo.DirectoryPath, simulated, StringComparison.Ordinal);
        Assert.EndsWith("-DEMO-NOT-SIGNED.pdf", simulated, StringComparison.Ordinal);

        var real = SigningService.DefaultOutputPath(Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString("N"), "contract.pdf"));
        Assert.EndsWith("contract-semnat.pdf", real, StringComparison.Ordinal);
        Assert.DoesNotContain("DEMO", real, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("DEMO", SigningService.DefaultOutputPath("note.txt", ".xml"), StringComparison.OrdinalIgnoreCase);
    }

    private static IEnumerable<string> Languages() => ["en-US", "ro-RO", "ru-RU"];

    private static Dictionary<string, string> Strings(string language) =>
        XDocument.Load(Path.Combine(s_app, "Strings", language, "Resources.resw")).Root!.Elements("data")
            .ToDictionary(data => (string)data.Attribute("name")!, data => (string?)data.Element("value") ?? "", StringComparer.Ordinal);

    private sealed class StubVerifier : IDocumentVerifier
    {
        public int Calls { get; private set; }
        public IReadOnlyList<VerificationReport> Verify(string file, IReadOnlyList<string>? detachedDocs = null)
        {
            Calls++;
            return [];
        }
    }
}
