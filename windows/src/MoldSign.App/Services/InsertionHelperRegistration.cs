using System.Diagnostics;
using Microsoft.Win32;
using Windows.ApplicationModel;

namespace MoldSign.App.Services;

/// <summary>Explicit per-user consent to an independent helper; never requires elevation or keeps the UI alive.</summary>
internal static class InsertionHelperRegistration
{
    internal const string TaskId = "MoldSignInsertionHelper";
    private const string RunKey = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private const string RunName = "MoldSignInsertionWatcher";
    internal static string HelperPath => Path.Combine(AppContext.BaseDirectory, "helper", "eSemnBun.Watcher.exe");

    internal static async Task<string> ConfigureAsync(AppSettings preferences)
    {
        if (DemoMode.Scenario is not null) return Loc.Get("Settings_HelperInstalled");
        if (!File.Exists(HelperPath)) return Loc.Get("Settings_HelperUnavailable");
        if (StartupRegistration.IsPackaged)
        {
            var task = await StartupTask.GetAsync(TaskId);
            if (!preferences.InsertionHelperEnabled) { task.Disable(); return ""; }
            var state = await task.RequestEnableAsync();
            if (state == StartupTaskState.DisabledByUser) return Loc.Get("Settings_StartupDisabledByUser");
            if (state == StartupTaskState.DisabledByPolicy) return Loc.Get("Settings_StartupPolicy");
        }
        else
        {
            using var key = Registry.CurrentUser.CreateSubKey(RunKey);
            if (preferences.InsertionHelperEnabled)
                key.SetValue(RunName, $"\"{HelperPath}\" --app \"{Environment.ProcessPath}\"", RegistryValueKind.String);
            else key.DeleteValue(RunName, throwOnMissingValue: false);
        }
        if (!preferences.InsertionHelperEnabled) return ""; // the helper observes persisted disable and exits itself
        Start();
        return Loc.Get(StartupRegistration.IsPackaged ? "Settings_HelperPackaged" : "Settings_HelperInstalled");
    }

    internal static async Task SuspendForDemoAsync()
    {
        foreach (var process in Process.GetProcessesByName("eSemnBun.Watcher"))
        {
            using (process)
            {
                try
                {
                    if (!string.Equals(process.MainModule?.FileName, HelperPath, StringComparison.OrdinalIgnoreCase)) continue;
                    process.Kill();
                    await process.WaitForExitAsync();
                }
                catch (Exception error) when (error is InvalidOperationException or System.ComponentModel.Win32Exception) { }
            }
        }
    }

    internal static void Start()
    {
        if (DemoMode.Scenario is not null || !File.Exists(HelperPath)) return;
        Process.Start(new ProcessStartInfo(HelperPath, $"--app \"{Environment.ProcessPath}\"") { UseShellExecute = false });
    }
}
