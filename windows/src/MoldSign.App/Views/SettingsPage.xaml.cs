using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;
using MoldSign.Core;

namespace MoldSign.App.Views;

public sealed partial class SettingsPage : Page
{
    public SettingsPage()
    {
        InitializeComponent();
        var settings = App.Current.Services.Settings;
        StartAtLoginToggle.IsOn = settings.StartAtLogin;
        ToastsToggle.IsOn = settings.ReaderToasts;
        AllowedSitesText.Text = Loc.Format("Settings_AllowedSites", BridgeOriginPolicy.Default.Patterns.Count);
        VersionText.Text = $"MoldSign {typeof(App).Assembly.GetName().Version} · .NET {Environment.Version}";
    }

    public AppState State => AppState.Current;

    private async void OnBridgeToggled(object sender, RoutedEventArgs e)
    {
        if (BridgeToggle.IsOn == State.BridgeEnabled) return; // echo of the OneWay binding
        await App.Current.Services.SetBridgeEnabledAsync(BridgeToggle.IsOn);
    }

    private void OnToastsToggled(object sender, RoutedEventArgs e)
    {
        var settings = App.Current.Services.Settings;
        if (settings.ReaderToasts == ToastsToggle.IsOn) return;
        settings.ReaderToasts = ToastsToggle.IsOn;
        settings.Save();
    }
}
