using System.Text.Json;
using MoldSign.Cli;

namespace MoldSign.Core.Tests;

/// <summary>Capability discovery is metadata-only and never reaches hardware or PIN sources.</summary>
public class CliCapabilitiesTests
{
    [Fact]
    public void Windows_capabilities_are_one_json_object_and_do_not_claim_document_parity()
    {
        var (code, output, error) = Run(["capabilities", "--json"]);
        Assert.Equal(0, code);
        Assert.Empty(error);
        using var parsed = JsonDocument.Parse(output);
        var root = parsed.RootElement;
        Assert.Equal(1, root.GetProperty("schemaVersion").GetInt32());
        Assert.True(root.GetProperty("ok").GetBoolean());
        var data = root.GetProperty("data");
        Assert.Equal("windows", data.GetProperty("platform").GetString());
        Assert.Equal(new[] { "capabilities", "help", "readers", "cert", "sign-hex", "mcp", "encrypt", "decrypt", "encryption-certs", "remove-file" },
            data.GetProperty("commands").EnumerateArray().Select(v => v.GetString()));
        Assert.Equal(new[] { "capabilities" },
            data.GetProperty("structuredOutputCommands").EnumerateArray().Select(v => v.GetString()));
        Assert.False(data.GetProperty("documentSigning").GetProperty("available").GetBoolean());
        Assert.False(data.GetProperty("verification").GetProperty("available").GetBoolean());
        Assert.True(data.GetProperty("mcpServerAvailable").GetBoolean());
        Assert.False(data.GetProperty("desktopApprovalBrokerAvailable").GetBoolean());
        Assert.Equal(0, data.GetProperty("verification").GetProperty("formats").GetArrayLength());
    }

    [Theory]
    [InlineData("verify")]
    [InlineData("sign")]
    [InlineData("sign-hex")]
    [InlineData("cert")]
    [InlineData("readers")]
    public void Other_json_commands_fail_before_hardware_or_pin_access(string command)
    {
        var (code, output, error) = Run([command, "private-document-or-pin", "--json", "--pin-stdin"]);
        Assert.Equal(1, code);
        Assert.DoesNotContain("private-document-or-pin", output + error);
        using var parsed = JsonDocument.Parse(output);
        Assert.False(parsed.RootElement.GetProperty("ok").GetBoolean());
        Assert.Equal("UNSUPPORTED", parsed.RootElement.GetProperty("error").GetProperty("code").GetString());
        Assert.False(parsed.RootElement.GetProperty("error").GetProperty("retryable").GetBoolean());
        Assert.StartsWith("error: ", error);
    }

    [Theory]
    [InlineData("capabilities", "--json", "--reader", "private-reader")]
    [InlineData("capabilities", "--json", "--json")]
    [InlineData("--json")]
    public void Malformed_discovery_has_sanitized_structured_usage_error(params string[] args)
    {
        var (code, output, error) = Run(args);
        Assert.Equal(1, code);
        Assert.DoesNotContain("private-reader", output + error);
        using var parsed = JsonDocument.Parse(output);
        Assert.Equal("INVALID_ARGUMENT", parsed.RootElement.GetProperty("error").GetProperty("code").GetString());
    }

    [Fact]
    public void Human_readable_discovery_accepts_quiet_without_hardware()
    {
        var (code, output, error) = Run(["--quiet", "capabilities"]);
        Assert.Equal(0, code);
        Assert.Empty(error);
        Assert.Contains("Verification: unavailable", output);
    }

    private static (int Code, string Output, string Error) Run(string[] args)
    {
        var output = new StringWriter();
        var error = new StringWriter();
        var host = new CliHost
        {
            In = new StringReader("secret-stdin-must-not-be-read"),
            Out = output,
            Error = error,
            GetEnvironmentVariable = _ => throw new InvalidOperationException("environment accessed"),
            IsInputRedirected = () => throw new InvalidOperationException("stdin queried"),
            PromptHidden = _ => throw new InvalidOperationException("PIN requested"),
            Cards = new NoCardAccess(),
        };
        return (CliApp.Run(args, host), output.ToString(), error.ToString());
    }

    private sealed class NoCardAccess : ICardAccess
    {
        public IReadOnlyList<SmartCardReaderInfo> ListReaders() => throw new InvalidOperationException("readers queried");
        public ICardTransport Connect(string? readerName) => throw new InvalidOperationException("card opened");
    }
}
