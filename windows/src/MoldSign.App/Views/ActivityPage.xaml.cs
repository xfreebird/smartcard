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
            RefreshDocuments();
        };
        Unloaded += (_, _) => State.Activity.CollectionChanged -= OnActivityChanged;
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
        foreach (var item in State.Activity.Where(item => history || (item.Success && item.Path != null &&
            (item.SignedOutput == true || (item.SignedOutput == null && System.IO.Path.GetFileName(item.Path).Contains("-semnat"))))))
            DisplayItems.Add(item);
        EmptyMessage.Text = history ? Loc.Get("RecentEmpty.Text") : Loc.Get("saved_empty") + "\n" + Loc.Get("saved_hint");
        EmptyMessage.Visibility = DisplayItems.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
        ClearButton.IsEnabled = State.Activity.Count > 0;
        ClearButton.Visibility = history ? Visibility.Visible : Visibility.Collapsed;
    }

    private void OnItemClick(object sender, ItemClickEventArgs e)
    {
        if (e.ClickedItem is not ActivityItem { Path: { } path }) return; // browser requests have no file
        if (File.Exists(path)) WindowHelpers.RevealInExplorer(path);
        else State.PruneMissingFiles();
    }

    private async void OnVerifyClick(object sender, RoutedEventArgs e)
    {
        if (sender is not FrameworkElement { DataContext: ActivityItem { Path: { } path } }) return;
        if (!File.Exists(path)) { State.PruneMissingFiles(); return; }
        await App.Current.EnsureMainWindow(activate: true).VerifyFilesAsync(new[] { path });
    }

    /// <summary>"Golește lista" with a confirmation: the log goes, the signed documents stay on disk.</summary>
    private async void OnClearClick(object sender, RoutedEventArgs e)
    {
        var dialog = new ContentDialog
        {
            XamlRoot = XamlRoot,
            Title = Loc.Get("Activity_ClearTitle"),
            Content = Loc.Get("Activity_ClearMessage"),
            PrimaryButtonText = Loc.Get("Activity_ClearConfirm"),
            CloseButtonText = Loc.Get("Action_Cancel"),
            DefaultButton = ContentDialogButton.Close,
        };
        if (await dialog.ShowAsync() == ContentDialogResult.Primary) State.ClearActivity();
    }
}
