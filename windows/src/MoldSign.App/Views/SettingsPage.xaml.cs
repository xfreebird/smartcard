using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;
using MoldSign.Core;

namespace MoldSign.App.Views;

public sealed partial class SettingsPage : Page
{
    private async void OnCardDetailsClick(object sender, RoutedEventArgs e)
    {
        var dialog = new ContentDialog {
            XamlRoot = XamlRoot, RequestedTheme = ActualTheme, Title = Loc.Get("settings_card_reader"),
            Content = new CardPage { MaxHeight = 480 }, CloseButtonText = Loc.Get("saved_close")
        };
        await dialog.ShowAsync();
    }

    private bool _loadingStartup;
    private bool _loadingPreferences = true;

    public SettingsPage()
    {
        InitializeComponent();
        SigningHeading.Text = Loc.Get("settings_signing");
        DeleteAllPinsLabel.Text = Loc.Get("SettingsDeletePins/Content");
        NoSavedPins.Text = Loc.Get("ui_no_saved_pins");
        GeneralCategoryLabel.Text = Loc.Get("Settings_General");
        CardDetailsLabel.Text = Loc.Get("settings_card_reader");
        PinsCategoryLabel.Text = Loc.Get("SettingsPins/Text");
        BrowserCategoryLabel.Text = Loc.Get("BridgeLabel/Text");
        AdvancedCategoryLabel.Text = Loc.Get("SignAdvanced/Header");
        BrowserAdvanced.Header = AdvancedCategoryLabel.Text;
        AboutCategoryLabel.Text = Loc.Get("about_app_title");
        // WinUI's built-in state text follows the OS resources, which may differ from the app language.
        foreach (var toggle in new[] { DemoModeToggle, StartAtLoginToggle, ToastsToggle,
            OpenOnInsertionToggle, OpenOnReaderInsertionToggle, RememberPinToggle,
            BridgeToggle, BrowserStampsToggle, LegacyClientToggle, McpApprovalToggle, ExperimentalTokensToggle })
        {
            toggle.OnContent = Loc.Get("toggle_on");
            toggle.OffContent = Loc.Get("toggle_off");
        }
        ShowCategory(null);
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(SettingsBack, Loc.Get("SettingsPageTitle/Text"));
        var settings = App.Current.Services.Settings;
        DemoModeToggle.Header = Loc.Get("demo_mode_title");
        DemoModeToggle.IsOn = App.Current.Services.IsDemo;
        DemoModeToggle.IsEnabled = DemoMode.PreviewScenario is null;
        DemoModeDescription.Text = Loc.Get("demo_mode_description");
        RememberPinToggle.IsEnabled = !App.Current.Services.IsDemo;
        DeleteAllPinsButton.IsEnabled = !App.Current.Services.IsDemo;
        ToastsToggle.IsOn = settings.ReaderToasts;
        OpenOnInsertionToggle.IsOn = settings.OpenOnCardInsertion;
        OpenOnReaderInsertionToggle.IsOn = settings.OpenOnReaderInsertion;
        RememberPinToggle.IsOn = settings.RememberPin;
        LanguagePicker.SelectedIndex = settings.Language switch { "ro-RO" => 1, "en-US" => 2, "ru-RU" => 3, _ => 0 };
        ThemePicker.SelectedItem = ThemePicker.Items.OfType<ComboBoxItem>().FirstOrDefault(i => (string)i.Tag == settings.Theme);
        ExperimentalTokensToggle.Header = Loc.Get("Token_ExperimentalTitle");
        ExperimentalTokensDescription.Text = Loc.Get("Token_ExperimentalDetail");
        ExperimentalTokensToggle.IsOn = settings.ExperimentalTokensEnabled && !App.Current.Services.IsDemo;
        ExperimentalTokensToggle.IsEnabled = !App.Current.Services.IsDemo;
        McpApprovalToggle.Header = Loc.Get("MCP_Enabled");
        McpApprovalToggle.IsOn = settings.McpApprovalEnabled && !App.Current.Services.IsDemo;
        McpApprovalToggle.IsEnabled = !App.Current.Services.IsDemo;
        McpApprovalDescription.Text = Loc.Get("MCP_Description");
        McpApprovalDirectory.Text = McpApprovalBroker.DefaultDirectory;
        BrowserStampsToggle.Header = Loc.Get("Stamp_Browser");
        StampBatchHint.Text = Loc.Get("Stamp_BatchHint");
        BrowserStampsToggle.IsOn = settings.BrowserStampsEnabled;
        LegacyClientToggle.Header = Loc.Get("Legacy_ClientTitle");
        LegacyClientDescription.Text = Loc.Get("Legacy_ClientDescription");
        LegacyClientToggle.IsOn = settings.LegacyDesktopClientEnabled && !StartupRegistration.IsPackaged;
        LegacyClientToggle.Visibility = StartupRegistration.IsPackaged ? Visibility.Collapsed : Visibility.Visible;
        LegacyClientDescription.Visibility = LegacyClientToggle.Visibility;
        CheckUpdatesButton.Content = Loc.Get("Update_Check");
        CheckUpdatesButton.Visibility = App.Current.Services.Updates.Available ? Visibility.Visible : Visibility.Collapsed;
        _loadingPreferences = false;
        ShowSavedPins();
        Loaded += async (_, _) => ShowStartup(await StartupRegistration.GetAsync());
        AllowedSitesText.Text = Loc.Format("Settings_AllowedSites", BridgeOriginPolicy.Default.Patterns.Count);
        VersionText.Text = $"{AppInfo.ProductName} {typeof(App).Assembly.GetName().Version} · .NET {Environment.Version}";
        AboutLegalTitle.Text = Loc.Get("about_legal_title");
        AboutDisclaimerBody.Text = Loc.Get("about_disclaimer_body");
        var language = App.Current.Services.Settings.Language;
        if (string.IsNullOrEmpty(language)) language = System.Globalization.CultureInfo.CurrentUICulture.Name;
        var legalBase = "https://esemnbun.md" + (language.StartsWith("ro") ? "/ro" : language.StartsWith("ru") ? "/ru" : "");
        AboutTermsLink.Content = Loc.Get("about_terms");
        AboutTermsLink.NavigateUri = new Uri(legalBase + "/terms/");
        AboutPrivacyLink.Content = Loc.Get("about_privacy");
        AboutPrivacyLink.NavigateUri = new Uri(legalBase + "/privacy/");
        AboutDisclaimerLink.Content = Loc.Get("about_disclaimer");
        AboutDisclaimerLink.NavigateUri = new Uri(legalBase + "/terms/");
        AboutDeveloper.Text = $"{Loc.Get("about_developer")}: Nicolae Ghimbovschi";
        ResolveBridgeButton.Content = Loc.Get("Bridge_Resolve");
    }


    private async void OnCheckUpdatesClick(object sender, RoutedEventArgs e)
    {
        CheckUpdatesButton.IsEnabled = false;
        try { UpdateStatus.Text = await App.Current.Services.Updates.CheckAsync(automatic: false) ?? ""; }
        finally { CheckUpdatesButton.IsEnabled = true; }
    }

    private async void OnMcpApprovalToggled(object sender, RoutedEventArgs e)
    {
        if (_loadingPreferences) return;
        McpApprovalToggle.IsEnabled = false;
        try
        {
            var success = await App.Current.Services.SetMcpApprovalEnabledAsync(McpApprovalToggle.IsOn);
            McpApprovalStatus.Text = success ? "" : Loc.Get("MCP_Unavailable");
            _loadingPreferences = true;
            McpApprovalToggle.IsOn = App.Current.Services.Settings.McpApprovalEnabled;
            _loadingPreferences = false;
        }
        finally { McpApprovalToggle.IsEnabled = !App.Current.Services.IsDemo; }
    }

    private void OnExperimentalTokensToggled(object sender, RoutedEventArgs e)
    {
        if (_loadingPreferences) return;
        App.Current.Services.SetExperimentalTokens(ExperimentalTokensToggle.IsOn);
    }

    private void OnBrowserStampsToggled(object sender, RoutedEventArgs e)
    {
        if (_loadingPreferences) return;
        var settings = App.Current.Services.Settings;
        settings.BrowserStampsEnabled = BrowserStampsToggle.IsOn; settings.Save();
    }

    private void OnLegacyClientToggled(object sender, RoutedEventArgs e)
    {
        if (_loadingPreferences || StartupRegistration.IsPackaged) return;
        var services = App.Current.Services;
        services.Settings.LegacyDesktopClientEnabled = LegacyClientToggle.IsOn;
        services.Settings.Save();
        services.Bridge.AllowsLegacyDesktopClient = LegacyClientToggle.IsOn;
    }

    public AppState State => AppState.Current;

    private async void OnCategoryClick(object sender, RoutedEventArgs e)
    {
        var category = (sender as Button)?.Tag as string;
        if (category == "pins")
        {
            ShowSavedPins();
            await ShowDetailsAsync(PinsSection, PinsCategoryLabel.Text, "SettingsPinsDialog");
        }
        else if (category == "about") await ShowDetailsAsync(AboutContent, AboutCategoryLabel.Text, "SettingsAboutDialog");
        else ShowCategory(category);
    }

    private async Task ShowDetailsAsync(FrameworkElement content, string title, string automationId)
    {
        // Focused tasks return to the same Settings position when dismissed.
        var index = SectionHost.Children.IndexOf(content);
        SectionHost.Children.Remove(content);
        content.Visibility = Visibility.Visible;
        var previousWidth = content.Width;
        if (content == AboutContent) content.Width = Math.Max(200, Math.Min(480, XamlRoot.Size.Width - 96));
        var scroll = new ScrollViewer {
            Width = content.Width,
            Content = content, VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            HorizontalContentAlignment = HorizontalAlignment.Stretch, HorizontalScrollMode = ScrollMode.Disabled,
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
            MaxHeight = Math.Max(200, XamlRoot.Size.Height - 220)
        };
        var dialog = new ContentDialog {
            XamlRoot = XamlRoot, RequestedTheme = ActualTheme, Title = title, Content = scroll, CloseButtonText = Loc.Get("saved_close")
        };
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetAutomationId(dialog, automationId);
        try { await dialog.ShowAsync(); }
        finally
        {
            scroll.Content = null;
            content.Width = previousWidth;
            content.Visibility = Visibility.Collapsed;
            SectionHost.Children.Insert(index, content);
        }
    }
    private void OnSettingsBack(object sender, RoutedEventArgs e) => ShowCategory(null);

    private void ShowCategory(string? category)
    {
        SettingsRows.Visibility = category is null ? Visibility.Visible : Visibility.Collapsed;
        DemoCard.Visibility = SettingsRows.Visibility;
        SettingsBack.Visibility = category is null ? Visibility.Collapsed : Visibility.Visible;
        GeneralSection.Visibility = category == "general" ? Visibility.Visible : Visibility.Collapsed;
        PinsSection.Visibility = category == "pins" ? Visibility.Visible : Visibility.Collapsed;
        BrowserSection.Visibility = category == "browser" ? Visibility.Visible : Visibility.Collapsed;
        AdvancedSection.Visibility = category == "advanced" ? Visibility.Visible : Visibility.Collapsed;
        AboutContent.Visibility = category == "about" ? Visibility.Visible : Visibility.Collapsed;
        CategoryTitle.Text = category switch {
            "general" => GeneralCategoryLabel.Text, "pins" => PinsCategoryLabel.Text,
            "browser" => BrowserCategoryLabel.Text, "advanced" => AdvancedCategoryLabel.Text,
            "about" => AboutCategoryLabel.Text, _ => Loc.Get("SettingsPageTitle/Text")
        };
        SettingsScroll.UpdateLayout();
        SettingsScroll.ChangeView(null, 0, null, disableAnimation: true);
    }

    private async void OnDemoModeToggled(object sender, RoutedEventArgs args)
    {
        if (_loadingPreferences) return;
        var enabled = DemoModeToggle.IsOn;
        if (enabled)
        {
            var dialog = new ContentDialog
            {
                XamlRoot = XamlRoot, RequestedTheme = ActualTheme, Title = Loc.Get("demo_enable_title"), Content = Loc.Get("demo_mode_confirm"),
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

    private async void OnBridgeToggled(object sender, RoutedEventArgs e)
    {
        if (BridgeToggle.IsOn == State.BridgeEnabled) return; // echo of the OneWay binding
        await App.Current.Services.SetBridgeEnabledAsync(BridgeToggle.IsOn);
    }

    private async void OnResolveBridgeClick(object sender, RoutedEventArgs e)
    {
        if (App.Current.Services.IsDemo || XamlRoot is null) return;
        ResolveBridgeButton.IsEnabled = false;
        try
        {
            var owners = await PortConflictProcesses.FindAsync();
            if (owners.Count == 0)
            {
                await App.Current.Services.SetBridgeEnabledAsync(true);
                return;
            }
            var vendorOwners = owners.Where(PortConflictProcesses.IsVendor).ToArray();
            if (vendorOwners.Length == 0) { State.BridgeStatus = Loc.Get("Bridge_ResolveNone"); return; }
            var details = string.Join("\n", vendorOwners.Select(owner => $"{owner.Path} (PID {owner.Id})"));
            var dialog = new ContentDialog
            {
                XamlRoot = XamlRoot, RequestedTheme = ActualTheme, Title = Loc.Get("Bridge_ResolveTitle"),
                Content = new TextBlock { Text = $"{Loc.Get("Bridge_ResolveBody")}\n\n{details}", TextWrapping = TextWrapping.Wrap, IsTextSelectionEnabled = true },
                PrimaryButtonText = Loc.Get("Bridge_CloseAndRetry"), CloseButtonText = Loc.Get("Action_Cancel"),
                DefaultButton = ContentDialogButton.Close,
            };
            if (await dialog.ShowAsync() != ContentDialogResult.Primary) return;
            if (!await PortConflictProcesses.StopAsync(vendorOwners)) { State.BridgeStatus = Loc.Get("Bridge_ResolveFailed"); return; }
            await App.Current.Services.SetBridgeEnabledAsync(true);
        }
        catch (Exception error) { AppLog.Error(error); State.BridgeStatus = Loc.Get("Bridge_ResolveFailed"); }
        finally { ResolveBridgeButton.IsEnabled = true; }
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
        settings.StartAtLogin = mode is StartupMode.On or StartupMode.Managed or StartupMode.PolicyOn;
        settings.Save();
        ShowStartup(mode);
    }

    private void ShowStartup(StartupMode mode)
    {
        _loadingStartup = true;
        StartAtLoginToggle.IsOn = mode is StartupMode.On or StartupMode.Managed or StartupMode.PolicyOn;
        StartAtLoginToggle.IsEnabled = mode is StartupMode.On or StartupMode.Off;
        _loadingStartup = false;
        StartAtLoginNote.Text = mode switch
        {
            StartupMode.Managed => Loc.Get("Settings_StartupManaged"),
            StartupMode.PolicyOn or StartupMode.PolicyOff => Loc.Get("Settings_StartupPolicy"),
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
        DispatcherQueue.TryEnqueue(() => App.Current.ApplyLanguage());
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
        var keys = App.Current.Services.Pins.SavedCards();
        NoSavedPins.Visibility = keys.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
        DeleteAllPinsButton.IsEnabled = !App.Current.Services.IsDemo && keys.Count > 0;
        foreach (var key in keys)
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
