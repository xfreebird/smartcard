using System.Security.Cryptography;
using MoldSign.Cli;

namespace MoldSign.Core.Tests;

public sealed class WindowsMcpUnattendedTests
{
    [Fact]
    public void Certificate_mismatch_does_not_read_secret_or_verify_and_survives_restart()
    {
        using var fixture = new Fixture();
        var reads = 0;
        var signer = fixture.Signer(new string('0', 64), () => { reads++; return "0000"; });
        Assert.Equal("CARD_CHANGED", Assert.Throws<McpException>(() => signer.Sign(SigningCoreTests.MinimalPdf())).Code);
        Assert.Equal(0, reads);
        Assert.DoesNotContain(fixture.Simulations.Single().Commands, a => a[1] == 0x20);
        var restarted = fixture.Signer(fixture.Fingerprint, () => { reads++; return "0000"; });
        Assert.Equal("SIGNING_DISABLED", Assert.Throws<McpException>(() => restarted.Sign(SigningCoreTests.MinimalPdf())).Code);
        Assert.Equal(0, reads);
        Assert.Single(fixture.Simulations);
    }

    [Fact]
    public void Successful_signing_writes_valid_pdf_and_clears_marker_without_echoing_secret()
    {
        using var fixture = new Fixture();
        var input = SigningCoreTests.MinimalPdf();
        var original = (byte[])input.Clone();
        var signer = fixture.Signer(fixture.Fingerprint, () =>
        {
            // Mutating caller memory at the latest possible point cannot change the snapshot.
            Array.Fill(input, (byte)0);
            return "0000";
        });
        var result = signer.Sign(input);
        Assert.Equal("completed", result["state"]!.GetValue<string>());
        Assert.Equal(Convert.ToHexStringLower(SHA256.HashData(original)), result["inputSHA256"]!.GetValue<string>());
        var filename = result["output"]!["relativePath"]!.GetValue<string>();
        var signed = fixture.Output.Read(filename, 16 * 1024 * 1024);
        var report = Assert.Single(Validator.ValidatePdf(signed));
        Assert.True(report.ContentIntact);
        Assert.True(report.SignatureValid);
        Assert.Equal(original, signed[..original.Length]);
        Assert.False(File.Exists(Path.Combine(fixture.Directory, WindowsMcpUnattendedSigner.MarkerName)));
        Assert.Single(fixture.Simulations.Single().Commands, a => a[1] == 0x20);
        Assert.DoesNotContain("pin", result.ToJsonString(), StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Wrong_pin_is_attempted_once_and_next_request_is_disabled()
    {
        using var fixture = new Fixture(wrongPin: true);
        var reads = 0;
        var signer = fixture.Signer(fixture.Fingerprint, () => { reads++; return "0000"; });
        Assert.Equal("PIN_INCORRECT", Assert.Throws<McpException>(() => signer.Sign(SigningCoreTests.MinimalPdf())).Code);
        Assert.Equal("SIGNING_DISABLED", Assert.Throws<McpException>(() => signer.Sign(SigningCoreTests.MinimalPdf())).Code);
        Assert.Equal(1, reads);
        Assert.Equal(1, fixture.VerifyAttempts);
        Assert.Empty(System.IO.Directory.GetFiles(fixture.Directory, "*.pdf"));
    }

    [Fact]
    public void Timestamp_failure_preserves_gate_and_never_retries_signature()
    {
        using var fixture = new Fixture();
        fixture.Pki.WrongImprint = true; // A permanent invalid timestamp, not a retriable HTTP 503.
        var signer = fixture.Signer(fixture.Fingerprint, () => "0000");
        Assert.Equal("NETWORK_FAILED", Assert.Throws<McpException>(() => signer.Sign(SigningCoreTests.MinimalPdf())).Code);
        Assert.Equal("SIGNING_DISABLED", Assert.Throws<McpException>(() => signer.Sign(SigningCoreTests.MinimalPdf())).Code);
        Assert.Equal(1, fixture.Identity.SignCalls);
        Assert.Empty(System.IO.Directory.GetFiles(fixture.Directory, "*.pdf"));
    }

    [Fact]
    public void Transient_timestamp_retry_does_not_repeat_pin_or_card_signature()
    {
        using var fixture = new Fixture();
        fixture.Pki.FailFirstTimestamp = true;
        var signer = fixture.Signer(fixture.Fingerprint, () => "0000");
        Assert.Equal("completed", signer.Sign(SigningCoreTests.MinimalPdf())["state"]!.GetValue<string>());
        Assert.Equal(2, fixture.Pki.TimestampRequests);
        Assert.Equal(1, fixture.Identity.SignCalls);
        Assert.Equal(1, fixture.VerifyAttempts);
    }

    [Fact]
    public void Missing_or_malformed_credential_never_reaches_verify()
    {
        using var fixture = new Fixture();
        var signer = fixture.Signer(fixture.Fingerprint, () => "secret-with-control\n");
        Assert.Equal("CREDENTIAL_UNAVAILABLE", Assert.Throws<McpException>(() => signer.Sign(SigningCoreTests.MinimalPdf())).Code);
        Assert.DoesNotContain(fixture.Simulations.Single().Commands, a => a[1] == 0x20);
    }

    [Fact]
    public void Configuration_requires_explicit_opt_in_and_never_reads_provider_during_discovery()
    {
        Dictionary<string, McpTrustedRoot> roots = [];
        Assert.Null(WindowsMcpUnattendedSigner.Create([], roots));
        Assert.Equal("INVALID_ARGUMENT", Assert.Throws<McpException>(() =>
            WindowsMcpUnattendedSigner.Create(["--pin-source", "env:UNSET_AUTOMATION_TEST"], roots)).Code);
        Assert.Equal("INVALID_ARGUMENT", Assert.Throws<McpException>(() =>
            WindowsMcpUnattendedSigner.Create(["--allow-unattended-signing", "--allow-unattended-signing"], roots)).Code);
        var provider = WindowsMcpCredentialSource.Create("env:ESEMNBUN_UNIT_TEST_UNSET_458D15");
        Assert.Equal("CREDENTIAL_UNAVAILABLE", Assert.Throws<McpException>(() => provider()).Code);
        Assert.Throws<McpException>(() => WindowsMcpCredentialSource.Create("env:bad\nname"));
        Assert.Throws<McpException>(() => WindowsMcpCredentialSource.Create("onepassword:op://vault/item/pin"));
    }

    private sealed class Fixture : IDisposable
    {
        internal readonly SigningCoreTests.TestIdentity Identity = new();
        internal readonly SigningCoreTests.FakePki Pki;
        internal readonly string Directory;
        internal readonly McpTrustedRoot Output;
        internal readonly List<CosmoXCardTests.SimulatedSmCard> Simulations = [];
        internal int VerifyAttempts;
        private readonly bool wrongPin;
        internal string Fingerprint => Convert.ToHexString(SHA256.HashData(Identity.Certificate));
        internal Fixture(bool wrongPin = false)
        {
            this.wrongPin = wrongPin;
            Directory = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString("D"));
            System.IO.Directory.CreateDirectory(Directory);
            Output = new McpTrustedRoot(Directory);
            Pki = new SigningCoreTests.FakePki(Identity);
        }
        internal WindowsMcpUnattendedSigner Signer(string fingerprint, Func<string> provider)
        {
            var service = new SigningService(() =>
            {
                var sim = IdentityGuardTests.Simulator(Identity.Certificate, CosmoXCardTests.SessionAfterAuthentication());
                sim.InternalAuthenticate = Identity.Sign; Simulations.Add(sim);
                ICardTransport transport = new IdentityGuardTests.AuthenticatingTransport(sim, "MCP fixture");
                return new ObservingTransport(transport, () => VerifyAttempts++, wrongPin);
            }, Pki.Trust);
            return new WindowsMcpUnattendedSigner(Output, fingerprint, provider, service);
        }
        public void Dispose()
        {
            Output.Dispose(); Pki.Dispose(); Identity.Dispose(); System.IO.Directory.Delete(Directory, true);
        }
    }
    private sealed class ObservingTransport(ICardTransport inner, Action verify, bool wrongPin) : ICardTransport
    {
        public string ReaderName => inner.ReaderName;
        public byte[] Transmit(byte[] apdu)
        {
            if (apdu.Length > 1 && apdu[1] == 0x20)
            {
                verify();
                if (wrongPin) return [0x63, 0xC2];
            }
            return inner.Transmit(apdu);
        }
        public void Dispose() => inner.Dispose();
    }
}
