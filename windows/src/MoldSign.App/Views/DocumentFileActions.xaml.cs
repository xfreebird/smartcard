using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;
using Windows.Storage;
using Windows.System;

namespace MoldSign.App.Views;

public sealed partial class DocumentFileActions : UserControl
{
    public DocumentFileActions()
    {
        InitializeComponent();
        OpenLabel.Text = Loc.Get("file_open_document");
        RevealLabel.Text = Loc.Get("File_ShowInFolder");
        AutomationProperties.SetName(OpenFile, OpenLabel.Text);
        AutomationProperties.SetName(RevealFile, RevealLabel.Text);
        ToolTipService.SetToolTip(OpenFile, OpenLabel.Text);
        ToolTipService.SetToolTip(RevealFile, RevealLabel.Text);
    }

    public static readonly DependencyProperty FilePathProperty = DependencyProperty.Register(
        nameof(FilePath), typeof(string), typeof(DocumentFileActions),
        new PropertyMetadata(null, (sender, _) => ((DocumentFileActions)sender).UpdateActions()));

    public string? FilePath
    {
        get => (string?)GetValue(FilePathProperty);
        set => SetValue(FilePathProperty, value);
    }

    public bool ShowFolderLabel
    {
        get => RevealLabel.Visibility == Visibility.Visible;
        set => RevealLabel.Visibility = value ? Visibility.Visible : Visibility.Collapsed;
    }

    private void UpdateActions()
    {
        var extension = Path.GetExtension(FilePath)?.ToLowerInvariant();
        OpenFile.Visibility = extension is ".pdf" or ".xml" ? Visibility.Visible : Visibility.Collapsed;
        Visibility = string.IsNullOrEmpty(FilePath) ? Visibility.Collapsed : Visibility.Visible;
    }

    private async void OnOpen(object sender, RoutedEventArgs e)
    {
        if (FilePath is not { } path) return;
        try
        {
            var file = await StorageFile.GetFileFromPathAsync(path);
            if (!await Launcher.LaunchFileAsync(file)) ShowUnavailable(OpenFile);
        }
        catch (Exception error) { AppLog.Error(error); ShowUnavailable(OpenFile); }
    }

    private void OnReveal(object sender, RoutedEventArgs e)
    {
        if (FilePath is not { } path || !File.Exists(path)) { ShowUnavailable(RevealFile); return; }
        try { WindowHelpers.RevealInExplorer(path); }
        catch (Exception error) { AppLog.Error(error); ShowUnavailable(RevealFile); }
    }

    private static void ShowUnavailable(Button anchor)
        => new Flyout { Content = new TextBlock { Text = Loc.Get("saved_unavailable"), TextWrapping = TextWrapping.Wrap } }.ShowAt(anchor);
}
