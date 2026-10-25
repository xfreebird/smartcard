using System.Collections.ObjectModel;
using System.Globalization;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;

namespace MoldSign.App.Views;

/// <summary>FileRow (docs/10 §3): name, size, auto format chip.</summary>
public sealed record FileRow(string Path)
{
    public string Name => System.IO.Path.GetFileName(Path);

    public string Format => string.Equals(System.IO.Path.GetExtension(Path), ".pdf", StringComparison.OrdinalIgnoreCase)
        ? "PAdES-T"
        : "XAdES-T";

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
            catch (IOException)
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
        Files.CollectionChanged += (_, _) => UpdateSignButton();
    }

    public ObservableCollection<FileRow> Files { get; } = [];

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
        if (Files.Count == 0) return;
        SignButton.IsEnabled = false;
        try
        {
            // TODO(WIN-01): pass XadesFormatBox / PackagingButtons choices through once XAdES is ported.
            var outcome = await App.Current.Services.SignFilesAsync([.. Files.Select(f => f.Path)]);
            if (outcome.Success) Files.Clear();
            if (!string.IsNullOrEmpty(outcome.Message))
            {
                Result.Severity = outcome.Success ? InfoBarSeverity.Success : InfoBarSeverity.Warning;
                Result.Message = outcome.Message;
                Result.IsOpen = true;
            }
        }
        finally
        {
            UpdateSignButton();
        }
    }

    private void UpdateSignButton()
    {
        SignButton.IsEnabled = Files.Count > 0;
        SignButton.Content = Files.Count switch
        {
            0 or 1 => Loc.Get("Action_Sign"),
            var n => Loc.Format("Sign_ButtonCount", n),
        };
    }
}
