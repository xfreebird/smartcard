using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Globalization;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;
using MoldSign.Core;

namespace MoldSign.App.Views;

public sealed partial class SignPage : Page
{
    public SignPage()
    {
        InitializeComponent();
        DetachedOption.Content = Loc.Get("Packaging_Detached");
        EnvelopingOption.Content = Loc.Get("Packaging_Enveloping");
        SignedResultsTitle.Text = Loc.Get("Sign_SignedFiles");
        DocumentDrop.FilesChosen += OnFilesChosen;
        Files.CollectionChanged += (_, _) =>
        {
            UpdateDocumentsArea();
            UpdateSignButton();
        };
        Loaded += (_, _) =>
        {
            State.PropertyChanged += OnStateChanged;
            UpdateDocumentsArea();
            UpdateSignButton();
        };
        Unloaded += (_, _) => State.PropertyChanged -= OnStateChanged;
    }

    public ObservableCollection<FileRow> Files { get; } = [];

    public AppState State => AppState.Current;

    private void OnStateChanged(object? sender, PropertyChangedEventArgs e) => UpdateSignButton();

    private void OnFilesChosen(object? sender, IReadOnlyList<string> paths)
        => QueueFiles(paths);

    public void QueueFiles(IReadOnlyList<string> paths)
    {
        if (App.Current.Services.IsDemo && paths.Any(path => !App.Current.Services.IsDemoDocument(path)))
        {
            Result.Message = Loc.Get("demo_fixture_only"); Result.IsOpen = true; return;
        }
        foreach (var path in paths)
        {
            if (Files.All(f => !string.Equals(f.Path, path, StringComparison.OrdinalIgnoreCase))) Files.Add(new FileRow(path));
        }
    }

    private void OnRemoveClick(object sender, RoutedEventArgs e)
    {
        if ((sender as FrameworkElement)?.Tag is string path && Files.FirstOrDefault(f => f.Path == path) is { } row)
            Files.Remove(row);
    }

    private async void OnSignClick(object sender, RoutedEventArgs e)
    {
        await SignRowsAsync(Files.ToArray());
    }

    private async void OnRetryClick(object sender, RoutedEventArgs e)
    {
        if ((sender as FrameworkElement)?.Tag is string path && Files.FirstOrDefault(row => row.Path == path) is { } row)
            await SignRowsAsync([row]);
    }

    private async Task SignRowsAsync(IReadOnlyList<FileRow> rows)
    {
        if (rows.Count == 0 || !State.CanSign) return;
        foreach (var row in rows) row.Error = "";
        var packaging = PackagingButtons.SelectedIndex == 1 ? XadesPackaging.Enveloping : XadesPackaging.Detached;
        var outcome = await App.Current.Services.SignDocumentsAsync(
            [.. rows.Select(f => new DocumentJob(f.Path, f.Format))], packaging);
        foreach (var path in outcome.Outputs)
        {
            var button = new Button
            {
                Content = new TextBlock { Text = System.IO.Path.GetFileName(path), TextWrapping = TextWrapping.Wrap },
                Tag = path, HorizontalAlignment = HorizontalAlignment.Stretch,
                HorizontalContentAlignment = HorizontalAlignment.Left,
            };
            ToolTipService.SetToolTip(button, path);
            button.Click += OnSignedFileClick;
            SignedFiles.Children.Insert(0, button);
        }
        SignedResults.Visibility = SignedFiles.Children.Count > 0 ? Visibility.Visible : Visibility.Collapsed;
        foreach (var completed in outcome.CompletedInputs)
            if (Files.FirstOrDefault(row => row.Path == completed) is { } row) Files.Remove(row);
        if (outcome.FailedInput is { } failed && Files.FirstOrDefault(row => row.Path == failed) is { } failedRow)
            failedRow.Error = outcome.Message;
        if (!string.IsNullOrEmpty(outcome.Message))
        {
            Result.Severity = outcome.Success ? InfoBarSeverity.Success : InfoBarSeverity.Warning;
            Result.Message = outcome.Message;
            Result.IsOpen = true;
        }
        UpdateSignButton();
    }

    private void OnSignedFileClick(object sender, RoutedEventArgs e)
    {
        if ((sender as FrameworkElement)?.Tag is string path && File.Exists(path))
            WindowHelpers.RevealInExplorer(path);
    }

    /// <summary>No files: the large drop zone alone. Files: their list, then the drop zone, compact, under it.</summary>
    private void UpdateDocumentsArea()
    {
        var hasFiles = Files.Count > 0;
        FileList.Visibility = hasFiles ? Visibility.Visible : Visibility.Collapsed;
        ListRow.Height = hasFiles ? new GridLength(1, GridUnitType.Star) : GridLength.Auto;
        DocumentDrop.IsCompact = hasFiles;
    }

    /// <summary>
    /// Enabled with files queued and the selected card ready (green light). Accent style only while enabled: a
    /// disabled accent-filled button reads as broken (default style otherwise).
    /// </summary>
    private void UpdateSignButton()
    {
        var enabled = Files.Count > 0 && State.CanSign;
        SignButton.IsEnabled = enabled;
        SignButton.Style = WindowHelpers.ButtonStyle(accent: enabled);
        SignButton.Content = Files.Count switch
        {
            0 or 1 => Loc.Get("Action_Sign"),
            var n => Loc.Format("Sign_ButtonCount", n),
        };
    }
}
