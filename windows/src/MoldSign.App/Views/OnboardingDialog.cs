using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media.Imaging;
using MoldSign.App.Services;

namespace MoldSign.App.Views;

/// <summary>
/// First-run onboarding (WIN-04, docs/10 §4.7): welcome plus how eSemnBun stays available — start at
/// sign-in and the separate reader/card-insertion helper. The toggles apply immediately (the same
/// APIs as Settings › General); dismissal persists FirstRunDone.
/// </summary>
internal sealed class OnboardingDialog : ContentDialog
{
    private readonly ToggleSwitch _startAtLogin = new();
    private readonly ToggleSwitch _openOnInsertion = new();
    private readonly TextBlock _status = new();
    private readonly TextBlock _startupStatus = new();
    private bool _loading = true;

    private OnboardingDialog()
    {
        var caption = (Style)Application.Current.Resources["MsCaptionTextStyle"];
        PrimaryButtonText = Loc.Get("Onboarding_GetStarted");
        DefaultButton = ContentDialogButton.Primary;

        var content = new StackPanel { Spacing = 16, MaxWidth = 460 };
        var hero = new Grid { ColumnSpacing = 16 };
        hero.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        hero.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        hero.Children.Add(new Image
        {
            Source = new BitmapImage(new Uri("ms-appx:///Assets/Square150x150Logo.scale-200.png")),
            Width = 52, Height = 52, VerticalAlignment = VerticalAlignment.Top,
        });
        var introduction = new StackPanel { Spacing = 4 };
        introduction.Children.Add(new TextBlock
        {
            Text = Loc.Get("Onboarding_Title"), Style = (Style)Application.Current.Resources["MsTitleTextStyle"],
            TextWrapping = TextWrapping.Wrap, TextTrimming = TextTrimming.None,
        });
        introduction.Children.Add(new TextBlock
        {
            Text = Loc.Get("Onboarding_Body"), Style = caption,
            TextWrapping = TextWrapping.Wrap, TextTrimming = TextTrimming.None,
        });
        Grid.SetColumn(introduction, 1);
        hero.Children.Add(introduction);
        content.Children.Add(hero);
        content.Children.Add(new TextBlock
        {
            Text = Loc.Get("Onboarding_Choices"), Style = (Style)Application.Current.Resources["MsHeadlineTextStyle"],
            TextWrapping = TextWrapping.Wrap, TextTrimming = TextTrimming.None,
        });
        var choices = new StackPanel { Spacing = 8 };
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetAutomationId(_startAtLogin, "OnboardingStartAtLogin");
        _startAtLogin.Toggled += OnStartAtLoginToggled;
        _startupStatus.Style = caption;
        _startupStatus.TextWrapping = TextWrapping.Wrap;
        _startupStatus.TextTrimming = TextTrimming.None;
        _startupStatus.Visibility = Visibility.Collapsed;
        choices.Children.Add(OptionCard(Loc.Get("Onboarding_StartAtLogin"), Loc.Get("Onboarding_StartupDetail"), _startAtLogin, _startupStatus));
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetAutomationId(_openOnInsertion, "OnboardingOpenOnInsertion");
        _openOnInsertion.Toggled += OnOpenOnInsertionToggled;
        _status.Style = caption;
        _status.TextWrapping = TextWrapping.Wrap;
        _status.TextTrimming = TextTrimming.None;
        _status.Visibility = Visibility.Collapsed;
        choices.Children.Add(OptionCard(Loc.Get("Onboarding_OpenOnInsertion"), Loc.Get("Onboarding_HelperNote"), _openOnInsertion, _status));
        content.Children.Add(choices);
        var changeLater = new TextBlock { Text = Loc.Get("Onboarding_ChangeLater"), TextWrapping = TextWrapping.Wrap, TextTrimming = TextTrimming.None };
        changeLater.Style = caption;
        content.Children.Add(changeLater);
        Content = content;
    }

    private static Border OptionCard(string label, string detail, ToggleSwitch toggle, TextBlock status)
    {
        var row = new Grid { ColumnSpacing = 12 };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        var text = new StackPanel { Spacing = 4, VerticalAlignment = VerticalAlignment.Center };
        text.Children.Add(new TextBlock
        {
            Text = label, Style = (Style)Application.Current.Resources["MsHeadlineTextStyle"],
            TextWrapping = TextWrapping.Wrap, TextTrimming = TextTrimming.None,
        });
        text.Children.Add(new TextBlock
        {
            Text = detail, Style = (Style)Application.Current.Resources["MsCaptionTextStyle"],
            TextWrapping = TextWrapping.Wrap, TextTrimming = TextTrimming.None,
        });
        text.Children.Add(status);
        toggle.OnContent = "";
        toggle.OffContent = "";
        toggle.MinWidth = 0;
        toggle.HorizontalAlignment = HorizontalAlignment.Right;
        toggle.VerticalAlignment = VerticalAlignment.Center;
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetName(toggle, label);
        Grid.SetColumn(toggle, 1);
        row.Children.Add(text);
        row.Children.Add(toggle);
        return new Border { Style = (Style)Application.Current.Resources["MsCardBorderStyle"], Child = row };
    }

    private static void SetStatus(TextBlock target, string text)
    {
        target.Text = text;
        target.Visibility = string.IsNullOrEmpty(text) ? Visibility.Collapsed : Visibility.Visible;
    }

    private static string StartupStatus(StartupMode mode) => mode switch
    {
        StartupMode.DisabledByUser => Loc.Get("Settings_StartupDisabledByUser"),
        StartupMode.Managed => Loc.Get("Settings_StartupManaged"),
        StartupMode.PolicyOn or StartupMode.PolicyOff => Loc.Get("Settings_StartupPolicy"),
        _ => "",
    };

    /// <summary>Presents the dialog over the main window once its content is loaded, then persists completion.</summary>
    public static async Task ShowAsync(MainWindow window)
    {
        if (window.Content is not FrameworkElement root) return;
        if (root.XamlRoot is null)
        {
            var loaded = new TaskCompletionSource();
            void Loaded(object? sender, RoutedEventArgs args) => loaded.TrySetResult();
            root.Loaded += Loaded;
            try { if (root.XamlRoot is null) await loaded.Task.WaitAsync(TimeSpan.FromSeconds(10)); }
            finally { root.Loaded -= Loaded; }
        }
        var settings = App.Current.Services.Settings;
        // ContentDialog is hosted in a popup, so explicitly follow the window's selected theme.
        var dialog = new OnboardingDialog { XamlRoot = root.XamlRoot, RequestedTheme = root.ActualTheme };
        var mode = await StartupRegistration.GetAsync();
        dialog._startAtLogin.IsOn = mode is StartupMode.On or StartupMode.Managed or StartupMode.PolicyOn;
        dialog._startAtLogin.IsEnabled = mode is StartupMode.On or StartupMode.Off;
        SetStatus(dialog._startupStatus, StartupStatus(mode));
        dialog._openOnInsertion.IsOn = settings.OpenOnCardInsertion || settings.OpenOnReaderInsertion;
        dialog._loading = false;
        await dialog.ShowAsync();
        settings.FirstRunDone = true;
        settings.Save();
    }

    private async void OnStartAtLoginToggled(object sender, RoutedEventArgs e)
    {
        if (_loading) return;
        _startAtLogin.IsEnabled = false;
        _openOnInsertion.IsEnabled = false;
        IsPrimaryButtonEnabled = false;
        StartupMode mode;
        var failed = false;
        try { mode = await StartupRegistration.SetAsync(_startAtLogin.IsOn); }
        catch (Exception error)
        {
            AppLog.Error(error);
            failed = true;
            mode = App.Current.Services.Settings.StartAtLogin ? StartupMode.On : StartupMode.Off;
        }
        finally { _openOnInsertion.IsEnabled = true; IsPrimaryButtonEnabled = true; }
        var settings = App.Current.Services.Settings;
        settings.StartAtLogin = mode is StartupMode.On or StartupMode.Managed or StartupMode.PolicyOn;
        settings.Save();
        _loading = true;
        _startAtLogin.IsOn = mode is StartupMode.On or StartupMode.Managed or StartupMode.PolicyOn;
        _startAtLogin.IsEnabled = mode is StartupMode.On or StartupMode.Off;
        _loading = false;
        SetStatus(_startupStatus, failed ? Loc.Get("Error_Generic") : StartupStatus(mode));
    }

    private async void OnOpenOnInsertionToggled(object sender, RoutedEventArgs e)
    {
        if (_loading) return;
        var settings = App.Current.Services.Settings;
        settings.OpenOnCardInsertion = _openOnInsertion.IsOn;
        settings.OpenOnReaderInsertion = _openOnInsertion.IsOn;
        settings.Save();
        _openOnInsertion.IsEnabled = false;
        var startupWasEnabled = _startAtLogin.IsEnabled;
        _startAtLogin.IsEnabled = false;
        IsPrimaryButtonEnabled = false;
        try { SetStatus(_status, await InsertionHelperRegistration.ConfigureAsync(settings)); }
        catch (Exception error) { AppLog.Error(error); SetStatus(_status, Loc.Get("Error_Generic")); }
        finally
        {
            _openOnInsertion.IsEnabled = true;
            _startAtLogin.IsEnabled = startupWasEnabled;
            IsPrimaryButtonEnabled = true;
        }
    }
}
