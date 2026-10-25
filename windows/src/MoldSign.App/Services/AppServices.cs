using System.Diagnostics;
using Microsoft.UI.Dispatching;
using Microsoft.UI.Xaml;
using MoldSign.Core;

namespace MoldSign.App.Services;

/// <summary>Result of a UI-triggered operation, ready for an InfoBar.</summary>
public sealed record OperationOutcome(bool Success, string Message, IReadOnlyList<string> Outputs);

/// <summary>
/// Composition root of the tray app: SigningService (Core) + ReaderWatcher + PinVault + BridgeHost +
/// ConsentCoordinator. Card work runs on the thread pool; AppState is only touched on the UI thread.
/// </summary>
public sealed class AppServices : IAsyncDisposable
{
    private readonly DispatcherQueue _ui;
    private string? _holderReadFor;

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
        // First reader with a card; the WinRT reader name and the PC/SC name can differ in format.
        Signing = new SigningService(() => WinSCardTransport.Connect(new WinSCardOptions()),
                                     trace: line => Debug.WriteLine($"[card] {line}"));
        Bridge = new BridgeHost(BridgeOriginPolicy.Default, tlsPfxPath: () => null /* TODO(WIN-06) */);

        Signing.ReaderStateChanged += (_, state) => _ui.TryEnqueue(() => AppState.Current.Apply(state));
        Readers.Changed += OnReadersChanged;
    }

    public AppSettings Settings { get; }
    public PinVault Pins { get; }
    public ReaderWatcher Readers { get; }
    public ConsentCoordinator Consent { get; }
    public SigningService Signing { get; }
    public BridgeHost Bridge { get; }

    public void Start()
    {
        Readers.Start();
        _ = SetBridgeEnabledAsync(Settings.BridgeEnabled);
        // TODO(WIN-04): apply Settings.StartAtLogin.
    }

    public async Task SetBridgeEnabledAsync(bool enabled)
    {
        try
        {
            if (enabled) await Bridge.StartAsync();
            else await Bridge.StopAsync();
            AppState.Current.BridgeStatus = Loc.Get(enabled ? "Bridge_On" : "Bridge_Off");
        }
        catch (IOException e)
        {
            // Port taken, typically by the vendor Java server.
            Debug.WriteLine($"bridge: {e.Message}");
            enabled = false;
            AppState.Current.BridgeStatus = Loc.Format("Bridge_PortBusy", BridgeProtocol.HttpPort);
        }
        AppState.Current.BridgeEnabled = enabled;
        Settings.BridgeEnabled = enabled;
        Settings.Save();
    }

    /// <summary>Format auto-pick (PLAN §2): PDF → PAdES-T, everything else → XAdES-T detached.</summary>
    public Task<OperationOutcome> SignFilesAsync(IReadOnlyList<string> paths) => Task.Run(() =>
    {
        var outputs = new List<string>();
        try
        {
            foreach (var path in paths)
            {
                SignResult result = string.Equals(Path.GetExtension(path), ".pdf", StringComparison.OrdinalIgnoreCase)
                    ? Signing.SignPdf(path, SigningService.DefaultOutputPath(path), Consent.Request)
                    : Signing.SignXades([path], XadesFormat.T, XadesPackaging.Detached,
                                        SigningService.DefaultOutputPath(path, ".xml"), Consent.Request);
                outputs.AddRange(result.OutputFiles);
                Record(Path.GetFileName(path), Loc.Get("Activity_Signed"), true, result.OutputFiles.FirstOrDefault());
            }
            Consent.LastRemainingAttempts = null;
            return new OperationOutcome(true, Loc.Format("Sign_Done", outputs.Count), outputs);
        }
        catch (CardException e) when (e.Kind == CardErrorKind.WrongPin)
        {
            // Never auto-retry; drop the stored PIN; show the remaining attempts next time.
            if (Consent.LastCertificateSha1 is { } sha1) Pins.Delete(sha1);
            Consent.LastRemainingAttempts = e.RemainingAttempts;
            return new OperationOutcome(false, e.RemainingAttempts is { } n
                ? Loc.Format("Pin_Attempts", n)
                : AppState.ErrorText(e.Kind), outputs);
        }
        catch (CardException e) when (e.Kind == CardErrorKind.Cancelled)
        {
            return new OperationOutcome(false, "", outputs);
        }
        catch (CardException e)
        {
            return new OperationOutcome(false, AppState.ErrorText(e.Kind), outputs);
        }
        catch (NotImplementedException)
        {
            return new OperationOutcome(false, Loc.Get("Error_NotImplemented"), outputs);
        }
        catch (IOException e)
        {
            return new OperationOutcome(false, e.Message, outputs);
        }
    });

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

    private void OnReadersChanged(object? sender, IReadOnlyList<ReaderSnapshot> readers)
    {
        if (readers.Count == 0)
        {
            _holderReadFor = null;
            Signing.PublishReaderState(new ReaderState.NoReader());
            return;
        }

        var withCard = readers.FirstOrDefault(r => r.CardPresent);
        if (withCard is null)
        {
            _holderReadFor = null;
            Signing.PublishReaderState(new ReaderState.Empty(readers[0].Name));
            return;
        }

        if (_holderReadFor == withCard.Name) return; // already greeted this insertion
        _holderReadFor = withCard.Name;
        Signing.PublishReaderState(new ReaderState.CardPresent(withCard.Name, null));

        // docs/09 §3.7: PIN-less certificate read so the UI can greet the holder (full mutual auth, card lock).
        _ = Task.Run(() =>
        {
            try
            {
                var certificate = Signing.Certificate();
                Signing.PublishReaderState(new ReaderState.CardPresent(withCard.Name, certificate.CommonName, certificate));
            }
            catch (CardException e)
            {
                Debug.WriteLine($"certificate read failed: {e.Kind}: {e.Message}");
            }
        });
    }

    private void Record(string file, string action, bool success, string? path) =>
        _ui.TryEnqueue(() => AppState.Current.AddActivity(new ActivityItem(file, action, DateTimeOffset.Now, success, path)));
}
