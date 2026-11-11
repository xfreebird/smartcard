using MoldSign.Core;

namespace MoldSign.App.Services;

/// <summary>User demo mode works in every build; environment fixtures remain Debug-only.</summary>
internal static class DemoMode
{
    private static bool _enabled;
    public static bool ScreenshotCapture
    {
        get
        {
#if DEBUG
            return PreviewScenario is not null && Environment.GetEnvironmentVariable("MSIGN_SCREENSHOT_CAPTURE") == "1";
#else
            return false;
#endif
        }
    }
    public static void Configure(bool enabled) => _enabled = enabled;
    public static string? PreviewScenario
    {
        get
        {
#if DEBUG
            return Environment.GetEnvironmentVariable("MSIGN_DEMO_CARDS");
#else
            return null;
#endif
        }
    }
    public static string? Scenario => PreviewScenario ?? (_enabled ? "2" : null);
}
