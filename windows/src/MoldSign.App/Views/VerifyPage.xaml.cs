using System.Globalization;
using Microsoft.UI.Text;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;
using MoldSign.Core;
using VerdictKind = MoldSign.Core.Verdict;

namespace MoldSign.App.Views;

public sealed partial class VerifyPage : Page
{
    private string? _signature;
    private readonly List<string> _documents = [];
    private int _version;
    private int _selectionVersion;

    private readonly bool _detailsMode;

    public VerifyPage() : this(detailsMode: false) { }

    internal VerifyPage(bool detailsMode)
    {
        _detailsMode = detailsMode;
        InitializeComponent();
        FileDrop.Extensions.Add(".pdf");
        FileDrop.Extensions.Add(".xml");
        FileDrop.FilesChosen += OnFilesChosen;
        if (detailsMode)
        {
            PageTitle.Visibility = FileDrop.Visibility = FormatHint.Visibility = Visibility.Collapsed;
        }
    }

    /// Invalidate only when the containing modal closes, not during WinUI popup reparenting.
    internal void CancelInspection() { ++_version; ++_selectionVersion; }

    private void OnClearResultsClick(object sender, RoutedEventArgs e)
    {
        ++_version;
        ++_selectionVersion;
        _signature = null;
        _documents.Clear();
        SignatureCards.Children.Clear();
        DocumentInfo.Visibility = Verdict.Visibility = SignatureCount.Visibility = ReferencedDocuments.Visibility = Checking.Visibility = ClearResults.Visibility = Visibility.Collapsed;
        Spinner.IsActive = false;
        Result.IsOpen = false;
        FileDrop.IsCompact = false;
    }

    private async void OnFilesChosen(object? sender, IReadOnlyList<string> paths) => await VerifyFilesAsync(paths);

    public async Task VerifyFilesAsync(IReadOnlyList<string> paths)
    {
        if (paths.Count == 0) return;
        var selection = ++_selectionVersion;
        if (App.Current.Services.IsDemo && paths.Any(path => !App.Current.Services.IsDemoDocument(path)))
        { ShowError(Loc.Get("demo_fixture_only")); return; }
        _signature = paths.FirstOrDefault(p => p.EndsWith(".xml", StringComparison.OrdinalIgnoreCase))
            ?? paths.FirstOrDefault(p => p.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase)) ?? paths[0];
        _documents.Clear();
        AddDocuments(paths);
        SignatureCards.Children.Clear();
        foreach (var path in paths.Where(path => path.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase) || path.EndsWith(".xml", StringComparison.OrdinalIgnoreCase)))
        {
            if (selection != _selectionVersion) break;
            _signature = path;
            await VerifyCurrentAsync();
        }
    }

    private async void OnAddDocumentsClick(object sender, RoutedEventArgs e)
    {
        try
        {
            if (XamlRoot is null) return;
            var paths = App.Current.Services.IsDemo ? App.Current.Services.DemoDocuments
                : await WindowHelpers.PickFilesAsync(XamlRoot);
            AddDocuments(paths);
            if (paths.Count > 0)
            {
                SignatureCards.Children.Clear();
                await VerifyCurrentAsync();
            }
        }
        catch (Exception error)
        {
            AppLog.Error(error);
            ShowError(Loc.Format("Error_FileSelection", error.Message));
        }
    }

    private void AddDocuments(IEnumerable<string> paths)
    {
        foreach (var path in paths)
        {
            if (string.Equals(path, _signature, StringComparison.OrdinalIgnoreCase)) continue;
            _documents.RemoveAll(existing => string.Equals(Path.GetFileName(existing), Path.GetFileName(path),
                StringComparison.OrdinalIgnoreCase));
            _documents.Add(path);
        }
    }

    private void OnRevealClick(object sender, RoutedEventArgs e)
    {
        try
        {
            if (_signature is { } path) WindowHelpers.RevealInExplorer(path);
        }
        catch (Exception error)
        {
            AppLog.Error(error);
            ShowError(error.Message);
        }
    }

    private async Task VerifyCurrentAsync()
    {
        if (_signature is not { } path) return;
        var version = ++_version;
        ClearResults.Visibility = _detailsMode ? Visibility.Collapsed : Visibility.Visible;
        DocumentName.Text = Path.GetFileName(path);
        DocumentInfo.Visibility = Visibility.Visible;
        FileDrop.IsCompact = true;
        Verdict.Visibility = Visibility.Collapsed;
        SignatureCount.Visibility = Visibility.Collapsed;
        SignatureCards.Children.Add(new TextBlock { Text = Path.GetFileName(path), FontWeight = FontWeights.SemiBold, TextWrapping = TextWrapping.Wrap });
        Result.IsOpen = false;
        Checking.Visibility = Visibility.Visible;
        Spinner.IsActive = true;
        ReferencedDocuments.Visibility = path.EndsWith(".xml", StringComparison.OrdinalIgnoreCase)
            ? Visibility.Visible : Visibility.Collapsed;
        ReferencedNames.Text = string.Join(Environment.NewLine, _documents.Select(Path.GetFileName));
        try
        {
            var outcome = await App.Current.Services.VerifyAsync(path, _documents.ToArray(), recordActivity: !_detailsMode);
            if (version != _version) return;
            if (outcome.Reports is not { } reports) { ShowError(outcome.Message); return; }

            var verdict = Validator.OverallVerdict(reports);
            VerdictText.Text = outcome.Message;
            VerdictIcon.Glyph = verdict switch
            {
                VerdictKind.Valid => "\uE73E",
                VerdictKind.Invalid => "\uE783",
                VerdictKind.Indeterminate => "\uE7BA",
                _ => "\uE946",
            };
            VerdictIcon.Style = (Style)Resources[verdict switch
            {
                VerdictKind.Valid => "VerifySuccessIconStyle",
                VerdictKind.Invalid => "VerifyDangerIconStyle",
                VerdictKind.Indeterminate => "VerifyWarningIconStyle",
                _ => "VerifySecondaryIconStyle",
            }];
            Verdict.Visibility = Visibility.Visible;
            SignatureCount.Text = Loc.Format("Verify_SignatureCount", reports.Count);
            SignatureCount.Visibility = Visibility.Visible;
            for (var i = 0; i < reports.Count; i++) SignatureCards.Children.Add(SignatureCard(reports[i], i + 1));
        }
        catch (Exception error)
        {
            AppLog.Error(error);
            if (version == _version) ShowError(Loc.Get("Verify_Failed"));
        }
        finally
        {
            if (version == _version)
            {
                Checking.Visibility = Visibility.Collapsed;
                Spinner.IsActive = false;
            }
        }
    }

    private Border SignatureCard(VerificationReport report, int index)
    {
        var content = new StackPanel { Spacing = 12 };
        content.Children.Add(new TextBlock
        {
            Text = $"{Loc.Format("Verify_Signature", index)} · {SignatureLabels.Human(report.Kind)}",
            FontWeight = FontWeights.SemiBold,
            TextWrapping = TextWrapping.Wrap,
        });
        content.Children.Add(new TextBlock { Text = "Author: " + report.Signer, FontWeight = FontWeights.SemiBold, TextWrapping = TextWrapping.Wrap });
        if (report.SignerIDNP is { } idnp) content.Children.Add(new TextBlock { Text = "IDNP: " + idnp, IsTextSelectionEnabled = true });
        content.Children.Add(Field("Verify_Signer", report.Signer));
        content.Children.Add(Field("Verify_SigningTime", FormatTime(report.SigningTime)));
        content.Children.Add(Field("Verify_Timestamp", report.TimestampTime is { } time
            ? FormatTime(time) : Loc.Get("Verify_NoTimestamp")));
        content.Children.Add(Field("Verify_Level", SignatureLabels.Human(report.Level)));
        content.Children.Add(Check("Verify_Integrity", report.ContentIntact, "Verify_IntegrityGood", "Verify_IntegrityBad"));
        content.Children.Add(Check("Verify_Crypto", report.SignatureValid, "Verify_CryptoGood", "Verify_CryptoBad"));
        content.Children.Add(Check("Verify_Chain", report.ChainTrusted, "Verify_ChainGood", "Verify_ChainBad", warnOnly: true));
        if (report.TimestampImprintValid is { } imprint)
            content.Children.Add(Check("Verify_Imprint", imprint, "Verify_ImprintGood", "Verify_ImprintBad"));

        var limitations = new List<string>();
        if (report.TimestampImprintValid is not null && !report.TimestampSignatureValidated)
            limitations.Add(Loc.Get("Verify_TsaNotChecked"));
        if (!report.RevocationValidated) limitations.Add(Loc.Get("Verify_RevocationNotChecked"));
        if (limitations.Count > 0)
            content.Children.Add(new InfoBar
            {
                IsOpen = true, IsClosable = false, Severity = InfoBarSeverity.Informational,
                Title = Loc.Get("Verify_Limits"), Message = string.Join(" ", limitations),
            });

        var certificate = new StackPanel { Spacing = 8 };
        foreach (var field in report.CertificateDetails)
            certificate.Children.Add(new TextBlock { Text = $"{CertificateLabels.Label(field.Key)}: {field.Value}", TextWrapping = TextWrapping.Wrap, IsTextSelectionEnabled = true });
        var certificateDisclosure = new Expander { Header = Loc.Get("cert_label_certificate_details"), Content = certificate, HorizontalAlignment = HorizontalAlignment.Stretch, HorizontalContentAlignment = HorizontalAlignment.Stretch };
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetAutomationId(certificateDisclosure, "VerifyCertificateDetails");
        content.Children.Add(certificateDisclosure);
        var details = new StackPanel { Spacing = 12 };
        details.Children.Add(Field("Verify_Format", SignatureLabels.Human(report.Kind)));
        details.Children.Add(Field("Verify_Identifier", report.Name));
        if (!string.IsNullOrWhiteSpace(report.SigningTime))
            details.Children.Add(Field("Verify_SigningTime", report.SigningTime));
        if (report.TimestampTime is { } timestamp) details.Children.Add(Field("Verify_Timestamp", timestamp));
        details.Children.Add(Field("Verify_TsaSignature", Loc.Get(report.TimestampSignatureValidated ? "Verify_Checked" : "Verify_NotChecked")));
        details.Children.Add(Field("Verify_Revocation", Loc.Get(report.RevocationValidated ? "Verify_Checked" : "Verify_NotChecked")));
        if (!string.IsNullOrWhiteSpace(report.Notes)) details.Children.Add(Field("Verify_Notes", report.Notes));
        var technicalDisclosure = new Expander
        {
            Header = Loc.Get("Verify_Details"), Content = details, HorizontalAlignment = HorizontalAlignment.Stretch,
            HorizontalContentAlignment = HorizontalAlignment.Stretch,
        };
        Microsoft.UI.Xaml.Automation.AutomationProperties.SetAutomationId(technicalDisclosure, "VerifyTechnicalDetails");
        content.Children.Add(technicalDisclosure);
        return new Border
        {
            Child = content, Padding = new Thickness(16), CornerRadius = new CornerRadius(14),
            Style = (Style)Resources["VerificationCardStyle"], BorderThickness = new Thickness(1),
        };
    }

    private static StackPanel Field(string label, string value)
    {
        var panel = new StackPanel { Spacing = 4 };
        panel.Children.Add(new TextBlock
        {
            Text = Loc.Get(label), FontSize = 12, TextWrapping = TextWrapping.Wrap,
            Style = (Style)Application.Current.Resources["MsCaptionTextStyle"],
        });
        panel.Children.Add(new TextBlock
        {
            Text = string.IsNullOrWhiteSpace(value) ? Loc.Get("Verify_Unavailable") : value,
            TextWrapping = TextWrapping.Wrap, IsTextSelectionEnabled = true,
        });
        return panel;
    }

    private Grid Check(string label, bool ok, string good, string bad, bool warnOnly = false)
    {
        var row = new Grid { ColumnSpacing = 12 };
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        row.Children.Add(new FontIcon
        {
            Glyph = ok ? "\uE73E" : warnOnly ? "\uE7BA" : "\uE783", FontSize = 18,
            Style = (Style)Resources[ok ? "VerifySuccessIconStyle" : warnOnly ? "VerifyWarningIconStyle" : "VerifyDangerIconStyle"],
        });
        var text = Field(label, Loc.Get(ok ? good : bad));
        Grid.SetColumn(text, 1);
        row.Children.Add(text);
        return row;
    }

    private static string FormatTime(string value) =>
        DateTimeOffset.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.None, out var date)
            ? date.ToLocalTime().ToString("G", CultureInfo.CurrentCulture)
            : string.IsNullOrWhiteSpace(value) ? Loc.Get("Verify_Unavailable") : value;

    private void ShowError(string message)
    {
        Result.Severity = InfoBarSeverity.Error;
        Result.Message = message;
        Result.IsOpen = true;
    }
}
