using System.Collections.Specialized;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;

namespace MoldSign.App.Views;

public sealed partial class ActivityPage : Page
{
    public ActivityPage()
    {
        InitializeComponent();
        Loaded += (_, _) =>
        {
            State.PruneMissingFiles(); // document rows only while the file exists
            State.Activity.CollectionChanged += OnActivityChanged;
            ClearButton.IsEnabled = State.Activity.Count > 0;
        };
        Unloaded += (_, _) => State.Activity.CollectionChanged -= OnActivityChanged;
    }

    public AppState State => AppState.Current;

    private void OnActivityChanged(object? sender, NotifyCollectionChangedEventArgs e) =>
        ClearButton.IsEnabled = State.Activity.Count > 0;

    private void OnItemClick(object sender, ItemClickEventArgs e)
    {
        if (e.ClickedItem is not ActivityItem { Path: { } path }) return; // browser requests have no file
        if (File.Exists(path)) WindowHelpers.RevealInExplorer(path);
        else State.PruneMissingFiles();
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
