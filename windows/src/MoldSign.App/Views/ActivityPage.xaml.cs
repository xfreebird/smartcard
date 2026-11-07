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
        SignedFilter.Content = Loc.Get("saved_signed");
        HistoryFilter.Content = Loc.Get("saved_history");
        RefreshDocuments();
        Loaded += (_, _) =>
        {
            State.PruneMissingFiles(); // document rows only while the file exists
            State.Activity.CollectionChanged += OnActivityChanged;
            State.SignedDocuments.CollectionChanged += OnActivityChanged;
            RefreshDocuments();
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
        ClearButton.IsEnabled = State.Activity.Count > 0;
        ClearButton.Visibility = history ? Visibility.Visible : Visibility.Collapsed;
    }

    private bool _detailsOpen;

    private async void OnItemClick(object sender, ItemClickEventArgs e)
    {
        if (_detailsOpen || XamlRoot is null || e.ClickedItem is not ActivityItem { Path: { } path }) return;
        if (!File.Exists(path)) { State.PruneMissingFiles(); return; }
        _detailsOpen = true;
        try
        {
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
                CloseButtonText = Loc.Get("saved_close"), DefaultButton = ContentDialogButton.Close,
            };
            dialog.Opened += async (_, _) => await details.VerifyFilesAsync(new[] { path });
            dialog.Closed += (_, _) => details.CancelInspection();
            await dialog.ShowAsync();
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
}
