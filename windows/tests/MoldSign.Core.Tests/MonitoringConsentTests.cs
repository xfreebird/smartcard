using MoldSign.Diagnostics;
using MoldSign.Desktop;

namespace MoldSign.Core.Tests;

public class MonitoringConsentTests
{
    [Fact]
    public async Task UnknownAndDeclineNeverInitializeOrFlush()
    {
        var starts = 0;
        var persisted = default(MonitoringConsent);
        using var controller = new MonitoringController(default, _ => { starts++; return new FakeRuntime(); },
            value => persisted = value, () => { });
        Assert.True(controller.NeedsPrompt);
        Assert.False(controller.Consent.CanSendCrash);
        Assert.False(controller.Consent.CanSendMetrics);
        controller.RecordNavigation("sign");
        controller.Apply(false, false);
        await controller.ShutdownAsync();
        Assert.Equal(0, starts);
        Assert.True(persisted.DecisionMade);
        Assert.False(controller.NeedsPrompt);
        Assert.False(persisted.IsEnabled);
    }

    [Fact]
    public void UnknownConsentCannotBeInferredFromStrayTrueSignalFlags()
    {
        using var controller = new MonitoringController(new(false, true, true),
            _ => throw new Exception("Unknown consent must not initialize the SDK"), _ => { }, () => { });
        Assert.True(controller.NeedsPrompt);
        Assert.False(controller.Consent.CanSendCrash);
        Assert.False(controller.Consent.CanSendMetrics);
    }

    [Theory]
    [InlineData(true, false)]
    [InlineData(false, true)]
    [InlineData(true, true)]
    public async Task RestoredConsentGatesEachSignal(bool crash, bool metrics)
    {
        var runtime = new FakeRuntime();
        MonitoringConsent started = default;
        using var controller = new MonitoringController(new(true, crash, metrics), value => { started = value; return runtime; },
            _ => throw new Exception("Restore must not change persisted consent"), () => { });
        Assert.False(controller.NeedsPrompt);
        Assert.Equal(crash, started.CanSendCrash);
        Assert.Equal(metrics, started.CanSendMetrics);
        controller.RecordNavigation("sign");
        Assert.Equal(metrics ? 1 : 0, runtime.Navigations);
        await controller.ShutdownAsync();
        Assert.Equal(metrics ? 1 : 0, runtime.Durations);
        Assert.Equal(1, runtime.Flushes);
        Assert.True(runtime.Stopped);
    }

    [Fact]
    public void RevocationStopsOldGenerationWithoutFlushAndPurgesCache()
    {
        var runtime = new FakeRuntime();
        var purges = 0;
        using var controller = new MonitoringController(new(true, true, true), _ => runtime, _ => { }, () => purges++);
        controller.Apply(false, false);
        controller.RecordNavigation("sign");
        Assert.True(runtime.Stopped);
        Assert.Equal(0, runtime.Flushes);
        Assert.Equal(0, runtime.Navigations);
        Assert.Equal(0, runtime.Durations);
        Assert.Equal(2, purges); // startup cache purge and opt-out purge
    }

    [Fact]
    public void ChangingOneSignalRebuildsRuntimeWithOnlyCurrentConsent()
    {
        var started = new List<MonitoringConsent>();
        var generations = new List<FakeRuntime>();
        using var controller = new MonitoringController(new(true, true, false), value =>
        {
            started.Add(value);
            var runtime = new FakeRuntime(); generations.Add(runtime); return runtime;
        }, _ => { }, () => { });
        controller.Apply(false, true);
        Assert.True(generations[0].Stopped);
        Assert.Equal(0, generations[0].Flushes);
        Assert.False(started[1].CanSendCrash);
        Assert.True(started[1].CanSendMetrics);
    }

    [Theory]
    [InlineData(false, false)]
    [InlineData(true, false)]
    [InlineData(false, true)]
    [InlineData(true, true)]
    public void PreferencesRoundTripPreservesDecisionAndSeparateFlags(bool crash, bool metrics)
    {
        var directory = Path.Combine(Path.GetTempPath(), "esemnbun-consent-" + Guid.NewGuid().ToString("N"));
        try
        {
            var store = new DesktopPreferenceStore(Path.Combine(directory, "settings.json"));
            Assert.False(store.Load<DesktopPreferences>().MonitoringDecisionMade);
            store.Save(new DesktopPreferences
            {
                MonitoringDecisionMade = true, MonitoringCrashReports = crash, MonitoringUsageMetrics = metrics,
            });
            var restored = store.Load<DesktopPreferences>();
            Assert.True(restored.MonitoringDecisionMade);
            Assert.Equal(crash, restored.MonitoringCrashReports);
            Assert.Equal(metrics, restored.MonitoringUsageMetrics);
        }
        finally { if (Directory.Exists(directory)) Directory.Delete(directory, true); }
    }

    [Fact]
    public void DemoSuspensionPreventsInitializationDespitePersistedRealConsent()
    {
        var starts = 0;
        var runtime = new FakeRuntime();
        using var controller = new MonitoringController(new(true, true, true), _ => { starts++; return runtime; },
            _ => throw new Exception("Suspension must preserve consent"), () => { }, suspended: true);
        controller.RecordNavigation("sign");
        Assert.Equal(0, starts);
        Assert.Equal(0, runtime.Navigations);
        controller.SetSuspended(false);
        Assert.Equal(1, starts);
        controller.SetSuspended(true);
        Assert.True(runtime.Stopped);
        Assert.Equal(0, runtime.Flushes);
        Assert.True(controller.Consent.CanSendCrash);
        Assert.True(controller.Consent.CanSendMetrics);
    }

    [Fact]
    public void DecliningWhileDemoSuspendedCannotEnableMonitoringOnExit()
    {
        var starts = 0;
        using var controller = new MonitoringController(new(true, true, true), _ => { starts++; return new FakeRuntime(); },
            _ => { }, () => { }, suspended: true);
        controller.Apply(false, false);
        controller.SetSuspended(false);
        Assert.Equal(0, starts);
    }

    private sealed class FakeRuntime : IMonitoringRuntime
    {
        public int Navigations, Durations, Flushes;
        public bool Stopped;
        public void RecordNavigation(string page) => Navigations++;
        public void RecordSessionDuration() => Durations++;
        public Task FlushAsync() { Flushes++; return Task.CompletedTask; }
        public void Dispose() => Stopped = true;
    }
}
