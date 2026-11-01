using System.Collections.Concurrent;
using System.Formats.Asn1;
using System.Net;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text.Json;
using System.Threading.Channels;
using System.Xml;
using System.Xml.Linq;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Hosting;
using MoldSign.Core;

namespace MoldSign.App.Services;

public sealed record BridgeOutcome(string Origin, string Format, CardEntry Card, Exception? Error);

/// <summary>Loopback MoldSign bridge: HTTPS, consent, queued signing and origin-bound PIN sessions.</summary>
public sealed class BridgeHost(
    BridgeOriginPolicy policy,
    Func<string> tlsPfxPath,
    Func<IReadOnlyList<CardEntry>> cards,
    SigningService signing,
    ConsentProvider consent,
    int httpPort = BridgeProtocol.HttpPort,
    int httpsPort = BridgeProtocol.HttpsPort,
    bool allowsLegacyDesktopClient = false,
    IBridgeFileSigner? fileSigner = null) : IAsyncDisposable
{
    private sealed record Result(string? Base64, string? Error, string? Payload = null, string ContentType = "application/json");
    private sealed record Document(byte[] Bytes, string ContentType, string Format, string Packaging,
        string Algorithm, string? Certificate, BridgeFileSigningRequest? FileRequest = null);
    private sealed record Job(string Id, string Origin, Document Document, CardEntry Card, string? Batch);
    private sealed record PinSession(string Origin, string Certificate, ConsentResult Consent, DateTimeOffset LastUse);
    private sealed class Session(string origin, bool fileRequest = false)
    {
        public string Origin { get; } = origin;
        public bool FileRequest { get; } = fileRequest;
        public DateTimeOffset Created { get; } = DateTimeOffset.UtcNow;
        public TaskCompletionSource<Result> Completion { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
    }

    private readonly IBridgeFileSigner _fileSigner = fileSigner ?? new BridgeFileSigner(signing);
    private readonly ConcurrentDictionary<string, Session> _sessions = new();
    private readonly ConcurrentDictionary<string, PinSession> _pins = new();
    private readonly SemaphoreSlim _lifecycle = new(1);
    private WebApplication? _app;
    private Channel<Job>? _jobs;
    private CancellationTokenSource? _shutdown;
    private X509Certificate2Collection? _identity;

    public event EventHandler<BridgeOutcome>? Completed;
    public event EventHandler? SigningStarted;
    public bool AllowsLegacyDesktopClient { get; set; } = allowsLegacyDesktopClient;
    public bool IsRunning => _app is not null;
    public bool HasTls => _identity is not null && IsRunning;

    public async Task StartAsync(CancellationToken cancellationToken = default)
    {
        await _lifecycle.WaitAsync(cancellationToken);
        try
        {
            if (_app is not null) return;
            var identity = BridgeTls.Load(tlsPfxPath());
            WebApplication? app = null;
            try
            {
                var builder = WebApplication.CreateSlimBuilder(new WebApplicationOptions { Args = [] });
                builder.Logging.ClearProviders();
                builder.WebHost.ConfigureKestrel(kestrel =>
                {
                    kestrel.AddServerHeader = false;
                    kestrel.Limits.MaxRequestBodySize = BridgeProtocol.MaxRequestBodyBytes;
                    kestrel.Listen(IPAddress.Loopback, httpPort);
                    kestrel.Listen(IPAddress.Loopback, httpsPort, listen => listen.UseHttps(options =>
                    {
                        options.ServerCertificate = identity.First(c => c.HasPrivateKey);
                        options.ServerCertificateChain = new X509Certificate2Collection(
                            identity.Where(c => !c.HasPrivateKey).ToArray());
                    }));
                });
                app = builder.Build();
                app.Use(OriginGateAsync);
                app.MapGet("/certificates", CertificatesAsync);
                app.MapPost("/sign/data", CreateAsync);
                app.MapGet("/sign/data/PKCS11/{id}/Any", PollAsync);
                app.MapGet("/hello", (HttpContext context) => NativeControlResult(context, hello: true));
                // The wallet is continuously refreshed by the host's reader monitor.
                app.MapPost("/certificates/refresh", (HttpContext context) => NativeControlResult(context, hello: false));
                app.MapPost("/sign/pdf", CreateFileAsync);
                app.MapPost("/sign/file", CreateFileAsync);
                app.MapGet("/sign/pdf/PKCS11/{id}", PollAsync);
                app.MapGet("/sign/file/PKCS11/{id}", PollAsync);
                // Verification needs a consent-only dialog: never ask for a card PIN just to verify.
                foreach (var path in new[] { "/sign/file/verify", "/verify/pdf", "/sign/pdf/verify" })
                    app.MapPost(path, () => Results.StatusCode(StatusCodes.Status501NotImplemented));
                var jobs = Channel.CreateBounded<Job>(new BoundedChannelOptions(32)
                {
                    SingleReader = true,
                    FullMode = BoundedChannelFullMode.Wait,
                });
                await app.StartAsync(cancellationToken);
                _identity = identity;
                _shutdown = new CancellationTokenSource();
                var token = _shutdown.Token;
                _jobs = jobs;
                _app = app;
                _ = Task.Run(() => ProcessJobsAsync(jobs.Reader, token));
            }
            catch
            {
                if (app is not null) await app.DisposeAsync();
                foreach (var certificate in identity) certificate.Dispose();
                throw;
            }
        }
        finally { _lifecycle.Release(); }
    }

    public async Task StopAsync()
    {
        await _lifecycle.WaitAsync();
        try
        {
            if (_app is not { } app) return;
            _app = null;
            _shutdown?.Cancel();
            _jobs?.Writer.TryComplete();
            _jobs = null;
            foreach (var session in _sessions.Values)
                session.Completion.TrySetResult(new Result(null, "Browser connection stopped"));
            _sessions.Clear();
            _pins.Clear();
            try { await app.StopAsync(TimeSpan.FromSeconds(5)); }
            finally
            {
                await app.DisposeAsync();
                if (_identity is { } identity)
                    foreach (var certificate in identity) certificate.Dispose();
                _identity = null;
                _shutdown?.Dispose();
                _shutdown = null;
            }
        }
        finally { _lifecycle.Release(); }
    }

    public ValueTask DisposeAsync() => new(StopAsync());

    private Task CertificatesAsync(HttpContext context) => context.Response.WriteAsJsonAsync(
        new CertificateListResponse(cards().Select(CertificateModelFor).ToArray()), context.RequestAborted);

    private static CertificateModel CertificateModelFor(CardEntry entry, int index)
    {
        using var certificate = X509CertificateLoader.LoadCertificate(entry.Certificate.Der);
        return new CertificateModel
        {
            CertificateId = entry.Certificate.Sha1.ToLowerInvariant(),
            Label = entry.Certificate.CommonName,
            ProviderId = $"PKCS11-{index}",
            Policy = "1.2.498.3.32.1.1",
            CertificateName = $"{entry.Certificate.CommonName} (null) (1.2.498.3.32.1.1)",
            SubjectDN = BrowserDN(certificate.SubjectName),
            IssuerDN = BrowserDN(certificate.IssuerName),
            Authority = false,
            Trusted = true,
            PrivateKeyPresent = true,
            CertificateBase64 = Convert.ToBase64String(entry.Certificate.Der),
        };
    }

    private static string BrowserDN(X500DistinguishedName name)
    {
        var sequence = new AsnReader(name.RawData, AsnEncodingRules.DER).ReadSequence();
        var attributes = new List<string>();
        while (sequence.HasData)
        {
            var set = sequence.ReadSetOf();
            while (set.HasData)
            {
                var attribute = set.ReadSequence();
                var oid = attribute.ReadObjectIdentifier();
                var key = oid switch
                {
                    "2.5.4.3" => "CN", "2.5.4.4" => "SN", "2.5.4.42" => "GN",
                    "2.5.4.6" => "C", "2.5.4.7" => "L", "2.5.4.8" => "ST",
                    "2.5.4.10" => "O", "2.5.4.11" => "OU", "2.5.4.5" => "SERIALNUMBER",
                    _ => oid,
                };
                var value = attribute.ReadCharacterString((UniversalTagNumber)attribute.PeekTag().TagValue);
                attributes.Add($"{key}={value}");
            }
        }
        // The portal splits on ',' and '=' without trimming keys; .NET's ", CN=" loses the holder.
        attributes.Reverse();
        return string.Join(",", attributes);
    }

    private IResult NativeControlResult(HttpContext context, bool hello)
    {
        if (!AllowsLegacyDesktopClient || !IsNativeRequest(context.Request)) return Results.StatusCode(StatusCodes.Status403Forbidden);
        return hello ? Results.Text("Hello world") : Results.Ok();
    }

    private Task CreateFileAsync(HttpContext context)
    {
        // File paths are never accepted from a browser, even an allowed government origin.
        if (!AllowsLegacyDesktopClient || !IsNativeRequest(context.Request))
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            return Task.CompletedTask;
        }
        return CreateAsync(context);
    }

    private static bool IsNativeRequest(HttpRequest request) =>
        !request.Headers.ContainsKey("Origin") &&
        !request.Headers.Keys.Any(key => key.StartsWith("Sec-Fetch-", StringComparison.OrdinalIgnoreCase));

    private static bool IsLegacyRoute(HttpRequest request)
    {
        var path = request.Path.Value ?? "";
        if (HttpMethods.IsGet(request.Method))
        {
            if (path is "/hello" or "/certificates" or "/certificates/") return true;
            var segments = path.Split('/', StringSplitOptions.RemoveEmptyEntries);
            return segments.Length == 4 && segments[0] == "sign" && (segments[1] is "pdf" or "file") &&
                segments[2] == "PKCS11" && Guid.TryParseExact(segments[3], "D", out _);
        }
        return HttpMethods.IsPost(request.Method) && (path is "/certificates/refresh" or "/sign/pdf" or "/sign/file");
    }

    private static async Task<Document> ParseFileAsync(HttpContext context)
    {
        var xmlResponse = context.Request.ContentType?.Contains("xml", StringComparison.OrdinalIgnoreCase) == true;
        Dictionary<string, string?> fields;
        List<string> files;
        if (xmlResponse)
        {
            using var reader = XmlReader.Create(context.Request.Body, new XmlReaderSettings
            {
                Async = true, DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null,
                MaxCharactersInDocument = BridgeProtocol.MaxRequestBodyBytes,
            });
            var xml = await XDocument.LoadAsync(reader, LoadOptions.None, context.RequestAborted);
            fields = xml.Descendants().Where(e => !e.HasElements).GroupBy(e => e.Name.LocalName)
                .ToDictionary(g => g.Key, g => (string?)g.First().Value);
            files = xml.Descendants().Where(e => e.Name.LocalName == "filesToSign" && !e.HasElements).Select(e => e.Value).ToList();
        }
        else
        {
            using var json = await JsonDocument.ParseAsync(context.Request.Body,
                new JsonDocumentOptions { MaxDepth = 16 }, context.RequestAborted);
            fields = json.RootElement.EnumerateObject().Where(p => p.Value.ValueKind is JsonValueKind.String or JsonValueKind.Null)
                .ToDictionary(p => p.Name, p => p.Value.GetString());
            if (json.RootElement.TryGetProperty("certificate", out var cert) && cert.ValueKind == JsonValueKind.Object &&
                cert.TryGetProperty("certificateBase64", out var value)) fields["certificateBase64"] = value.GetString();
            files = json.RootElement.TryGetProperty("filesToSign", out var list) && list.ValueKind == JsonValueKind.Array
                ? list.EnumerateArray().Select(e => e.GetString() ?? "").ToList() : [];
            if (fields.TryGetValue("signatureFile", out var signature) && !string.IsNullOrEmpty(signature))
                throw new InvalidDataException("Adding a signature to an existing XAdES is not supported");
        }
        string? Field(string name) => fields.GetValueOrDefault(name);
        var pdf = context.Request.Path == "/sign/pdf";
        if (pdf) files = [Field("originalFile") ?? ""];
        if (files.Count is 0 or > 64 || files.Any(string.IsNullOrWhiteSpace)) throw new InvalidDataException("Missing input files");
        var destination = pdf ? Field("signedFile") : Field("destinationFile");
        if (string.IsNullOrWhiteSpace(destination)) destination = pdf
            ? Path.Combine(Path.GetDirectoryName(files[0]) ?? "", Path.GetFileNameWithoutExtension(files[0]) + "-signed.pdf")
            : files[0] + ".xades";
        foreach (var path in files.Append(destination))
            if (!Path.IsPathFullyQualified(path) || path.StartsWith(@"\\", StringComparison.Ordinal) || path.StartsWith("//", StringComparison.Ordinal))
                throw new InvalidDataException("Only absolute local file paths are supported");
        if (files.Contains(destination, StringComparer.OrdinalIgnoreCase)) throw new InvalidDataException("The output must differ from the input");
        var format = pdf ? "PAdES-T" : Field("signFormat") ?? "XAdES-T";
        if (format is not ("PAdES-T" or "XAdES-BES" or "XAdES-T" or "XAdES-C")) throw new InvalidDataException("Unsupported signature format");
        var algorithm = Field("signAlgorithm") ?? Field("algorithm") ?? "SHA-256";
        if (algorithm is not ("SHA-1" or "SHA-256")) throw new InvalidDataException("Unsupported digest algorithm");
        var packaging = string.Equals(Field("type"), "Embedded", StringComparison.OrdinalIgnoreCase) ? XadesPackaging.Enveloping : XadesPackaging.Detached;
        var fileRequest = new BridgeFileSigningRequest(files, destination, format, packaging, algorithm, Field("certificateBase64"), pdf, xmlResponse);
        return new Document([], pdf ? "Pdf" : "Xml", format, "", algorithm, fileRequest.CertificateBase64, fileRequest);
    }

    private async Task CreateAsync(HttpContext context)
    {
        Prune();
        try
        {
            var document = context.Request.Path == "/sign/data" ? await ParseAsync(context) : await ParseFileAsync(context);
            var available = cards();
            var sha1 = string.IsNullOrWhiteSpace(document.Certificate) ? null :
                Convert.ToHexString(SHA1.HashData(Convert.FromBase64String(document.Certificate)));
            var card = sha1 is not null
                ? available.FirstOrDefault(c => c.Certificate.Sha1.Equals(sha1, StringComparison.OrdinalIgnoreCase))
                : available.Count == 1 ? available[0] : null;
            if (card is null) throw new InvalidDataException("Select an available signing certificate");
            if (_sessions.Count >= 128) { context.Response.StatusCode = 429; return; }
            var id = Guid.NewGuid().ToString();
            var origin = context.Request.Headers.Origin.ToString();
            var session = new Session(origin, document.FileRequest is not null);
            _sessions[id] = session;
            var batch = context.Request.Query["use_pin_session"].FirstOrDefault();
            if (_jobs is null || !_jobs.Writer.TryWrite(new Job(id, origin, document, card, batch)))
            {
                _sessions.TryRemove(id, out _);
                context.Response.StatusCode = 503;
                return;
            }
            context.Response.StatusCode = StatusCodes.Status201Created;
            var pollPath = document.FileRequest is null ? $"/sign/data/PKCS11/{id}/Any" : $"{context.Request.Path}/PKCS11/{id}";
            // Never reflect a caller-controlled Host header into an actionable result URL.
            var resultHost = context.Request.IsHttps ? "localhost.cts.md" : "127.0.0.1";
            context.Response.Headers.Location = $"{context.Request.Scheme}://{resultHost}:{context.Connection.LocalPort}{pollPath}";
            context.Response.Headers["sessionId"] = id;
        }
        catch (Exception error) when (error is JsonException or XmlException or FormatException or InvalidDataException or InvalidOperationException or ArgumentException)
        {
            context.Response.StatusCode = StatusCodes.Status400BadRequest;
            context.Response.Headers["error"] = SafeHeader(error.Message);
        }
    }

    private async Task PollAsync(HttpContext context)
    {
        var id = context.Request.RouteValues["id"]?.ToString() ?? "";
        var origin = context.Request.Headers.Origin.ToString();
        if (!_sessions.TryGetValue(id, out var session) || session.Origin != origin)
        {
            context.Response.StatusCode = 404;
            return;
        }
        if (session.FileRequest && (!AllowsLegacyDesktopClient || !IsNativeRequest(context.Request)))
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            return;
        }
        try
        {
            var result = await session.Completion.Task.WaitAsync(TimeSpan.FromMinutes(10), context.RequestAborted);
            if (result.Error is { } error)
            {
                context.Response.StatusCode = StatusCodes.Status400BadRequest;
                context.Response.Headers["error"] = SafeHeader(error);
            }
            else if (result.Payload is { } payload)
            {
                context.Response.ContentType = result.ContentType;
                await context.Response.WriteAsync(payload, context.RequestAborted);
            }
            else
            {
                await context.Response.WriteAsJsonAsync(new { base64File = result.Base64 }, context.RequestAborted);
            }
            _sessions.TryRemove(id, out _);
            if (context.Request.Query["keep_pin_session"] != "1") _pins.TryRemove(id, out _);
        }
        catch (TimeoutException)
        {
            context.Response.StatusCode = 408;
            _sessions.TryRemove(id, out _);
            _pins.TryRemove(id, out _);
        }
        catch (OperationCanceledException) when (context.RequestAborted.IsCancellationRequested) { }
    }

    private async Task ProcessJobsAsync(ChannelReader<Job> reader, CancellationToken token)
    {
        try
        {
            await foreach (var job in reader.ReadAllAsync(token))
            {
                if (!_sessions.TryGetValue(job.Id, out var session)) continue;
                Exception? failure = null;
                ConsentResult? accepted = null;
                try { SigningStarted?.Invoke(this, EventArgs.Empty); }
                catch (Exception) { }
                try
                {
                    token.ThrowIfCancellationRequested();
                    ConsentResult Authorize(ConsentRequest request)
                    {
                        token.ThrowIfCancellationRequested();
                        if (job.Batch is { } batch && _pins.TryGetValue(batch, out var stored) &&
                            stored.Origin == job.Origin &&
                            stored.Certificate.Equals(request.Certificate.Sha1, StringComparison.OrdinalIgnoreCase) &&
                            DateTimeOffset.UtcNow - stored.LastUse < TimeSpan.FromMinutes(5))
                        {
                            _pins[batch] = stored with { LastUse = DateTimeOffset.UtcNow };
                            accepted = stored.Consent;
                        }
                        else accepted = consent(request);
                        return accepted;
                    }
                    Result result;
                    if (job.Document.FileRequest is { } fileRequest)
                    {
                        // Consent happens before reading any requested path. Ignore a submitted PIN:
                        // a local client must not bypass the app's explicit authorization UI.
                        var decision = Authorize(new ConsentRequest
                        {
                            Requester = "MoldSign Desktop Suite",
                            Documents = fileRequest.Files.Append(fileRequest.Destination).ToArray(),
                            Format = fileRequest.Format,
                            Certificate = job.Card.Certificate,
                        });
                        if (decision.IsCancelled) throw new OperationCanceledException("Signing cancelled");
                        ConsentResult Approved(ConsentRequest request)
                        {
                            if (!request.Certificate.Sha1.Equals(job.Card.Certificate.Sha1, StringComparison.OrdinalIgnoreCase))
                                return ConsentResult.Cancelled;
                            return decision;
                        }
                        var path = _fileSigner.Sign(fileRequest, job.Card, Approved);
                        var payload = fileRequest.Pdf ? JsonSerializer.Serialize(new { path }) :
                            JsonSerializer.Serialize(new { fileLocation = path, signatures = Array.Empty<object>() });
                        if (!fileRequest.Pdf && fileRequest.XmlResponse)
                            payload = new XElement("XadesSignatureModelContainer", new XElement("fileLocation", path), new XElement("signatures")).ToString(SaveOptions.DisableFormatting);
                        result = new Result(null, null, payload, fileRequest.XmlResponse && !fileRequest.Pdf ? "application/xml" : "application/json");
                    }
                    else result = new Result(Convert.ToBase64String(Sign(job, Authorize)), null);
                    if (!token.IsCancellationRequested && accepted is { IsCancelled: false })
                        _pins[job.Id] = new PinSession(job.Origin, job.Card.Certificate.Sha1, accepted, DateTimeOffset.UtcNow);
                    session.Completion.TrySetResult(result);
                }
                catch (Exception error)
                {
                    failure = error;
                    if (job.Batch is { } batch) _pins.TryRemove(batch, out _);
                    _pins.TryRemove(job.Id, out _);
                    session.Completion.TrySetResult(new Result(null, error.Message));
                }
                try { Completed?.Invoke(this, new BridgeOutcome(job.Origin, job.Document.Format, job.Card, failure)); }
                catch (Exception) { /* An observer must not terminate the signing queue. */ }
            }
        }
        catch (OperationCanceledException) when (token.IsCancellationRequested) { }
    }

    private byte[] Sign(Job job, ConsentProvider authorize)
    {
        var dir = Directory.CreateTempSubdirectory("MoldSign-");
        try
        {
            var pdf = job.Document.ContentType.Equals("Pdf", StringComparison.OrdinalIgnoreCase) ||
                      job.Document.ContentType.Equals("application/pdf", StringComparison.OrdinalIgnoreCase);
            var input = Path.Combine(dir.FullName, pdf ? "document.pdf" : "document.xml");
            var output = Path.Combine(dir.FullName, pdf ? "signed.pdf" : "signed.xml");
            File.WriteAllBytes(input, job.Document.Bytes);
            var requester = Uri.TryCreate(job.Origin, UriKind.Absolute, out var uri) ? uri.Host : "localhost";
            if (pdf)
                signing.SignPdf(input, output, authorize, requester, job.Card.Reader, job.Card.Certificate.Sha1);
            else
            {
                var format = job.Document.Format switch
                {
                    "XAdES-BES" => XadesFormat.Bes,
                    "XAdES-T" => XadesFormat.T,
                    "XAdES-C" => XadesFormat.C,
                    _ => throw new InvalidDataException("Unsupported signature format"),
                };
                var packaging = job.Document.Packaging.Equals("Embedded", StringComparison.OrdinalIgnoreCase)
                    ? XadesPackaging.Enveloping : XadesPackaging.Detached;
                signing.SignXades([input], format, packaging, output, authorize, requester,
                    job.Card.Reader, job.Card.Certificate.Sha1, digestAlgorithm: job.Document.Algorithm);
            }
            return File.ReadAllBytes(output);
        }
        finally { dir.Delete(recursive: true); }
    }

    private static async Task<Document> ParseAsync(HttpContext context)
    {
        string data, contentType, format, packaging, algorithm;
        string? certificate;
        if (context.Request.ContentType?.Contains("xml", StringComparison.OrdinalIgnoreCase) == true)
        {
            using var reader = XmlReader.Create(context.Request.Body, new XmlReaderSettings
            {
                Async = true, DtdProcessing = DtdProcessing.Prohibit, XmlResolver = null,
                MaxCharactersInDocument = BridgeProtocol.MaxRequestBodyBytes,
            });
            var xml = await XDocument.LoadAsync(reader, LoadOptions.None, context.RequestAborted);
            string? Field(string name) => xml.Descendants().FirstOrDefault(e => e.Name.LocalName == name && !e.HasElements)?.Value;
            data = Field("data") ?? "";
            contentType = Field("contentType") ?? "";
            format = Field("signFormat") ?? "XAdES-T";
            packaging = Field("signatureType") ?? "Embedded";
            algorithm = Field("algorithm") ?? "SHA-256";
            certificate = Field("certificateBase64");
        }
        else
        {
            using var json = await JsonDocument.ParseAsync(context.Request.Body,
                new JsonDocumentOptions { MaxDepth = 16 }, context.RequestAborted);
            string? Field(string name) => json.RootElement.TryGetProperty(name, out var value) ? value.GetString() : null;
            data = Field("data") ?? "";
            contentType = Field("contentType") ?? "";
            format = Field("signFormat") ?? "XAdES-T";
            packaging = Field("signatureType") ?? "Embedded";
            algorithm = Field("algorithm") ?? "SHA-256";
            certificate = json.RootElement.TryGetProperty("certificate", out var cert) && cert.ValueKind == JsonValueKind.Object &&
                cert.TryGetProperty("certificateBase64", out var value) ? value.GetString() : null;
        }
        if (string.IsNullOrWhiteSpace(data)) throw new InvalidDataException("Missing document data");
        if (contentType.Equals("Pdf", StringComparison.OrdinalIgnoreCase) ||
            contentType.Equals("application/pdf", StringComparison.OrdinalIgnoreCase))
            format = "PAdES-T";
        return new Document(Convert.FromBase64String(data), contentType, format, packaging, algorithm, certificate);
    }

    private void Prune()
    {
        var now = DateTimeOffset.UtcNow;
        foreach (var entry in _pins)
            if (now - entry.Value.LastUse >= TimeSpan.FromMinutes(5)) _pins.TryRemove(entry.Key, out _);
        foreach (var entry in _sessions)
            if (now - entry.Value.Created >= TimeSpan.FromMinutes(10))
            {
                entry.Value.Completion.TrySetResult(new Result(null, "Signing request expired"));
                _sessions.TryRemove(entry.Key, out _);
            }
    }

    private static string SafeHeader(string text) =>
        new(text.Take(400).Select(c => c is >= ' ' and <= '~' ? c : ' ').ToArray());

    private async Task OriginGateAsync(HttpContext context, RequestDelegate next)
    {
        var remote = context.Connection.RemoteIpAddress;
        string? origin = context.Request.Headers.Origin.Count > 0 ? context.Request.Headers.Origin.ToString() : null;
        string? desktop = context.Request.Headers[BridgeOriginPolicy.DesktopClientHeaderName].FirstOrDefault();
        var path = context.Request.Path.Value ?? "";
        var fileRoute = path.StartsWith("/sign/pdf", StringComparison.Ordinal) || path.StartsWith("/sign/file", StringComparison.Ordinal);
        if ((fileRoute || path is "/hello" or "/certificates/refresh") &&
            (!AllowsLegacyDesktopClient || !IsNativeRequest(context.Request)))
        {
            context.Response.StatusCode = StatusCodes.Status403Forbidden;
            return;
        }
        var legacy = AllowsLegacyDesktopClient && IsNativeRequest(context.Request) && IsLegacyRoute(context.Request);
        if (remote is null || !IPAddress.IsLoopback(remote) || !(policy.IsAllowed(origin, desktop) || legacy))
        {
            context.Response.StatusCode = 403;
            return;
        }
        if (origin is not null) context.Response.Headers.AccessControlAllowOrigin = origin;
        context.Response.Headers.AccessControlAllowMethods = BridgeProtocol.AllowMethods;
        context.Response.Headers.AccessControlAllowHeaders = BridgeProtocol.AllowHeaders;
        context.Response.Headers.AccessControlExposeHeaders = BridgeProtocol.AllowHeaders + ", sessionId";
        context.Response.Headers.AccessControlMaxAge = BridgeProtocol.MaxAgeSeconds;
        if (origin is not null) context.Response.Headers.Vary = "Origin";
        if (HttpMethods.IsOptions(context.Request.Method))
        {
            context.Response.Headers["Access-Control-Allow-Private-Network"] = "true";
            context.Response.StatusCode = 200;
            return;
        }
        await next(context);
    }
}
