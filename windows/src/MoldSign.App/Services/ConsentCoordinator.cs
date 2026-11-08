using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using MoldSign.Core;
using MoldSign.Desktop;

namespace MoldSign.App.Services;

/// <summary>
/// The platform side of <see cref="ConsentProvider"/> (docs/09 §3.4): SigningService calls it on a worker
/// thread; it shows UI on the dispatcher and blocks until the user answers.
/// Stored PIN → Windows Hello only; otherwise the PIN window (docs/10 §4.3).
/// </summary>
public sealed class ConsentCoordinator(DispatcherQueue ui, IPinVault pins, AppSettings settings)
{
    private readonly CancellationTokenSource _shutdown = new();
    public void CancelPending() => _shutdown.Cancel();

    /// <summary>SHA-1 of the certificate the last PIN was given for (deleted from the vault on WrongPin).</summary>
    public string? LastCertificateSha1 { get; private set; }

    /// <summary>Remaining attempts to show in the next dialog after a wrong PIN.</summary>
    public int? LastRemainingAttempts { get; set; }

    public ConsentResult Request(ConsentRequest request) => Request(request, CancellationToken.None);

    public ConsentResult Request(ConsentRequest request, CancellationToken cancellationToken)
    {
        if (_shutdown.IsCancellationRequested) return ConsentResult.Cancelled;
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(_shutdown.Token, cancellationToken);
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
            if (request.Requester == "Tu" && request.Documents.Count > 1 &&
                !await ApproveBatchAsync(request, cancellationToken)) return ConsentResult.Cancelled;
            var reason = request.Requester == "Tu"
                ? Loc.Format("Consent_HelloReason", request.Certificate.CommonName)
                : Loc.Format("Consent_HelloBrowser", request.Requester, request.Certificate.CommonName,
                    string.Join(", ", request.Documents), SignatureLabels.Human(request.Format));
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

    private async Task<bool> ApproveBatchAsync(ConsentRequest request, CancellationToken cancellationToken)
    {
        var window = App.Current.EnsureMainWindow(activate: true);
        var root = (FrameworkElement)window.Content;
        if (!root.IsLoaded)
        {
            var loaded = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
            void OnLoaded(object sender, RoutedEventArgs e) => loaded.TrySetResult();
            root.Loaded += OnLoaded;
            try { await loaded.Task.WaitAsync(cancellationToken); }
            finally { root.Loaded -= OnLoaded; }
        }
        var documents = new StackPanel { Spacing = 12 };
        documents.Children.Add(new TextBlock { Text = request.Certificate.CommonName, TextWrapping = TextWrapping.Wrap });
        foreach (var document in request.Documents)
            documents.Children.Add(new TextBlock { Text = document, TextWrapping = TextWrapping.Wrap });
        var dialog = new ContentDialog
        {
            XamlRoot = root.XamlRoot,
            RequestedTheme = root.ActualTheme,
            Title = Loc.Get("Action_Sign"),
            Content = new ScrollViewer { MaxHeight = 280, Content = documents,
                VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
                HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled },
            PrimaryButtonText = Loc.Get("Action_Sign"), CloseButtonText = Loc.Get("Action_Cancel"),
            DefaultButton = ContentDialogButton.Close,
        };
        using var cancellation = cancellationToken.Register(() => ui.TryEnqueue(dialog.Hide));
        var result = await dialog.ShowAsync();
        cancellationToken.ThrowIfCancellationRequested();
        return result == ContentDialogResult.Primary;
    }

    /// <summary>PIN QSCD window: 4–8 digits, no paste, remember toggle, attempts-left line; centered on the screen.</summary>
    private Task<(string? Pin, bool Remember)> ShowPinWindowAsync(ConsentRequest request, CancellationToken cancellationToken)
    {
        var heading = request.Requester == "Tu"
            ? Loc.Format("Pin_For", request.Certificate.CommonName)
            : $"{Loc.Format("Consent_Title", request.Requester)}\n{request.Certificate.CommonName}";
        var details = request.Documents.Count > 0
            ? request.Documents.Concat(new[] { request.Format }).ToArray()
            : [];
        var window = new PinWindow(heading, details, settings.RememberPin, LastRemainingAttempts);
        return window.ShowAsync(cancellationToken);
    }
}
