using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using MoldSign.Core;

namespace MoldSign.App.Services;

/// <summary>
/// MoldSign Server protocol replica on Kestrel (docs/04, docs/09 §3.6, WIN-06), living as long as the tray app.
/// Skeleton: origin policy (SEC-01), loopback only + body cap (SEC-03), CORS + Private Network Access
/// preflights, and <c>GET /certificates</c>. Signing routes need consent (SEC-02) and WIN-01.
/// </summary>
public sealed class BridgeHost : IAsyncDisposable
{
    private readonly BridgeOriginPolicy _policy;
    private readonly Func<string?> _tlsPfxPath;
    private WebApplication? _app;

    /// <param name="policy">Usually <see cref="BridgeOriginPolicy.Default"/>.</param>
    /// <param name="tlsPfxPath">
    /// localhost.cts.md identity (PFX) for https://localhost.cts.md:18443, or null for HTTP only.
    /// TODO(WIN-06): load it from the installed vendor suite when present, else the app bundle (D-03, SEC-07);
    /// the PFX password is the one compiled into the vendor ApiServer (never in this repo).
    /// </param>
    public BridgeHost(BridgeOriginPolicy policy, Func<string?> tlsPfxPath)
    {
        _policy = policy ?? throw new ArgumentNullException(nameof(policy));
        _tlsPfxPath = tlsPfxPath ?? throw new ArgumentNullException(nameof(tlsPfxPath));
    }

    public bool IsRunning => _app is not null;

    /// <summary>True when the TLS listener (18443) is up as well.</summary>
    public bool HasTls { get; private set; }

    /// <summary>Starts the listeners; throws <see cref="IOException"/> when a port is taken (e.g. the vendor suite runs).</summary>
    public async Task StartAsync(CancellationToken cancellationToken = default)
    {
        if (_app is not null) return;

        var builder = WebApplication.CreateSlimBuilder();
        builder.Logging.ClearProviders();
        var pfx = _tlsPfxPath();
        HasTls = pfx is not null && File.Exists(pfx);
        builder.WebHost.ConfigureKestrel(kestrel =>
        {
            kestrel.AddServerHeader = false;
            kestrel.Limits.MaxRequestBodySize = BridgeProtocol.MaxRequestBodyBytes;
            // SEC-03: 127.0.0.1 only (never ListenAnyIP).
            kestrel.Listen(IPAddress.Loopback, BridgeProtocol.HttpPort);
            if (HasTls)
            {
                // TODO(WIN-06): pass the vendor PFX password; consider IPv6 loopback for localhost.cts.md.
                kestrel.Listen(IPAddress.Loopback, BridgeProtocol.HttpsPort, listen => listen.UseHttps(pfx!));
            }
        });

        var app = builder.Build();
        app.Use(OriginGateAsync);

        app.MapGet("/certificates", static () =>
            Results.Text(JsonSerializer.Serialize(new CertificateListResponse([])), "application/json"));
        // TODO(WIN-06): GET /certificates from SigningService.Certificate() (certificateId = SHA-1, privateKeyPresent).
        // TODO(WIN-06): POST /sign/data, /sign/pdf, /sign/file, /sign/file/verify, /verify/pdf with 201 (empty body, mpass) + ABSOLUTE
        //               Location, 303 polling, Jersey-XML or JSON models (docs/04); consent window in front (SEC-02).

        await app.StartAsync(cancellationToken);
        _app = app;
    }

    public async Task StopAsync()
    {
        if (_app is not { } app) return;
        _app = null;
        await app.StopAsync();
        await app.DisposeAsync();
    }

    public ValueTask DisposeAsync() => new(StopAsync());

    /// <summary>
    /// SEC-01/03: loopback peers only; Origin must match the vendor allow-list, or be absent with
    /// <c>moldSign: DesktopSuiteClient</c>. Rejected requests get 403 and NO CORS headers.
    /// </summary>
    private async Task OriginGateAsync(HttpContext context, RequestDelegate next)
    {
        var remote = context.Connection.RemoteIpAddress;
        if (remote is null || !IPAddress.IsLoopback(remote))
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            return;
        }

        var request = context.Request;
        string? origin = request.Headers.Origin.Count > 0 ? request.Headers.Origin.ToString() : null;
        var desktop = request.Headers[BridgeOriginPolicy.DesktopClientHeaderName];
        string? desktopHeader = desktop.Count > 0 ? desktop.ToString() : null;

        if (!_policy.IsAllowed(origin, desktopHeader))
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            return;
        }

        var headers = context.Response.Headers;
        headers.AccessControlAllowOrigin = origin ?? "*";
        headers.AccessControlAllowMethods = BridgeProtocol.AllowMethods;
        headers.AccessControlAllowHeaders = BridgeProtocol.AllowHeaders;
        headers.AccessControlExposeHeaders = BridgeProtocol.AllowHeaders;
        headers.AccessControlMaxAge = BridgeProtocol.MaxAgeSeconds;
        if (origin is not null) headers.Vary = "Origin";

        if (HttpMethods.IsOptions(request.Method))
        {
            // Chrome Private Network Access preflight (public site → 127.0.0.1).
            headers["Access-Control-Allow-Private-Network"] = "true";
            context.Response.StatusCode = StatusCodes.Status200OK;
            return;
        }

        await next(context);
    }
}
