using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;
using MoldSign.Core;

namespace MoldSign.App.Views;

public sealed partial class SettingsPage : Page
{
    private bool _loadingStartup;
    private bool _loadingPreferences = true;

    public SettingsPage()
    {
        InitializeComponent();
        var settings = App.Current.Services.Settings;
        DemoModeToggle.Header = Loc.Get("demo_mode_title");
        DemoModeToggle.IsOn = App.Current.Services.IsDemo;
        DemoModeToggle.IsEnabled = DemoMode.PreviewScenario is null;
        DemoModeDescription.Text = Loc.Get("demo_mode_description");
        RememberPinToggle.IsEnabled = !App.Current.Services.IsDemo;
        DeleteAllPinsButton.IsEnabled = !App.Current.Services.IsDemo;
        MonitoringTitle.Text = Loc.Get("monitoring_title");
        MonitoringHint.Text = Loc.Get(App.Current.Services.IsDemo ? "demo_monitoring_paused" : "monitoring_settings_hint");
        MonitoringCrashToggle.Header = Loc.Get("monitoring_crash");
        MonitoringMetricsToggle.Header = Loc.Get("monitoring_metrics");
        MonitoringCrashToggle.IsOn = App.Current.Monitoring.Consent.CanSendCrash;
        MonitoringMetricsToggle.IsOn = App.Current.Monitoring.Consent.CanSendMetrics;
        ToastsToggle.IsOn = settings.ReaderToasts;
        OpenOnInsertionToggle.IsOn = settings.OpenOnCardInsertion;
        OpenOnReaderInsertionToggle.IsOn = settings.OpenOnReaderInsertion;
        RememberPinToggle.IsOn = settings.RememberPin;
        LanguagePicker.SelectedIndex = settings.Language switch { "ro-RO" => 1, "en-US" => 2, "ru-RU" => 3, _ => 0 };
        ThemePicker.SelectedItem = ThemePicker.Items.OfType<ComboBoxItem>().FirstOrDefault(i => (string)i.Tag == settings.Theme);
        _loadingPreferences = false;
        ShowSavedPins();
        Loaded += async (_, _) => ShowStartup(await StartupRegistration.GetAsync());
        AllowedSitesText.Text = Loc.Format("Settings_AllowedSites", BridgeOriginPolicy.Default.Patterns.Count);
        VersionText.Text = $"{AppInfo.ProductName} {typeof(App).Assembly.GetName().Version} · .NET {Environment.Version}";
        AboutTitle.Text = Loc.Get("about_app_title");
        AboutDeveloper.Text = $"{Loc.Get("about_developer")}: Nicolae Ghimbovschi";
    }

    public AppState State => AppState.Current;

    private async void OnDemoModeToggled(object sender, RoutedEventArgs args)
    {
        if (_loadingPreferences) return;
        var enabled = DemoModeToggle.IsOn;
        if (enabled)
        {
            var dialog = new ContentDialog
            {
                XamlRoot = XamlRoot, Title = Loc.Get("demo_enable_title"), Content = Loc.Get("demo_mode_confirm"),
                PrimaryButtonText = Loc.Get("demo_mode_enable"), CloseButtonText = Loc.Get("Action_Cancel"),
                DefaultButton = ContentDialogButton.Close,
            };
            Microsoft.UI.Xaml.Automation.AutomationProperties.SetAutomationId(dialog, "DemoModeConfirmation");
            if (await dialog.ShowAsync() != ContentDialogResult.Primary) { RestoreDemoToggle(); return; }
        }
        try
        {
            if (!await App.Current.SetDemoModeAsync(enabled))
            {
                DemoModeStatus.Text = Loc.Get("demo_switch_busy"); RestoreDemoToggle();
            }
        }
        catch (Exception error) { AppLog.Error(error); DemoModeStatus.Text = Loc.Get("Error_Generic"); RestoreDemoToggle(); }
    }
    private void RestoreDemoToggle()
    {
        _loadingPreferences = true;
        DemoModeToggle.IsOn = App.Current.Services.IsDemo;
        _loadingPreferences = false;
    }

    private void OnMonitoringToggled(object sender, RoutedEventArgs e)
    {
        if (_loadingPreferences) return;
        App.Current.Monitoring.Apply(MonitoringCrashToggle.IsOn, MonitoringMetricsToggle.IsOn);
    }

    private async void OnBridgeToggled(object sender, RoutedEventArgs e)
    {
        if (BridgeToggle.IsOn == State.BridgeEnabled) return; // echo of the OneWay binding
        await App.Current.Services.SetBridgeEnabledAsync(BridgeToggle.IsOn);
    }

    private async void OnImportIdentityClick(object sender, RoutedEventArgs e)
    {
        try
        {
            if (XamlRoot is null) return;
            var paths = await WindowHelpers.PickFilesAsync(XamlRoot, ".p12", ".pfx");
            if (paths.Count > 0) await App.Current.Services.ImportBridgeIdentityAsync(paths[0]);
        }
        catch (Exception error)
        {
            AppLog.Error(error);
            State.BridgeStatus = Loc.Format("Error_FileSelection", error.Message);
        }
    }

    private async void OnStartAtLoginToggled(object sender, RoutedEventArgs e)
    {
        if (_loadingStartup || _loadingPreferences || App.Current.Services.IsDemo) return;
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
    private async void OnOpenOnInsertionToggled(object sender, RoutedEventArgs e)
    {
        if (_loadingPreferences) return;
        App.Current.Services.Settings.OpenOnCardInsertion = OpenOnInsertionToggle.IsOn;
        App.Current.Services.Settings.Save();
        await ConfigureInsertionHelperAsync();
    }

    private async void OnOpenOnReaderInsertionToggled(object sender, RoutedEventArgs e)
    {
        if (_loadingPreferences) return;
        App.Current.Services.Settings.OpenOnReaderInsertion = OpenOnReaderInsertionToggle.IsOn;
        App.Current.Services.Settings.Save();
        await ConfigureInsertionHelperAsync();
    }

    private async Task ConfigureInsertionHelperAsync()
    {
        try { InsertionHelperStatus.Text = await InsertionHelperRegistration.ConfigureAsync(App.Current.Services.Settings); }
        catch (Exception error) { AppLog.Error(error); InsertionHelperStatus.Text = Loc.Get("Error_Generic"); }
    }

    private void OnLanguageChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loadingPreferences || LanguagePicker.SelectedItem is not ComboBoxItem item) return;
        App.Current.Services.Settings.Language = item.Tag as string ?? "";
        App.Current.Services.Settings.Save();
    }

    private void OnThemeChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loadingPreferences || ThemePicker.SelectedItem is not ComboBoxItem item) return;
        App.Current.Services.Settings.Theme = (string)item.Tag;
        App.Current.Services.Settings.Save();
        App.Current.ApplyTheme();
    }

    private void OnRememberPinToggled(object sender, RoutedEventArgs e)
    {
        if (_loadingPreferences || App.Current.Services.IsDemo) return;
        App.Current.Services.Settings.RememberPin = RememberPinToggle.IsOn;
        App.Current.Services.Settings.Save();
    }

    private void OnDeletePinsClick(object sender, RoutedEventArgs e)
    {
        if (App.Current.Services.IsDemo) return;
        App.Current.Services.Pins.DeleteAll();
        PinsStatus.Text = Loc.Get("Settings_PinsDeleted");
        ShowSavedPins();
    }

    private void ShowSavedPins()
    {
        SavedPinsList.Children.Clear();
        foreach (var key in App.Current.Services.Pins.SavedCards())
        {
            var holder = State.WalletItems.FirstOrDefault(card => card.Certificate?.Sha1 == key)?.Holder;
            var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 12 };
            row.Children.Add(new TextBlock { Text = holder ?? key, VerticalAlignment = VerticalAlignment.Center,
                MaxWidth = 420, TextTrimming = TextTrimming.CharacterEllipsis });
            var remove = new Button { Content = new FontIcon { Glyph = "\uE74D", FontSize = 16 } };
            Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(remove, Loc.Get("Action_ForgetPin"));
            remove.Click += (_, _) => { App.Current.Services.Pins.Delete(key); ShowSavedPins(); };
            row.Children.Add(remove);
            SavedPinsList.Children.Add(row);
        }
    }

}
