using System.Text.Json;

namespace MoldSign.Desktop;

/// <summary>Non-secret preferences shared by the UI and independent insertion helper.</summary>
public class DesktopPreferences
{
    public string Language { get; set; } = "";
    public string Theme { get; set; } = "system";
    public bool OpenOnCardInsertion { get; set; }
    public bool OpenOnReaderInsertion { get; set; }
    public bool BridgeEnabled { get; set; } = true;
    public bool RememberPin { get; set; }
    public bool ReaderToasts { get; set; } = true;
    public bool StartAtLogin { get; set; }
    public bool FirstRunDone { get; set; }
    public bool DemoModeEnabled { get; set; }
    [System.Text.Json.Serialization.JsonIgnore]
    public bool InsertionHelperEnabled => !DemoModeEnabled && (OpenOnCardInsertion || OpenOnReaderInsertion);
}

/// <summary>Atomic preferences persistence; it contains no PINs or credential-vault operations.</summary>
public sealed class DesktopPreferenceStore(string path)
{
    public static string DefaultPath => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
        "MoldSign", "settings.json");

    public T Load<T>() where T : DesktopPreferences, new()
    {
        try
        {
            if (!File.Exists(path)) return new T();
            using var stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete);
            return JsonSerializer.Deserialize<T>(stream) ?? new T();
        }
        catch (Exception error) when (error is IOException or JsonException or UnauthorizedAccessException) { return new T(); }
    }

    public void Save(DesktopPreferences preferences)
    {
        var directory = Path.GetDirectoryName(path)!;
        Directory.CreateDirectory(directory);
        var temporary = Path.Combine(directory, $".settings-{Guid.NewGuid():N}.tmp");
        try
        {
            // The runtime type, so the app's own settings (a derived class) are written too; the insertion helper
            // reads the same file as the base type and ignores them.
            File.WriteAllText(temporary, JsonSerializer.Serialize(preferences, preferences.GetType(),
                new JsonSerializerOptions { WriteIndented = true }));
            File.Move(temporary, path, overwrite: true);
        }
        finally { if (File.Exists(temporary)) File.Delete(temporary); }
    }
}
