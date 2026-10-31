using System.Runtime.InteropServices;
using System.Diagnostics;
using System.Text.Json;
using Sentry;
using Sentry.Protocol;

namespace MoldSign.Diagnostics;

/// <summary>
/// App-only diagnostics boundary. The signing core, document bytes, PINs and card metadata never
/// become telemetry. Automatic events are rebuilt from a code/symbol-only allowlist before transport.
/// </summary>
public static class AppDiagnostics
{
    private const string Dsn = "https://18522837b40ec8eb6753adb68739eda1@o4512349416980480.ingest.de.sentry.io/4512349473865808";
    private static readonly string Version = typeof(AppDiagnostics).Assembly.GetName().Version?.ToString(3) ?? "0.2.0";
    private static readonly string Release = "esemnbun-windows@" + Version;
    private static readonly string Distribution = RuntimeInformation.ProcessArchitecture.ToString().ToLowerInvariant();
#if DEBUG
    private const string EnvironmentName = "development";
#else
    private const string EnvironmentName = "production";
#endif

    public static IMonitoringRuntime Start(MonitoringConsent consent)
    {
        if (!consent.IsEnabled) throw new InvalidOperationException("Monitoring requires consent.");
        return new Runtime(consent);
    }

    public static void PurgeCache()
    {
        // A previous SDK generation must never be replayed after revocation/re-consent.
        var path = Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.LocalApplicationData), "MoldSign", "Sentry");
        try { if (Directory.Exists(path)) Directory.Delete(path, recursive: true); }
        catch (IOException) { }
        catch (UnauthorizedAccessException) { }
    }

    private static IDisposable Initialize(MonitoringConsent consent, CancellationToken revoked) => SentrySdk.Init(options =>
    {
        options.Dsn = Dsn;
        options.Release = Release;
        options.Environment = EnvironmentName;
        options.Distribution = Distribution;
        options.IsGlobalModeEnabled = true;
        options.SendDefaultPii = false;
        options.IsEnvironmentUser = false;
        options.ServerName = null;
        options.Debug = false;
        options.MaxBreadcrumbs = 0;
        options.SetBeforeBreadcrumb(_ => null);
        options.EnableLogs = false;
        options.SetBeforeSendMetric(metric => consent.CanSendMetrics && !revoked.IsCancellationRequested && IsAllowedMetric(metric.Name) ? metric : null);
        options.SetBeforeSendLog(_ => null);
        options.AutoSessionTracking = false;
        options.MaxAttachmentSize = 0;
        // Keep raw minidumps / process memory out of this sensitive signing application.
        options.DisableFileWrite = true;
        options.EnableScopeSync = false;
        // Traces are explicit fixed-name app operations; no URL, HTTP body, SQL or command-line capture.
        options.DisableDiagnosticSourceIntegration();
        options.DisableSystemDiagnosticsMetricsIntegration();
        options.DisableSentryHttpMessageHandler = true;
        options.TracesSampleRate = consent.CanSendMetrics ? (EnvironmentName == "development" ? 1.0 : 0.1) : 0.0;
        options.SetBeforeSend(source => consent.CanSendCrash && !revoked.IsCancellationRequested ? Sanitize(source) : null);
        options.SetBeforeSendTransaction(source => consent.CanSendMetrics && !revoked.IsCancellationRequested ? SanitizeTransaction(source) : null);
        options.AddInAppInclude("MoldSign.");
        options.DefaultTags["app.component"] = "desktop";
        options.ShutdownTimeout = TimeSpan.Zero;
        options.CacheDirectoryPath = null;
        options.SendClientReports = false;
        options.DisableAppDomainProcessExitFlush();
        options.DisableWinUiUnhandledExceptionIntegration();
        if (!consent.CanSendCrash)
        {
            options.DisableAppDomainUnhandledExceptionCapture();
            options.DisableUnobservedTaskExceptionCapture();
        }
        options.CreateHttpMessageHandler = () => new RevocationHandler(revoked);
    });

    public static void CaptureUnhandled(Exception error, MonitoringConsent consent)
    {
        if (!consent.CanSendCrash) return;
        error.Data[Mechanism.HandledKey] = false;
        error.Data[Mechanism.MechanismKey] = "WinUI";
        error.Data[Mechanism.TerminalKey] = true;
        SentrySdk.CaptureException(error);
        // A WinUI unhandled exception can terminate immediately after its synchronous callback.
        SentrySdk.FlushAsync(TimeSpan.FromSeconds(2)).GetAwaiter().GetResult();
    }

    public static bool IsEnabled => SentrySdk.IsEnabled;

    public static Task FlushAsync() => SentrySdk.FlushAsync(TimeSpan.FromSeconds(10));

#if DEBUG
    /// <summary>QA requires actual persisted/user consent; the fixture never grants consent itself.</summary>
    public static async Task<string?> VerifyAsync(MonitoringConsent consent)
    {
        if (!consent.CanSendCrash) return null;
        try { throw new DiagnosticVerificationException(); }
        catch (DiagnosticVerificationException error)
        {
            var eventId = SentrySdk.CaptureException(error);
            await FlushAsync();
            return eventId.ToString();
        }
    }
#endif

    internal static bool IsAllowedMetric(string name) => name is "esemnbun.desktop.sessions" or "esemnbun.desktop.session_seconds"
        or "esemnbun.desktop.navigation.sign" or "esemnbun.desktop.navigation.verify"
        or "esemnbun.desktop.navigation.browser" or "esemnbun.desktop.navigation.card"
        or "esemnbun.desktop.navigation.settings" or "esemnbun.desktop.navigation.activity";

    private sealed class Runtime : IMonitoringRuntime
    {
        private readonly CancellationTokenSource _revoked = new();
        private readonly IDisposable _sdk;
        private readonly Stopwatch? _duration;
        private readonly MonitoringConsent _consent;
        public Runtime(MonitoringConsent consent)
        {
            _consent = consent;
            _sdk = Initialize(consent, _revoked.Token);
            if (consent.CanSendMetrics)
            {
                _duration = Stopwatch.StartNew();
                SentrySdk.Metrics.EmitCounter("esemnbun.desktop.sessions", 1);
            }
        }
        public void RecordNavigation(string page)
        {
            var metric = "esemnbun.desktop.navigation." + page;
            if (_consent.CanSendMetrics && !_revoked.IsCancellationRequested && IsAllowedMetric(metric))
                SentrySdk.Metrics.EmitCounter(metric, 1);
        }
        public void RecordSessionDuration()
        {
            if (_consent.CanSendMetrics && !_revoked.IsCancellationRequested && _duration is not null)
                SentrySdk.Metrics.EmitDistribution("esemnbun.desktop.session_seconds", _duration.Elapsed.TotalSeconds,
                    MeasurementUnit.Duration.Second);
        }
        public Task FlushAsync() => AppDiagnostics.FlushAsync();
        public void Dispose()
        {
            _revoked.Cancel();
            _sdk.Dispose(); // ShutdownTimeout=0, no opt-out flush.
            _revoked.Dispose();
        }
    }

    private sealed class RevocationHandler(CancellationToken revoked) : DelegatingHandler(new HttpClientHandler())
    {
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            using var linked = CancellationTokenSource.CreateLinkedTokenSource(revoked, cancellationToken);
            linked.Token.ThrowIfCancellationRequested();
            return await base.SendAsync(request, linked.Token);
        }
    }

    internal static SentryEvent? Sanitize(SentryEvent source)
    {
        // Message-only events have no reliable diagnostic value here; they may contain user content.
        if (source.SentryExceptions?.Any() != true) return null;
        using var json = JsonDocument.Parse("{\"event_id\":\"" + source.EventId + "\"}");
        var safe = SentryEvent.FromJson(json.RootElement);
        safe.Level = source.Level;
        safe.Release = Release;
        safe.Environment = EnvironmentName;
        safe.Distribution = Distribution;
        safe.Platform = "csharp";
        safe.Sdk.Name = source.Sdk.Name;
        safe.Sdk.Version = source.Sdk.Version;
        safe.SentryExceptions = source.SentryExceptions.Select(error => new SentryException
        {
            Type = error.Type,
            Module = error.Module,
            Value = error.Type?.EndsWith(nameof(DiagnosticVerificationException), StringComparison.Ordinal) == true
                ? "esemnbun-sentry-verification-windows" : "Application error (details omitted)",
            Mechanism = new Mechanism { Type = "application", Handled = error.Mechanism?.Handled },
            Stacktrace = SafeStack(error.Stacktrace),
        }).ToArray();
        safe.DebugImages = source.DebugImages?.Select(image => new DebugImage
        {
            Type = image.Type, DebugId = image.DebugId, DebugChecksum = image.DebugChecksum,
            CodeId = image.CodeId, ImageAddress = image.ImageAddress, ImageSize = image.ImageSize,
            DebugFile = FileName(image.DebugFile), CodeFile = FileName(image.CodeFile),
        }).ToList();
        return safe;
    }

    private static SentryStackTrace? SafeStack(SentryStackTrace? source)
    {
        if (source is null) return null;
        var safe = new SentryStackTrace { AddressAdjustment = source.AddressAdjustment };
        foreach (var frame in source.Frames)
            safe.Frames.Add(new SentryStackFrame
            {
                FileName = FileName(frame.FileName), Function = frame.Function, Module = frame.Module,
                LineNumber = frame.LineNumber, ColumnNumber = frame.ColumnNumber, InApp = frame.InApp,
                Platform = frame.Platform, Package = FileName(frame.Package),
                ImageAddress = frame.ImageAddress, SymbolAddress = frame.SymbolAddress,
                InstructionAddress = frame.InstructionAddress, AddressMode = frame.AddressMode,
                FunctionId = frame.FunctionId,
            });
        return safe;
    }

    internal static SentryTransaction? SanitizeTransaction(SentryTransaction source)
    {
        if (source.Name != "app.startup" || source.Operation != "app.lifecycle") return null;
        // Rebuild rather than attempting to blacklist arbitrary context, spans, breadcrumbs or extras.
        using var buffer = new MemoryStream();
        using (var writer = new Utf8JsonWriter(buffer))
        {
            writer.WriteStartObject();
            writer.WriteString("event_id", source.EventId.ToString());
            writer.WriteString("transaction", "app.startup");
            writer.WriteString("start_timestamp", source.StartTimestamp);
            if (source.EndTimestamp is { } end) writer.WriteString("timestamp", end);
            writer.WriteString("platform", "csharp");
            writer.WriteString("release", Release);
            writer.WriteString("environment", EnvironmentName);
            writer.WriteString("dist", Distribution);
            writer.WriteStartObject("contexts");
            writer.WriteStartObject("trace");
            writer.WriteString("trace_id", source.TraceId.ToString());
            writer.WriteString("span_id", source.SpanId.ToString());
            writer.WriteString("op", "app.lifecycle");
            writer.WriteEndObject();
            writer.WriteEndObject();
            writer.WriteEndObject();
        }
        using var json = JsonDocument.Parse(buffer.ToArray());
        var safe = SentryTransaction.FromJson(json.RootElement);
        safe.Sdk.Name = source.Sdk.Name;
        safe.Sdk.Version = source.Sdk.Version;
        return safe;
    }

    private static string? FileName(string? value) => value?.Replace('\\', '/').Split('/').LastOrDefault();

    private sealed class DiagnosticVerificationException() : Exception("esemnbun-sentry-verification-windows");
}
