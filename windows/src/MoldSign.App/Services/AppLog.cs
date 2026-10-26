namespace MoldSign.App.Services;

internal static class AppLog
{
    private static readonly object s_gate = new();

    public static void Error(Exception error)
    {
        try
        {
            lock (s_gate)
            {
                var directory = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "MoldSign");
                Directory.CreateDirectory(directory);
                var path = Path.Combine(directory, "errors.log");
                if (File.Exists(path) && new FileInfo(path).Length > 512 * 1024) File.WriteAllText(path, "");
                // Exception messages can contain documents or credentials; record call sites only.
                File.AppendAllText(path,
                    $"{DateTimeOffset.Now:O} {error.GetType().FullName} 0x{error.HResult:X8}\n{error.StackTrace}\n");
            }
        }
        catch (Exception) { }
    }
}
