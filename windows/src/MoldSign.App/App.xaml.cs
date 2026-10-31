using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;
using MoldSign.App.Tray;
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

    protected override async void OnLaunched(LaunchActivatedEventArgs args)
    {
#if DEBUG
        if (Environment.GetEnvironmentVariable("MSIGN_DEMO_PIN_ONLY") == "1")
        {
            _ = DebugBatchPinPreview.ShowAsync();
            return;
        }
#endif
        if (DemoMode.PreviewScenario is null)
        {
            _activation = new DesktopActivationBroker();
            if (!_activation.IsPrimary)
            {
                try { await _activation.OpenExistingAsync(CancellationToken.None); }
                catch (IOException error) { AppLog.Error(error); }
                catch (TimeoutException error) { AppLog.Error(error); }
                _activation.Dispose();
                Exit();
                return;
            }
            var activationUi = DispatcherQueue.GetForCurrentThread();
            _activation.Listen(() => activationUi.TryEnqueue(() => EnsureMainWindow(activate: true)));
        }
        // TODO(WIN-07): files passed by the Explorer verb "Semnează cu MoldSign" arrive here as arguments.
        AppLog.Stage("OnLaunched");
        var dispatcher = DispatcherQueue.GetForCurrentThread();
        Services = new AppServices(
            dispatcher,
            ownerWindow: () => _main is null ? 0 : WindowHelpers.Handle(_main),
            dependencies: new AppServiceDependencies
            {
                Readers = DemoMode.Scenario is { } demo ? new DemoReaderSource(demo) : null,
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
        if (!Services.IsDemo && Services.Settings.InsertionHelperEnabled) InsertionHelperRegistration.Start();

        if (Services.IsDemo || !Services.Settings.FirstRunDone || !StartupRegistration.LaunchedAtSignIn(args.Arguments))
        {
            // TODO(WIN-04): three-step first run (docs/10 §4.7); for now open the main window once.
            EnsureMainWindow(activate: true);
            if (Services.IsDemo)
            {
                if (Environment.GetEnvironmentVariable("MSIGN_DEMO_DARK") is "1" && _main?.Content is FrameworkElement root)
                    root.RequestedTheme = ElementTheme.Dark;
                var page = Environment.GetEnvironmentVariable("MSIGN_DEMO_PAGE") ?? "sign";
                void Prepare() => dispatcher.TryEnqueue(DispatcherQueuePriority.Low,
                    () => { _main?.ShowSection(page); _main?.PrepareDemoCapture(page); });
                if (_main?.Content is FrameworkElement content)
                {
                    if (content.IsLoaded) Prepare();
                    else content.Loaded += (_, _) => Prepare();
                }
            }
            else
            {
                Services.Settings.FirstRunDone = true;
                Services.Settings.Save();
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
                new AppServiceDependencies { Readers = enabled ? new DemoReaderSource("2") : null });
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
