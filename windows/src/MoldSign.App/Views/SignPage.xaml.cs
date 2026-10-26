using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Globalization;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;
using MoldSign.Core;

namespace MoldSign.App.Views;

/// <summary>
/// FileRow (docs/10 §3): name, size and the format picker. PDFs offer PAdES-T (default), XAdES-BES, XAdES-T and
/// XAdES-C (detached XAdES over the PDF bytes → &lt;name&gt;-semnat.xml); other files offer the XAdES levels.
/// </summary>
public sealed class FileRow(string path)
{
    private readonly List<SignatureFormat> _formats = [.. SignatureFormats.Allowed(path)];

    public string Path { get; } = path;

    public string Name => System.IO.Path.GetFileName(Path);

    public SignatureFormat Format { get; set; } = SignatureFormats.Default(path);

    public List<string> FormatLabels => [.. _formats.Select(SignatureFormats.Label)];

    /// <summary>Two-way with the row's ComboBox.</summary>
    public int FormatIndex
    {
        get => _formats.IndexOf(Format);
        set
        {
            if (value >= 0 && value < _formats.Count) Format = _formats[value];
        }
    }

    public string SizeText
    {
        get
        {
            try
            {
                var bytes = new FileInfo(Path).Length;
                return bytes < 1024 * 1024
                    ? string.Create(CultureInfo.CurrentCulture, $"{Math.Max(1, bytes / 1024)} KB")
                    : string.Create(CultureInfo.CurrentCulture, $"{bytes / (1024.0 * 1024):0.#} MB");
            }
            catch (Exception error) when (error is IOException or UnauthorizedAccessException)
            {
                return "";
            }
        }
    }
}

public sealed partial class SignPage : Page
{
    public SignPage()
    {
        InitializeComponent();
        Drop.FilesChosen += OnFilesChosen;
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
    {
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
        if (Files.Count == 0 || !State.CanSign) return;
        var packaging = PackagingButtons.SelectedIndex == 1 ? XadesPackaging.Enveloping : XadesPackaging.Detached;
        var outcome = await App.Current.Services.SignDocumentsAsync(
            [.. Files.Select(f => new DocumentJob(f.Path, f.Format))], packaging);
        if (outcome.Success) Files.Clear();
        if (!string.IsNullOrEmpty(outcome.Message))
        {
            Result.Severity = outcome.Success ? InfoBarSeverity.Success : InfoBarSeverity.Warning;
            Result.Message = outcome.Message;
            Result.IsOpen = true;
        }
        UpdateSignButton();
    }

    /// <summary>No files: the large drop zone alone. Files: their list, then the drop zone, compact, under it.</summary>
    private void UpdateDocumentsArea()
    {
        var hasFiles = Files.Count > 0;
        FileList.Visibility = hasFiles ? Visibility.Visible : Visibility.Collapsed;
        ListRow.Height = hasFiles ? new GridLength(1, GridUnitType.Star) : GridLength.Auto;
        Drop.IsCompact = hasFiles;
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
