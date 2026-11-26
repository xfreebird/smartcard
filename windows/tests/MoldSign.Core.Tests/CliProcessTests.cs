using System.Diagnostics;
using System.Text.Json.Nodes;
using MoldSign.Cli;

namespace MoldSign.Core.Tests;

/// <summary>The real `esemnbun` entry point as a child process, and the no-echo PIN line editor.</summary>
public sealed class CliProcessTests
{
    private static ConsoleKeyInfo Key(char value, ConsoleKey key) => new(value, key, false, false, false);

    [Fact]
    public void Hidden_prompt_edits_without_echo_and_ignores_control_keys()
    {
        var keys = new Queue<ConsoleKeyInfo>([
            Key('1', ConsoleKey.D1), Key('2', ConsoleKey.D2), Key('9', ConsoleKey.D9), Key('\b', ConsoleKey.Backspace),
            Key('\t', ConsoleKey.Tab), Key('3', ConsoleKey.D3), Key('4', ConsoleKey.D4), Key('\r', ConsoleKey.Enter)]);
        var error = new StringWriter();

        Assert.Equal("1234", CliHost.ReadHidden("PIN: ", error, keys.Dequeue));
        Assert.Equal("PIN: " + Environment.NewLine, error.ToString());
        Assert.Empty(keys);
    }

    [Fact]
    public void Hidden_prompt_cancels_on_escape_or_an_empty_line()
    {
        var escape = new Queue<ConsoleKeyInfo>([Key('1', ConsoleKey.D1), Key('\u001b', ConsoleKey.Escape)]);
        Assert.Null(CliHost.ReadHidden("PIN: ", TextWriter.Null, escape.Dequeue));
        var empty = new Queue<ConsoleKeyInfo>([Key('\b', ConsoleKey.Backspace), Key('\r', ConsoleKey.Enter)]);
        Assert.Null(CliHost.ReadHidden("PIN: ", TextWriter.Null, empty.Dequeue));
    }

    [Fact]
    public void The_entry_point_writes_structured_capabilities_without_hardware()
    {
        var (code, output, error) = Esemnbun("", "capabilities", "--json");

        Assert.Equal(0, code);
        Assert.Equal("", error);
        var json = JsonNode.Parse(output)!;
        Assert.True(json["ok"]!.GetValue<bool>());
        Assert.Equal("windows", json["data"]!["platform"]!.GetValue<string>());
    }

    [Fact]
    public void The_entry_point_serves_mcp_until_stdin_closes_and_rejects_pins_in_arguments()
    {
        var (mcp, output, _) = Esemnbun("", "mcp");
        Assert.Equal(0, mcp);
        Assert.Equal("", output);

        var (code, _, error) = Esemnbun("", "sign-hex", "00", "--pin", "1234");
        Assert.Equal(1, code);
        Assert.Contains("never accepted on the command line", error);
        Assert.DoesNotContain("1234", error);
    }

    private static (int Code, string Out, string Err) Esemnbun(string stdin, params string[] arguments)
    {
        var start = new ProcessStartInfo(Environment.GetEnvironmentVariable("DOTNET_HOST_PATH") ?? "dotnet")
        {
            UseShellExecute = false, RedirectStandardInput = true, RedirectStandardOutput = true, RedirectStandardError = true,
        };
        start.ArgumentList.Add("exec");
        start.ArgumentList.Add(Path.Combine(AppContext.BaseDirectory, "esemnbun.dll"));
        foreach (var argument in arguments) start.ArgumentList.Add(argument);
        start.Environment.Remove("MSIGN_PIN");
        using var process = Process.Start(start)!;
        process.StandardInput.Write(stdin);
        process.StandardInput.Close();
        var output = process.StandardOutput.ReadToEndAsync();
        var error = process.StandardError.ReadToEndAsync();
        if (!process.WaitForExit(60_000)) { process.Kill(entireProcessTree: true); throw new TimeoutException("esemnbun did not exit"); }
        return (process.ExitCode, output.Result, error.Result);
    }
}
