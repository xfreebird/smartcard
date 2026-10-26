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
        using var entered = new ManualResetEventSlim();
        using var release = new ManualResetEventSlim();
        _connect = () =>
        {
            entered.Set();
            if (!release.Wait(TimeSpan.FromSeconds(5))) throw new TimeoutException();
            throw new IOException("Test transport unavailable");
        };
        using var created = await PostAsync("""{"data":"PGRvYy8+","contentType":"Xml","signFormat":"XAdES-BES","certificate":{"certificateBase64":""}}""");
        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        Assert.Empty(await created.Content.ReadAsByteArrayAsync());
        Assert.NotNull(created.Headers.Location);
        Assert.True(created.Headers.Location.IsAbsoluteUri);
        Assert.Contains("/sign/data/PKCS11/", created.Headers.Location.AbsolutePath);
        var poll = _client.GetAsync(created.Headers.Location);
        try
        {
            Assert.True(entered.Wait(TimeSpan.FromSeconds(3)));
            await Task.Delay(100);
            Assert.False(poll.IsCompleted);
        }
        finally { release.Set(); }
        using var result = await poll;
        Assert.Equal(HttpStatusCode.BadRequest, result.StatusCode);
        Assert.Contains("Test transport unavailable", Assert.Single(result.Headers.GetValues("error")));
        using var repeated = await _client.GetAsync(created.Headers.Location);
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
