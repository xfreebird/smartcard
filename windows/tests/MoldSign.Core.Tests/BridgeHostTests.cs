using System.Net;
using System.Net.Sockets;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.Json;
using System.Security.Cryptography.Xml;
using System.Xml;
using MoldSign.App.Services;

namespace MoldSign.Core.Tests;

public sealed class BridgeHostTests : IAsyncLifetime
{
    private readonly string _identity = Path.Combine(Path.GetTempPath(), $"moldsign-bridge-{Guid.NewGuid()}.p12");
    private readonly RSA _key = RSA.Create(2048);
    private X509Certificate2 _certificate = null!;
    private BridgeHost _server = null!;
    private HttpClient _client = null!;
    private IReadOnlyList<CardEntry> _cards = [];
    private Func<ICardTransport> _connect = () => throw new IOException("Test transport unavailable");
    private Func<ConsentRequest, ConsentResult> _consent = _ => ConsentResult.Cancelled;
    private int _consents;
    private int _httpPort;

    public async Task InitializeAsync()
    {
        var request = new CertificateRequest("CN=localhost.cts.md,O=Bridge Test,C=MD", _key, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        var san = new SubjectAlternativeNameBuilder();
        san.AddDnsName("localhost.cts.md");
        request.CertificateExtensions.Add(san.Build());
        _certificate = request.CreateSelfSigned(DateTimeOffset.UtcNow.AddDays(-1), DateTimeOffset.UtcNow.AddDays(1));
        File.WriteAllBytes(_identity, _certificate.Export(X509ContentType.Pfx, BridgeTls.Password));
        _cards = [new CardEntry("Test reader", CertificateSummary.FromDer(_certificate.RawData))];
        _httpPort = FreePort();
        var httpsPort = FreePort();
        while (httpsPort == _httpPort) httpsPort = FreePort();
        _server = new BridgeHost(BridgeOriginPolicy.Default, () => _identity, () => _cards,
            new SigningService(() => _connect()), request => { Interlocked.Increment(ref _consents); return _consent(request); },
            _httpPort, httpsPort);
        await _server.StartAsync();
        _client = new HttpClient(new HttpClientHandler
        {
            UseProxy = false,
            ServerCertificateCustomValidationCallback = (_, certificate, _, _) => certificate?.Thumbprint == _certificate.Thumbprint,
        }) { BaseAddress = new Uri($"https://127.0.0.1:{httpsPort}"), Timeout = TimeSpan.FromSeconds(10) };
        _client.DefaultRequestHeaders.Add("Origin", "https://msign.gov.md");
    }

    public async Task DisposeAsync()
    {
        await _server.DisposeAsync();
        _client.Dispose();
        _certificate.Dispose();
        _key.Dispose();
        File.Delete(_identity);
    }

    [Fact]
    public async Task LegacyDesktopAccessIsOptInAndNeverAcceptsBrowserRequests()
    {
        _client.DefaultRequestHeaders.Remove("Origin");
        using var disabled = await _client.GetAsync("/hello");
        Assert.Equal(HttpStatusCode.Forbidden, disabled.StatusCode);
        _server.AllowsLegacyDesktopClient = true;
        Assert.Equal("Hello world", await _client.GetStringAsync("/hello"));
        using var refresh = await _client.PostAsync("/certificates/refresh", new StringContent(""));
        Assert.True(refresh.IsSuccessStatusCode);
        using var browser = new HttpRequestMessage(HttpMethod.Post, "/sign/pdf")
        {
            Content = new StringContent("{}", Encoding.UTF8, "application/json"),
        };
        browser.Headers.Add("Origin", "https://msign.gov.md");
        using var rejectedBrowser = await _client.SendAsync(browser);
        Assert.Equal(HttpStatusCode.Forbidden, rejectedBrowser.StatusCode);
        using var fetch = new HttpRequestMessage(HttpMethod.Get, "/hello");
        fetch.Headers.Add("Sec-Fetch-Mode", "no-cors");
        using var rejectedFetch = await _client.SendAsync(fetch);
        Assert.Equal(HttpStatusCode.Forbidden, rejectedFetch.StatusCode);
        using var unrelated = await _client.PostAsync("/encrypt", new StringContent("{}"));
        Assert.Equal(HttpStatusCode.Forbidden, unrelated.StatusCode);
        _server.AllowsLegacyDesktopClient = false;
        using var revoked = await _client.GetAsync("/hello");
        Assert.Equal(HttpStatusCode.Forbidden, revoked.StatusCode);
    }

    [Fact]
    public async Task NativeFileSigningRequiresConsentAndReturnsVendorPathContract()
    {
        var signer = new RecordingFileSigner();
        await RestartWithFileSignerAsync(signer);
        _client.DefaultRequestHeaders.Remove("Origin");
        var input = Path.Combine(Path.GetTempPath(), "input.pdf");
        var output = Path.Combine(Path.GetTempPath(), "signed.pdf");
        var body = JsonSerializer.Serialize(new { originalFile = input, signedFile = output, pin = "untrusted-client-pin" });
        // A submitted PIN cannot bypass consent; no file adapter is called when the user cancels.
        using var cancelled = await _client.PostAsync("/sign/pdf", new StringContent(body, Encoding.UTF8, "application/json"));
        Assert.Equal(HttpStatusCode.Created, cancelled.StatusCode);
        using var cancelledResult = await _client.GetAsync(cancelled.Headers.Location);
        Assert.Equal(HttpStatusCode.BadRequest, cancelledResult.StatusCode);
        Assert.Equal(0, signer.Calls);
        Assert.Equal(1, _consents);
        _consent = _ => ConsentResult.WithPin("fixture-pin");
        using var created = await _client.PostAsync("/sign/pdf", new StringContent(body, Encoding.UTF8, "application/json"));
        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        Assert.Empty(await created.Content.ReadAsByteArrayAsync());
        Assert.StartsWith("/sign/pdf/PKCS11/", created.Headers.Location!.AbsolutePath);
        using var result = JsonDocument.Parse(await _client.GetStringAsync(created.Headers.Location));
        Assert.Equal(output, result.RootElement.GetProperty("path").GetString());
        Assert.Equal(1, signer.Calls);
        Assert.Equal(2, _consents);
        Assert.True(signer.ConsentAccepted);
    }

    [Fact]
    public async Task NativeXadesPreservesDigestPackagingAndActualHttpLocation()
    {
        var signer = new RecordingFileSigner();
        await RestartWithFileSignerAsync(signer);
        _consent = _ => ConsentResult.WithPin("fixture-pin");
        using var client = new HttpClient(new HttpClientHandler { UseProxy = false })
        { BaseAddress = new Uri($"http://127.0.0.1:{_httpPort}") };
        var input = Path.Combine(Path.GetTempPath(), "source.txt");
        var output = Path.Combine(Path.GetTempPath(), "signature.xml");
        var body = JsonSerializer.Serialize(new { filesToSign = new[] { input }, destinationFile = output,
            signFormat = "XAdES-BES", signAlgorithm = "SHA-1", type = "Embedded", eachFileSeparately = true });
        using var request = new HttpRequestMessage(HttpMethod.Post, "/sign/file")
        { Content = new StringContent(body, Encoding.UTF8, "application/json") };
        request.Headers.Host = "attacker.example:1234";
        using var created = await client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        Assert.Equal("http", created.Headers.Location!.Scheme);
        Assert.Equal("127.0.0.1", created.Headers.Location.Host);
        Assert.Equal(_httpPort, created.Headers.Location.Port);
        using var result = JsonDocument.Parse(await client.GetStringAsync(created.Headers.Location));
        Assert.Equal(output, result.RootElement.GetProperty("fileLocation").GetString());
        Assert.Equal("SHA-1", signer.LastRequest!.Algorithm);
        Assert.Equal(XadesPackaging.Enveloping, signer.LastRequest.Packaging);
        Assert.Equal("XAdES-BES", signer.LastRequest.Format);
    }

    [Fact]
    public async Task FilePathsCannotOverwriteInputsOrReachNetworkShares()
    {
        var signer = new RecordingFileSigner();
        await RestartWithFileSignerAsync(signer);
        _client.DefaultRequestHeaders.Remove("Origin");
        var local = Path.Combine(Path.GetTempPath(), "input.pdf");
        foreach (var (input, output) in new[] { (local, local), ("relative.pdf", local), (@"\\server\share\input.pdf", local) })
        {
            var body = JsonSerializer.Serialize(new { originalFile = input, signedFile = output });
            using var created = await _client.PostAsync("/sign/pdf", new StringContent(body, Encoding.UTF8, "application/json"));
            Assert.Equal(HttpStatusCode.BadRequest, created.StatusCode);
        }
        Assert.Equal(0, signer.Calls);
        Assert.Equal(0, _consents);
    }

    private async Task RestartWithFileSignerAsync(IBridgeFileSigner signer)
    {
        await _server.DisposeAsync();
        _server = new BridgeHost(BridgeOriginPolicy.Default, () => _identity, () => _cards,
            new SigningService(() => _connect()), request => { Interlocked.Increment(ref _consents); return _consent(request); },
            _httpPort, _client.BaseAddress!.Port, allowsLegacyDesktopClient: true, fileSigner: signer);
        await _server.StartAsync();
    }

    private sealed class RecordingFileSigner : IBridgeFileSigner
    {
        public int Calls { get; private set; }
        public bool ConsentAccepted { get; private set; }
        public BridgeFileSigningRequest? LastRequest { get; private set; }
        public string Sign(BridgeFileSigningRequest request, CardEntry card, ConsentProvider consent)
        {
            Calls++;
            LastRequest = request;
            ConsentAccepted = !consent(new ConsentRequest { Requester = "MoldSign Desktop Suite", Documents = request.Files,
                Format = request.Format, Certificate = card.Certificate }).IsCancelled;
            return request.Destination;
        }
    }

    [Fact]
    public async Task HttpsListsTheActualWalletCertificates()
    {
        Assert.True(_server.HasTls);
        using var response = await _client.GetAsync("/certificates?private_only=true");
        response.EnsureSuccessStatusCode();
        using var json = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var certificate = Assert.Single(json.RootElement.GetProperty("certificateModel").EnumerateArray());
        Assert.Equal(Convert.ToBase64String(_certificate.RawData), certificate.GetProperty("certificateBase64").GetString());
        Assert.False(certificate.GetProperty("authority").GetBoolean());
        Assert.True(certificate.GetProperty("privateKeyPresent").GetBoolean());
        var subject = certificate.GetProperty("subjectDN").GetString()!;
        Assert.Contains("CN=localhost.cts.md", subject.Split(','));
        Assert.All(subject.Split(','), attribute => Assert.Equal(attribute.TrimStart(), attribute));
        Assert.DoesNotContain(", ", certificate.GetProperty("issuerDN").GetString()!);
        Assert.Equal(0, _consents);
        using var trailingSlash = await _client.GetAsync("/certificates/");
        trailingSlash.EnsureSuccessStatusCode();
        _cards = [];
        using var empty = JsonDocument.Parse(await _client.GetStringAsync("/certificates"));
        Assert.Empty(empty.RootElement.GetProperty("certificateModel").EnumerateArray());
    }

    [Fact]
    public async Task OriginGateAndPrivateNetworkPreflightApplyToHttps()
    {
        using var preflight = new HttpRequestMessage(HttpMethod.Options, "/sign/data");
        using var accepted = await _client.SendAsync(preflight);
        Assert.Equal(HttpStatusCode.OK, accepted.StatusCode);
        Assert.Equal("true", Assert.Single(accepted.Headers.GetValues("Access-Control-Allow-Private-Network")));
        using var request = new HttpRequestMessage(HttpMethod.Get, "/certificates");
        request.Headers.Add("Origin", "https://evil.example");
        request.Headers.Add("moldSign", "DesktopSuiteClient");
        using var rejected = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.Forbidden, rejected.StatusCode);
        Assert.False(rejected.Headers.Contains("Access-Control-Allow-Origin"));
    }

    [Fact]
    public async Task PortalGetsEmptyCreatedThenOneLongPollNotRedirects()
    {
        var entered = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        using var release = new ManualResetEventSlim();
        _connect = () =>
        {
            entered.TrySetResult();
            // The test controls completion. A separate short deadline here races the
            // HTTP client's continuation under load and changes the expected error.
            release.Wait();
            throw new IOException("Test transport unavailable");
        };
        Task<HttpResponseMessage> poll;
        Uri location;
        try
        {
            using var created = await PostAsync("""{"data":"PGRvYy8+","contentType":"Xml","signFormat":"XAdES-BES","certificate":{"certificateBase64":""}}""");
            Assert.Equal(HttpStatusCode.Created, created.StatusCode);
            Assert.Empty(await created.Content.ReadAsByteArrayAsync());
            Assert.NotNull(created.Headers.Location);
            Assert.True(created.Headers.Location.IsAbsoluteUri);
            Assert.Contains("/sign/data/PKCS11/", created.Headers.Location.AbsolutePath);
            location = created.Headers.Location;
            poll = _client.GetAsync(location);
            await entered.Task.WaitAsync(TimeSpan.FromSeconds(30));
            await Task.Delay(100);
            Assert.False(poll.IsCompleted);
        }
        finally { release.Set(); }
        using var result = await poll;
        Assert.Equal(HttpStatusCode.BadRequest, result.StatusCode);
        Assert.Contains("Test transport unavailable", Assert.Single(result.Headers.GetValues("error")));
        using var repeated = await _client.GetAsync(location);
        Assert.Equal(HttpStatusCode.NotFound, repeated.StatusCode);
    }

    [Fact]
    public async Task MalformedRequestsAndUnavailableCardDoNotKillTheHost()
    {
        foreach (var body in new[] { "{", """{"data":true}""", """{"data":"%%%"}""",
                     """{"data":"PGRvYy8+","certificate":{"certificateBase64":"not-base64"}}""" })
        {
            using var response = await PostAsync(body);
            Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        }
        _cards = [];
        using var missingCard = await PostAsync("""{"data":"PGRvYy8+"}""");
        Assert.Equal(HttpStatusCode.BadRequest, missingCard.StatusCode);
        using var stillRunning = await _client.GetAsync("/certificates");
        Assert.True(stillRunning.IsSuccessStatusCode);
        Assert.Equal(0, _consents);
    }

    [Fact]
    public async Task JerseyXmlRequestUsesTheSameAsyncProtocol()
    {
        using var created = await _client.PostAsync("/sign/data", new StringContent(
            "<input><data>PGRvYy8+</data><contentType>Xml</contentType><signFormat>XAdES-BES</signFormat>" +
            "<certificate><certificateBase64></certificateBase64></certificate></input>", Encoding.UTF8, "application/xml"));
        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        using var result = await _client.GetAsync(created.Headers.Location);
        Assert.Equal(HttpStatusCode.BadRequest, result.StatusCode);
    }

    [Fact]
    public async Task MissingIdentityDoesNotSilentlyStartHttpOnly()
    {
        await using var missing = new BridgeHost(BridgeOriginPolicy.Default, () => _identity + ".missing", () => [],
            new SigningService(() => _connect()), _ => ConsentResult.Cancelled, FreePort(), FreePort());
        await Assert.ThrowsAsync<FileNotFoundException>(() => missing.StartAsync());
        Assert.False(missing.IsRunning);
    }

    [Fact]
    public async Task RealSimulatedSignatureAndBatchReuseAreBoundToOrigin()
    {
        using var identity = new SigningCoreTests.TestIdentity();
        _cards = [new CardEntry("Test reader", CertificateSummary.FromDer(identity.Certificate))];
        _connect = () =>
        {
            var sim = IdentityGuardTests.Simulator(identity.Certificate, CosmoXCardTests.SessionAfterAuthentication());
            sim.InternalAuthenticate = identity.Sign;
            return new IdentityGuardTests.AuthenticatingTransport(sim, "Test reader");
        };
        _consent = _ => ConsentResult.WithPin("1234");
        const string body = """{"data":"PGRvYy8+","contentType":"Xml","signFormat":"XAdES-BES","signatureType":"Embedded","pin":"9999"}""";
        using var first = await PostAsync(body);
        Assert.Equal(HttpStatusCode.Created, first.StatusCode);
        var id = Assert.Single(first.Headers.GetValues("sessionId"));
        using var firstResult = await _client.GetAsync(first.Headers.Location + "?keep_pin_session=1");
        firstResult.EnsureSuccessStatusCode();
        using (var result = JsonDocument.Parse(await firstResult.Content.ReadAsStringAsync()))
        {
            var document = new XmlDocument { PreserveWhitespace = true, XmlResolver = null };
            document.LoadXml(Encoding.UTF8.GetString(Convert.FromBase64String(
                result.RootElement.GetProperty("base64File").GetString()!)));
            var signature = (XmlElement)document.GetElementsByTagName("Signature", SignedXml.XmlDsigNamespaceUrl)[0]!;
            var verifier = new SignedXml(document);
            verifier.LoadXml(signature);
            using var certificate = X509CertificateLoader.LoadCertificate(identity.Certificate);
            using var publicKey = certificate.GetRSAPublicKey()!;
            Assert.True(verifier.CheckSignature(publicKey));
        }
        using var second = await _client.PostAsync($"/sign/data?use_pin_session={id}",
            new StringContent(body, Encoding.UTF8, "application/json"));
        using var secondResult = await _client.GetAsync(second.Headers.Location);
        secondResult.EnsureSuccessStatusCode();
        Assert.Equal(1, _consents);

        using var foreignRequest = new HttpRequestMessage(HttpMethod.Post, $"/sign/data?use_pin_session={id}");
        foreignRequest.Headers.Add("Origin", "https://mpass.gov.md");
        foreignRequest.Content = new StringContent(body, Encoding.UTF8, "application/json");
        using var foreign = await _client.SendAsync(foreignRequest);
        using var foreignPoll = new HttpRequestMessage(HttpMethod.Get, foreign.Headers.Location);
        foreignPoll.Headers.Add("Origin", "https://mpass.gov.md");
        using var foreignResult = await _client.SendAsync(foreignPoll);
        foreignResult.EnsureSuccessStatusCode();
        Assert.Equal(2, _consents);
    }

    [Fact]
    public async Task SwappedCardCannotReceiveTheSelectedCardsPin()
    {
        using var selected = new SigningCoreTests.TestIdentity();
        using var swapped = new SigningCoreTests.TestIdentity();
        _cards = [new CardEntry("Test reader", CertificateSummary.FromDer(selected.Certificate))];
        var sim = IdentityGuardTests.Simulator(swapped.Certificate, CosmoXCardTests.SessionAfterAuthentication());
        sim.InternalAuthenticate = swapped.Sign;
        _connect = () => new IdentityGuardTests.AuthenticatingTransport(sim, "Test reader");
        _consent = _ => ConsentResult.WithPin("1234");
        using var created = await PostAsync("""{"data":"PGRvYy8+","contentType":"Xml","signFormat":"XAdES-BES"}""");
        using var result = await _client.GetAsync(created.Headers.Location);
        Assert.Equal(HttpStatusCode.BadRequest, result.StatusCode);
        Assert.Equal(0, _consents);
        Assert.DoesNotContain(sim.Commands, command => command.Length > 1 && command[1] == 0x20);
    }

    private Task<HttpResponseMessage> PostAsync(string body) =>
        _client.PostAsync("/sign/data", new StringContent(body, Encoding.UTF8, "application/json"));

    private static int FreePort()
    {
        var listener = new TcpListener(IPAddress.Loopback, 0);
        listener.Start();
        var port = ((IPEndPoint)listener.LocalEndpoint).Port;
        listener.Stop();
        return port;
    }
}
