using System.Security.AccessControl;
using System.Security.Principal;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Nodes;
using MoldSign.Cli;
using MoldSign.Core;

namespace MoldSign.App.Services;

/// <summary>Opt-in private spool; the app owns approval, certificate selection and card access.</summary>
internal sealed class McpApprovalBroker : IAsyncDisposable
{
    internal static string DefaultDirectory => Path.Combine(Path.GetDirectoryName(AppSettings.PreferencesPath)!, "MCP");
    private readonly McpTrustedRoot directory, requests, responses, outputs;
    private readonly Func<byte[], string, CancellationToken, Action, Task<byte[]>> sign;
    private readonly CancellationTokenSource shutdown = new();
    private readonly Task loop;
    private readonly FileStream lease;
    private readonly HashSet<string> seen = new(StringComparer.Ordinal);
    private Task? active;
    private string? activeId;
    private CancellationTokenSource? activeCancellation;
    internal McpApprovalBroker(Func<byte[], string, CancellationToken, Action, Task<byte[]>> sign)
    {
        this.sign = sign;
        CreatePrivate(DefaultDirectory);
        directory = new McpTrustedRoot(DefaultDirectory, privateDirectory: true);
        try
        {
            lease = directory.AcquireLease(".broker-lease");
            foreach (var child in new[] { "requests", "responses", "outputs", "staging" }) CreatePrivate(Path.Combine(DefaultDirectory, child));
            requests = new McpTrustedRoot(Path.Combine(DefaultDirectory, "requests"), privateDirectory: true);
            responses = new McpTrustedRoot(Path.Combine(DefaultDirectory, "responses"), privateDirectory: true);
            outputs = new McpTrustedRoot(Path.Combine(DefaultDirectory, "outputs"), privateDirectory: true);
        }
        catch { lease?.Dispose(); requests?.Dispose(); responses?.Dispose(); directory.Dispose(); throw; }
        loop = Task.Run(PollAsync, CancellationToken.None);
    }
    private static void CreatePrivate(string path)
    {
        if (Directory.Exists(path)) return; // Existing authority is validated, never silently relaxed/repaired.
        var owner = WindowsIdentity.GetCurrent().User!;
        var security = new DirectorySecurity();
        security.SetOwner(owner);
        security.SetAccessRuleProtection(true, false);
        security.AddAccessRule(new FileSystemAccessRule(owner, FileSystemRights.FullControl,
            InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit, PropagationFlags.None, AccessControlType.Allow));
        new DirectoryInfo(path).Create(security);
    }
    private async Task PollAsync()
    {
        while (!shutdown.IsCancellationRequested)
        {
            try
            {
                if (activeId is { } running && CancellationRequested(running) && activeCancellation is { } cancellation)
                    await cancellation.CancelAsync();
                if (active?.IsCompleted == true)
                {
                    await active;
                    active = null; activeId = null;
                    activeCancellation?.Dispose(); activeCancellation = null;
                }
                var now = DateTime.UtcNow;
                foreach (var file in Directory.EnumerateFiles(Path.Combine(DefaultDirectory, "requests"), "*.json")
                    .Where(file => Guid.TryParseExact(Path.GetFileNameWithoutExtension(file), "D", out _) && !seen.Contains(Path.GetFileNameWithoutExtension(file))).Take(64))
                {
                    var id = Path.GetFileNameWithoutExtension(file);
                    if (!Guid.TryParseExact(id, "D", out _)) continue;
                    // A durable response makes a job non-replayable after an app restart, including uncertain signing.
                    if (seen.Contains(id)) continue;
                    if (HasResponse(id))
                    {
                        seen.Add(id);
                        try
                        {
                            var prior = JsonNode.Parse(responses.Read(id + ".json", 8192, privateFile: true));
                            if (prior?["state"]?.ToString() is "awaiting_user" or "signing") Respond(id, "failed", error: "OUTCOME_UNKNOWN");
                        }
                        catch { } // An unreadable prior response still prevents replay.
                        continue;
                    }
                    if (seen.Count >= 1024) continue; // Bounded process metadata; retention cleanup releases old jobs.
                    seen.Add(id);
                    if (now - File.GetLastWriteTimeUtc(file) > TimeSpan.FromMinutes(5)) { Respond(id, "expired", error: "EXPIRED"); continue; }
                    if (CancellationRequested(id)) { Respond(id, "cancelled", error: "USER_CANCELLED"); continue; }
                    if (active is not null) { Respond(id, "failed", error: "BUSY"); continue; }
                    byte[] pdf;
                    string name;
                    try
                    {
                        var value = JsonNode.Parse(requests.Read(id + ".json", 12 * 1024 * 1024, privateFile: true), documentOptions: new() { MaxDepth = 8 })!.AsObject();
                        if (value.Count != 5 || value["schemaVersion"]?.ToString() != "1" || value["operation"]?.ToString() != "prepare" || value["jobId"]?.ToString() != id)
                            throw new InvalidDataException();
                        name = value["name"]!.GetValue<string>();
                        if (name.Length is 0 or > 255 || name.Any(char.IsControl) || name.Contains('/') || name.Contains('\\')) throw new InvalidDataException();
                        pdf = Convert.FromBase64String(value["pdf"]!.GetValue<string>());
                        if (pdf.Length > 8 * 1024 * 1024 || !pdf.AsSpan().StartsWith("%PDF-"u8)) throw new InvalidDataException();
                    }
                    catch { Respond(id, "failed", error: "SIGNING_FAILED"); continue; }
                    Respond(id, "awaiting_user", Hash(pdf), replace: false);
                    activeId = id;
                    activeCancellation = CancellationTokenSource.CreateLinkedTokenSource(shutdown.Token);
                    activeCancellation.CancelAfter(TimeSpan.FromMilliseconds(Math.Max(1, Math.Min(TimeSpan.FromMinutes(5).TotalMilliseconds,
                        (File.GetLastWriteTimeUtc(file).AddMinutes(5) - DateTime.UtcNow).TotalMilliseconds))));
                    active = CompleteAsync(id, pdf, name, File.GetLastWriteTimeUtc(file).AddMinutes(5), activeCancellation.Token);
                }
                Cleanup(now);
            }
            catch { /* Fixed outcomes only; no document, credential or raw filesystem diagnostics. */ }
            try { await Task.Delay(250, shutdown.Token); } catch (OperationCanceledException) { }
        }
    }
    private static bool HasResponse(string id) => File.Exists(Path.Combine(DefaultDirectory, "responses", id + ".json"));
    private bool CancellationRequested(string id)
    {
        try { requests.Read(id + "-cancel.json", 1024, privateFile: true); return true; }
        catch (McpException e) when (e.Code == "PATH_DENIED") { return false; }
    }
    private async Task CompleteAsync(string id, byte[] pdf, string name, DateTime deadline, CancellationToken cancellation)
    {
        var hash = Hash(pdf);
        try
        {
            cancellation.ThrowIfCancellationRequested();
            // The awaiting-user response is already a durable no-replay marker. Only expose
            // signing once native preview and consent succeeded, before PIN verification.
            var signed = await sign(pdf, name, cancellation, () => Respond(id, "signing", hash));
            // Once signing happened, preserve its result even if cancellation raced the card/TSA.
            outputs.Publish(id + ".pdf", signed);
            Respond(id, "completed", hash, Hash(signed));
        }
        catch (McpException error) { Respond(id, "failed", hash, error: error.Code == "BUSY" ? "BUSY" : "OUTCOME_UNKNOWN"); }
        catch (OperationCanceledException)
        {
            var expired = DateTime.UtcNow >= deadline && !shutdown.IsCancellationRequested;
            Respond(id, expired ? "expired" : "cancelled", hash, error: expired ? "EXPIRED" : "USER_CANCELLED");
        }
        catch (CardException error)
        {
            var code = error.Kind switch {
                CardErrorKind.Cancelled => "USER_CANCELLED", CardErrorKind.WrongPin => "PIN_INCORRECT",
                CardErrorKind.PinBlocked => "PIN_BLOCKED", CardErrorKind.CardChanged => "CARD_CHANGED",
                CardErrorKind.NoCard or CardErrorKind.NoReader => "NO_CARD", CardErrorKind.Network => "NETWORK_FAILED",
                _ => "OUTCOME_UNKNOWN" };
            Respond(id, error.Kind == CardErrorKind.Cancelled ? "cancelled" : "failed", hash, error: code);
        }
        catch { Respond(id, "failed", hash, error: "OUTCOME_UNKNOWN"); }
    }
    private static string Hash(byte[] bytes) => Convert.ToHexStringLower(SHA256.HashData(bytes));
    private void Respond(string id, string state, string? input = null, string? output = null, string? error = null, bool replace = true)
    {
        var value = new JsonObject { ["schemaVersion"] = 1, ["jobId"] = id, ["state"] = state };
        if (input is not null) value["inputSHA256"] = input;
        if (output is not null) value["outputSHA256"] = output;
        if (error is not null) value["errorCode"] = error;
        responses.Publish(id + ".json", Encoding.UTF8.GetBytes(value.ToJsonString()), replace: replace);
    }
    private void Cleanup(DateTime now)
    {
        foreach (var (child, root) in new[] { ("requests", requests), ("responses", responses), ("outputs", outputs) })
            foreach (var file in Directory.EnumerateFiles(Path.Combine(DefaultDirectory, child)).Take(128))
            {
                var name = Path.GetFileName(file);
                var id = Path.GetFileNameWithoutExtension(file).Replace("-cancel", "", StringComparison.Ordinal);
                if (!Guid.TryParseExact(id, "D", out _) || id == activeId || now - File.GetLastWriteTimeUtc(file) < TimeSpan.FromHours(24)) continue;
                root.Remove(name); seen.Remove(id);
            }
    }
    public async ValueTask DisposeAsync()
    {
        await shutdown.CancelAsync(); if (activeCancellation is not null) await activeCancellation.CancelAsync();
        await loop;
        if (active is not null) { try { await active; } catch { } }
        activeCancellation?.Dispose(); shutdown.Dispose();
        outputs.Dispose(); responses.Dispose(); requests.Dispose(); await lease.DisposeAsync(); directory.Dispose();
    }
}
