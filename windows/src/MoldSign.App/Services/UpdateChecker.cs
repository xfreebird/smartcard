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
    internal void Start()
    {
        if (!Available || _periodic is not null) return;
        _stopped = false;
        _periodic = new CancellationTokenSource();
        _ = RunAsync(_periodic.Token);
    }
    internal void Stop() { _stopped = true; _periodic?.Cancel(); _periodic?.Dispose(); _periodic = null; }
    private async Task RunAsync(CancellationToken token)
    {
        try
        {
            while (!token.IsCancellationRequested)
            {
                await CheckAsync(automatic: true);
                await Task.Delay(TimeSpan.FromDays(1), token);
            }
        }
        catch (OperationCanceledException) { }
    }
    internal bool Available => !StartupRegistration.IsPackaged;

    internal async Task<string?> CheckAsync(bool automatic)
    {
        if (!Available || _checking || _stopped) return null;
        _checking = true;
        try
        {
            if (automatic && File.Exists(_stamp) && DateTimeOffset.TryParse(await File.ReadAllTextAsync(_stamp), out var last)
                && DateTimeOffset.UtcNow - last < TimeSpan.FromDays(7)) return null;
            Directory.CreateDirectory(Path.GetDirectoryName(_stamp)!);
            await File.WriteAllTextAsync(_stamp, DateTimeOffset.UtcNow.ToString("O"));
            using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };
            using var response = await client.GetAsync("https://esemnbun.md/updates/windows.json", _periodic?.Token ?? CancellationToken.None);
            response.EnsureSuccessStatusCode();
            var manifest = JsonSerializer.Deserialize<Manifest>(await response.Content.ReadAsStringAsync())
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
        catch (Exception error) when (error is HttpRequestException or TaskCanceledException or IOException or JsonException or UnauthorizedAccessException or System.ComponentModel.Win32Exception)
        { return automatic ? null : Loc.Get("Update_Failed"); }
        finally { _checking = false; }
    }
}
