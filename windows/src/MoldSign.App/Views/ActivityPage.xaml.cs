using System.Collections.Specialized;
using System.Collections.ObjectModel;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;

namespace MoldSign.App.Views;

public sealed partial class ActivityPage : Page
{
    public ActivityPage()
    {
        InitializeComponent();
        DocumentList.ItemsSource = DisplayItems;
        SignedFilter.Content = Loc.Get("saved_files");
        HistoryFilter.Content = Loc.Get("saved_history");
        RefreshDocuments();
        Loaded += (_, _) =>
        {
            State.PruneMissingFiles(); // document rows only while the file exists
            State.Activity.CollectionChanged += OnActivityChanged;
            State.SignedDocuments.CollectionChanged += OnActivityChanged;
            RefreshDocuments();
#if DEBUG
            if(DemoMode.ScreenshotCapture && AppSettings.IsolatedTestPreferences && Environment.GetEnvironmentVariable("MSIGN_CAPTURE_DIALOG")?.StartsWith("protect-",StringComparison.Ordinal)==true)
                DispatcherQueue.TryEnqueue(async()=>await new FileProtectionDialog(XamlRoot,ActualTheme).ShowAsync());
#endif
        };
        Unloaded += (_, _) =>
        {
            State.Activity.CollectionChanged -= OnActivityChanged;
            State.SignedDocuments.CollectionChanged -= OnActivityChanged;
        };
    }


    public AppState State => AppState.Current;

    private ObservableCollection<ActivityItem> DisplayItems { get; } = new();

    private void OnActivityChanged(object? sender, NotifyCollectionChangedEventArgs e) => RefreshDocuments();
    private void OnFilterChanged(object sender, SelectionChangedEventArgs e) => RefreshDocuments();
    private void RefreshDocuments()
    {
        if (DocumentList is null || EmptyMessage is null) return;
        var history = DocumentFilter.SelectedIndex == 1;
        DisplayItems.Clear();
        foreach (var item in history ? State.Activity : State.SignedDocuments)
            DisplayItems.Add(item);
        EmptyMessage.Text = history ? Loc.Get("RecentEmpty/Text") : Loc.Get("saved_empty") + "\n" + Loc.Get("saved_hint");
        EmptyMessage.Visibility = DisplayItems.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
        ClearButton.IsEnabled = DisplayItems.Count > 0;
        ClearButton.Content = Loc.Get(history ? "Activity_ClearConfirm" : "saved_delete_all");
        ClearButton.Visibility = Visibility.Visible;
    }

    private bool _detailsOpen;

    private async void OnItemClick(object sender, ItemClickEventArgs e)
    {
        if (_detailsOpen || XamlRoot is null || e.ClickedItem is not ActivityItem { Path: { } path } item) return;
        if (!File.Exists(path)) { State.PruneMissingFiles(); return; }
        _detailsOpen = true;
        try
        {
            if (item.IsProtectionOutput)
            {
                var content = new StackPanel { Spacing = 16 };
                content.Children.Add(new TextBlock { Text = item.FileName, TextWrapping = TextWrapping.Wrap });
                content.Children.Add(new TextBlock { Text = item.ActionLabel, TextWrapping = TextWrapping.Wrap });
                var open = new Button { Content = Loc.Get("File_ShowInFolder") };
                open.Click += (_, _) => System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo("explorer.exe", "/select,\"" + path + "\"") { UseShellExecute = true });
                content.Children.Add(open);
                var saved = new ContentDialog { XamlRoot = XamlRoot, RequestedTheme = ActualTheme,
                    Title = Loc.Get("saved_files"), Content = content, CloseButtonText = Loc.Get("saved_close"),
                    PrimaryButtonText = DocumentFilter.SelectedIndex == 0 ? Loc.Get("saved_delete") : "" };
                if (await saved.ShowAsync() == ContentDialogResult.Primary) await ConfirmDeleteAsync(new[] { item });
                return;
            }
            // Use the same fresh verification and certificate renderer as Verify, without
            // navigating away, replacing Verify's selected files, or adding another history row.
            var details = new VerifyPage(detailsMode: true)
            {
                MaxHeight = Math.Max(200, XamlRoot.Size.Height - 180),
                HorizontalAlignment = HorizontalAlignment.Stretch,
            };
            var dialog = new ContentDialog
            {
                XamlRoot = XamlRoot, RequestedTheme = ActualTheme, Title = Loc.Get("saved_details"), Content = details,
                PrimaryButtonText = DocumentFilter.SelectedIndex == 0 ? Loc.Get("saved_delete") : "",
                CloseButtonText = Loc.Get("saved_close"), DefaultButton = ContentDialogButton.Close,
            };
            dialog.Opened += async (_, _) => await details.VerifyFilesAsync(new[] { path });
            dialog.Closed += (_, _) => details.CancelInspection();
            if (await dialog.ShowAsync() == ContentDialogResult.Primary)
                await ConfirmDeleteAsync(new[] { item });
        }
        catch (Exception error)
        {
            AppLog.Error(error);
        }
        finally { _detailsOpen = false; }
    }

    private async void OnVerifyClick(object sender, RoutedEventArgs e)
    {
        if (sender is not FrameworkElement { DataContext: ActivityItem { Path: { } path } }) return;
        if (!File.Exists(path)) { State.PruneMissingFiles(); return; }
        await App.Current.EnsureMainWindow(activate: true).VerifyFilesAsync(new[] { path });
    }

    /// <summary>Clear operation history only; the saved document library and files are retained.</summary>
    private async void OnClearClick(object sender, RoutedEventArgs e)
    {
        if (DocumentFilter.SelectedIndex == 0)
        {
            await ConfirmDeleteAsync(State.SignedDocuments.ToArray());
            return;
        }
        var dialog = new ContentDialog
        {
            XamlRoot = XamlRoot,
            RequestedTheme = ActualTheme,
            Title = Loc.Get("Activity_ClearTitle"),
            Content = Loc.Get("Activity_ClearMessage"),
            PrimaryButtonText = Loc.Get("Activity_ClearConfirm"),
            CloseButtonText = Loc.Get("Action_Cancel"),
            DefaultButton = ContentDialogButton.Close,
        };
        if (await dialog.ShowAsync() == ContentDialogResult.Primary) State.ClearActivity();
    }
    private async Task ConfirmDeleteAsync(ActivityItem[] items)
    {
        if (items.Length == 0) return;
        var dialog = new ContentDialog
        {
            XamlRoot = XamlRoot, RequestedTheme = ActualTheme,
            Title = Loc.Get(items.Length == 1 ? "saved_delete" : "saved_delete_all"),
            Content = (items.Length == 1 ? items[0].FileName + "\n\n" : "") + Loc.Get("saved_delete_warning"),
            PrimaryButtonText = Loc.Get("saved_delete"), CloseButtonText = Loc.Get("Action_Cancel"),
            DefaultButton = ContentDialogButton.Close,
        };
        if (await dialog.ShowAsync() != ContentDialogResult.Primary) return;
        if (!State.DeleteSignedDocuments(items))
            await new ContentDialog
            {
                XamlRoot = XamlRoot, RequestedTheme = ActualTheme,
                Content = Loc.Get("saved_delete_failed"), CloseButtonText = Loc.Get("saved_close"),
            }.ShowAsync();
    }

}
