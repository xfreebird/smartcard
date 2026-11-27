using MoldSign.Desktop;

namespace MoldSign.App.Services;

/// <summary>UI preference adapter; persistence is shared with the independent insertion helper.</summary>
public sealed class AppSettings : DesktopPreferences
{
    public bool McpApprovalEnabled { get; set; }
    public bool BrowserStampsEnabled { get; set; }
    public bool LegacyDesktopClientEnabled { get; set; }
    /// <summary>Phase TOK: recognize USB signing tokens (experimental, off by default).</summary>
    public bool ExperimentalTokensEnabled { get; set; }
    internal static string PreferencesPath
    {
        get
        {
#if DEBUG
            if (Environment.GetEnvironmentVariable("MSIGN_TEST_PREFERENCES") is { Length: > 0 } path)
                return Path.GetFullPath(path);
#endif
            return DesktopPreferenceStore.DefaultPath;
        }
    }
    internal static string ActivityPath => Path.Combine(Path.GetDirectoryName(PreferencesPath)!, "activity.json");
    internal static bool IsolatedTestPreferences
    {
        get
        {
#if DEBUG
            return !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("MSIGN_TEST_PREFERENCES"));
#else
            return false;
#endif
        }
    }
    private static readonly DesktopPreferenceStore Store = new(PreferencesPath);
    public static AppSettings Load() => DemoMode.PreviewScenario is not null && !IsolatedTestPreferences
        ? new AppSettings { BridgeEnabled = false } : Store.Load<AppSettings>();

    public void Save()
    {
        if (DemoMode.PreviewScenario is not null && !IsolatedTestPreferences) return;
        try { Store.Save(this); }
        catch (Exception error) when (error is IOException or UnauthorizedAccessException) { AppLog.Error(error); }
    }
}
