using System.Text;

namespace MoldSign.Cli;

internal static class McpHost
{
    internal static int Run(IReadOnlyList<string> arguments, CliHost host)
    {
        var roots = new Dictionary<string, McpTrustedRoot>(StringComparer.Ordinal);
        try
        {
            var options = arguments.ToList();
            var unattended = WindowsMcpUnattendedSigner.Create(options, roots);
            for (var i = 0; i < options.Count; i++)
            {
                if (options[i] != "--root" || ++i >= options.Count || roots.Count >= 32) throw new McpException("INVALID_ARGUMENT");
                var value = options[i];
                var split = value.IndexOf('=');
                if (split < 1 || !McpServer.Identifier(value[..split]) || roots.ContainsKey(value[..split])) throw new McpException("INVALID_ARGUMENT");
                roots.Add(value[..split], new McpTrustedRoot(value[(split + 1)..]));
            }
            var server = new McpServer(roots, unattended);
            var frame = new StringBuilder();
            while (true)
            {
                var next = host.In.Read();
                if (next == -1) return frame.Length == 0 ? 0 : Fail(host, "Incomplete MCP frame");
                if (next != '\n')
                {
                    if (frame.Length >= McpServer.MaxFrame) return Fail(host, "MCP frame exceeds limit");
                    frame.Append((char)next);
                    continue;
                }
                var line = frame.ToString().TrimEnd('\r');
                frame.Clear();
                if (Encoding.UTF8.GetByteCount(line) > McpServer.MaxFrame) return Fail(host, "MCP frame exceeds limit");
                var operation = Task.Run(() => server.Handle(line));
                if (!operation.Wait(TimeSpan.FromSeconds(unattended is null ? 30 : 120))) return Fail(host, "MCP operation exceeded deadline");
                if (operation.Result is { } reply) { host.Out.WriteLine(reply); host.Out.Flush(); }
            }
        }
        catch { return Fail(host, "MCP configuration or transport failed"); }
        finally { foreach (var root in roots.Values) root.Dispose(); }
    }
    private static int Fail(CliHost host, string message) { host.Error.WriteLine(message); return 1; }
}
