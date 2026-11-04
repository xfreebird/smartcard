using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;

namespace MoldSign.App.Tray;

/// <summary>
/// Borderless always-on-top window next to the notification area; hides when it loses focus. Mirrors the macOS
/// popover: card on top, Sign/Verify, recent documents, browser connection, window/quit rows. Every action that opens
/// something (a picker, Explorer, the main window) hides the flyout first; a signing/verification result reopens it.
/// </summary>
public sealed partial class TrayFlyoutWindow : Window
{
    private DateTime _hiddenByDeactivationAt;

    public TrayFlyoutWindow()
    {
        InitializeComponent();
        WindowHelpers.MakeFlyout(this);
        WindowHelpers.ApplyAcrylic(this);
        Activated += OnActivated;
        AppWindow.Closing += OnClosing;
        Wallet.CardActivated += (_, _) =>
        {
            HideFlyout();
            App.Current.EnsureMainWindow(activate: true).ShowSection("card");
        };
        // The card list expands in place (docs/10 §0.2b): the flyout grows and stays anchored above the taskbar.
        Wallet.ExpandedChanged += (_, _) =>
        {
            if (AppWindow.IsVisible) WindowHelpers.PlaceNearTray(this, Wallet.ExpandedExtraHeight);
        };
        State.PropertyChanged += OnStatePropertyChanged;
        Closed += (_, _) => State.PropertyChanged -= OnStatePropertyChanged;
        UpdateSignButton();
    }

    public AppState State => AppState.Current;

    private void OnStatePropertyChanged(object? sender, System.ComponentModel.PropertyChangedEventArgs e) => UpdateSignButton();

    public void Toggle()
    {
        // A click on the tray icon first deactivates (hides) the flyout; don't reopen it on that same click.
        if (AppWindow.IsVisible) HideFlyout();
        else if (DateTime.UtcNow - _hiddenByDeactivationAt > TimeSpan.FromMilliseconds(300)) ShowFlyout();
    }

    public void ShowFlyout()
    {
        State.PruneMissingFiles(); // recents only list documents that still exist
        // Beyond what fits above the taskbar, the expanded card list scrolls inside the flyout.
        Wallet.MaxExpandedHeight = Math.Max(Wallet.CollapsedHeight,
            WindowHelpers.MaxFlyoutHeight(this) - (WindowHelpers.FlyoutHeight - Wallet.CollapsedHeight));
        WindowHelpers.PlaceNearTray(this, Wallet.ExpandedExtraHeight);
        AppWindow.Show();
        Activate();
    }

    public void HideFlyout()
    {
        AppWindow.Hide();
        Wallet.Collapse(); // reopen on the selected card
    }

    private void OnActivated(object sender, WindowActivatedEventArgs args)
    {
        if (args.WindowActivationState != WindowActivationState.Deactivated || !AppWindow.IsVisible) return;
        _hiddenByDeactivationAt = DateTime.UtcNow;
        HideFlyout();
    }

    private void OnClosing(AppWindow sender, AppWindowClosingEventArgs args)
    {
        if (App.Current.IsQuitting || App.Current.IsRebuildingWindows) return;
        args.Cancel = true;
        sender.Hide();
    }

    private async void OnSignClick(object sender, RoutedEventArgs e)
    {
        HideFlyout(); // the picker (and the PIN dialog in the main window) must not sit behind an always-on-top flyout
        try
        {
            var window = App.Current.EnsureMainWindow(activate: true);
            var paths = App.Current.Services.IsDemo ? App.Current.Services.DemoDocuments
                : await WindowHelpers.PickFilesAsync(window.AppWindow.Id);
            if (paths.Count > 0) ShowOutcome(await App.Current.Services.SignFilesAsync(paths));
        }
        catch (Exception error)
        {
            AppLog.Error(error);
            ShowOutcome(new OperationOutcome(false, Loc.Format("Error_FileSelection", error.Message), []));
        }
    }

    private async void OnVerifyClick(object sender, RoutedEventArgs e)
    {
        HideFlyout();
        try
        {
            var window = App.Current.EnsureMainWindow(activate: true);
            var paths = App.Current.Services.IsDemo ? App.Current.Services.DemoDocuments
                : await WindowHelpers.PickFilesAsync(window.AppWindow.Id, ".pdf", ".xml");
            if (paths.Count > 0) await window.VerifyFilesAsync(paths);
        }
        catch (Exception error)
        {
            AppLog.Error(error);
            ShowOutcome(new OperationOutcome(false, Loc.Format("Error_FileSelection", error.Message), []));
        }
    }

    private void OnRecentClick(object sender, ItemClickEventArgs e)
    {
        if (e.ClickedItem is not ActivityItem { Path: { } path }) return;
        HideFlyout();
        WindowHelpers.RevealInExplorer(path);
    }

    /// <summary>"Golește lista": empties the recent documents right away (the Activity page keeps the history).</summary>
    private void OnClearRecentClick(object sender, RoutedEventArgs e) => State.ClearRecentDocuments();

    /// <summary>Accent only while enabled (the selected card can sign); default style while disabled.</summary>
    private void UpdateSignButton()
    {
        SignButton.IsEnabled = State.CanSign;
        SignButton.Style = WindowHelpers.ButtonStyle(accent: State.CanSign);
    }

    private async void OnBridgeToggled(object sender, RoutedEventArgs e)
    {
        if (BridgeToggle.IsOn == State.BridgeEnabled) return; // echo of the OneWay binding
        await App.Current.Services.SetBridgeEnabledAsync(BridgeToggle.IsOn);
    }

    private void OnRereadClick(object sender, RoutedEventArgs e) => App.Current.Services.RereadCards();

    private void OnSettingsClick(object sender, RoutedEventArgs e)
    {
        HideFlyout();
        App.Current.EnsureMainWindow(activate: true).ShowSection("settings");
    }

    private void OnOpenWindowClick(object sender, RoutedEventArgs e)
    {
        HideFlyout();
        App.Current.EnsureMainWindow(activate: true);
    }

    private void OnQuitClick(object sender, RoutedEventArgs e) => App.Current.Quit();

    /// <summary>Reopens the flyout with the result (it was hidden for the picker); cancelled = silent.</summary>
    private void ShowOutcome(OperationOutcome outcome)
    {
        if (string.IsNullOrEmpty(outcome.Message)) return;
        Result.Severity = outcome.Success ? InfoBarSeverity.Success :
            outcome.Reports is { } reports && MoldSign.Core.Validator.OverallVerdict(reports) != MoldSign.Core.Verdict.Invalid
                ? InfoBarSeverity.Informational : InfoBarSeverity.Warning;
        Result.Message = outcome.Message;
        Result.IsOpen = true;
        ShowFlyout();
    }
}
