using MoldSign.Desktop;

namespace MoldSign.App.Services;

internal sealed record ProtectionPreview(FileProtectionOperation Operation, string Filename)
{
    public static ProtectionPreview? Selected
    {
        get
        {
#if DEBUG
            if (DemoMode.ScreenshotCapture && AppSettings.IsolatedTestPreferences &&
                Environment.GetEnvironmentVariable("MSIGN_CAPTURE_DIALOG") is { } scenario &&
                scenario.StartsWith("protect-", StringComparison.Ordinal))
            {
                var operation = scenario.Contains("remove") ? FileProtectionOperation.Remove :
                    scenario.Contains("decrypt") ? FileProtectionOperation.Decrypt : FileProtectionOperation.Encrypt;
                return new(operation, operation == FileProtectionOperation.Decrypt ? "Contract.pdf.symmetric.p7m" : "Contract.pdf");
            }
#endif
            return null;
        }
    }
}
