using System.IO.Pipes;
using System.Text;
using MoldSign.Desktop;

namespace MoldSign.Core.Tests;

/// <summary>Desktop policies shared by the app and its helper: file processing, verification errors, preferences, activation.</summary>
public sealed class DesktopPolicyTests
{
    [Fact]
    public void Legacy_processors_encrypt_only_with_aes_256()
    {
        var processor = new LegacyProcessor();
        IPasswordFileProcessor contract = processor;
        Assert.Throws<NotSupportedException>(() => contract.Encrypt("in.bin", "parola", 128));
        Assert.Empty(processor.Calls);
        processor.Result = [7];
        Assert.Equal(new byte[] { 7 }, contract.Encrypt("in.bin", "parola", 256));
        Assert.Equal([("in.bin", FileProtectionOperation.Encrypt)], processor.Calls);
        processor.Result = null;
        Assert.Throws<InvalidOperationException>(() => contract.Encrypt("in.bin", "parola", 256));
    }

    [Fact]
    public void Password_processor_removal_overwrites_on_windows_only()
    {
        var path = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString("N") + ".bin");
        File.WriteAllBytes(path, [1, 2, 3]);
        try
        {
            var processor = new PasswordFileProcessor();
            if (OperatingSystem.IsWindows())
            {
                Assert.Null(processor.Process(path, FileProtectionOperation.Remove, ""));
                Assert.False(File.Exists(path));
            }
            else
            {
                Assert.Throws<PlatformNotSupportedException>(() => processor.Process(path, FileProtectionOperation.Remove, ""));
                Assert.Equal(new byte[] { 1, 2, 3 }, File.ReadAllBytes(path));
            }
        }
        finally { File.Delete(path); }
    }

    [Fact]
    public void Verification_failures_keep_their_kind()
    {
        var unsupported = new VerifyDocument(new Throwing(new NotImplementedException()), _ => true).Execute("a.xml");
        Assert.Equal(VerificationStatus.Unsupported, unsupported.Status);
        var failure = new InvalidOperationException("parser");
        var failed = new VerifyDocument(new Throwing(failure), _ => true).Execute("a.pdf");
        Assert.Equal(VerificationStatus.Failed, failed.Status);
        Assert.Same(failure, failed.Error);
        Assert.Null(failed.Verdict);
    }

    [Fact]
    public void Preferences_live_in_local_app_data_and_corrupt_files_fall_back_to_defaults()
    {
        Assert.Equal(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "MoldSign", "settings.json"),
            DesktopPreferenceStore.DefaultPath);
        var directory = Directory.CreateTempSubdirectory("moldsign-preferences-");
        try
        {
            var path = Path.Combine(directory.FullName, "settings.json");
            File.WriteAllText(path, "{ not json");
            var restored = new DesktopPreferenceStore(path).Load<DesktopPreferences>();
            Assert.False(restored.DemoModeEnabled);
            Assert.Equal(new DesktopPreferences().InsertionHelperEnabled, restored.InsertionHelperEnabled);
        }
        finally { directory.Delete(true); }
    }

    [Fact]
    public async Task Activation_ignores_malformed_and_oversized_commands_and_keeps_listening()
    {
        if (!OperatingSystem.IsWindows()) return; // per-session named pipes are the Windows activation channel
        await ActivationSurvivesBadClients();
    }

    [System.Runtime.Versioning.SupportedOSPlatform("windows")]
    private static async Task ActivationSurvivesBadClients()
    {
        var key = "MoldSign-Test-" + Guid.NewGuid().ToString("N");
        await using var primary = new DesktopActivationBroker(key);
        var received = new List<(string Action, IReadOnlyList<string> Paths)>();
        var signed = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        primary.ListenFiles(paths => { lock (received) received.Add(("sign", paths)); signed.TrySetResult(); });

        foreach (var raw in new[] { "files:[not json\n", "verify:{\n", "unknown\n", new string('x', 40000) + "\n" })
            await Send(key, raw);
        await using (var oversized = new DesktopActivationBroker(key))
            await Assert.ThrowsAsync<ArgumentException>(() => oversized.OpenFilesAsync([new string('d', 40000)], default));

        await using var secondary = new DesktopActivationBroker(key);
        Assert.False(secondary.IsPrimary);
        await secondary.OpenFilesAsync([@"C:\Documents\contract.pdf"], default);
        await signed.Task.WaitAsync(TimeSpan.FromSeconds(10));
        lock (received) Assert.Equal([("sign", (IReadOnlyList<string>)[@"C:\Documents\contract.pdf"])], received.Select(r => (r.Action, r.Paths)).ToArray(),
            new ActivationComparer());
    }

    private static async Task Send(string key, string raw)
    {
        var user = Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(Encoding.UTF8.GetBytes($"{Environment.UserDomainName}\\{Environment.UserName}")))[..16];
        var pipe = $"{key}-{user}-{System.Diagnostics.Process.GetCurrentProcess().SessionId}";
        await using var client = new NamedPipeClientStream(".", pipe, PipeDirection.Out, PipeOptions.Asynchronous);
        await client.ConnectAsync(5000);
        try { await client.WriteAsync(Encoding.UTF8.GetBytes(raw)); await client.FlushAsync(); }
        catch (IOException) { } // the listener may close an oversized frame early
    }

    private sealed class ActivationComparer : IEqualityComparer<(string Action, IReadOnlyList<string> Paths)>
    {
        public bool Equals((string Action, IReadOnlyList<string> Paths) x, (string Action, IReadOnlyList<string> Paths) y) =>
            x.Action == y.Action && x.Paths.SequenceEqual(y.Paths);
        public int GetHashCode((string Action, IReadOnlyList<string> Paths) value) => value.Action.GetHashCode(StringComparison.Ordinal);
    }

    private sealed class LegacyProcessor : IPasswordFileProcessor
    {
        public byte[]? Result { get; set; }
        public List<(string Input, FileProtectionOperation Operation)> Calls { get; } = [];
        public byte[]? Process(string input, FileProtectionOperation operation, string password)
        {
            Calls.Add((input, operation));
            return Result;
        }
    }

    private sealed class Throwing(Exception error) : IDocumentVerifier
    {
        public IReadOnlyList<VerificationReport> Verify(string file, IReadOnlyList<string>? detachedDocs = null) => throw error;
    }
}
