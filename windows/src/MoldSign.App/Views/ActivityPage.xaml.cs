using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;

namespace MoldSign.App.Views;

public sealed partial class ActivityPage : Page
{
    public ActivityPage()
    {
        InitializeComponent();
    }

    public AppState State => AppState.Current;

    private void OnItemClick(object sender, ItemClickEventArgs e)
    {
        if (e.ClickedItem is ActivityItem { Path: { } path }) WindowHelpers.RevealInExplorer(path);
    }
}
