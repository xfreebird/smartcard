using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using MoldSign.Core;

namespace MoldSign.App.Services;

/// <summary>
/// The platform side of <see cref="ConsentProvider"/> (docs/09 §3.4): SigningService calls it on a worker
/// thread; it shows UI on the dispatcher and blocks until the user answers.
/// Stored PIN → Windows Hello only; otherwise the PIN dialog (docs/10 §4.3).
/// </summary>
public sealed class ConsentCoordinator(DispatcherQueue ui, PinVault pins, AppSettings settings, Func<Task<XamlRoot?>> dialogRoot)
{
    /// <summary>SHA-1 of the certificate the last PIN was given for (deleted from the vault on WrongPin).</summary>
    public string? LastCertificateSha1 { get; private set; }

    /// <summary>Remaining attempts to show in the next dialog after a wrong PIN.</summary>
    public int? LastRemainingAttempts { get; set; }

    public ConsentResult Request(ConsentRequest request)
    {
        LastCertificateSha1 = request.Certificate.Sha1;
        var answer = new TaskCompletionSource<ConsentResult>(TaskCreationOptions.RunContinuationsAsynchronously);
        var queued = ui.TryEnqueue(async () =>
        {
            try
            {
                answer.SetResult(await RequestOnUiThreadAsync(request));
            }
            catch (Exception e)
            {
                answer.SetException(e);
            }
        });
        return queued ? answer.Task.GetAwaiter().GetResult() : ConsentResult.Cancelled;
    }

    private async Task<ConsentResult> RequestOnUiThreadAsync(ConsentRequest request)
    {
        var sha1 = request.Certificate.Sha1;
        if (settings.RememberPin && pins.Contains(sha1))
        {
            var stored = await pins.LoadAsync(sha1, Loc.Format("Consent_HelloReason", request.Certificate.CommonName));
            if (stored is not null) return ConsentResult.WithPin(stored);
        }

        if (await dialogRoot() is not { } root) return ConsentResult.Cancelled;
        var (pin, remember) = await ShowPinDialogAsync(request, root);
        if (pin is null) return ConsentResult.Cancelled;
        if (remember)
        {
            // A wrong PIN deletes it again (AppServices), so only a PIN the card accepted stays stored.
            pins.Save(pin, sha1);
            settings.RememberPin = true;
            settings.Save();
        }
        return ConsentResult.WithPin(pin);
    }

    /// <summary>PIN QSCD sheet: 4–8 digits, no paste, remember toggle, attempts-left line.</summary>
    private async Task<(string? Pin, bool Remember)> ShowPinDialogAsync(ConsentRequest request, XamlRoot root)
    {
        var requester = request.Requester == "Tu"
            ? Loc.Format("Pin_For", request.Certificate.CommonName)
            : Loc.Format("Consent_Title", request.Requester);
        var box = new PasswordBox
        {
            MaxLength = 8,
            PlaceholderText = "••••",
            InputScope = new InputScope { Names = { new InputScopeName(InputScopeNameValue.NumericPin) } },
        };
        box.Paste += (_, e) => e.Handled = true;
        var remember = new CheckBox { Content = Loc.Get("Pin_Remember"), IsChecked = settings.RememberPin };

        var panel = new StackPanel { Spacing = 12, MinWidth = 320 };
        panel.Children.Add(new TextBlock { Text = requester, TextWrapping = TextWrapping.Wrap });
        if (request.Documents.Count > 0)
        {
            panel.Children.Add(new TextBlock
            {
                Text = $"{string.Join(", ", request.Documents)} · {request.Format}",
                TextWrapping = TextWrapping.Wrap,
                Opacity = 0.8,
            });
        }
        panel.Children.Add(box);
        panel.Children.Add(remember);
        if (LastRemainingAttempts is { } left)
        {
            panel.Children.Add(new TextBlock
            {
                Text = Loc.Format("Pin_Attempts", left),
                Foreground = WindowHelpers.ThemeBrush(left <= 2 ? "WarningBrush" : "TextFillColorSecondaryBrush"),
            });
        }

        var dialog = new ContentDialog
        {
            XamlRoot = root,
            Title = Loc.Get("Pin_Title"),
            Content = panel,
            PrimaryButtonText = Loc.Get("Action_Sign"),
            CloseButtonText = Loc.Get("Action_Cancel"),
            DefaultButton = ContentDialogButton.Primary,
            IsPrimaryButtonEnabled = false,
        };
        box.PasswordChanged += (_, _) =>
            dialog.IsPrimaryButtonEnabled = box.Password.Length is >= 4 and <= 8 && box.Password.All(char.IsAsciiDigit);

        var result = await dialog.ShowAsync();
        return result == ContentDialogResult.Primary ? (box.Password, remember.IsChecked == true) : (null, false);
    }
}
