namespace MoldSign.Diagnostics;

/// <summary>Missing and legacy preferences are unknown and never authorize either signal.</summary>
public readonly record struct MonitoringConsent(bool DecisionMade = false, bool CrashReports = false, bool UsageMetrics = false)
{
    public bool CanSendCrash => DecisionMade && CrashReports;
    public bool CanSendMetrics => DecisionMade && UsageMetrics;
    public bool IsEnabled => CanSendCrash || CanSendMetrics;
}

public interface IMonitoringRuntime : IDisposable
{
    void RecordNavigation(string page);
    void RecordSessionDuration();
    Task FlushAsync();
}

/// <summary>Consent policy independent of the SDK, persistence and WinUI.</summary>
public sealed class MonitoringController : IDisposable
{
    private readonly Func<MonitoringConsent, IMonitoringRuntime> _start;
    private readonly Action<MonitoringConsent> _persist;
    private IMonitoringRuntime? _runtime;
    private readonly Action _purge;
    public MonitoringConsent Consent { get; private set; }
    public bool NeedsPrompt => !Consent.DecisionMade;
    public bool IsSuspended { get; private set; }
    public event Action<MonitoringConsent>? Changed;

    public MonitoringController(MonitoringConsent initial, Func<MonitoringConsent, IMonitoringRuntime> start,
        Action<MonitoringConsent> persist, Action? purge = null, bool suspended = false)
    {
        Consent = initial;
        IsSuspended = suspended;
        _start = start;
        _persist = persist;
        _purge = purge ?? AppDiagnostics.PurgeCache;
        _purge();
        if (initial.IsEnabled && !IsSuspended) _runtime = _start(initial);
    }

    public void Apply(bool crashReports, bool usageMetrics)
    {
        var next = new MonitoringConsent(true, crashReports, usageMetrics);
        if (next == Consent) return;
        // Revoke before stopping the old generation. Stop never flushes. Its transport is cancelled.
        Consent = next;
        _runtime?.Dispose();
        _runtime = null;
        _persist(next);
        _purge();
        if (next.IsEnabled && !IsSuspended) _runtime = _start(next);
        Changed?.Invoke(next);
    }

    public void SetSuspended(bool suspended)
    {
        if (IsSuspended == suspended) return;
        IsSuspended = suspended;
        _runtime?.Dispose(); _runtime = null;
        _purge();
        if (!suspended && Consent.IsEnabled) _runtime = _start(Consent);
        Changed?.Invoke(Consent);
    }

    public void RecordNavigation(string page)
    {
        if (!IsSuspended && Consent.CanSendMetrics) _runtime?.RecordNavigation(page);
    }

    public async Task ShutdownAsync()
    {
        if (!IsSuspended && Consent.CanSendMetrics) _runtime?.RecordSessionDuration();
        // Normal explicit quit may flush signals the user currently permits. Revocation never uses this path.
        if (!IsSuspended && Consent.IsEnabled && _runtime is not null) await _runtime.FlushAsync();
        Dispose();
    }

    public void Dispose()
    {
        _runtime?.Dispose();
        _runtime = null;
    }
}
