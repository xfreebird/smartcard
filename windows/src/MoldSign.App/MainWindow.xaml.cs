using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Animation;
using System.Text.Json;
using MoldSign.App.Services;
using MoldSign.App.Controls;
using MoldSign.App.Views;

namespace MoldSign.App;

public sealed partial class MainWindow : Window
{
    private bool _initializingNavigation = true;

    public MainWindow()
    {
        InitializeComponent();
        ProtectionMenu.Content = Loc.Get("protect_title");
        EncryptMenuItem.Text = Loc.Get("protect_encrypt");
        DecryptMenuItem.Text = Loc.Get("protect_decrypt");
        RemoveMenuItem.Text = Loc.Get("protect_remove");
        ExtendsContentIntoTitleBar = true;
        SetTitleBar(AppTitleBar);
        if (Content is FrameworkElement root)
            root.ActualThemeChanged += (_, _) => WindowHelpers.ApplyCaptionTheme(this);
        WindowHelpers.ApplyCaptionTheme(this);
        AppWindow.Title = AppInfo.ProductName;
        AppWindow.SetIcon(Path.Combine(AppContext.BaseDirectory, "Assets", "AppIcon.ico"));
        // A normal app window: taskbar button and Alt+Tab (only the tray flyout is hidden from switchers).
        AppWindow.IsShownInSwitchers = true;
        WindowHelpers.ApplyMica(this);
        WindowHelpers.ResizeMain(this);
        AppWindow.Closing += OnClosing;

        Nav.SelectedItem = Nav.MenuItems[0];
        ContentFrame.Navigate(typeof(SignPage));
        _initializingNavigation = false;
    }

    private async void OnEncryptClick(object sender, RoutedEventArgs e) => await ShowProtection(0);
    private async void OnDecryptClick(object sender, RoutedEventArgs e) => await ShowProtection(1);
    private async void OnRemoveClick(object sender, RoutedEventArgs e) => await ShowProtection(2);
    private async Task ShowProtection(int operation) => await new FileProtectionDialog(Content.XamlRoot, ((FrameworkElement)Content).ActualTheme, operation).ShowAsync();

    public AppState State => AppState.Current;

    public void QueueSignFiles(IReadOnlyList<string> paths)
    {
        ShowSection("sign");
        if (ContentFrame.Content is SignPage page) page.QueueFiles(paths);
    }

    public async Task VerifyFilesAsync(IReadOnlyList<string> paths)
    {
        ShowSection("verify");
        if (ContentFrame.Content is VerifyPage page) await page.VerifyFilesAsync(paths);
    }

    /// <summary>Selects a section: "sign", "verify", "activity", "card" or "settings".</summary>
    public void ShowSection(string tag)
    {
        if (tag == "settings")
        {
            Nav.SelectedItem = Nav.SettingsItem;
            Navigate(typeof(SettingsPage));
            return;
        }
        foreach (var item in Nav.MenuItems.OfType<NavigationViewItem>())
        {
            if ((string?)item.Tag == tag) Nav.SelectedItem = item;
        }
        Navigate(PageFor(tag));
    }

    public void ResetForServices()
    {
        Nav.SelectedItem = Nav.SettingsItem;
        ContentFrame.Navigate(typeof(SettingsPage), null, new SuppressNavigationTransitionInfo());
    }

    private void OnClosing(AppWindow sender, AppWindowClosingEventArgs args)
    {
        // Tray-first: closing hides; "Ieșire" in the tray quits.
        if (App.Current.IsQuitting || App.Current.IsRebuildingWindows) return;
        args.Cancel = true;
        sender.Hide();
    }

    private void OnStatusRereadClick(object sender, RoutedEventArgs e) => App.Current.Services.RereadCards();

    private void OnNavSelectionChanged(NavigationView sender, NavigationViewSelectionChangedEventArgs args)
    {
        if (_initializingNavigation || args.SelectedItem != sender.SelectedItem) return;
        var page = args.IsSettingsSelected
            ? typeof(SettingsPage)
            : PageFor((args.SelectedItem as NavigationViewItem)?.Tag as string);
        Navigate(page);
    }

    private void Navigate(Type page)
    {
        var section = page == typeof(SignPage) ? "sign" : page == typeof(VerifyPage) ? "verify"
            : page == typeof(CardPage) ? "card" : page == typeof(SettingsPage) ? "settings"
            : page == typeof(ActivityPage) ? "activity" : "unknown";
        if (ContentFrame.CurrentSourcePageType != page)
            ContentFrame.Navigate(page, null, App.Current.Services.IsDemo ? new SuppressNavigationTransitionInfo() : null);
        AppLog.Stage($"Navigation frame={ContentFrame.CurrentSourcePageType?.Name}");
    }

    /// <summary>Development-only capture handshake, written after the requested page has rendered stably.</summary>
    public void PrepareDemoCapture(string tag)
    {
#if DEBUG
        var path = Environment.GetEnvironmentVariable("MSIGN_DEMO_READY_FILE");
        if (!App.Current.Services.IsDemo || string.IsNullOrEmpty(path)) return;
        var expected = PageFor(tag);
        var frames = 0;
        EventHandler<object>? rendered = null;
        rendered = (_, _) =>
        {
            if (ContentFrame.Content is not Page page || page.GetType() != expected || !page.IsLoaded)
            {
                frames = 0;
                return;
            }
            page.UpdateLayout();
            if (!WalletsCentered(page)) { frames = 0; return; }
            if (++frames < 3) return;
            CompositionTarget.Rendering -= rendered;
            if (Environment.GetEnvironmentVariable("MSIGN_QA_STAMP_PREVIEW") == "1" && page is SignPage signPage) {
                var sample=Environment.GetEnvironmentVariable("MSIGN_QA_STAMP_FILE");
                var samples=App.Current.Services.DemoDocuments.Where(p => p.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase)).ToArray();
                if (!string.IsNullOrEmpty(sample) && samples.Length>0) File.Copy(sample,samples[0],true);
                signPage.QueueFiles(samples);
                if (Environment.GetEnvironmentVariable("MSIGN_QA_FILE_OPTIONS") != "1" && signPage.Files.FirstOrDefault() is { } row)
                    _ = PdfStampEditor.ShowAsync(signPage.XamlRoot, row, _ => { });
            }

            // The temporary marker contains only scenario metadata, never certificates, documents or PINs.
            File.WriteAllText(path, JsonSerializer.Serialize(new
            {
                Page = tag,
                ActualPage = page.GetType().Name,
                Scenario = DemoMode.Scenario,
                ProcessId = Environment.ProcessId,
                Window = WindowHelpers.Handle(this).ToInt64(),
                CarouselsCentered = true,
            }));
        };
        if (AppWindow.Presenter is OverlappedPresenter presenter) presenter.IsAlwaysOnTop = true;
        ShowSection(tag);
        ContentFrame.UpdateLayout();
        CompositionTarget.Rendering += rendered;
#endif
    }

    private static bool WalletsCentered(DependencyObject element)
    {
        if (element is CardWallet wallet && !wallet.IsSelectionCentered) return false;
        for (var index = 0; index < VisualTreeHelper.GetChildrenCount(element); index++)
            if (!WalletsCentered(VisualTreeHelper.GetChild(element, index))) return false;
        return true;
    }

    private static Type PageFor(string? tag) => tag switch
    {
        "verify" => typeof(VerifyPage),
        "activity" => typeof(ActivityPage),
        "card" => typeof(CardPage),
        "settings" => typeof(SettingsPage),
        _ => typeof(SignPage),
    };
}
