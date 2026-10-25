using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;
using MoldSign.Core;

namespace MoldSign.App.Views;

public sealed partial class SettingsPage : Page
{
    private bool _loadingStartup;

    public SettingsPage()
    {
        InitializeComponent();
        var settings = App.Current.Services.Settings;
        ToastsToggle.IsOn = settings.ReaderToasts;
        Loaded += async (_, _) => ShowStartup(await StartupRegistration.GetAsync());
        AllowedSitesText.Text = Loc.Format("Settings_AllowedSites", BridgeOriginPolicy.Default.Patterns.Count);
        VersionText.Text = $"{AppInfo.ProductName} {typeof(App).Assembly.GetName().Version} · .NET {Environment.Version}";
    }

    public AppState State => AppState.Current;

    private async void OnBridgeToggled(object sender, RoutedEventArgs e)
    {
        if (BridgeToggle.IsOn == State.BridgeEnabled) return; // echo of the OneWay binding
        await App.Current.Services.SetBridgeEnabledAsync(BridgeToggle.IsOn);
    }

    private async void OnStartAtLoginToggled(object sender, RoutedEventArgs e)
    {
        if (_loadingStartup) return;
        var mode = await StartupRegistration.SetAsync(StartAtLoginToggle.IsOn);
        var settings = App.Current.Services.Settings;
        settings.StartAtLogin = mode is StartupMode.On or StartupMode.Managed;
        settings.Save();
        ShowStartup(mode);
    }

    private void ShowStartup(StartupMode mode)
    {
        _loadingStartup = true;
        StartAtLoginToggle.IsOn = mode is StartupMode.On or StartupMode.Managed;
        StartAtLoginToggle.IsEnabled = mode is StartupMode.On or StartupMode.Off;
        _loadingStartup = false;
        StartAtLoginNote.Text = mode switch
        {
            StartupMode.Managed => Loc.Get("Settings_StartupManaged"),
            StartupMode.DisabledByUser => Loc.Get("Settings_StartupDisabledByUser"),
            _ => "",
        };
        StartAtLoginNote.Visibility = StartAtLoginNote.Text.Length > 0 ? Visibility.Visible : Visibility.Collapsed;
    }

    private void OnToastsToggled(object sender, RoutedEventArgs e)
    {
        var settings = App.Current.Services.Settings;
        if (settings.ReaderToasts == ToastsToggle.IsOn) return;
        settings.ReaderToasts = ToastsToggle.IsOn;
        settings.Save();
    }
}
