using System.Diagnostics;
using System.IO.Pipes;
using System.Security.Cryptography;
using System.Text;
using System.Runtime.Versioning;

namespace MoldSign.Desktop;

/// <summary>Per-user/session activation only. It accepts no document, PIN or signing instruction.</summary>
[SupportedOSPlatform("windows")]
public sealed class DesktopActivationBroker : IDisposable
{
    private readonly Mutex _lifetime;
    private readonly CancellationTokenSource _shutdown = new();
    private readonly string _pipe;
    private Task? _listener;

    public DesktopActivationBroker(string instanceKey = "MoldSign")
    {
        var user = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes($"{Environment.UserDomainName}\\{Environment.UserName}")))[..16];
        var key = $"{instanceKey}-{user}-{Process.GetCurrentProcess().SessionId}";
        _lifetime = new Mutex(false, @"Local\" + key, out var created);
        IsPrimary = created;
        _pipe = key;
    }

    public bool IsPrimary { get; }

    public void Listen(Action open)
    {
        if (!IsPrimary || _listener is not null) return;
        // Create the first pipe before returning so a secondary process can connect
        // immediately, even when the thread pool is busy during application startup.
        _listener = ListenAsync(open);
    }

    private async Task ListenAsync(Action open)
    {
        while (!_shutdown.IsCancellationRequested)
        {
            try
            {
                using var server = new NamedPipeServerStream(_pipe, PipeDirection.In, 1,
                    PipeTransmissionMode.Byte, PipeOptions.Asynchronous | PipeOptions.CurrentUserOnly);
                await server.WaitForConnectionAsync(_shutdown.Token).ConfigureAwait(false);
                var buffer = new byte[16];
                var count = await server.ReadAsync(buffer, _shutdown.Token).ConfigureAwait(false);
                if (Encoding.UTF8.GetString(buffer, 0, count) == "open") open();
            }
            catch (OperationCanceledException) { break; }
            catch (IOException) { /* A failed client cannot end activation listening. */ }
        }
    }

    public async Task OpenExistingAsync(CancellationToken cancellationToken)
    {
        using var client = new NamedPipeClientStream(".", _pipe, PipeDirection.Out, PipeOptions.Asynchronous);
        await client.ConnectAsync(3000, cancellationToken);
        await client.WriteAsync("open"u8.ToArray(), cancellationToken);
        await client.FlushAsync(cancellationToken);
    }

    public void Dispose()
    {
        _shutdown.Cancel();
        _lifetime.Dispose();
    }
}
