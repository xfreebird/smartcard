using System.Text;
using MoldSign.Cli;

if (OperatingSystem.IsWindows())
{
    // Holder names carry Romanian diacritics (ă, î, ș, ț).
    try
    {
        Console.OutputEncoding = Encoding.UTF8;
    }
    catch (IOException)
    {
        // No console attached (redirected): keep the default.
    }
}

return CliApp.Run(args, CliHost.FromConsole());
