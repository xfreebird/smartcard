using System.Text;
using MoldSign.Cli;
using MoldSign.Desktop;

namespace MoldSign.Core.Tests;

public sealed class ScannerHardeningTests
{
    [Fact]
    public void MalformedPdfWithExcessiveObjectsHasAFixedFailureInsteadOfEscapingTheVerifier()
    {
        var bytes = Encoding.ASCII.GetBytes("%PDF-1.7\n" + string.Concat(Enumerable.Repeat("1 0 obj <<>> endobj\n", 100_001)));
        var report = Assert.Single(Validator.ValidatePdf(bytes));
        Assert.Equal(Verdict.Invalid, report.Verdict);
        Assert.False(report.ContentIntact);
        Assert.False(report.SignatureValid);
    }

    [Fact]
    public void OversizedOriginIsRejectedEvenByAWildcardPolicy()
    {
        var policy = new BridgeOriginPolicy(["*"]);
        Assert.True(policy.IsAllowed("https://msign.gov.md", null));
        Assert.False(policy.IsAllowed("https://" + new string('a', 4096), null));
    }

    [Fact]
    public async Task RootDisposalCannotRaceNativePublicationIntoAnotherDirectory()
    {
        var directory = Directory.CreateTempSubdirectory("mcp-root-lifetime-");
        var root = new McpTrustedRoot(directory.FullName);
        try
        {
            var writes = Task.Run(() =>
            {
                for (var i = 0; i < 32; i++)
                {
                    try { root.WriteExclusive($"{i}.bin", [1, 2, 3]); }
                    catch (McpException error) { Assert.Equal("PATH_DENIED", error.Code); }
                }
            });
            root.Dispose();
            await writes;
            Assert.Equal("PATH_DENIED", Assert.Throws<McpException>(() => root.Read("0.bin", 10)).Code);
            foreach (var file in directory.EnumerateFiles()) Assert.Equal(new byte[] { 1, 2, 3 }, File.ReadAllBytes(file.FullName));
        }
        finally { root.Dispose(); directory.Delete(recursive: true); }
    }

    [Fact]
    public async Task ActivationBrokerJoinsAnIdleListenerAndReleasesItsInstance()
    {
        if (!OperatingSystem.IsWindows()) return;
        var key = "MoldSign-Shutdown-" + Guid.NewGuid().ToString("N");
        var first = new DesktopActivationBroker(key);
        first.Listen(() => throw new InvalidOperationException("No activation was sent"));
        await first.DisposeAsync().AsTask().WaitAsync(TimeSpan.FromSeconds(5));
        await first.DisposeAsync();
        await using var next = new DesktopActivationBroker(key);
        Assert.True(next.IsPrimary);
    }
}
