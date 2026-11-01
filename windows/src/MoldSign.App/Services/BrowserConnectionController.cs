using MoldSign.Core;

namespace MoldSign.App.Services;

public interface IBrowserConnectionController
{
    Task SetEnabledAsync(bool enabled);
    Task ImportIdentityAsync(string path);
}

/// <summary>Browser lifecycle and identity installation, independent of document batches and reader discovery.</summary>
internal sealed class BrowserConnectionController(BridgeHost bridge, AppSettings preferences,
    Action<bool, string> publish, bool preview) : IBrowserConnectionController, IDisposable
{
    private CancellationTokenSource? _recovery;
    private bool _portBusy;
    private readonly SemaphoreSlim _control = new(1);
    private bool _disposed;

    public async Task SetEnabledAsync(bool enabled)
    {
        await _control.WaitAsync();
        try
        {
            if (_disposed) return;
            _recovery?.Cancel();
            _recovery?.Dispose();
            _recovery = null;
            await ApplyEnabledAsync(enabled);
            if (enabled && _portBusy)
            {
                _recovery = new CancellationTokenSource();
                _ = RecoverAsync(_recovery.Token);
            }
        }
        finally { _control.Release(); }
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

    public void Dispose() { _disposed = true; _recovery?.Cancel(); _recovery?.Dispose(); _recovery = null; }

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
        if (preview) return;
        try
        {
            var certificates = BridgeTls.Load(path);
            foreach (var certificate in certificates) certificate.Dispose();
            var destination = BridgeTls.IdentityPath;
            Directory.CreateDirectory(Path.GetDirectoryName(destination)!);
            if (!string.Equals(Path.GetFullPath(path), Path.GetFullPath(destination), StringComparison.OrdinalIgnoreCase))
                File.Copy(path, destination, overwrite: true);
            if (preferences.BridgeEnabled) { await bridge.StopAsync(); await SetEnabledAsync(true); }
            else publish(false, Loc.Get("Bridge_IdentityImported"));
        }
        catch (Exception error) { AppLog.Error(error); publish(preferences.BridgeEnabled, Loc.Get("Bridge_IdentityInvalid")); }
    }
}
