using System.Diagnostics;
using System.Net.Http;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace MoldSign.App.Services;

/// <summary>Direct-install update notices. Store packages never fetch this feed or open update links.</summary>
internal sealed class UpdateChecker
{
    private sealed record Manifest([property: JsonPropertyName("version")] string Version,
        [property: JsonPropertyName("downloadURL")] string DownloadUrl);
    private readonly string _stamp = Path.Combine(Path.GetDirectoryName(AppSettings.PreferencesPath)!, "update-check.txt");
    private bool _checking;
    private bool _stopped;
    private CancellationTokenSource? _periodic;
    private Task? _loop;
    private Task<string?>? _checkTask;
    internal void Start()
    {
        if (!Available || _periodic is not null) return;
        _stopped = false;
        _periodic = new CancellationTokenSource();
        _loop = RunAsync(_periodic.Token);
    }
    internal async Task StopAsync()
    {
        _stopped = true;
        var source = _periodic;
        if (source is not null) await source.CancelAsync();
        if (_loop is not null) await _loop;
        if (_checkTask is not null) await _checkTask;
        source?.Dispose();
        if (_periodic == source) { _periodic = null; _loop = null; }
    }
    private async Task RunAsync(CancellationToken token)
    {
        try
        {
            while (!token.IsCancellationRequested)
            {
                await CheckAsync(automatic: true, token);
                await Task.Delay(TimeSpan.FromDays(1), token);
            }
        }
        catch (OperationCanceledException) { }
    }
    internal bool Available => !StartupRegistration.IsPackaged;

    internal Task<string?> CheckAsync(bool automatic, CancellationToken cancellationToken = default)
    {
        var task = CheckCoreAsync(automatic, cancellationToken);
        if (!task.IsCompleted) _checkTask = task;
        return task;
    }

    private async Task<string?> CheckCoreAsync(bool automatic, CancellationToken cancellationToken)
    {
        if (!Available || _checking || _stopped) return null;
        var token = cancellationToken == default ? _periodic?.Token ?? CancellationToken.None : cancellationToken;
        _checking = true;
        try
        {
            if (automatic && File.Exists(_stamp) && DateTimeOffset.TryParse(await File.ReadAllTextAsync(_stamp, token), out var last)
                && DateTimeOffset.UtcNow - last < TimeSpan.FromDays(7)) return null;
            Directory.CreateDirectory(Path.GetDirectoryName(_stamp)!);
            await File.WriteAllTextAsync(_stamp, DateTimeOffset.UtcNow.ToString("O"), token);
            using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };
            using var response = await client.GetAsync("https://esemnbun.md/updates/windows.json", token);
            response.EnsureSuccessStatusCode();
            var manifest = JsonSerializer.Deserialize<Manifest>(await response.Content.ReadAsStringAsync(token))
                ?? throw new InvalidDataException();
            if (manifest.Version?.Split('.').Length != 3 || !Version.TryParse(manifest.Version, out var latest) ||
                !Uri.TryCreate(manifest.DownloadUrl, UriKind.Absolute, out var target) ||
                target.Scheme != "https" || target.Host != "esemnbun.md" || !string.IsNullOrEmpty(target.UserInfo)) throw new InvalidDataException();
            var installed = typeof(App).Assembly.GetName().Version ?? new Version(0, 0, 0);
            if (latest > new Version(installed.Major, installed.Minor, Math.Max(0, installed.Build)))
            {
                if (_stopped) return null;
                Process.Start(new ProcessStartInfo(target.AbsoluteUri) { UseShellExecute = true });
                return automatic ? null : Loc.Get("Update_Available");
            }
            return automatic ? null : Loc.Get("Update_Current");
        }
        catch (Exception error) when (error is HttpRequestException or OperationCanceledException or IOException or JsonException or UnauthorizedAccessException or System.ComponentModel.Win32Exception)
        { return automatic ? null : Loc.Get("Update_Failed"); }
        finally { _checking = false; }
    }
}
