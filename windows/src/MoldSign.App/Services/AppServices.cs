using System.Diagnostics;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using MoldSign.Core;

namespace MoldSign.App.Services;

/// <summary>Result of a UI-triggered operation, ready for an InfoBar.</summary>
public sealed record OperationOutcome(bool Success, string Message, IReadOnlyList<string> Outputs);

/// <summary>One document to sign and the format chosen for it on the Sign page (PDF: PAdES-T or XAdES; others: XAdES).</summary>
public sealed record DocumentJob(string Path, SignatureFormat Format);

/// <summary>
/// Composition root of the tray app: SigningService (Core) + ReaderWatcher + PinVault + BridgeHost +
/// ConsentCoordinator. Card work runs on the thread pool; AppState is only touched on the UI thread.
///
/// Several cards (docs/09 §3.1b): every reader's card is read PIN-less as soon as it appears (per generation, late
/// answers for a re-inserted card are dropped), the wallet selection decides which reader a signature goes to, and
/// the selected card's certificate SHA-1 travels with it as the identity guard, so a card swapped in the meantime
/// fails with <see cref="CardErrorKind.CardChanged"/> before the PIN is sent.
/// </summary>
public sealed class AppServices : IAsyncDisposable
{
    private readonly DispatcherQueue _ui;

    /// <param name="ui">UI-thread dispatcher.</param>
    /// <param name="dialogRoot">XamlRoot for the PIN dialog (the main window, shown on demand).</param>
    /// <param name="ownerWindow">HWND owning the Windows Hello prompt.</param>
    public AppServices(DispatcherQueue ui, Func<Task<XamlRoot?>> dialogRoot, Func<nint> ownerWindow)
    {
        _ui = ui;
        Settings = AppSettings.Load();
        Pins = new PinVault(ownerWindow);
        Readers = new ReaderWatcher();
        Consent = new ConsentCoordinator(ui, Pins, Settings, dialogRoot);
        // Every operation names its PC/SC reader (the wallet selection); null = the first reader with a card.
        Signing = new SigningService(reader => WinSCardTransport.Connect(new WinSCardOptions { ReaderName = reader }),
                                     trace: line => Debug.WriteLine($"[card] {line}"));
        Bridge = new BridgeHost(BridgeOriginPolicy.Default, tlsPfxPath: () => null /* TODO(WIN-06) */);

        Signing.Progress += (_, step) => _ui.TryEnqueue(() => State.SetStep(step));
        Readers.Changed += (_, slots) => _ui.TryEnqueue(() => OnReadersChanged(slots));
    }

    public AppSettings Settings { get; }
    public PinVault Pins { get; }
    public ReaderWatcher Readers { get; }
    public ConsentCoordinator Consent { get; }
    public SigningService Signing { get; }
    public BridgeHost Bridge { get; }

    private static AppState State => AppState.Current;

    public void Start()
    {
        State.LoadActivity(); // saved log, documents that no longer exist dropped
        Readers.Start();
        _ = SetBridgeEnabledAsync(Settings.BridgeEnabled);
    }

    public async Task SetBridgeEnabledAsync(bool enabled)
    {
        try
        {
            if (enabled) await Bridge.StartAsync();
            else await Bridge.StopAsync();
            State.BridgeStatus = Loc.Get(enabled ? "Bridge_On" : "Bridge_Off");
        }
        catch (IOException e)
        {
            // Port taken, typically by the vendor Java server.
            Debug.WriteLine($"bridge: {e.Message}");
            enabled = false;
            State.BridgeStatus = Loc.Format("Bridge_PortBusy", BridgeProtocol.HttpPort);
        }
        State.BridgeEnabled = enabled;
        Settings.BridgeEnabled = enabled;
        Settings.Save();
    }

    // MARK: - Cards

    /// <summary>Wallet click / arrow keys: the card the next signature uses.</summary>
    public void SelectCard(string reader) => State.Select(reader);

    /// <summary>"Recitește cardul": one card (its context menu) or every card (toolbar button).</summary>
    public void RereadCards(string? reader = null)
    {
        foreach (var card in State.Reread(reader)) _ = ReadCertificateAsync(card);
        Readers.Refresh();
    }

    private void OnReadersChanged(IReadOnlyList<ReaderSlot> slots)
    {
        foreach (var card in State.ApplySlots(slots)) _ = ReadCertificateAsync(card);
    }

    /// <summary>docs/09 §3.7: PIN-less certificate read so the wallet can greet the holder (full mutual auth, card lock).</summary>
    private async Task ReadCertificateAsync(WalletCard card)
    {
        try
        {
            var certificate = await Task.Run(() => Signing.Certificate(card.Reader));
            State.CompleteRead(card, certificate); // ignored when the card changed meanwhile
        }
        catch (CardException e)
        {
            Debug.WriteLine($"certificate read failed in {card.Reader}: {e.Kind}: {e.Message}");
            // Removed while reading: the next reader snapshot drops the card anyway.
            if (e.Kind is not (CardErrorKind.NoCard or CardErrorKind.NoReader)) State.FailRead(card, e.Kind);
        }
    }

    // MARK: - Signing

    /// <summary>Tray flyout "Semnează…": each file in its default format (PDF → PAdES-T, others → XAdES-T detached).</summary>
    public Task<OperationOutcome> SignFilesAsync(IReadOnlyList<string> paths) =>
        SignDocumentsAsync([.. paths.Select(p => new DocumentJob(p, SignatureFormats.Default(p)))], XadesPackaging.Detached);

    /// <summary>
    /// Signs with the selected wallet card, each document in its chosen format (a PDF can also get XAdES, written as
    /// <c>&lt;name&gt;-semnat.xml</c>). One consent/PIN per file for now (TODO(WIN-01): one PIN for the batch, like MAC-05).
    /// </summary>
    public async Task<OperationOutcome> SignDocumentsAsync(IReadOnlyList<DocumentJob> jobs, XadesPackaging packaging)
    {
        if (State.SelectedReader is not { } reader || State.Certificate is not { } certificate || !State.CanSign)
            return new OperationOutcome(false, State.LightLabel, []);

        State.SetBusy(true);
        var outputs = new List<string>();
        try
        {
            await Task.Run(() =>
            {
                foreach (var job in jobs)
                {
                    var result = Signing.Sign(job.Path, job.Format, packaging, Consent.Request,
                                              reader: reader, expectedCertificateSha1: certificate.Sha1);
                    outputs.AddRange(result.OutputFiles);
                    Record(Path.GetFileName(job.Path), $"{Loc.Get("Activity_Signed")} · {SignatureFormats.Label(job.Format)}",
                           true, result.OutputFiles.FirstOrDefault());
                }
            });
            Consent.LastRemainingAttempts = null;
            return new OperationOutcome(true, Loc.Format("Sign_Done", outputs.Count), outputs);
        }
        catch (CardException e) when (e.Kind == CardErrorKind.Cancelled)
        {
            return new OperationOutcome(false, "", outputs);
        }
        catch (CardException e)
        {
            return new OperationOutcome(false, HandleCardError(e, reader, certificate.Sha1), outputs);
        }
        catch (NotImplementedException)
        {
            return new OperationOutcome(false, Loc.Get("Error_NotImplemented"), outputs);
        }
        catch (IOException e)
        {
            return new OperationOutcome(false, e.Message, outputs);
        }
        finally
        {
            State.SetBusy(false);
        }
    }

    public Task<OperationOutcome> VerifyAsync(string path, IReadOnlyList<string>? detachedDocs = null) => Task.Run(() =>
    {
        try
        {
            var reports = Signing.Verify(path, detachedDocs);
            var allValid = reports.Count > 0 && reports.All(r => r.Verdict == Verdict.Valid);
            Record(Path.GetFileName(path), Loc.Get("Activity_Verified"), allValid, path);
            return new OperationOutcome(allValid, Loc.Get(allValid ? "Verdict_Valid" : "Verdict_Invalid"), []);
        }
        catch (NotImplementedException)
        {
            return new OperationOutcome(false, Loc.Get("Error_NotImplemented"), []);
        }
        catch (IOException e)
        {
            return new OperationOutcome(false, e.Message, []);
        }
    });

    public async ValueTask DisposeAsync()
    {
        Readers.Dispose();
        await Bridge.DisposeAsync();
    }

    /// <summary>docs/09 §3.3 on the UI thread: drop rejected PINs, mark stuck cards, re-read swapped ones.</summary>
    private string HandleCardError(CardException e, string reader, string certificateSha1)
    {
        switch (e.Kind)
        {
            case CardErrorKind.WrongPin:
                // Never auto-retry; drop the stored PIN; show the remaining attempts next time.
                Pins.Delete(certificateSha1);
                Consent.LastRemainingAttempts = e.RemainingAttempts;
                return e.RemainingAttempts is { } n ? $"{AppState.ErrorText(e.Kind)} {Loc.Format("Pin_Attempts", n)}" : AppState.ErrorText(e.Kind);
            case CardErrorKind.PinBlocked:
                Pins.Delete(certificateSha1);
                State.MarkProblem(reader, e.Kind);
                break;
            case CardErrorKind.CardStateStuck:
                State.MarkProblem(reader, e.Kind);
                break;
            case CardErrorKind.CardChanged:
                // Another card sits in the reader now: read it, so the user sees who will sign before trying again.
                RereadCards(reader);
                break;
        }
        return AppState.ErrorText(e.Kind);
    }

    private void Record(string file, string action, bool success, string? path) =>
        _ui.TryEnqueue(() => State.AddActivity(new ActivityItem(file, action, DateTimeOffset.Now, success, path)));
}
