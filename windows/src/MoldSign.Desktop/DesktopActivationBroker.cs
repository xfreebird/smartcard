using System.Diagnostics;
using System.IO.Pipes;
using System.Security.Cryptography;
using System.Text;
using System.Runtime.Versioning;
using System.Text.Json;

namespace MoldSign.Desktop;

/// <summary>Per-user/session window activation and document selection; never accepts a PIN or signs.</summary>
[SupportedOSPlatform("windows")]
public sealed class DesktopActivationBroker : IDisposable, IAsyncDisposable
{
    private readonly Mutex _lifetime;
    private readonly CancellationTokenSource _shutdown = new();
    private readonly string _pipe;
    private Task? _listener;
    private readonly object _stopGate = new();
    private Task? _stop;

    public DesktopActivationBroker(string instanceKey = "MoldSign")
    {
        var user = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes($"{Environment.UserDomainName}\\{Environment.UserName}")))[..16];
        var key = $"{instanceKey}-{user}-{Process.GetCurrentProcess().SessionId}";
        _lifetime = new Mutex(false, @"Local\" + key, out var created);
        IsPrimary = created;
        _pipe = key;
    }

    public bool IsPrimary { get; }

    public void Listen(Action open) => ListenFiles(_ => open());

    public void ListenFiles(Action<IReadOnlyList<string>> open)
        => ListenCommands((_, paths) => open(paths));

    public void ListenCommands(Action<string, IReadOnlyList<string>> open)
    {
        if (!IsPrimary || _listener is not null) return;
        // Create the first pipe before returning so a secondary process can connect
        // immediately, even when the thread pool is busy during application startup.
        _listener = ListenAsync(open);
    }

    private async Task ListenAsync(Action<string, IReadOnlyList<string>> open)
    {
        while (!_shutdown.IsCancellationRequested)
        {
            try
            {
                using var server = new NamedPipeServerStream(_pipe, PipeDirection.In, 1,
                    PipeTransmissionMode.Byte, PipeOptions.Asynchronous | PipeOptions.CurrentUserOnly);
                await server.WaitForConnectionAsync(_shutdown.Token).ConfigureAwait(false);
                using var message = new MemoryStream();
                var buffer = new byte[1024];
                var complete = false;
                while (!complete && message.Length <= 32768)
                {
                    var count = await server.ReadAsync(buffer, _shutdown.Token).ConfigureAwait(false);
                    if (count == 0) break;
                    var end = Array.IndexOf(buffer, (byte)'\n', 0, count);
                    await message.WriteAsync(buffer.AsMemory(0, end < 0 ? count : end), _shutdown.Token).ConfigureAwait(false);
                    complete = end >= 0;
                }
                if (message.Length > 32768) continue;
                var line = Encoding.UTF8.GetString(message.ToArray());
                if (line == "open") open("open", Array.Empty<string>());
                else if (line is { Length: <= 32768 } && line.StartsWith("files:", StringComparison.Ordinal))
                {
                    try { open("sign", JsonSerializer.Deserialize<string[]>(line[6..]) ?? []); }
                    catch (JsonException) { }
                }
                else if (line.StartsWith("verify:", StringComparison.Ordinal))
                {
                    try { open("verify", JsonSerializer.Deserialize<string[]>(line[7..]) ?? []); }
                    catch (JsonException) { }
                }
            }
            catch (OperationCanceledException) { break; }
            catch (IOException) { /* A failed client cannot end activation listening. */ }
        }
    }

    public async Task OpenExistingAsync(CancellationToken cancellationToken)
    {
        using var client = new NamedPipeClientStream(".", _pipe, PipeDirection.Out, PipeOptions.Asynchronous);
        await client.ConnectAsync(3000, cancellationToken);
        await client.WriteAsync("open\n"u8.ToArray(), cancellationToken);
        await client.FlushAsync(cancellationToken);
    }

    public async Task OpenFilesAsync(IReadOnlyList<string> paths, CancellationToken cancellationToken)
        => await OpenCommandAsync("sign", paths, cancellationToken);

    public async Task OpenCommandAsync(string action, IReadOnlyList<string> paths, CancellationToken cancellationToken)
    {
        var prefix = action == "verify" ? "verify:" : "files:";
        var command = prefix + JsonSerializer.Serialize(paths) + "\n";
        if (command.Length > 32768) throw new ArgumentException("Too many document paths.", nameof(paths));
        using var client = new NamedPipeClientStream(".", _pipe, PipeDirection.Out, PipeOptions.Asynchronous);
        await client.ConnectAsync(3000, cancellationToken);
        await client.WriteAsync(Encoding.UTF8.GetBytes(command), cancellationToken);
        await client.FlushAsync(cancellationToken);
    }

    public void Dispose() => DisposeAsync().AsTask().GetAwaiter().GetResult();

    public ValueTask DisposeAsync()
    {
        lock (_stopGate) return new ValueTask(_stop ??= StopAsync());
    }

    private async Task StopAsync()
    {
        try
        {
            await _shutdown.CancelAsync().ConfigureAwait(false);
            if (_listener is not null) await _listener.ConfigureAwait(false);
        }
        finally { _shutdown.Dispose(); _lifetime.Dispose(); }
    }
}
