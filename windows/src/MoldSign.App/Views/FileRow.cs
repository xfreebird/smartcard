using System.Globalization;
using System.ComponentModel;
using Microsoft.UI.Xaml;
using MoldSign.Core;
using MoldSign.App.Services;

namespace MoldSign.App.Views;

/// <summary>
/// FileRow (docs/10 §3): name, size and the format picker. PDFs offer PAdES-T (default), XAdES-BES, XAdES-T and
/// XAdES-C (detached XAdES over the PDF bytes → &lt;name&gt;-semnat.xml); other files offer the XAdES levels.
/// </summary>
public sealed class FileRow(string path) : INotifyPropertyChanged
{
    public event PropertyChangedEventHandler? PropertyChanged;
    private string _error = "";
    public string Error
    {
        get => _error;
        set { _error = value; PropertyChanged?.Invoke(this, new(nameof(Error))); PropertyChanged?.Invoke(this, new(nameof(ErrorVisibility))); }
    }
    public Visibility ErrorVisibility => string.IsNullOrEmpty(Error) ? Visibility.Collapsed : Visibility.Visible;
    public string RetryLabel => Loc.Get("File_Retry");
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
                    ? Loc.Format("File_SizeKB", Math.Max(1, bytes / 1024))
                    : Loc.Format("File_SizeMB", (bytes / (1024.0 * 1024)).ToString("0.#", CultureInfo.CurrentCulture));
            }
            catch (Exception error) when (error is IOException or UnauthorizedAccessException)
            {
                return "";
            }
        }
    }
}
