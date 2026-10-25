using System.Runtime.InteropServices;
using Microsoft.Win32;
using Windows.ApplicationModel;

namespace MoldSign.App.Services;

/// <summary>What the "Pornește la autentificare" toggle shows.</summary>
public enum StartupMode
{
    Off,
    On,
    /// <summary>MSI <c>STARTATLOGIN=1</c> (HKLM Run, all users) or an MSIX policy: on, not changeable here.</summary>
    Managed,
    /// <summary>MSIX: the user turned it off in Settings › Apps › Startup / Task Manager; only they can turn it back on.</summary>
    DisabledByUser,
}

/// <summary>
/// Start at sign-in (WIN-04). One API for both distributions:
/// <list type="bullet">
/// <item>MSIX: the <c>windows.startupTask</c> extension declared in Package.appxmanifest (TaskId <see cref="TaskId"/>);</item>
/// <item>unpackaged (MSI, portable): the per-user Run key; a machine-wide Run value written by the MSI
///       (<c>STARTATLOGIN=1</c>) is reported as <see cref="StartupMode.Managed"/>.</item>
/// </list>
/// </summary>
internal static partial class StartupRegistration
{
    /// <summary>Must match <c>uap5:StartupTask TaskId</c> in Package.appxmanifest.</summary>
    public const string TaskId = "MoldSignStartup";

    /// <summary>Run-key value name; must match the MSI's RegistryValue in installer/Package.wxs.</summary>
    public const string RunValueName = "MoldSign";

    /// <summary>Argument added to the Run command: start in the tray without opening the window.</summary>
    public const string AutostartArgument = "--autostart";

    private const string RunKey = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private const int AppModelErrorNoPackage = 15700;

    /// <summary>True when the process runs with package identity (MSIX).</summary>
    public static bool IsPackaged { get; } = DetectPackage();

    public static async Task<StartupMode> GetAsync()
    {
        if (IsPackaged)
        {
            var task = await StartupTask.GetAsync(TaskId);
            return Map(task.State);
        }
        if (MachineRunValue() is not null) return StartupMode.Managed;
        using var user = Registry.CurrentUser.OpenSubKey(RunKey);
        return user?.GetValue(RunValueName) is string ? StartupMode.On : StartupMode.Off;
    }

    /// <summary>Turns start-at-sign-in on or off; returns the resulting mode (MSIX may refuse).</summary>
    public static async Task<StartupMode> SetAsync(bool enabled)
    {
        if (IsPackaged)
        {
            var task = await StartupTask.GetAsync(TaskId);
            if (enabled) return Map(await task.RequestEnableAsync());
            task.Disable();
            return Map(task.State);
        }
        if (MachineRunValue() is not null) return StartupMode.Managed;
        using var user = Registry.CurrentUser.CreateSubKey(RunKey, writable: true);
        if (enabled)
            user.SetValue(RunValueName, $"\"{Environment.ProcessPath}\" {AutostartArgument}", RegistryValueKind.String);
        else
            user.DeleteValue(RunValueName, throwOnMissingValue: false);
        return enabled ? StartupMode.On : StartupMode.Off;
    }

    /// <summary>True when this process was started by the Run key / startup task (don't pop the window).</summary>
    public static bool LaunchedAtSignIn(string? arguments) =>
        Environment.GetCommandLineArgs().Contains(AutostartArgument, StringComparer.OrdinalIgnoreCase)
        || (arguments?.Contains(AutostartArgument, StringComparison.OrdinalIgnoreCase) ?? false);

    private static StartupMode Map(StartupTaskState state) => state switch
    {
        StartupTaskState.Enabled => StartupMode.On,
        StartupTaskState.EnabledByPolicy or StartupTaskState.DisabledByPolicy => StartupMode.Managed,
        StartupTaskState.DisabledByUser => StartupMode.DisabledByUser,
        _ => StartupMode.Off,
    };

    private static string? MachineRunValue()
    {
        using var machine = Registry.LocalMachine.OpenSubKey(RunKey);
        return machine?.GetValue(RunValueName) as string;
    }

    private static bool DetectPackage()
    {
        uint length = 0;
        return GetCurrentPackageFullName(ref length, null) != AppModelErrorNoPackage;
    }

    [LibraryImport("kernel32.dll", StringMarshalling = StringMarshalling.Utf16)]
    private static partial int GetCurrentPackageFullName(ref uint packageFullNameLength, [Out] char[]? packageFullName);
}
