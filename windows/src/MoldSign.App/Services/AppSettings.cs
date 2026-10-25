using System.Text.Json;

namespace MoldSign.App.Services;

/// <summary>
/// User preferences in %LOCALAPPDATA%\MoldSign\settings.json (the app is unpackaged, so
/// ApplicationData.LocalSettings is not available; WIN-08 may switch to it under MSIX).
/// </summary>
public sealed class AppSettings
{
    private static readonly string s_path = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "MoldSign", "settings.json");

    public bool BridgeEnabled { get; set; } = true;
    public bool RememberPin { get; set; }
    public bool ReaderToasts { get; set; } = true;
    /// <summary>TODO(WIN-04): register/unregister (HKCU Run key unpackaged, StartupTask under MSIX).</summary>
    public bool StartAtLogin { get; set; }
    public bool FirstRunDone { get; set; }

    public static AppSettings Load()
    {
        try
        {
            if (File.Exists(s_path))
                return JsonSerializer.Deserialize<AppSettings>(File.ReadAllText(s_path)) ?? new AppSettings();
        }
        catch (Exception e) when (e is IOException or JsonException or UnauthorizedAccessException)
        {
            // Corrupt or locked: start from defaults.
        }
        return new AppSettings();
    }

    public void Save()
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(s_path)!);
            File.WriteAllText(s_path, JsonSerializer.Serialize(this, new JsonSerializerOptions { WriteIndented = true }));
        }
        catch (Exception e) when (e is IOException or UnauthorizedAccessException)
        {
            System.Diagnostics.Debug.WriteLine($"settings not saved: {e.Message}");
        }
    }
}
