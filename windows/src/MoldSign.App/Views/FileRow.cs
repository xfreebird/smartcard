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

    private PdfStampPlacement? _stamp;
    public PdfStampPlacement? Stamp { get => _stamp; set { _stamp = value; PropertyChanged?.Invoke(this, new(nameof(StampLabel))); PropertyChanged?.Invoke(this, new(nameof(OptionsSummary))); PropertyChanged?.Invoke(this, new(nameof(TypeLabel))); PropertyChanged?.Invoke(this, new(nameof(StampSummary))); } }
    public Visibility StampVisibility => Format == SignatureFormat.PadesT ? Visibility.Visible : Visibility.Collapsed;
    public string StampLabel => Loc.Get(Stamp is null ? "Stamp_Add" : "Stamp_Edit");
    private static string HumanLabel(SignatureFormat format) => Loc.Get(format switch {
        SignatureFormat.PadesT => "format_pdf", SignatureFormat.XadesBes => "format_xml",
        SignatureFormat.XadesT => "format_xml_time", _ => "format_xml_data"
    });
    public string TypeLabel => HumanLabel(Format);
    public string StampSummary => Stamp is null ? Loc.Get("file_stamp_off") : Stamp.AllPages ? Loc.Get("file_stamp_all") : $"{Loc.Get("file_stamp_page")} {Stamp.Page+1}";
    public string OptionsLabel => Loc.Get("file_options");
    public string OptionsSummary => HumanLabel(Format) + (Format != SignatureFormat.PadesT ? "" : " · " +
        (Stamp is null ? Loc.Get("file_stamp_off") : Stamp.AllPages ? Loc.Get("file_stamp_all") : $"{Loc.Get("file_stamp_page")} {Stamp.Page+1}"));
    public string Path { get; } = path;

    public string Name => System.IO.Path.GetFileName(Path);

    public SignatureFormat Format { get; set; } = SignatureFormats.Default(path);

    public List<string> FormatLabels => [.. _formats.Select(HumanLabel)];

    /// <summary>Two-way with the row's ComboBox.</summary>
    public int FormatIndex
    {
        get => _formats.IndexOf(Format);
        set
        {
            if (value >= 0 && value < _formats.Count) Format = _formats[value];
            PropertyChanged?.Invoke(this, new(nameof(StampVisibility)));
            PropertyChanged?.Invoke(this, new(nameof(OptionsSummary))); PropertyChanged?.Invoke(this, new(nameof(TypeLabel))); PropertyChanged?.Invoke(this, new(nameof(StampSummary)));
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
