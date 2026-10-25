using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;
using MoldSign.App.Views;

namespace MoldSign.App;

public sealed partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        ExtendsContentIntoTitleBar = true;
        SetTitleBar(AppTitleBar);
        AppWindow.Title = "MoldSign";
        WindowHelpers.ApplyMica(this);
        WindowHelpers.ResizeMain(this);
        AppWindow.Closing += OnClosing;

        Nav.SelectedItem = Nav.MenuItems[0];
        ContentFrame.Navigate(typeof(SignPage));
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

    private void OnClosing(AppWindow sender, AppWindowClosingEventArgs args)
    {
        // Tray-first: closing hides; "Ieșire" in the tray quits.
        if (App.Current.IsQuitting) return;
        args.Cancel = true;
        sender.Hide();
    }

    private void OnNavSelectionChanged(NavigationView sender, NavigationViewSelectionChangedEventArgs args)
    {
        var page = args.IsSettingsSelected
            ? typeof(SettingsPage)
            : PageFor((args.SelectedItem as NavigationViewItem)?.Tag as string);
        Navigate(page);
    }

    private void Navigate(Type page)
    {
        if (ContentFrame.CurrentSourcePageType != page) ContentFrame.Navigate(page);
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
