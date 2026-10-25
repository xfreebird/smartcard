using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;

namespace MoldSign.App.Tray;

/// <summary>Borderless always-on-top window next to the notification area; hides when it loses focus.</summary>
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
        Drop.FilesChosen += OnFilesChosen;
    }

    public AppState State => AppState.Current;

    public void Toggle()
    {
        // A click on the tray icon first deactivates (hides) the flyout; don't reopen it on that same click.
        if (AppWindow.IsVisible) HideFlyout();
        else if (DateTime.UtcNow - _hiddenByDeactivationAt > TimeSpan.FromMilliseconds(300)) ShowFlyout();
    }

    public void ShowFlyout()
    {
        WindowHelpers.PlaceNearTray(this);
        AppWindow.Show();
        Activate();
    }

    public void HideFlyout() => AppWindow.Hide();

    private void OnActivated(object sender, WindowActivatedEventArgs args)
    {
        if (args.WindowActivationState != WindowActivationState.Deactivated || !AppWindow.IsVisible) return;
        _hiddenByDeactivationAt = DateTime.UtcNow;
        HideFlyout();
    }

    private void OnClosing(AppWindow sender, AppWindowClosingEventArgs args)
    {
        if (App.Current.IsQuitting) return;
        args.Cancel = true;
        sender.Hide();
    }

    private async void OnFilesChosen(object? sender, IReadOnlyList<string> paths)
    {
        // Drop = sign (docs/10 §4.1); the format is picked per file.
        var outcome = await App.Current.Services.SignFilesAsync(paths);
        ShowOutcome(outcome);
    }

    private async void OnSignClick(object sender, RoutedEventArgs e)
    {
        if (Content.XamlRoot is not { } root) return;
        var paths = await WindowHelpers.PickFilesAsync(root);
        if (paths.Count > 0) ShowOutcome(await App.Current.Services.SignFilesAsync(paths));
    }

    private async void OnVerifyClick(object sender, RoutedEventArgs e)
    {
        if (Content.XamlRoot is not { } root) return;
        var paths = await WindowHelpers.PickFilesAsync(root, ".pdf", ".xml");
        if (paths.Count > 0) ShowOutcome(await App.Current.Services.VerifyAsync(paths[0]));
    }

    private void OnRecentClick(object sender, ItemClickEventArgs e)
    {
        if (e.ClickedItem is ActivityItem { Path: { } path }) WindowHelpers.RevealInExplorer(path);
    }

    private async void OnBridgeToggled(object sender, RoutedEventArgs e)
    {
        if (BridgeToggle.IsOn == State.BridgeEnabled) return; // echo of the OneWay binding
        await App.Current.Services.SetBridgeEnabledAsync(BridgeToggle.IsOn);
    }

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

    private void ShowOutcome(OperationOutcome outcome)
    {
        if (string.IsNullOrEmpty(outcome.Message)) return; // cancelled: silent
        Result.Severity = outcome.Success ? InfoBarSeverity.Success : InfoBarSeverity.Warning;
        Result.Message = outcome.Message;
        Result.IsOpen = true;
    }
}
