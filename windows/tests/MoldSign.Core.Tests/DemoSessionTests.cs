using MoldSign.Core;
using MoldSign.Desktop;

namespace MoldSign.Core.Tests;

public class DemoSessionTests
{
    [Fact]
    public void HappySigningAndVerificationUseOnlyFictionalFixturesWithoutPinOrCryptoSignature()
    {
        using var demo = new DemoSession();
        var input = demo.Documents[0];
        var before = File.ReadAllBytes(input);
        var signed = demo.Sign(input, SignatureFormat.PadesT, XadesPackaging.Detached,
            _ => throw new Exception("Demo must not request a PIN"), reader: "Demo reader 2");
        var output = Assert.Single(signed.OutputFiles);
        Assert.Contains("DEMO-NOT-SIGNED", output);
        Assert.NotEqual(input, output);
        Assert.Equal(before, File.ReadAllBytes(input));
        Assert.Equal("ISTRATI ELENA", signed.Certificate.CommonName);
        Assert.Equal("DEMO", signed.Format);
        Assert.Empty(new Validator().ValidatePdf(File.ReadAllBytes(output))); // no real PDF signature
        var report = Assert.Single(demo.Verify(output));
        Assert.Equal("DEMO", report.Kind);
        Assert.Equal(Verdict.Valid, report.Verdict); // explicitly simulated happy-state model
    }

    [Fact]
    public void ArbitraryDocumentsAreRejectedWithoutReadingOrChangingThem()
    {
        using var demo = new DemoSession();
        var outside = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString("N") + ".pdf");
        File.WriteAllText(outside, "PRIVATE SAMPLE - MUST REMAIN UNCHANGED");
        try
        {
            using (var locked = File.Open(outside, FileMode.Open, FileAccess.ReadWrite, FileShare.None))
            {
                Assert.False(demo.Owns(outside));
                Assert.Throws<InvalidOperationException>(() => demo.Sign(outside, SignatureFormat.PadesT,
                    XadesPackaging.Detached, _ => throw new Exception("No credential access")));
                Assert.Throws<InvalidOperationException>(() => demo.Verify(outside));
                Assert.Throws<InvalidOperationException>(() => demo.Verify(demo.Documents[0], [outside]));
            }
            Assert.Equal("PRIVATE SAMPLE - MUST REMAIN UNCHANGED", File.ReadAllText(outside));
        }
        finally { File.Delete(outside); }
    }

    [Fact]
    public void XmlOutputIsClearlySimulatedAndHasNoDigitalSignatureElement()
    {
        using var demo = new DemoSession();
        var result = demo.Sign(demo.Documents[1], SignatureFormat.XadesT, XadesPackaging.Detached,
            _ => throw new Exception("No credential access"));
        var xml = File.ReadAllText(Assert.Single(result.OutputFiles));
        Assert.Contains("legallyValid=\"false\"", xml);
        Assert.DoesNotContain("<ds:Signature", xml);
        Assert.DoesNotContain("SignatureValue", xml);
    }

    [Fact]
    public async Task DemoVaultRetainsNothingAndHasNoCredentialContainer()
    {
        var vault = new DemoPinVault();
        vault.Save("ignored-fictional-value", "fictional-card");
        Assert.False(vault.Contains("fictional-card"));
        Assert.Null(await vault.LoadAsync("fictional-card", "DEMO"));
        Assert.Empty(vault.SavedCards());
        vault.Delete("fictional-card"); vault.DeleteAll();
    }

    [Fact]
    public async Task PersistedDemoStopsHelperBeforeAnyHardwareSnapshot()
    {
        var preferences = new DesktopPreferences { DemoModeEnabled = true, OpenOnCardInsertion = true, OpenOnReaderInsertion = true };
        Assert.False(preferences.InsertionHelperEnabled);
        var watcher = new InsertionWatcher(new ForbiddenReaders(), new ForbiddenActivator(), () => preferences);
        Assert.False(await watcher.CheckAsync(CancellationToken.None));
    }
    [Fact]
    public void PersistentDemoFlagPreservesRealModeChoices()
    {
        var path = Path.Combine(Path.GetTempPath(), "demo-preferences-" + Guid.NewGuid().ToString("N"), "settings.json");
        try
        {
            var store = new DesktopPreferenceStore(path);
            store.Save(new DesktopPreferences { DemoModeEnabled = true, RememberPin = true, BridgeEnabled = true,
                OpenOnCardInsertion = true, MonitoringDecisionMade = true, MonitoringCrashReports = true });
            var restored = store.Load<DesktopPreferences>();
            Assert.True(restored.DemoModeEnabled);
            Assert.True(restored.RememberPin);
            Assert.True(restored.BridgeEnabled);
            Assert.True(restored.OpenOnCardInsertion);
            Assert.True(restored.MonitoringCrashReports);
            Assert.False(restored.InsertionHelperEnabled);
            restored.DemoModeEnabled = false;
            store.Save(restored);
            Assert.True(store.Load<DesktopPreferences>().InsertionHelperEnabled);
        }
        finally { Directory.Delete(Path.GetDirectoryName(path)!, true); }
    }

    private sealed class ForbiddenReaders : IReaderSnapshotSource
    { public IReadOnlyList<ReaderStatus> Read() => throw new Exception("Demo must not enumerate hardware"); }
    private sealed class ForbiddenActivator : IApplicationActivator
    { public Task OpenAsync(CancellationToken token) => throw new Exception("Demo must not launch a real activation"); }
}
