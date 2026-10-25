using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.App.Services;

namespace MoldSign.App.Views;

public sealed partial class VerifyPage : Page
{
    public VerifyPage()
    {
        InitializeComponent();
        Drop.Extensions.Add(".pdf");
        Drop.Extensions.Add(".xml");
        Drop.FilesChosen += OnFilesChosen;
    }

    private async void OnFilesChosen(object? sender, IReadOnlyList<string> paths)
    {
        var signature = paths.FirstOrDefault(p => p.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase)
                                                  || p.EndsWith(".xml", StringComparison.OrdinalIgnoreCase)) ?? paths[0];
        var detached = paths.Where(p => p != signature).ToList();
        var outcome = await App.Current.Services.VerifyAsync(signature, detached);

        var known = outcome.Message == Loc.Get("Verdict_Valid") || outcome.Message == Loc.Get("Verdict_Invalid");
        Verdict.Visibility = known ? Visibility.Visible : Visibility.Collapsed;
        if (known)
        {
            VerdictIcon.Glyph = outcome.Success ? "" : "";
            VerdictIcon.Foreground = WindowHelpers.ThemeBrush(outcome.Success ? "SuccessBrush" : "DangerBrush");
            VerdictText.Text = outcome.Message;
            Result.IsOpen = false;
        }
        else
        {
            Result.Severity = InfoBarSeverity.Informational;
            Result.Message = outcome.Message;
            Result.IsOpen = true;
        }
    }
}
