using System.Text.Json.Nodes;
using System.Diagnostics;
using System.Security.AccessControl;
using System.Security.Principal;
using MoldSign.Cli;
using MoldSign.Core;

namespace MoldSign.Core.Tests;

public sealed class WindowsMcpTests
{
    private static JsonObject Request(string method, JsonObject? extra = null)
    {
        var parameters = extra ?? new JsonObject();
        parameters["_meta"] = new JsonObject { ["io.modelcontextprotocol/protocolVersion"] = McpServer.Version,
            ["io.modelcontextprotocol/clientCapabilities"] = new JsonObject() };
        return new JsonObject { ["jsonrpc"] = "2.0", ["id"] = 1, ["method"] = method, ["params"] = parameters };
    }
    private static JsonObject Send(McpServer server, JsonObject request) => JsonNode.Parse(server.Handle(McpServer.Encode(request))!)!.AsObject();
    private static JsonObject Call(McpServer server, string name, JsonObject arguments) =>
        Send(server, Request("tools/call", new JsonObject { ["name"] = name, ["arguments"] = arguments }))["result"]!["structuredContent"]!.AsObject();

    [Fact]
    public void DiscoveryHasNoSigningAndNoPaths()
    {
        var server = new McpServer(new Dictionary<string, McpTrustedRoot>());
        var listing = Send(server, Request("tools/list"));
        Assert.Equal(new[] { "capabilities", "verify_document" }, listing["result"]!["tools"]!.AsArray().Select(t => t!["name"]!.GetValue<string>()));
        var data = Call(server, "capabilities", new JsonObject())["data"]!;
        Assert.False(data["unattendedSigningAvailable"]!.GetValue<bool>());
        Assert.Empty(data["rootIds"]!.AsArray());
        Assert.Null(server.Handle("{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\"}"));
        Assert.NotNull(JsonNode.Parse(server.Handle("broken")!)!["error"]);
    }

    [Fact]
    public void LegacyInitializationEnablesStandardToolCalls()
    {
        var server = new McpServer(new Dictionary<string, McpTrustedRoot>());
        var initialized = server.Handle("{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2025-11-25\",\"capabilities\":{},\"clientInfo\":{\"name\":\"test\",\"version\":\"1\"}}}");
        Assert.Equal(McpServer.LegacyVersion, JsonNode.Parse(initialized!)!["result"]!["protocolVersion"]!.GetValue<string>());
        var tools = JsonNode.Parse(server.Handle("{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/list\"}")!);
        Assert.Equal(2, tools!["result"]!["tools"]!.AsArray().Count);
        Assert.Null(tools["result"]!["resultType"]);
    }

    [Fact]
    public void RootConfinesOfflinePDFAndRejectsTraversalAndUnknownPIN()
    {
        var directory = Directory.CreateTempSubdirectory("esemnbun-mcp-test-");
        try
        {
            File.WriteAllText(Path.Combine(directory.FullName, "document.pdf"), "%PDF-1.4\n%%EOF\n");
            using var root = new McpTrustedRoot(directory.FullName);
            var server = new McpServer(new Dictionary<string, McpTrustedRoot> { ["docs"] = root });
            JsonObject Input(string path) => new() { ["input"] = new JsonObject { ["rootId"] = "docs", ["relativePath"] = path } };
            Assert.Equal("no_recognized_signature", Call(server, "verify_document", Input("document.pdf"))["data"]!["status"]!.GetValue<string>());
            Assert.Equal("PATH_DENIED", Call(server, "verify_document", Input("../private.pdf"))["error"]!["code"]!.GetValue<string>());
            var withPin = Input("document.pdf"); withPin["pin"] = "synthetic-secret";
            var error = Call(server, "verify_document", withPin);
            Assert.Equal("INVALID_ARGUMENT", error["error"]!["code"]!.GetValue<string>());
            Assert.DoesNotContain("synthetic-secret", McpServer.Encode(error));
            File.WriteAllText(Path.Combine(directory.FullName, "unsafe.xml"), "<!DOCTYPE a [<!ENTITY x SYSTEM 'file:///secret'>]><a>&x;</a>");
            Assert.Equal("INVALID_DOCUMENT", Call(server, "verify_document", Input("unsafe.xml"))["error"]!["code"]!.GetValue<string>());
            Assert.Throws<McpException>(() => root.Read("CON", 10));
            Assert.Throws<McpException>(() => root.Read("document.pdf:secret", 10));
        }
        finally { directory.Delete(recursive: true); }
    }

    [Fact]
    public void ExclusiveOutputCannotOverwriteAndRemovalCannotTraverse()
    {
        var directory = Directory.CreateTempSubdirectory("esemnbun-mcp-write-");
        try
        {
            using var root = new McpTrustedRoot(directory.FullName);
            root.WriteExclusive("output.pdf", [1, 2, 3]);
            Assert.Throws<McpException>(() => root.WriteExclusive("output.pdf", [9]));
            Assert.Equal(new byte[] { 1, 2, 3 }, root.Read("output.pdf", 8));
            Assert.Throws<McpException>(() => root.Remove("../outside"));
            root.Remove("output.pdf");
            Assert.Throws<McpException>(() => root.Read("output.pdf", 8));
        }
        finally { directory.Delete(recursive: true); }
    }

    [Fact]
    public void WindowsJunctionCannotEscapeTheRootAndRootCannotBeRenamed()
    {
        if (!OperatingSystem.IsWindows()) return;
        var directory = Directory.CreateTempSubdirectory("esemnbun-mcp-junction-");
        var outside = Directory.CreateTempSubdirectory("esemnbun-mcp-outside-");
        try
        {
            File.WriteAllText(Path.Combine(outside.FullName, "secret.pdf"), "%PDF-1.4");
            var junction = Path.Combine(directory.FullName, "link");
            var start = new ProcessStartInfo("cmd.exe") { UseShellExecute = false, RedirectStandardOutput = true, RedirectStandardError = true };
            start.ArgumentList.Add("/c"); start.ArgumentList.Add("mklink"); start.ArgumentList.Add("/J");
            start.ArgumentList.Add(junction); start.ArgumentList.Add(outside.FullName);
            using var process = Process.Start(start)!;
            Assert.True(process.WaitForExit(5000)); Assert.Equal(0, process.ExitCode);
            using (var root = new McpTrustedRoot(directory.FullName))
            {
                Assert.Throws<McpException>(() => root.Read("link/secret.pdf", 100));
                Assert.ThrowsAny<IOException>(() => directory.MoveTo(directory.FullName + "-moved"));
            }
            Directory.Delete(junction);
        }
        finally { directory.Delete(recursive: true); outside.Delete(recursive: true); }
    }

    [Fact]
    public void PrivateOutputRejectsBroadACLAndAcceptsOwnerOnlyACL()
    {
        if (!OperatingSystem.IsWindows()) return;
        var directory = Directory.CreateTempSubdirectory("esemnbun-mcp-acl-");
        try
        {
            var owner = WindowsIdentity.GetCurrent().User!;
            var security = new DirectorySecurity(); security.SetOwner(owner); security.SetAccessRuleProtection(true, false);
            security.AddAccessRule(new FileSystemAccessRule(owner, FileSystemRights.FullControl,
                InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit, PropagationFlags.None, AccessControlType.Allow));
            security.AddAccessRule(new FileSystemAccessRule(new SecurityIdentifier(WellKnownSidType.WorldSid, null),
                FileSystemRights.ReadAndExecute, AccessControlType.Allow));
            directory.SetAccessControl(security);
            Assert.Throws<McpException>(() => new McpTrustedRoot(directory.FullName, privateDirectory: true));
            security.PurgeAccessRules(new SecurityIdentifier(WellKnownSidType.WorldSid, null));
            directory.SetAccessControl(security);
            using var root = new McpTrustedRoot(directory.FullName, privateDirectory: true);
            root.WriteExclusive("marker", [1]);
            Assert.Equal(new byte[] { 1 }, root.Read("marker", 10));
        }
        finally { directory.Delete(recursive: true); }
    }

    [Fact]
    public void HostRejectsOversizeAndSecretArgumentsWithoutAccessingCredentials()
    {
        var output = new StringWriter(); var error = new StringWriter();
        CliHost Host(string input) => new() { In = new StringReader(input), Out = output, Error = error,
            GetEnvironmentVariable = _ => throw new InvalidOperationException(), IsInputRedirected = () => true,
            PromptHidden = _ => throw new InvalidOperationException(), Cards = new NoCards() };
        Assert.Equal(1, CliApp.Run(["mcp", "--root", "broker-output=/unused"], Host("")));
        Assert.Equal(1, CliApp.Run(["mcp", "--root", "unattended-output=/unused"], Host("")));
        Assert.Equal(1, CliApp.Run(["mcp", "--pin", "synthetic-secret"], Host("")));
        Assert.DoesNotContain("synthetic-secret", error.ToString());
        Assert.Empty(output.ToString());
        Assert.Equal(1, CliApp.Run(["mcp"], Host(new string('x', McpServer.MaxFrame + 1))));
    }
    private sealed class NoCards : ICardAccess
    {
        public IReadOnlyList<SmartCardReaderInfo> ListReaders() => throw new InvalidOperationException();
        public ICardTransport Connect(string? readerName) => throw new InvalidOperationException();
    }
}
