namespace MoldSign.Cli;

internal static class McpHost
{
    internal static int Run(IReadOnlyList<string> arguments, CliHost host)
    {
        var roots = new Dictionary<string, McpTrustedRoot>(StringComparer.Ordinal);
        WindowsMcpApprovalTransport? broker = null;
        try
        {
            var options = arguments.ToList();
            var unattended = WindowsMcpUnattendedSigner.Create(options, roots);
            var brokerIndex = options.IndexOf("--broker-directory");
            if (brokerIndex >= 0)
            {
                if (options.Count(a => a == "--broker-directory") != 1 || brokerIndex + 1 >= options.Count) throw new McpException("INVALID_ARGUMENT");
                broker = new WindowsMcpApprovalTransport(options[brokerIndex + 1]);
                roots.Add("broker-output", broker.Outputs);
                options.RemoveRange(brokerIndex, 2);
            }
            for (var i = 0; i < options.Count; i++)
            {
                if (options[i] != "--root" || ++i >= options.Count || roots.Count >= 32) throw new McpException("INVALID_ARGUMENT");
                var value = options[i];
                var split = value.IndexOf('=');
                if (split < 1 || !McpServer.Identifier(value[..split]) || value[..split] is "broker-output" or "unattended-output" || roots.ContainsKey(value[..split])) throw new McpException("INVALID_ARGUMENT");
                roots.Add(value[..split], new McpTrustedRoot(value[(split + 1)..]));
            }
            var server = new McpServer(roots, unattended, broker);
            return McpStdioSession.Run(host.In, host.Out, host.Error, server.Handle, () => broker?.Disconnect());
        }
        catch { return Fail(host, "MCP configuration or transport failed"); }
        finally { broker?.Dispose(); foreach (var root in roots.Values) root.Dispose(); }
    }
    private static int Fail(CliHost host, string message) { host.Error.WriteLine(message); return 1; }
}
