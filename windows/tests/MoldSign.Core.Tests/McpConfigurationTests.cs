using System.Text;
using System.Text.Json.Nodes;
using MoldSign.Cli;

namespace MoldSign.Core.Tests;

/// <summary>`esemnbun mcp` operator configuration: roots, desktop broker, unattended signing policy and PIN sources.</summary>
public sealed class McpConfigurationTests : IDisposable
{
    private readonly DirectoryInfo _directory = Directory.CreateTempSubdirectory("esemnbun-mcp-config-");

    public void Dispose() => _directory.Delete(true);

    private const string CapabilitiesCall =
        "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"capabilities\",\"arguments\":{}," +
        "\"_meta\":{\"io.modelcontextprotocol/protocolVersion\":\"2026-07-28\",\"io.modelcontextprotocol/clientCapabilities\":{}}}}";

    [Theory]
    [InlineData("--root")]
    [InlineData("--root", "docs")]
    [InlineData("--root", "=/tmp")]
    [InlineData("--root", "bad id=/tmp")]
    [InlineData("--root", "broker-output=/tmp")]
    [InlineData("--root", "unattended-output=/tmp")]
    [InlineData("--root", "docs=relative/path")]
    [InlineData("--unknown")]
    [InlineData("--broker-directory")]
    [InlineData("--signing-output-directory", "/tmp")]
    public void Invalid_configuration_fails_closed_without_serving(params string[] arguments)
    {
        var (code, output, error) = RunMcp(arguments, input: CapabilitiesCall + "\n");
        Assert.Equal(1, code);
        Assert.Equal("", output);
        Assert.Equal("MCP configuration or transport failed", error.Trim());
    }

    [Fact]
    public void Duplicate_roots_are_rejected()
    {
        var root = $"docs={_directory.FullName}";
        Assert.Equal(1, RunMcp(["--root", root, "--root", root], CapabilitiesCall + "\n").Code);
    }

    [Fact]
    public void Configured_roots_are_served_over_stdio_until_input_closes()
    {
        var documents = _directory.CreateSubdirectory("documents");
        var (code, output, error) = RunMcp(["--root", $"docs={documents.FullName}"], CapabilitiesCall + "\n");

        Assert.Equal(0, code);
        Assert.Equal("", error);
        var data = JsonNode.Parse(output.Trim())!["result"]!["structuredContent"]!["data"]!;
        Assert.Equal(["docs"], data["rootIds"]!.AsArray().Select(id => id!.GetValue<string>()));
        Assert.False(data["desktopApprovalBrokerAvailable"]!.GetValue<bool>());
        Assert.False(data["unattendedSigningAvailable"]!.GetValue<bool>());
    }

    [Fact]
    public void Desktop_broker_adds_its_private_output_root_and_cancels_jobs_on_disconnect()
    {
        var broker = _directory.CreateSubdirectory("broker");
        WindowsMcpApprovalTests.Private(broker);
        foreach (var child in new[] { "requests", "responses", "outputs" }) WindowsMcpApprovalTests.Private(broker.CreateSubdirectory(child));
        var documents = _directory.CreateSubdirectory("documents");
        File.WriteAllText(Path.Combine(documents.FullName, "contract.pdf"), "%PDF-1.4\n%%EOF\n");
        const string meta = "\"_meta\":{\"io.modelcontextprotocol/protocolVersion\":\"2026-07-28\",\"io.modelcontextprotocol/clientCapabilities\":{}}";
        var prepare = "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"prepare_signing\",\"arguments\":" +
                      "{\"input\":{\"rootId\":\"docs\",\"relativePath\":\"contract.pdf\"},\"format\":\"PAdES-T\"}," + meta + "}}";

        var (code, output, _) = RunMcp(["--broker-directory", broker.FullName, "--root", $"docs={documents.FullName}"],
            CapabilitiesCall + "\n" + prepare + "\n", replies: 2);

        Assert.Equal(0, code);
        var replies = output.Split('\n', StringSplitOptions.RemoveEmptyEntries).Select(line => JsonNode.Parse(line)!).ToArray();
        var data = replies[0]["result"]!["structuredContent"]!["data"]!;
        Assert.True(data["desktopApprovalBrokerAvailable"]!.GetValue<bool>());
        Assert.Equal(["broker-output", "docs"], data["rootIds"]!.AsArray().Select(id => id!.GetValue<string>()));
        var job = replies[1]["result"]!["structuredContent"]!["data"]!["jobId"]!.GetValue<string>();
        var requests = Path.Combine(broker.FullName, "requests");
        Assert.True(File.Exists(Path.Combine(requests, job + ".json")));
        Assert.True(File.Exists(Path.Combine(requests, job + "-cancel.json"))); // the client went away
    }

    [Fact]
    public void Unattended_signing_requires_every_explicit_option()
    {
        var certificate = new string('a', 64);
        var output = _directory.CreateSubdirectory("signed");
        string[][] invalid =
        [
            ["--allow-unattended-signing"],
            ["--allow-unattended-signing", "--signing-certificate-sha256", "abc", "--signing-output-directory", output.FullName, "--pin-source", "env:MSIGN_PIN"],
            ["--allow-unattended-signing", "--signing-certificate-sha256", certificate, "--pin-source", "env:MSIGN_PIN"],
            ["--allow-unattended-signing", "--signing-certificate-sha256", certificate, "--signing-output-directory", output.FullName],
            ["--allow-unattended-signing", "--signing-certificate-sha256", "--signing-output-directory", output.FullName, "--pin-source", "env:MSIGN_PIN"],
            ["--allow-unattended-signing", "--signing-certificate-sha256", certificate, "--signing-certificate-sha256", certificate,
                "--signing-output-directory", output.FullName, "--pin-source", "env:MSIGN_PIN"],
            ["--allow-unattended-signing", "--signing-certificate-sha256", certificate, "--signing-output-directory", output.FullName,
                "--pin-source", "env:MSIGN_PIN", "--onepassword-executable", "/usr/bin/op"],
            ["--allow-unattended-signing", "--signing-certificate-sha256", certificate, "--signing-output-directory", output.FullName,
                "--pin-source", "keychain:pin"],
        ];
        foreach (var arguments in invalid)
        {
            var roots = new Dictionary<string, McpTrustedRoot>();
            Assert.Equal("INVALID_ARGUMENT", Assert.Throws<McpException>(() => WindowsMcpUnattendedSigner.Create([.. arguments], roots)).Code);
            Assert.Empty(roots);
        }
    }

    [Fact]
    public void Unattended_signing_is_configured_only_on_windows_with_a_private_output()
    {
        var output = _directory.CreateSubdirectory("signed");
        WindowsMcpApprovalTests.Private(output);
        List<string> Arguments() => ["--allow-unattended-signing", "--signing-certificate-sha256", new string('b', 64),
            "--signing-output-directory", output.FullName, "--pin-source", "env:ESEMNBUN_TEST_UNSET_PIN", "--root", "docs=x"];
        var roots = new Dictionary<string, McpTrustedRoot>();
        var arguments = Arguments();
        if (!OperatingSystem.IsWindows())
        {
            Assert.Equal("UNSUPPORTED", Assert.Throws<McpException>(() => WindowsMcpUnattendedSigner.Create(arguments, roots)).Code);
            Assert.Empty(roots);
            return;
        }
        var signer = WindowsMcpUnattendedSigner.Create(arguments, roots);
        try
        {
            Assert.NotNull(signer);
            Assert.Equal(["--root", "docs=x"], arguments); // policy options are consumed, the rest is left for the host
            var server = new McpServer(roots, signer);
            var listing = JsonNode.Parse(server.Handle("{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\",\"params\":{\"_meta\":" +
                "{\"io.modelcontextprotocol/protocolVersion\":\"2026-07-28\",\"io.modelcontextprotocol/clientCapabilities\":{}}}}")!)!;
            Assert.Contains("sign_document", listing["result"]!["tools"]!.AsArray().Select(tool => tool!["name"]!.GetValue<string>()));

            var taken = new Dictionary<string, McpTrustedRoot> { ["unattended-output"] = roots["unattended-output"] };
            Assert.Equal("INVALID_ARGUMENT", Assert.Throws<McpException>(() => WindowsMcpUnattendedSigner.Create(Arguments(), taken)).Code);

        }
        finally { foreach (var root in roots.Values) root.Dispose(); }
    }

    [Fact]
    public void Environment_pins_are_read_late_and_must_be_4_to_8_digits()
    {
        var name = "ESEMNBUN_TEST_PIN_" + Guid.NewGuid().ToString("N")[..8].ToUpperInvariant();
        var provider = WindowsMcpCredentialSource.Create("env:" + name);
        try
        {
            Assert.Equal("CREDENTIAL_UNAVAILABLE", Assert.Throws<McpException>(() => provider()).Code);
            Environment.SetEnvironmentVariable(name, "123456");
            Assert.Equal("123456", provider());
            foreach (var malformed in new[] { "123", "123456789", "12a4", "١٢٣٤" })
            {
                Environment.SetEnvironmentVariable(name, malformed);
                Assert.Equal("CREDENTIAL_UNAVAILABLE", Assert.Throws<McpException>(() => provider()).Code);
            }
        }
        finally { Environment.SetEnvironmentVariable(name, null); }
    }

    [Theory]
    [InlineData("env:")]
    [InlineData("credential:")]
    [InlineData("credential:bad\tname")]
    [InlineData("onepassword:vault/item")]
    [InlineData("file:/tmp/pin")]
    public void Malformed_pin_sources_are_rejected_at_configuration(string source) =>
        Assert.Equal("INVALID_ARGUMENT", Assert.Throws<McpException>(() => WindowsMcpCredentialSource.Create(source)).Code);

    [Fact]
    public void Missing_windows_credentials_are_unavailable()
    {
        var provider = WindowsMcpCredentialSource.Create("credential:eSemnBun-test-" + Guid.NewGuid().ToString("N"));
        Assert.Equal("CREDENTIAL_UNAVAILABLE", Assert.Throws<McpException>(() => provider()).Code);
        Assert.Equal("INVALID_ARGUMENT", Assert.Throws<McpException>(() =>
            WindowsMcpCredentialSource.Create("credential:" + new string('x', 256))).Code);
    }

    [Fact]
    public void One_password_is_read_through_its_cli_with_bounded_output()
    {
        Assert.Equal("INVALID_ARGUMENT", Assert.Throws<McpException>(() =>
            WindowsMcpCredentialSource.Create("onepassword:op://vault/item/pin", "relative/op")).Code);
        var good = WindowsMcpCredentialSource.Create("onepassword:op://vault/item/pin", Script("good", "24680", exitCode: 0));
        Assert.Equal("24680", good());
        var arguments = File.ReadAllText(Path.Combine(_directory.FullName, "good.args")).Trim();
        Assert.Equal("read --no-newline op://vault/item/pin", arguments);

        var failing = WindowsMcpCredentialSource.Create("onepassword:op://vault/item/pin", Script("failing", "24680", exitCode: 1));
        Assert.Equal("CREDENTIAL_UNAVAILABLE", Assert.Throws<McpException>(() => failing()).Code);
        var oversized = WindowsMcpCredentialSource.Create("onepassword:op://vault/item/pin", Script("oversized", new string('7', 40), exitCode: 0));
        Assert.Equal("CREDENTIAL_UNAVAILABLE", Assert.Throws<McpException>(() => oversized()).Code);
        var missing = WindowsMcpCredentialSource.Create("onepassword:op://vault/item/pin", Path.Combine(_directory.FullName, "absent-op"));
        Assert.Equal("CREDENTIAL_UNAVAILABLE", Assert.Throws<McpException>(() => missing()).Code);
    }

    [Fact]
    public void One_password_reads_are_abandoned_after_the_deadline()
    {
        var slow = Script("slow", "13579", exitCode: 0, delaySeconds: 20);
        var started = DateTime.UtcNow;
        Assert.Equal("CREDENTIAL_UNAVAILABLE", Assert.Throws<McpException>(() =>
            WindowsMcpCredentialSource.ReadCommand(slow, "op://vault/item/pin", TimeSpan.FromSeconds(1))).Code);
        Assert.True(DateTime.UtcNow - started < TimeSpan.FromSeconds(15));
    }

    /// <summary>Fake `op` CLI: records its arguments, prints <paramref name="value"/> without a newline.</summary>
    private string Script(string name, string value, int exitCode, int delaySeconds = 0)
    {
        var args = Path.Combine(_directory.FullName, name + ".args");
        if (OperatingSystem.IsWindows())
        {
            var path = Path.Combine(_directory.FullName, name + ".cmd");
            var delay = delaySeconds > 0 ? $"ping -n {delaySeconds + 1} 127.0.0.1 >nul\r\n" : "";
            File.WriteAllText(path, $"@echo off\r\necho %*> \"{args}\"\r\n{delay}<nul set /p ={value}\r\nexit /b {exitCode}\r\n");
            return path;
        }
        var script = Path.Combine(_directory.FullName, name);
        var sleep = delaySeconds > 0 ? $"sleep {delaySeconds}\n" : "";
        File.WriteAllText(script, $"#!/bin/sh\necho \"$*\" > '{args}'\n{sleep}printf '%s' '{value}'\nexit {exitCode}\n");
        File.SetUnixFileMode(script, UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute);
        return script;
    }

    private static (int Code, string Out, string Err) RunMcp(string[] arguments, string input, int replies = 1)
    {
        var output = new StringWriter();
        var error = new StringWriter();
        using var reader = new GatedReader(input, () => output.ToString().Count(c => c == '\n') >= replies);
        var host = new CliHost
        {
            In = reader, Out = output, Error = error,
            GetEnvironmentVariable = _ => null, IsInputRedirected = () => true,
            PromptHidden = _ => throw new InvalidOperationException("MCP never prompts"),
            Cards = new NoCards(),
        };
        var code = CliApp.Run(["mcp", .. arguments], host);
        return (code, output.ToString(), error.ToString());
    }

    /// <summary>Serves the frames, then holds EOF until the expected replies were written (stdio keeps the pipe open).</summary>
    private sealed class GatedReader(string text, Func<bool> repliesWritten) : TextReader
    {
        private int _position;
        public override int Read()
        {
            if (_position < text.Length) return text[_position++];
            var deadline = DateTime.UtcNow.AddSeconds(30);
            while (!repliesWritten() && DateTime.UtcNow < deadline) Thread.Sleep(10);
            return -1;
        }
    }

    private sealed class NoCards : ICardAccess
    {
        public IReadOnlyList<SmartCardReaderInfo> ListReaders() => throw new InvalidOperationException("MCP verification never lists readers");
        public ICardTransport Connect(string? readerName) => throw new InvalidOperationException("MCP verification never opens a card");
    }
}
