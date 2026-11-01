using System.Diagnostics;
using System.Globalization;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.Win32.SafeHandles;

namespace MoldSign.App.Services;

/// <summary>Identifies listening processes without guessing that a particular Java process is MoldSign.</summary>
internal static partial class PortConflictProcesses
{
    internal sealed record Owner(int Id, DateTime StartedUtc, string Path);

    internal static async Task<IReadOnlyList<Owner>> FindAsync()
    {
        var executable = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "netstat.exe");
        using var command = Process.Start(new ProcessStartInfo(executable, "-ano -p tcp")
        {
            UseShellExecute = false, RedirectStandardOutput = true, CreateNoWindow = true,
        }) ?? throw new InvalidOperationException("Unable to inspect listeners.");
        var output = await command.StandardOutput.ReadToEndAsync();
        await command.WaitForExitAsync();
        if (command.ExitCode != 0) throw new InvalidOperationException("Unable to inspect listeners.");
        var ids = new HashSet<int>();
        foreach (var line in output.Split('\n'))
        {
            var fields = Whitespace().Split(line.Trim());
            if (fields.Length < 5 || !fields[0].Equals("TCP", StringComparison.OrdinalIgnoreCase)) continue;
            var endpoint = fields[1];
            if ((!endpoint.EndsWith(":18480", StringComparison.Ordinal) && !endpoint.EndsWith(":18443", StringComparison.Ordinal)) ||
                !fields[2].EndsWith(":0", StringComparison.Ordinal) ||
                !int.TryParse(fields[^1], NumberStyles.None, CultureInfo.InvariantCulture, out var pid) || pid <= 4 || pid == Environment.ProcessId) continue;
            ids.Add(pid);
        }
        var result = new List<Owner>();
        foreach (var id in ids)
        {
            try
            {
                using var process = Process.GetProcessById(id);
                // MainModule enumeration fails across some process architectures (e.g. x64 on Windows ARM).
                // QueryFullProcessImageName reads the image path without enumerating remote modules.
                var path = ImagePath(id);
                if (!string.IsNullOrEmpty(path)) result.Add(new(id, process.StartTime.ToUniversalTime(), path));
            }
            catch (Exception ex) when (ex is ArgumentException or InvalidOperationException or System.ComponentModel.Win32Exception) { }
        }
        return result;
    }

    internal static async Task<bool> StopAsync(IReadOnlyList<Owner> approved)
    {
        var current = await FindAsync();
        foreach (var owner in approved)
        {
            if (!current.Contains(owner)) return false; // Do not signal a reused PID or changed listener.
        }
        foreach (var owner in approved)
        {
            try
            {
                using var process = Process.GetProcessById(owner.Id);
                if (process.StartTime.ToUniversalTime() != owner.StartedUtc ||
                    !string.Equals(ImagePath(owner.Id), owner.Path, StringComparison.OrdinalIgnoreCase)) return false;
                process.Kill();
                using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(5));
                await process.WaitForExitAsync(timeout.Token);
            }
            catch (Exception ex) when (ex is ArgumentException or InvalidOperationException or System.ComponentModel.Win32Exception or OperationCanceledException) { return false; }
        }
        return true;
    }

    [GeneratedRegex(@"\s+")]
    private static partial Regex Whitespace();

    private static string? ImagePath(int id)
    {
        using var handle = OpenProcess(0x1000, false, id); // PROCESS_QUERY_LIMITED_INFORMATION
        if (handle.IsInvalid) return null;
        var path = new StringBuilder(32768);
        var length = path.Capacity;
        return QueryFullProcessImageName(handle, 0, path, ref length) ? path.ToString() : null;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern SafeProcessHandle OpenProcess(uint access, [MarshalAs(UnmanagedType.Bool)] bool inherit, int processId);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool QueryFullProcessImageName(SafeProcessHandle process, int flags, StringBuilder path, ref int size);
}
