using System.Text;
using System.Text.Json;
using MoldSign.Diagnostics;
using Sentry;
using Sentry.Protocol;

namespace MoldSign.Core.Tests;

public class DiagnosticsPrivacyTests
{
    [Fact]
    public void EventAllowlistDropsSigningContentButKeepsSymbolCoordinates()
    {
        const string sensitive = "PRIVATE_SIGNING_FIXTURE";
        var trace = new SentryStackTrace();
        trace.Frames.Add(new SentryStackFrame
        {
            FileName = "C:\\Users\\" + sensitive + "\\App.cs", AbsolutePath = "C:\\" + sensitive,
            ContextLine = sensitive, Function = "MoldSign.App.Start", LineNumber = 42, InApp = true,
        });
        trace.Frames[0].Vars["pin"] = sensitive;
        var source = new SentryEvent(new InvalidOperationException(sensitive))
        {
            Message = sensitive, ServerName = sensitive, User = new SentryUser { Email = sensitive },
            Request = new SentryRequest { Url = "https://example.org/" + sensitive },
            SentryExceptions = [new SentryException { Type = "InvalidOperationException", Value = sensitive, Stacktrace = trace, Mechanism = new Mechanism { Handled = false } }],
        };
        source.SetExtra("document", sensitive);
        source.SetTag("holder", sensitive);
        source.AddBreadcrumb(new Breadcrumb(sensitive, "default", null, "test", BreadcrumbLevel.Info));
        var safe = AppDiagnostics.Sanitize(source)!;
        var json = Serialize(safe);
        Assert.DoesNotContain(sensitive, json);
        Assert.DoesNotContain("C:\\", json);
        Assert.Contains("App.cs", json);
        Assert.Contains("MoldSign.App.Start", json);
        Assert.Contains("42", json);
        Assert.Equal(source.EventId, safe.EventId);
        Assert.False(Assert.Single(safe.SentryExceptions!).Mechanism!.Handled);
        Assert.Empty(safe.Breadcrumbs);
        Assert.Empty(safe.Extra);
        Assert.Empty(safe.Tags);
    }

    [Fact]
    public void ArbitraryMessageAndDynamicTransactionAreDropped()
    {
        Assert.Null(AppDiagnostics.Sanitize(new SentryEvent { Message = "document contents" }));
        Assert.Null(AppDiagnostics.SanitizeTransaction(new SentryTransaction("document contents", "http.request")));
    }

    [Fact]
    public void StartupTraceDropsArbitraryContext()
    {
        const string sensitive = "PRIVATE_SIGNING_FIXTURE";
        var source = new SentryTransaction("app.startup", "app.lifecycle");
        source.SetData("document", sensitive);
        source.SetTag("holder", sensitive);
        source.User = new SentryUser { Email = sensitive };
        var safe = AppDiagnostics.SanitizeTransaction(source)!;
        Assert.DoesNotContain(sensitive, Serialize(safe));
        Assert.Equal(source.TraceId, safe.TraceId);
        Assert.Equal(source.SpanId, safe.SpanId);
        Assert.Empty(safe.Spans);
        Assert.Empty(safe.Breadcrumbs);
    }

    private static string Serialize(SentryEvent value)
    {
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream)) value.WriteTo(writer, null);
        return Encoding.UTF8.GetString(stream.ToArray());
    }

    private static string Serialize(SentryTransaction value)
    {
        using var stream = new MemoryStream();
        using (var writer = new Utf8JsonWriter(stream)) value.WriteTo(writer, null);
        return Encoding.UTF8.GetString(stream.ToArray());
    }
}
