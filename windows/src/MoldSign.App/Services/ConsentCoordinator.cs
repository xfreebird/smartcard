using Microsoft.UI.Dispatching;
using MoldSign.Core;

namespace MoldSign.App.Services;

/// <summary>
/// The platform side of <see cref="ConsentProvider"/> (docs/09 §3.4): SigningService calls it on a worker
/// thread; it shows UI on the dispatcher and blocks until the user answers.
/// Stored PIN → Windows Hello only; otherwise the PIN window (docs/10 §4.3).
/// </summary>
public sealed class ConsentCoordinator(DispatcherQueue ui, PinVault pins, AppSettings settings)
{
    /// <summary>SHA-1 of the certificate the last PIN was given for (deleted from the vault on WrongPin).</summary>
    public string? LastCertificateSha1 { get; private set; }

    /// <summary>Remaining attempts to show in the next dialog after a wrong PIN.</summary>
    public int? LastRemainingAttempts { get; set; }

    public ConsentResult Request(ConsentRequest request)
    {
        using var timeout = new CancellationTokenSource();
        if (request.Requester != "Tu") timeout.CancelAfter(TimeSpan.FromMinutes(2));
        LastCertificateSha1 = request.Certificate.Sha1;
        var answer = new TaskCompletionSource<ConsentResult>(TaskCreationOptions.RunContinuationsAsynchronously);
        var queued = ui.TryEnqueue(async () =>
        {
            try
            {
                answer.SetResult(await RequestOnUiThreadAsync(request, timeout.Token));
            }
            catch (OperationCanceledException)
            {
                answer.SetResult(ConsentResult.Cancelled);
            }
            catch (Exception e)
            {
                answer.SetException(e);
            }
        });
        return queued ? answer.Task.GetAwaiter().GetResult() : ConsentResult.Cancelled;
    }

    private async Task<ConsentResult> RequestOnUiThreadAsync(ConsentRequest request, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var sha1 = request.Certificate.Sha1;
        if (settings.RememberPin && pins.Contains(sha1))
        {
            // Windows Hello is owned by the main window, so bring it forward (above the browser) for the prompt.
            using var presentation = WindowHelpers.PresentConsent(App.Current.EnsureMainWindow(activate: true),
                aboveBrowser: request.Requester != "Tu");
            var reason = request.Requester == "Tu"
                ? Loc.Format("Consent_HelloReason", request.Certificate.CommonName)
                : Loc.Format("Consent_HelloBrowser", request.Requester, request.Certificate.CommonName,
                    string.Join(", ", request.Documents), request.Format);
            var stored = await pins.LoadAsync(sha1, reason);
            cancellationToken.ThrowIfCancellationRequested();
            if (stored is not null) return ConsentResult.WithPin(stored);
        }

        App.Current.HideFlyout(); // the always-on-top flyout must not cover the PIN window
        var (pin, remember) = await ShowPinWindowAsync(request, cancellationToken);
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

    /// <summary>PIN QSCD window: 4–8 digits, no paste, remember toggle, attempts-left line; centered on the screen.</summary>
    private Task<(string? Pin, bool Remember)> ShowPinWindowAsync(ConsentRequest request, CancellationToken cancellationToken)
    {
        var heading = request.Requester == "Tu"
            ? Loc.Format("Pin_For", request.Certificate.CommonName)
            : $"{Loc.Format("Consent_Title", request.Requester)}\n{request.Certificate.CommonName}";
        var details = request.Documents.Count > 0
            ? new[] { $"{string.Join(", ", request.Documents)} · {request.Format}" }
            : [];
        var window = new PinWindow(heading, details, settings.RememberPin, LastRemainingAttempts);
        return window.ShowAsync(cancellationToken);
    }
}
