using MoldSign.Desktop;

namespace MoldSign.App.Services;

internal sealed record ProtectionPreview(FileProtectionOperation Operation, string Filename, bool Recipient = false)
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
                var recipient = scenario.Contains("certificate");
                return new(operation, operation == FileProtectionOperation.Decrypt ?
                    (recipient ? "Contract.pdf.asymmetric.p7m" : "Contract.pdf.symmetric.p7m") : "Contract.pdf", recipient);
            }
#endif
            return null;
        }
    }
}
