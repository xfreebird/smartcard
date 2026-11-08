using System.Text;
using System.Text.Json.Nodes;

namespace MoldSign.Cli;

/// <summary>Private local spool. Only this process's jobs are visible to its MCP client.</summary>
internal sealed class WindowsMcpApprovalTransport : IDisposable
{
    private readonly McpTrustedRoot directory, requests, responses;
    internal McpTrustedRoot Outputs { get; }
    private readonly HashSet<string> jobs = new(StringComparer.Ordinal);
    private readonly HashSet<string> cancellations = new(StringComparer.Ordinal);
    internal static readonly string[] States = ["awaiting_user", "signing", "completed", "failed", "cancelled", "expired"];
    internal static readonly string[] ErrorCodes = ["BUSY", "NO_CARD", "CARD_CHANGED", "USER_CANCELLED", "EXPIRED", "PIN_INCORRECT", "PIN_BLOCKED", "NETWORK_FAILED", "OUTCOME_UNKNOWN", "SIGNING_FAILED"];
    public WindowsMcpApprovalTransport(string path)
    {
        directory = new McpTrustedRoot(path, privateDirectory: true);
        try
        {
            requests = new McpTrustedRoot(Path.Combine(path, "requests"), privateDirectory: true);
            responses = new McpTrustedRoot(Path.Combine(path, "responses"), privateDirectory: true);
            Outputs = new McpTrustedRoot(Path.Combine(path, "outputs"), privateDirectory: true);
        }
        catch { directory.Dispose(); requests?.Dispose(); responses?.Dispose(); throw; }
    }
    public JsonObject Prepare(byte[] pdf, string name)
    {
        if (jobs.Count >= 16) throw new McpException("LIMIT_EXCEEDED");
        if (pdf.Length > 8 * 1024 * 1024) throw new McpException("LIMIT_EXCEEDED");
        if (!pdf.AsSpan().StartsWith("%PDF-"u8)) throw new McpException("UNSUPPORTED");
        var id = Guid.NewGuid().ToString("D");
        requests.Publish(id + ".json", Encoding.UTF8.GetBytes(McpServer.Encode(new JsonObject {
            ["schemaVersion"] = 1, ["operation"] = "prepare", ["jobId"] = id, ["name"] = name, ["pdf"] = Convert.ToBase64String(pdf) })));
        jobs.Add(id);
        return new JsonObject { ["jobId"] = id, ["state"] = "awaiting_user" };
    }
    public JsonObject Job(string id, bool cancel)
    {
        if (!jobs.Contains(id)) throw new McpException("UNKNOWN_JOB");
        if (cancel && !cancellations.Contains(id))
        {
            requests.Publish(id + "-cancel.json", Encoding.UTF8.GetBytes(McpServer.Encode(new JsonObject {
                ["schemaVersion"] = 1, ["operation"] = "cancel", ["jobId"] = id })));
            cancellations.Add(id);
        }
        var result = new JsonObject { ["jobId"] = id, ["state"] = "awaiting_user", ["cancellationRequested"] = cancellations.Contains(id) };
        byte[] bytes;
        try { bytes = responses.Read(id + ".json", 8192, privateFile: true); }
        catch (McpException e) when (e.Code == "PATH_DENIED") { return result; }
        JsonObject value;
        try { value = JsonNode.Parse(bytes, documentOptions: new() { MaxDepth = 8 })!.AsObject(); }
        catch { throw new McpException("BROKER_UNAVAILABLE"); }
        if (value["schemaVersion"]?.ToString() != "1" || value["jobId"]?.ToString() != id ||
            value["state"] is not JsonValue stateValue || !stateValue.TryGetValue<string>(out var state) || !States.Contains(state))
            throw new McpException("BROKER_UNAVAILABLE");
        result["state"] = state;
        foreach (var key in new[] { "inputSHA256", "outputSHA256" })
            if (value[key] is JsonValue hashValue && hashValue.TryGetValue<string>(out var hash) && hash.Length == 64 && hash.All(c => "0123456789abcdef".Contains(c))) result[key] = hash;
        if (value["errorCode"] is JsonValue errorValue && errorValue.TryGetValue<string>(out var error) && ErrorCodes.Contains(error)) result["errorCode"] = error;
        if (state == "completed") result["output"] = new JsonObject { ["rootId"] = "broker-output", ["relativePath"] = id + ".pdf" };
        return result;
    }
    public void Disconnect() { foreach (var id in jobs) { try { Job(id, true); } catch { } } }
    public void Dispose() { Disconnect(); Outputs.Dispose(); responses.Dispose(); requests.Dispose(); directory.Dispose(); }
}
