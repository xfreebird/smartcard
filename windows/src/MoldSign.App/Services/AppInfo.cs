namespace MoldSign.App.Services;

/// <summary>
/// Public product name (docs/10 §0.2b, UX-12): what users see in window titles, the tray tooltip, About, installers.
/// The codename MoldSign stays in code (namespaces, IDs, %LOCALAPPDATA%\MoldSign, credential names, MSIGN_PIN), and
/// vendor references stay "MoldSign" (the STISC Java suite, the bridge protocol).
/// </summary>
internal static class AppInfo
{
    public const string ProductName = "eSemnBun";

    /// <summary>The CLI command (installed as bin\esemnbun.exe: it differs from eSemnBun.exe only by case).</summary>
    public const string CliName = "esemnbun";
}
