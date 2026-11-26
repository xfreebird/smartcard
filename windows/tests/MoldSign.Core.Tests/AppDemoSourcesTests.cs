using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using MoldSign.App.Services;

namespace MoldSign.Core.Tests;

/// <summary>App demo sources (fictional readers/cards, no PC/SC) and the bridge TLS identity selection.</summary>
public sealed class AppDemoSourcesTests
{
    [Theory]
    [InlineData("none", new string[0], new SlotState[0])]
    [InlineData("empty", new[] { "Demo reader" }, new[] { SlotState.Empty })]
    [InlineData("mute", new[] { "Demo reader" }, new[] { SlotState.Mute })]
    [InlineData("1", new[] { "Demo reader 1" }, new[] { SlotState.Card })]
    [InlineData("2", new[] { "Demo reader 1", "Demo reader 2" }, new[] { SlotState.Card, SlotState.Card })]
    [InlineData("multiple-second", new[] { "Demo reader 1", "Demo reader 2" }, new[] { SlotState.Card, SlotState.Card })]
    [InlineData("3", new[] { "Demo reader 1", "Demo reader 2", "Demo reader 3" }, new[] { SlotState.Card, SlotState.Card, SlotState.Card })]
    public void Demo_reader_scenarios_publish_fixed_snapshots(string scenario, string[] readers, SlotState[] states)
    {
        using var source = new DemoReaderSource(scenario);
        var published = new List<IReadOnlyList<ReaderSlot>>();
        source.Changed += (_, slots) => published.Add(slots);

        source.Start();
        source.Refresh();

        Assert.Equal(2, published.Count);
        Assert.All(published, slots =>
        {
            Assert.Equal(readers, slots.Select(slot => slot.Name));
            Assert.Equal(states, slots.Select(slot => slot.State));
        });
    }

    [Theory]
    [InlineData("Demo reader 1", "POPESCU ION", "01")]
    [InlineData("Demo reader 2", "ISTRATI ELENA", "02")]
    public async Task Demo_cards_are_fictional_and_distinct_per_reader(string reader, string holder, string serial)
    {
        var result = await new DemoCardDataProvider("2").ReadAsync(reader);

        var certificate = Assert.IsType<CertificateSummary>(result.Certificate);
        Assert.Equal(holder, certificate.CommonName);
        Assert.Equal(holder, $"{certificate.Surname} {certificate.GivenName}");
        Assert.Equal(serial, certificate.SerialNumber);
        Assert.Equal("CN=Fictional demonstration card", certificate.Subject);
        Assert.Equal("DEMO CA", certificate.IssuerName);
        Assert.Empty(certificate.Der);
        Assert.Equal(40, certificate.Sha1.Length);
        Assert.Null(result.Problem);
        Assert.False(result.Busy);
        Assert.True((await new DemoCardDataProvider("signing").ReadAsync(reader)).Busy);
    }

    [Fact]
    public void Bridge_identity_prefers_the_override_then_the_imported_copy_then_the_bundle()
    {
        var previous = Environment.GetEnvironmentVariable("MSIGN_TLS_P12");
        try
        {
            Environment.SetEnvironmentVariable("MSIGN_TLS_P12", null);
            Assert.EndsWith(Path.Combine("MoldSign", "localhost.p12"), BridgeTls.IdentityPath, StringComparison.Ordinal);
            Assert.Equal(Path.Combine(AppContext.BaseDirectory, "localhost.p12"), BridgeTls.BundledPath);
            Assert.Equal(File.Exists(BridgeTls.IdentityPath) ? BridgeTls.IdentityPath : BridgeTls.BundledPath, BridgeTls.ResolvePath());

            var custom = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString("N") + ".p12");
            Environment.SetEnvironmentVariable("MSIGN_TLS_P12", custom);
            Assert.Equal(custom, BridgeTls.IdentityPath);
            Assert.Equal(custom, BridgeTls.ResolvePath());
        }
        finally { Environment.SetEnvironmentVariable("MSIGN_TLS_P12", previous); }
    }

    [Theory]
    [InlineData(true, false, X509KeyStorageFlags.UserKeySet)]       // Schannel needs a persisted user key
    [InlineData(false, true, X509KeyStorageFlags.DefaultKeySet)]    // macOS has no ephemeral key storage
    [InlineData(false, false, X509KeyStorageFlags.EphemeralKeySet)] // Linux keeps the key in memory only
    public void Bridge_identity_key_storage_follows_the_platform(bool windows, bool macOS, X509KeyStorageFlags expected) =>
        Assert.Equal(expected, BridgeTls.KeyStorageFor(windows, macOS));

    [Fact]
    public void Bridge_identity_must_exist_and_be_a_current_localhost_cts_md_key()
    {
        var missing = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString("N") + ".p12");
        Assert.Throws<FileNotFoundException>(() => BridgeTls.Load(missing));

        var now = DateTimeOffset.UtcNow;
        foreach (var (name, notAfter, withKey) in new[]
        {
            ("other.example", now.AddDays(1), true),
            ("localhost.cts.md", now.AddMinutes(-1), true),
            ("localhost.cts.md", now.AddDays(1), false),
        })
        {
            var path = Identity(name, now.AddDays(-2), notAfter, withKey);
            try { Assert.Throws<CryptographicException>(() => BridgeTls.Load(path)); }
            finally { File.Delete(path); }
        }

        var valid = Identity("localhost.cts.md", now.AddDays(-1), now.AddDays(1), withKey: true);
        try
        {
            var loaded = BridgeTls.Load(valid);
            try { Assert.Single(loaded, certificate => certificate.HasPrivateKey); }
            finally { foreach (var certificate in loaded) certificate.Dispose(); }
        }
        finally { File.Delete(valid); }
    }

    private static string Identity(string dnsName, DateTimeOffset notBefore, DateTimeOffset notAfter, bool withKey)
    {
        using var key = RSA.Create(2048);
        var request = new CertificateRequest($"CN={dnsName}", key, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        var san = new SubjectAlternativeNameBuilder();
        san.AddDnsName(dnsName);
        request.CertificateExtensions.Add(san.Build());
        using var certificate = request.CreateSelfSigned(notBefore, notAfter);
        var path = Path.Combine(Path.GetTempPath(), $"moldsign-identity-{Guid.NewGuid():N}.p12");
        if (withKey) File.WriteAllBytes(path, certificate.Export(X509ContentType.Pfx, BridgeTls.Password));
        else
        {
            using var publicOnly = X509CertificateLoader.LoadCertificate(certificate.RawData);
            File.WriteAllBytes(path, new X509Certificate2Collection(publicOnly).Export(X509ContentType.Pfx, BridgeTls.Password)!);
        }
        return path;
    }
}
