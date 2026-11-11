using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;
using MoldSign.App.Tray;
using MoldSign.App.Views;
using MoldSign.Desktop;

namespace MoldSign.App;

/// <summary>
/// Tray-first app (WIN-04): the notification-area icon and its flyout live for the whole session; the main
/// window is created on demand and only hidden when closed. The process ends via "Ieșire" only.
/// </summary>
public partial class App : Application
{
    private TrayIconService? _tray;
    private TrayFlyoutWindow? _flyout;
    private MainWindow? _main;
    private DesktopActivationBroker? _activation;

    public App()
    {
        AppLog.Stage("App constructor");
        UnhandledException += (_, e) =>
        {
            AppLog.Error(e.Exception);
        };
        var settings = AppSettings.Load();
        if (!StartupRegistration.IsPackaged) DesktopJumpList.Initialize();
        DemoMode.Configure(settings.DemoModeEnabled);
        // MSIX persists overrides. Resolve System explicitly so a previous choice cannot remain active;
        // Windows App SDK versions that reject an empty override still receive a supported BCP-47 tag.
        var systemLanguage = Windows.System.UserProfile.GlobalizationPreferences.Languages
            .FirstOrDefault(tag => tag.StartsWith("ro", StringComparison.OrdinalIgnoreCase) ||
                tag.StartsWith("en", StringComparison.OrdinalIgnoreCase) || tag.StartsWith("ru", StringComparison.OrdinalIgnoreCase));
        var language = settings.Language is "ro-RO" or "en-US" or "ru-RU" ? settings.Language
            : systemLanguage?.StartsWith("en", StringComparison.OrdinalIgnoreCase) == true ? "en-US"
            : systemLanguage?.StartsWith("ru", StringComparison.OrdinalIgnoreCase) == true ? "ru-RU" : "ro-RO";
        Microsoft.Windows.Globalization.ApplicationLanguages.PrimaryLanguageOverride = language;
        AppLog.Stage("before application resources");
        InitializeComponent();
        AppLog.Stage("after application resources");
        // Closing the last window must not end a tray app.
        DispatcherShutdownMode = DispatcherShutdownMode.OnExplicitShutdown;
        AppDomain.CurrentDomain.UnhandledException += (_, e) =>
        {
            if (e.ExceptionObject is Exception error) AppLog.Error(error);
        };
    }

    public static new App Current => (App)Application.Current;

    public AppServices Services { get; private set; } = null!;

    public bool IsQuitting { get; private set; }
    internal bool IsRebuildingWindows { get; private set; }

    public void ApplyLanguage()
    {
        var selected = Services.Settings.Language;
        var system = Windows.System.UserProfile.GlobalizationPreferences.Languages
            .FirstOrDefault(tag => tag.StartsWith("ro", StringComparison.OrdinalIgnoreCase) ||
                tag.StartsWith("en", StringComparison.OrdinalIgnoreCase) || tag.StartsWith("ru", StringComparison.OrdinalIgnoreCase));
        var language = selected is "ro-RO" or "en-US" or "ru-RU" ? selected
            : system?.StartsWith("en", StringComparison.OrdinalIgnoreCase) == true ? "en-US"
            : system?.StartsWith("ru", StringComparison.OrdinalIgnoreCase) == true ? "ru-RU" : "ro-RO";
        Microsoft.Windows.Globalization.ApplicationLanguages.PrimaryLanguageOverride = language;
        Loc.Reload();
        AppState.Current.RefreshLanguage();
        _ = TaskbarActions.RefreshAsync();
        IsRebuildingWindows = true;
        try
        {
            var position = _main?.AppWindow.Position;
            var size = _main?.AppWindow.Size;
            _flyout?.Close();
            _main?.Close();
            _flyout = new TrayFlyoutWindow();
            _main = new MainWindow();
            ApplyTheme();
            if (position is { } oldPosition) _main.AppWindow.Move(oldPosition);
            if (size is { } oldSize) _main.AppWindow.Resize(oldSize);
            if (_main.Content is FrameworkElement root)
                root.Loaded += (_, _) => _main?.ShowSection("settings");
            _main.AppWindow.Show();
            _main.Activate();
        }
        finally { IsRebuildingWindows = false; }
    }

    protected override async void OnLaunched(LaunchActivatedEventArgs args)
    {
        var launchArguments = Environment.GetCommandLineArgs();
        if (launchArguments.Length > 2 && launchArguments[1] == "--open-document")
        {
            try
            {
                if (File.Exists(launchArguments[2]))
                    System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(launchArguments[2]) { UseShellExecute = true });
            }
            catch (Exception error) { AppLog.Error(error); }
            Exit();
            return;
        }
        var action = launchArguments.Length > 1 && launchArguments[1] == "--verify" ? "verify" : "sign";
        var documentPaths = launchArguments.Length > 2 && launchArguments[1] is "--sign" or "--verify"
            ? launchArguments.Skip(2).Where(File.Exists).ToArray() : Array.Empty<string>();
#if DEBUG
        if (Environment.GetEnvironmentVariable("MSIGN_DEMO_PIN_ONLY") == "1")
        {
            _ = DebugBatchPinPreview.ShowAsync();
            return;
        }
#endif
        if (DemoMode.PreviewScenario is null)
        {
            // An isolated Debug profile must not activate an already-running installed app.
            _activation = new DesktopActivationBroker(AppSettings.IsolatedTestPreferences ? "MoldSign-QA" : "MoldSign");
            if (!_activation.IsPrimary)
            {
                try
                {
                    if (documentPaths.Length > 0 || launchArguments.Skip(1).Any(a => a is "--sign" or "--verify"))
                        await _activation.OpenCommandAsync(action, documentPaths, CancellationToken.None);
                    else await _activation.OpenExistingAsync(CancellationToken.None);
                }
                catch (IOException error) { AppLog.Error(error); }
                catch (TimeoutException error) { AppLog.Error(error); }
                _activation.Dispose();
                Exit();
                return;
            }
            var activationUi = DispatcherQueue.GetForCurrentThread();
            _activation.ListenCommands((command, paths) => activationUi.TryEnqueue(async () =>
            {
                var window = EnsureMainWindow(activate: true);
                if (command == "verify")
                {
                    if (paths.Count > 0) await window.VerifyFilesAsync(paths.Where(File.Exists).ToArray());
                    else window.ShowSection("verify");
                }
                else if (paths.Count > 0) window.QueueSignFiles(paths.Where(File.Exists).ToArray());
                else if (command == "sign") window.ShowSection("sign");
            }));
        }
        AppLog.Stage("OnLaunched");
        var dispatcher = DispatcherQueue.GetForCurrentThread();
        Services = new AppServices(
            dispatcher,
            ownerWindow: () => _main is null ? 0 : WindowHelpers.Handle(_main),
            dependencies: new AppServiceDependencies
            {
                DemoScenario = DemoMode.Scenario,
            });

        AppLog.Stage("before tray flyout");
        _flyout = new TrayFlyoutWindow();
        AppLog.Stage("after tray flyout");
        ApplyTheme();
        _tray = new TrayIconService(ToggleFlyout, () => EnsureMainWindow(activate: true), Quit);
        _tray.Create();
        AppLog.Stage("tray created");
        // Tray dot (docs/10 §0.2b): green with a card connected, gray otherwise; tooltip = the same in words.
        AppState.Current.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName is "" or null or nameof(AppState.Light) or nameof(AppState.LightLabel))
                _tray.Update(AppState.Current.TrayConnected, AppState.Current.TrayLabel);
        };
        _tray.Update(AppState.Current.TrayConnected, AppState.Current.TrayLabel);

        Services.CardInserted += (_, _) => EnsureMainWindow(activate: true);
        Services.Start();
        _ = TaskbarActions.RefreshAsync();
        if (!Services.IsDemo && Services.Settings.InsertionHelperEnabled) InsertionHelperRegistration.Start();

        if (Services.IsDemo || !Services.Settings.FirstRunDone || !StartupRegistration.LaunchedAtSignIn(args.Arguments))
        {
            // First run (WIN-04, docs/10 §4.7): open the main window once and show the onboarding.
            EnsureMainWindow(activate: true);
            if (action == "verify")
            {
                if (documentPaths.Length > 0 && _main is not null) await _main.VerifyFilesAsync(documentPaths);
                else _main?.ShowSection("verify");
            }
            else if (documentPaths.Length > 0) _main?.QueueSignFiles(documentPaths);
            if (Services.IsDemo)
            {
                if (Environment.GetEnvironmentVariable("MSIGN_DEMO_DARK") is "1" && _main?.Content is FrameworkElement root)
                    root.RequestedTheme = ElementTheme.Dark;
                var page = Environment.GetEnvironmentVariable("MSIGN_DEMO_PAGE") ?? action;
                void Prepare() => dispatcher.TryEnqueue(DispatcherQueuePriority.Low,
                    () =>
                    {
                        _main?.ShowSection(page);
                        _main?.PrepareDemoCapture(page);
#if DEBUG
                        if (DemoMode.ScreenshotCapture && AppSettings.IsolatedTestPreferences &&
                            Environment.GetEnvironmentVariable("MSIGN_QA_ONBOARDING") == "1")
                            dispatcher.TryEnqueue(async () =>
                            {
                                if (_main is null) return;
                                try { await OnboardingDialog.ShowAsync(_main); }
                                catch (Exception error) { AppLog.Error(error); }
                            });
#endif
                    });
                if (_main?.Content is FrameworkElement content)
                {
                    if (content.IsLoaded) Prepare();
                    else content.Loaded += (_, _) => Prepare();
                }
            }
            else
            {
                // First run (WIN-04, docs/10 §4.7): launch-preferences onboarding over the main window.
                // The dialog applies the toggles live and persists FirstRunDone when it closes in any way.
                if (!Services.Settings.FirstRunDone)
                {
                    if (_main is not null)
                    {
                        try { await OnboardingDialog.ShowAsync(_main); }
                        catch (Exception error) { AppLog.Error(error); }
                    }
                }
            }
        }
    }

    public MainWindow EnsureMainWindow(bool activate)
    {
        AppLog.Stage("before main window");
        _main ??= new MainWindow();
        AppLog.Stage("after main window");
        ApplyTheme();
        if (activate)
        {
            _main.AppWindow.Show();
            _main.Activate();
        }
        return _main;
    }

    private bool _switchingDemo;
    public async Task<bool> SetDemoModeAsync(bool enabled)
    {
        if (_switchingDemo || Services.IsOperationActive || DemoMode.PreviewScenario is not null) return false;
        if (Services.Settings.DemoModeEnabled == enabled) return true;
        _switchingDemo = true;
        try
        {
            var settings = Services.Settings;
            settings.DemoModeEnabled = enabled;
            settings.Save();
            // The independent helper observes the flag before its next hardware read.
            if (enabled) await InsertionHelperRegistration.SuspendForDemoAsync();
            await Services.DisposeAsync();
            DemoMode.Configure(enabled);
            Services = new AppServices(DispatcherQueue.GetForCurrentThread(),
                () => _main is null ? 0 : WindowHelpers.Handle(_main),
                new AppServiceDependencies { DemoScenario = enabled ? "2" : null });
            Services.CardInserted += (_, _) => EnsureMainWindow(activate: true);
            Services.Start();
            _main?.ResetForServices();
            if (!enabled)
            {
                if (Services.Settings.InsertionHelperEnabled) InsertionHelperRegistration.Start();
                EnsureMainWindow(activate: true);
            }
            return true;
        }
        finally { _switchingDemo = false; }
    }

    public void ApplyTheme()
    {
        var theme = Services.Settings.Theme switch
        {
            "light" => ElementTheme.Light,
            "dark" => ElementTheme.Dark,
            _ => ElementTheme.Default,
        };
        if (_main?.Content is FrameworkElement main) main.RequestedTheme = theme;
        if (_flyout?.Content is FrameworkElement flyout) flyout.RequestedTheme = theme;
    }

    public void ToggleFlyout() => _flyout?.Toggle();

    public void HideFlyout() => _flyout?.HideFlyout();

    public async void Quit()
    {
        IsQuitting = true;
        _tray?.Dispose();
        _activation?.Dispose();
        await Services.DisposeAsync();
        _flyout?.Close();
        _main?.Close();
        Exit();
    }
}
