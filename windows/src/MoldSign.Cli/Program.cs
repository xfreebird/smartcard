using System.Text;
using MoldSign.Cli;

if (OperatingSystem.IsWindows())
{
    // Console and redirected MCP frames carry Romanian diacritics (ă, î, ș, ț).
    try
    {
        Console.OutputEncoding = new UTF8Encoding(false);
        if (args.Length > 0 && args[0] == "mcp") Console.InputEncoding = new UTF8Encoding(false, true);
    }
    catch (IOException)
    {
        // No console attached (redirected): keep the default.
    }
}

return CliApp.Run(args, CliHost.FromConsole());
