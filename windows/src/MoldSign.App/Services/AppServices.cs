using System.Diagnostics;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using MoldSign.Core;
using MoldSign.Desktop;

namespace MoldSign.App.Services;

/// <summary>Result of a UI-triggered operation, ready for an InfoBar.</summary>
public sealed record OperationOutcome(bool Success, string Message, IReadOnlyList<string> Outputs)
{
    public IReadOnlyList<VerificationReport>? Reports { get; init; }
    public IReadOnlyList<string> CompletedInputs { get; init; } = [];
    public string? FailedInput { get; init; }
}

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
    private IReadOnlyList<CardEntry> _bridgeCards = [];
    private int _busyCount;
    private int _activeOperations;
    private volatile bool _disposed;
    private readonly DemoSession? _demo;
    private bool _demoSelectionApplied;
    private readonly IDocumentSigner _documentSigner;
    private readonly IDocumentVerifier _verifier;
    private readonly DocumentBatchSigner _batches;
    private readonly Func<string, Task<CertificateSummary>> _certificates;
    private readonly ConsentProvider _authorize;

    /// <param name="ui">UI-thread dispatcher.</param>
    /// <param name="ownerWindow">HWND owning the Windows Hello prompt.</param>
    public AppServices(DispatcherQueue ui, Func<nint> ownerWindow, AppServiceDependencies? dependencies = null)
    {
        dependencies ??= new AppServiceDependencies();
        _ui = ui;
        Settings = AppSettings.Load();
        Readers = DemoMode.Scenario is { } scenario ? new DemoReaderSource(scenario) : dependencies.Readers ?? new ReaderWatcher();
        Pins = Readers is DemoReaderSource ? new DemoPinVault() : dependencies.Pins ?? new PinVault(ownerWindow);
        Consent = new ConsentCoordinator(ui, Pins, Settings);
        // Every operation names its PC/SC reader (the wallet selection); null = the first reader with a card.
        _demo = Readers is DemoReaderSource ? new DemoSession() : null;
        Func<string?, ICardTransport> transport = IsDemo
            ? _ => throw new InvalidOperationException("Demo mode never opens a card transport.")
            : dependencies.Transport ?? (reader => WinSCardTransport.Connect(new WinSCardOptions { ReaderName = reader }));
        Signing = new SigningService(transport);
        _documentSigner = IsDemo ? _demo! : dependencies.Documents ?? Signing;
        _verifier = IsDemo ? _demo! : dependencies.Verifier ?? Signing;
        _certificates = dependencies.Certificates ?? (reader => Task.Run(() => Signing.Certificate(reader)));
        var authorization = dependencies.Authorize ?? Consent.Request;
        _authorize = IsDemo ? _ => throw new InvalidOperationException("Demo mode never requests a real PIN.")
            : request => _disposed ? ConsentResult.Cancelled : authorization(request);
        _batches = new DocumentBatchSigner(_documentSigner);
        Bridge = new BridgeHost(BridgeOriginPolicy.Default, BridgeTls.ResolvePath,
            () => Volatile.Read(ref _bridgeCards), Signing, _authorize,
            allowsLegacyDesktopClient: Settings.LegacyDesktopClientEnabled && !StartupRegistration.IsPackaged);
        BrowserConnection = IsDemo || dependencies.BrowserConnection is null ? new BrowserConnectionController(Bridge, Settings, (enabled, status) =>
        {
            if (_disposed) return;
            State.BridgeEnabled = enabled;
            State.BridgeStatus = status;
        }, IsDemo) : dependencies.BrowserConnection;
        State.WalletChanged += OnWalletChanged;
        Bridge.SigningStarted += (_, _) =>
        {
            Interlocked.Increment(ref _activeOperations);
            _ui.TryEnqueue(() => { if (!_disposed) SetBusy(true); });
        };
        Bridge.Completed += (_, outcome) =>
        {
            Interlocked.Decrement(ref _activeOperations);
            _ui.TryEnqueue(() =>
        {
            if (_disposed) return;
            SetBusy(false);
            var host = Uri.TryCreate(outcome.Origin, UriKind.Absolute, out var uri) ? uri.Host : "localhost";
            var action = outcome.Error is CardException error
                ? HandleCardError(error, outcome.Card.Reader, outcome.Card.Certificate.Sha1)
                : outcome.Error is null ? Loc.Get("Activity_Signed") : Loc.Get("Error_Generic");
            State.AddActivity(new ActivityItem(host, $"{action} · {outcome.Format}",
                DateTimeOffset.Now, outcome.Error is null, null));
        });
        };

        Signing.Progress += (_, step) => _ui.TryEnqueue(() => State.SetStep(step));
        Readers.Changed += (_, slots) => _ui.TryEnqueue(() => { if (!_disposed) OnReadersChanged(slots); });
    }

    public event EventHandler? CardInserted;
    private readonly MoldSign.Desktop.InsertionActivationPolicy _activationPolicy = new();

    public AppSettings Settings { get; }
    internal UpdateChecker Updates { get; } = new();
    public IPinVault Pins { get; }
    public IReaderSource Readers { get; }
    public bool IsDemo => Readers is DemoReaderSource;
    public bool IsOperationActive => State.IsBusy || Volatile.Read(ref _activeOperations) > 0;
    public IReadOnlyList<string> DemoDocuments => _demo?.Documents ?? [];
    public bool IsDemoDocument(string path) => _demo?.Owns(path) == true;
    private void OnWalletChanged(object? sender, EventArgs args) => Volatile.Write(ref _bridgeCards, State.BridgeCards);
    public ConsentCoordinator Consent { get; }
    public SigningService Signing { get; }
    public BridgeHost Bridge { get; }
    public IBrowserConnectionController BrowserConnection { get; }

    private static AppState State => AppState.Current;

    public void Start()
    {
        State.ResetSession(IsDemo);
        if (!IsDemo) State.LoadActivity(); // demo does not expose real document history
        Readers.Start();
        if (!IsDemo) Updates.Start();
        if (!IsDemo) _ = SetBridgeEnabledAsync(Settings.BridgeEnabled);
    }

    public Task SetBridgeEnabledAsync(bool enabled) => BrowserConnection.SetEnabledAsync(enabled);
    public Task ImportBridgeIdentityAsync(string source) => BrowserConnection.ImportIdentityAsync(source);

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
        try
        {
            var inserted = _activationPolicy.Update(slots.Select(slot =>
                new ReaderStatus(slot.Name, slot.State != SlotState.Empty, slot.State == SlotState.Mute, slot.Generation)).ToArray(), Settings);
            foreach (var card in State.ApplySlots(slots)) _ = ReadCertificateAsync(card);
            if (IsDemo && !_demoSelectionApplied)
            {
                _demoSelectionApplied = true;
                var selected = int.TryParse(Environment.GetEnvironmentVariable("MSIGN_DEMO_SELECTED"), out var index) ? index : 0;
                if (DemoMode.Scenario == "multiple-second") selected = 1;
                var cards = State.WalletItems.Where(item => item.Kind == WalletItemKind.Card).ToList();
                if (cards.Count > 0 && cards[Math.Clamp(selected, 0, cards.Count - 1)].Reader is { } reader) State.Select(reader);
            }
            if (inserted) CardInserted?.Invoke(this, EventArgs.Empty);
        }
        catch (Exception error)
        {
            AppLog.Error(error);
            throw;
        }
    }

    /// <summary>docs/09 §3.7: PIN-less certificate read so the wallet can greet the holder (full mutual auth, card lock).</summary>
    private async Task ReadCertificateAsync(WalletCard card)
    {
        if (IsDemo)
        {
            var scenario = DemoMode.Scenario;
            if (scenario == "reading") return;
            if (scenario == "blocked") State.FailRead(card, CardErrorKind.PinBlocked);
            else if (scenario == "stuck") State.FailRead(card, CardErrorKind.CardStateStuck);
            else State.CompleteRead(card, DemoReaderSource.Certificate(card.Reader));
            if (scenario == "signing") State.SetBusy(true);
            return;
        }
        Interlocked.Increment(ref _activeOperations);
        try
        {
            var certificate = await _certificates(card.Reader);
            if (_disposed) return;
            State.CompleteRead(card, certificate); // ignored when the card changed meanwhile
        }
        catch (CardException e)
        {
            Debug.WriteLine($"certificate read failed in {card.Reader}: {e.Kind}: {e.Message}");
            // Removed while reading: the next reader snapshot drops the card anyway.
            if (!_disposed && e.Kind is not (CardErrorKind.NoCard or CardErrorKind.NoReader)) State.FailRead(card, e.Kind);
        }
        catch (Exception e)
        {
            AppLog.Error(e);
            if (!_disposed) State.FailRead(card, CardErrorKind.CardNotResponding);
        }
        finally { Interlocked.Decrement(ref _activeOperations); }
    }

    // MARK: - Signing

    /// <summary>Tray flyout "Semnează…": each file in its default format (PDF → PAdES-T, others → XAdES-T detached).</summary>
    public Task<OperationOutcome> SignFilesAsync(IReadOnlyList<string> paths) =>
        SignDocumentsAsync([.. paths.Select(p => new DocumentJob(p, SignatureFormats.Default(p)))], XadesPackaging.Detached);

    /// <summary>
    /// Signs with the selected wallet card, each document in its chosen format (a PDF can also get XAdES, written as
    /// <c>&lt;name&gt;-semnat.xml</c>). One scoped consent/PIN for the frozen batch; the certificate is checked for every file.
    /// </summary>
    public async Task<OperationOutcome> SignDocumentsAsync(IReadOnlyList<DocumentJob> jobs, XadesPackaging packaging)
    {
        if (IsDemo && jobs.Any(job => !IsDemoDocument(job.Path)))
            return new OperationOutcome(false, Loc.Get("demo_fixture_only"), []);
        var frozenJobs = jobs.ToArray();
        if (frozenJobs.Length == 0) return new OperationOutcome(false, "", []);
        if (State.SelectedReader is not { } reader || State.Certificate is not { } certificate || !State.CanSign)
            return new OperationOutcome(false, State.LightLabel, []);

        var outputs = new List<string>();
        var completedInputs = new List<string>();
        OperationOutcome Outcome(bool success, string message, bool failed = true) => new(success, message, outputs)
        {
            CompletedInputs = completedInputs.ToArray(),
            FailedInput = !success && failed ? frozenJobs.FirstOrDefault(job => !completedInputs.Contains(job.Path))?.Path : null,
        };
        try
        {
            SetBusy(true);
            await Task.Run(() =>
            {
                var result = _batches.Sign(frozenJobs.Select(job => new SigningDocumentJob(job.Path, job.Format)).ToArray(),
                    reader, certificate.Sha1, packaging, _authorize, (job, signed) =>
                    {
                        outputs.AddRange(signed.OutputFiles);
                        completedInputs.Add(job.Path);
                        Record(Path.GetFileName(job.Path), IsDemo ? Loc.Get("demo_sign_success") : $"{Loc.Get("Activity_Signed")} · {SignatureFormats.Label(job.Format)}",
                            true, signed.OutputFiles.FirstOrDefault());
                    });
                if (result.Error is { } failure) System.Runtime.ExceptionServices.ExceptionDispatchInfo.Capture(failure).Throw();
            });
            Consent.LastRemainingAttempts = null;
            return Outcome(true, IsDemo ? Loc.Get("demo_sign_success") : Loc.Format("Sign_Done", outputs.Count));
        }
        catch (CardException e) when (e.Kind == CardErrorKind.Cancelled)
        {
            return Outcome(false, "", failed: false);
        }
        catch (CardException e)
        {
            return Outcome(false, HandleCardError(e, reader, certificate.Sha1));
        }
        catch (DocumentBatchBusyException)
        {
            return Outcome(false, Loc.Get("Light_Busy"), failed: false);
        }
        catch (NotImplementedException)
        {
            return Outcome(false, Loc.Get("Error_NotImplemented"));
        }
        catch (IOException e)
        {
            return Outcome(false, e.Message);
        }
        catch (Exception e)
        {
            AppLog.Error(e);
            return Outcome(false, Loc.Get("Error_Generic"));
        }
        finally
        {
            if (!IsDemo && outputs.Count > 0) _ = TaskbarActions.RefreshAsync(outputs.ToArray());
            SetBusy(false);
        }
    }

    public Task<OperationOutcome> VerifyAsync(string path, IReadOnlyList<string>? detachedDocs = null)
    {
        if (IsDemo && (!IsDemoDocument(path) || detachedDocs?.Any(file => !IsDemoDocument(file)) == true))
            return Task.FromResult(new OperationOutcome(false, Loc.Get("demo_fixture_only"), []));
        Interlocked.Increment(ref _activeOperations);
        return Task.Run(() =>
    {
        try
        {
            var reports = _verifier.Verify(path, detachedDocs);
            var verdict = Validator.OverallVerdict(reports);
            var allValid = verdict == Verdict.Valid;
            Record(Path.GetFileName(path), IsDemo ? Loc.Get("demo_verify_success") : Loc.Get("Activity_Verified"), allValid, path);
            var key = verdict switch
            {
                Verdict.Valid => "Verdict_Valid",
                Verdict.Invalid => "Verdict_Invalid",
                Verdict.Indeterminate => "Verdict_Unknown",
                _ => "Verdict_Unsigned",
            };
            return new OperationOutcome(allValid, IsDemo ? Loc.Get("demo_verify_success") : Loc.Get(key), []) { Reports = reports };
        }
        catch (NotImplementedException)
        {
            return new OperationOutcome(false, Loc.Get("Error_NotImplemented"), []);
        }
        catch (IOException e)
        {
            return new OperationOutcome(false, e.Message, []);
        }
        catch (Exception e)
        {
            AppLog.Error(e);
            return new OperationOutcome(false, Loc.Get("Verify_Failed"), []);
        }
        finally { Interlocked.Decrement(ref _activeOperations); }
    });
    }

    public async ValueTask DisposeAsync()
    {
        _disposed = true;
        Updates.Stop();
        State.WalletChanged -= OnWalletChanged;
        Readers.Dispose();
        Consent.CancelPending();
        (BrowserConnection as IDisposable)?.Dispose();
        await Bridge.DisposeAsync();
        // Old in-flight reads / browser work must finish before a new service generation is visible.
        while (Volatile.Read(ref _activeOperations) > 0) await Task.Delay(25);
        _demo?.Dispose();
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
        _ui.TryEnqueue(() => { if (!_disposed) State.AddActivity(new ActivityItem(file, action, DateTimeOffset.Now, success, path)); });

    private void SetBusy(bool busy)
    {
        _busyCount = Math.Max(0, _busyCount + (busy ? 1 : -1));
        State.SetBusy(_busyCount > 0);
    }
}
