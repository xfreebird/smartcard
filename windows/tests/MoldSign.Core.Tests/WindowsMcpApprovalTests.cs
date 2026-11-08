using System.Security.AccessControl;
using System.Security.Principal;
using System.Text;
using System.Text.Json.Nodes;
using MoldSign.Cli;

namespace MoldSign.Core.Tests;

public sealed class WindowsMcpApprovalTests
{
    [Fact]
    public void ApprovalJobsOwnImmutableInputFilterResponsesAndCancelIdempotently()
    {
        var directory = Directory.CreateTempSubdirectory("esemnbun-mcp-approval-");
        try
        {
            Private(directory);
            foreach (var child in new[] { "requests", "responses", "outputs" }) Private(directory.CreateSubdirectory(child));
            using var broker = new WindowsMcpApprovalTransport(directory.FullName);
            using var responses = new McpTrustedRoot(Path.Combine(directory.FullName, "responses"));
            var pdf = Encoding.ASCII.GetBytes("%PDF-1.4\n%%EOF\n");
            var original = (byte[])pdf.Clone();
            var prepared = broker.Prepare(pdf, "document.pdf");
            var id = prepared["jobId"]!.GetValue<string>();
            Array.Fill(pdf, (byte)0);
            var staged = JsonNode.Parse(File.ReadAllText(Path.Combine(directory.FullName, "requests", id + ".json")))!;
            Assert.Equal(original, Convert.FromBase64String(staged["pdf"]!.GetValue<string>()));
            Assert.Equal("UNKNOWN_JOB", Assert.Throws<McpException>(() => broker.Job(Guid.NewGuid().ToString("D"), false)).Code);
            Assert.Equal("awaiting_user", broker.Job(id, false)["state"]!.GetValue<string>());
            responses.Publish(id + ".json", Encoding.UTF8.GetBytes(new JsonObject {
                ["schemaVersion"] = 1, ["jobId"] = id, ["state"] = "completed", ["inputSHA256"] = new string('a', 64),
                ["outputSHA256"] = "private-value", ["errorCode"] = "private-value", ["subject"] = "private-value"
            }.ToJsonString()));
            var result = broker.Job(id, false);
            Assert.Equal("broker-output", result["output"]!["rootId"]!.GetValue<string>());
            Assert.DoesNotContain("private-value", result.ToJsonString());
            Assert.Equal(new string('a', 64), result["inputSHA256"]!.GetValue<string>());
            Assert.True(broker.Job(id, true)["cancellationRequested"]!.GetValue<bool>());
            Assert.True(broker.Job(id, true)["cancellationRequested"]!.GetValue<bool>());
            var other = broker.Prepare(original, "other.pdf")["jobId"]!.GetValue<string>();
            broker.Disconnect();
            Assert.True(File.Exists(Path.Combine(directory.FullName, "requests", other + "-cancel.json")));
            Assert.Empty(Directory.GetFiles(Path.Combine(directory.FullName, "requests"), "*.tmp"));
        }
        finally { directory.Delete(true); }
    }

    [Fact]
    public void PublicationNeverOverwritesUnlessExplicitAndJobsAreBounded()
    {
        var directory = Directory.CreateTempSubdirectory("esemnbun-mcp-publication-");
        try
        {
            Private(directory);
            foreach (var child in new[] { "requests", "responses", "outputs" }) Private(directory.CreateSubdirectory(child));
            using var root = new McpTrustedRoot(directory.FullName);
            root.Publish("value", [1]);
            Assert.Throws<McpException>(() => root.Publish("value", [2]));
            Assert.Equal(new byte[] { 1 }, root.Read("value", 4));
            root.Publish("value", [3], replace: true);
            Assert.Equal(new byte[] { 3 }, root.Read("value", 4));
            using var broker = new WindowsMcpApprovalTransport(directory.FullName);
            for (var i = 0; i < 16; i++) broker.Prepare("%PDF-1.4"u8.ToArray(), "document.pdf");
            Assert.Equal("LIMIT_EXCEEDED", Assert.Throws<McpException>(() => broker.Prepare("%PDF-1.4"u8.ToArray(), "document.pdf")).Code);
        }
        finally { directory.Delete(true); }
    }

    private static void Private(DirectoryInfo directory)
    {
        if (OperatingSystem.IsWindows())
        {
            var owner = WindowsIdentity.GetCurrent().User!;
            var security = new DirectorySecurity(); security.SetOwner(owner); security.SetAccessRuleProtection(true, false);
            security.AddAccessRule(new FileSystemAccessRule(owner, FileSystemRights.FullControl,
                InheritanceFlags.ContainerInherit | InheritanceFlags.ObjectInherit, PropagationFlags.None, AccessControlType.Allow));
            directory.SetAccessControl(security);
        }
        else File.SetUnixFileMode(directory.FullName, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
    }
}
