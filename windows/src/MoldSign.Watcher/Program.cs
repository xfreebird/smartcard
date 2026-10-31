using System.Diagnostics;
using System.Text.Json;
using MoldSign.Core;
using MoldSign.Desktop;

namespace MoldSign.Watcher;

internal static class Program
{
    private static async Task Main(string[] args)
    {
        // A named lifetime object prevents duplicate helpers without relying on cross-thread mutex ownership.
        using var lifetime = new Mutex(false, @"Local\MoldSign.InsertionWatcher." + Environment.UserName + "." + Process.GetCurrentProcess().SessionId, out var primary);
        if (!primary) return;
        var app = Argument(args, "--app") ?? Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "eSemnBun.exe"));
        if (!File.Exists(app) || !string.Equals(Path.GetFileName(app), "eSemnBun.exe", StringComparison.OrdinalIgnoreCase)) return;
        var store = new DesktopPreferenceStore(DesktopPreferenceStore.DefaultPath);
        IReaderSnapshotSource source = new PcscSnapshots();
        Func<DesktopPreferences> preferences = store.Load<DesktopPreferences>;
#if DEBUG
        if ((Argument(args, "--scenario-file") ?? Environment.GetEnvironmentVariable("MSIGN_WATCHER_SCENARIO_FILE")) is { } scenario)
        {
            source = new JsonSnapshots(scenario);
            preferences = Argument(args, "--settings-file") is { } settingsPath
                ? new DesktopPreferenceStore(settingsPath).Load<DesktopPreferences>
                : () => new DesktopPreferences { OpenOnReaderInsertion = true, OpenOnCardInsertion = true };
        }
#endif
        var watcher = new InsertionWatcher(source, new ProcessActivator(app), preferences);
        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(1));
        try
        {
#if DEBUG
            var published = false;
#endif
            while (await watcher.CheckAsync(CancellationToken.None))
            {
#if DEBUG
                if (!published)
                {
                    if (Argument(args, "--ready-file") is { } ready) File.WriteAllText(ready, "baseline-ready");
                    published = true;
                }
#endif
                if (!await timer.WaitForNextTickAsync()) break;
            }
        }
        catch (Exception error) when (error is IOException or UnauthorizedAccessException or CardException) { }
    }

    private static string? Argument(string[] args, string key)
    {
        var index = Array.IndexOf(args, key);
        return index >= 0 && index + 1 < args.Length ? args[index + 1] : null;
    }

    private sealed class PcscSnapshots : IReaderSnapshotSource
    {
        public IReadOnlyList<ReaderStatus> Read()
        {
            try { return WinSCardTransport.GetReaderStates(); }
            catch (CardException) { return []; }
        }
    }

    private sealed class ProcessActivator(string app) : IApplicationActivator
    {
        public Task OpenAsync(CancellationToken cancellationToken)
        {
            cancellationToken.ThrowIfCancellationRequested();
            Process.Start(new ProcessStartInfo(app, "--open") { UseShellExecute = false });
            return Task.CompletedTask;
        }
    }
#if DEBUG
    private sealed class JsonSnapshots(string path) : IReaderSnapshotSource
    {
        public IReadOnlyList<ReaderStatus> Read()
        {
            try
            {
                using var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete);
                using var text = new StreamReader(stream);
                return JsonSerializer.Deserialize<ReaderStatus[]>(text.ReadToEnd()) ?? [];
            }
            catch (Exception error) when (error is IOException or JsonException) { return []; }
        }
    }
#endif
}
