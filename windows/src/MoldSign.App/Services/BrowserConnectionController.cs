using MoldSign.Core;

namespace MoldSign.App.Services;

public interface IBrowserConnectionController
{
    Task SetEnabledAsync(bool enabled);
    Task ImportIdentityAsync(string path);
}

/// <summary>Browser lifecycle and identity installation, independent of document batches and reader discovery.</summary>
internal sealed class BrowserConnectionController(BridgeHost bridge, AppSettings preferences,
    Action<bool, string> publish, bool preview) : IBrowserConnectionController, IAsyncDisposable
{
    private CancellationTokenSource? _recovery;
    private Task? _recoveryTask;
    private bool _portBusy;
    private readonly SemaphoreSlim _control = new(1);
    private bool _disposed;

    public async Task SetEnabledAsync(bool enabled)
    {
        await _control.WaitAsync(CancellationToken.None);
        try
        {
            if (_disposed) return;
            await StopRecoveryAsync();
            await ApplyEnabledAsync(enabled);
            StartRecoveryIfNeeded();
        }
        finally { _control.Release(); }
    }

    // _control is held by the caller; recovery itself waits asynchronously for it.
    private void StartRecoveryIfNeeded()
    {
        if (_disposed || !_portBusy || !preferences.BridgeEnabled) return;
        _recovery = new CancellationTokenSource();
        _recoveryTask = RecoverAsync(_recovery.Token);
    }

    private async Task RecoverAsync(CancellationToken token)
    {
        try
        {
            while (!token.IsCancellationRequested && _portBusy && preferences.BridgeEnabled)
            {
                await Task.Delay(TimeSpan.FromSeconds(5), token);
                await _control.WaitAsync(token);
                try { if (!token.IsCancellationRequested && !_disposed && preferences.BridgeEnabled) await ApplyEnabledAsync(true); }
                finally { _control.Release(); }
            }
        }
        catch (OperationCanceledException) { }
    }

    // Called with _control held. A cancelled recovery never waits for that semaphore again.
    private async Task StopRecoveryAsync()
    {
        if (_recovery is null) return;
        try
        {
            await Task.WhenAll(_recovery.CancelAsync(), _recoveryTask ?? Task.CompletedTask);
        }
        finally
        {
            _recovery.Dispose();
            _recovery = null;
            _recoveryTask = null;
        }
    }

    public async ValueTask DisposeAsync()
    {
        await _control.WaitAsync(CancellationToken.None);
        try { _disposed = true; await StopRecoveryAsync(); }
        finally { _control.Release(); }
    }

    private async Task ApplyEnabledAsync(bool enabled)
    {
        _portBusy = false;
        if (preview) { publish(enabled, Loc.Get("demo_mode_disclaimer")); return; }
        string status;
        try
        {
            if (enabled) await bridge.StartAsync(); else await bridge.StopAsync();
            status = Loc.Get(enabled ? "Bridge_On" : "Bridge_Off");
        }
        catch (FileNotFoundException error) { AppLog.Error(error); status = Loc.Get("Bridge_IdentityMissing"); }
        catch (System.Security.Cryptography.CryptographicException error) { AppLog.Error(error); status = Loc.Get("Bridge_IdentityInvalid"); }
        catch (IOException error) when (error.InnerException is Microsoft.AspNetCore.Connections.AddressInUseException)
        { _portBusy = true; status = Loc.Format("Bridge_PortBusy", $"{BridgeProtocol.HttpPort}/{BridgeProtocol.HttpsPort}"); }
        catch (Exception error) { AppLog.Error(error); status = Loc.Format("Bridge_Error", error.Message); }
        preferences.BridgeEnabled = enabled;
        preferences.Save();
        publish(enabled, status);
    }

    public async Task ImportIdentityAsync(string path)
    {
        await _control.WaitAsync(CancellationToken.None);
        try
        {
            if (preview || _disposed) return;
            await StopRecoveryAsync();
            var certificates = BridgeTls.Load(path);
            foreach (var certificate in certificates) certificate.Dispose();
            var destination = BridgeTls.IdentityPath;
            Directory.CreateDirectory(Path.GetDirectoryName(destination)!);
            if (!string.Equals(Path.GetFullPath(path), Path.GetFullPath(destination), StringComparison.OrdinalIgnoreCase))
                File.Copy(path, destination, overwrite: true);
            if (preferences.BridgeEnabled)
            {
                await bridge.StopAsync();
                await ApplyEnabledAsync(true);
                StartRecoveryIfNeeded();
            }
            else publish(false, Loc.Get("Bridge_IdentityImported"));
        }
        catch (Exception error) { AppLog.Error(error); publish(preferences.BridgeEnabled, Loc.Get("Bridge_IdentityInvalid")); }
        finally { _control.Release(); }
    }
}
