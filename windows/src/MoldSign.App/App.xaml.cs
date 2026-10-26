using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using MoldSign.App.Services;
using MoldSign.App.Tray;

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

    public App()
    {
        InitializeComponent();
        // Closing the last window must not end a tray app.
        DispatcherShutdownMode = DispatcherShutdownMode.OnExplicitShutdown;
        UnhandledException += (_, e) => AppLog.Error(e.Exception);
        AppDomain.CurrentDomain.UnhandledException += (_, e) =>
        {
            if (e.ExceptionObject is Exception error) AppLog.Error(error);
        };
    }

    public static new App Current => (App)Application.Current;

    public AppServices Services { get; private set; } = null!;

    public bool IsQuitting { get; private set; }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        // TODO(WIN-04): single instance (AppInstance.FindOrRegisterForKey + redirect) so a second launch opens the flyout.
        // TODO(WIN-07): files passed by the Explorer verb "Semnează cu MoldSign" arrive here as arguments.
        var dispatcher = DispatcherQueue.GetForCurrentThread();
        Services = new AppServices(
            dispatcher,
            dialogRoot: DialogRootAsync,
            ownerWindow: () => _main is null ? 0 : WindowHelpers.Handle(_main));

        _flyout = new TrayFlyoutWindow();
        _tray = new TrayIconService(ToggleFlyout, () => EnsureMainWindow(activate: true), Quit);
        _tray.Create();
        // Tray dot (docs/10 §0.2b): green with a card connected, gray otherwise; tooltip = the same in words.
        AppState.Current.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName is "" or null or nameof(AppState.Light) or nameof(AppState.LightLabel))
                _tray.Update(AppState.Current.TrayConnected, AppState.Current.TrayLabel);
        };
        _tray.Update(AppState.Current.TrayConnected, AppState.Current.TrayLabel);

        Services.Start();

        if (!Services.Settings.FirstRunDone && !StartupRegistration.LaunchedAtSignIn(args.Arguments))
        {
            // TODO(WIN-04): three-step first run (docs/10 §4.7); for now open the main window once.
            EnsureMainWindow(activate: true);
            Services.Settings.FirstRunDone = true;
            Services.Settings.Save();
        }
    }

    public MainWindow EnsureMainWindow(bool activate)
    {
        _main ??= new MainWindow();
        if (activate)
        {
            _main.AppWindow.Show();
            _main.Activate();
        }
        return _main;
    }

    /// <summary>XamlRoot for ContentDialogs: the main window, shown and loaded.</summary>
    private async Task<XamlRoot?> DialogRootAsync()
    {
        HideFlyout();
        var window = EnsureMainWindow(activate: true);
        if (window.Content is not FrameworkElement root) return null;
        if (root.XamlRoot is null)
        {
            var loaded = new TaskCompletionSource();
            root.Loaded += (_, _) => loaded.TrySetResult();
            await Task.WhenAny(loaded.Task, Task.Delay(TimeSpan.FromSeconds(3)));
        }
        return root.XamlRoot;
    }

    public void ToggleFlyout() => _flyout?.Toggle();

    public void HideFlyout() => _flyout?.HideFlyout();

    public async void Quit()
    {
        IsQuitting = true;
        _tray?.Dispose();
        await Services.DisposeAsync();
        _flyout?.Close();
        _main?.Close();
        Exit();
    }
}
