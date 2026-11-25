using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

namespace MoldSign.Cli;

/// <summary>Operator-selected credential references, never model-provided PINs or commands.</summary>
internal static partial class WindowsMcpCredentialSource
{
    public static Func<string> Create(string source, string? onePasswordExecutable = null)
    {
        Func<string> read;
        if (source.StartsWith("env:", StringComparison.Ordinal))
        {
            var name = source[4..];
            if (name.Length is 0 or > 128 || !name.All(c => char.IsAsciiLetterOrDigit(c) || c == '_'))
                throw new McpException("INVALID_ARGUMENT");
            read = () => Environment.GetEnvironmentVariable(name) ?? throw new McpException("CREDENTIAL_UNAVAILABLE");
        }
        else if (source.StartsWith("credential:", StringComparison.Ordinal))
        {
            var target = source[11..];
            if (target.Length is 0 or > 255 || target.Any(char.IsControl)) throw new McpException("INVALID_ARGUMENT");
            read = () => ReadWindowsCredential(target);
        }
        else if (source.StartsWith("onepassword:", StringComparison.Ordinal))
        {
            var reference = source[12..];
            if (!reference.StartsWith("op://", StringComparison.Ordinal) || reference.Length > 2048 || reference.Any(char.IsControl) ||
                onePasswordExecutable is null || !Path.IsPathFullyQualified(onePasswordExecutable) ||
                onePasswordExecutable.Any(char.IsControl)) throw new McpException("INVALID_ARGUMENT");
            read = () => ReadCommand(onePasswordExecutable, reference);
        }
        else throw new McpException("INVALID_ARGUMENT");
        return () =>
        {
            var pin = read();
            if (pin.Length is < 4 or > 8 || !pin.All(char.IsAsciiDigit)) throw new McpException("CREDENTIAL_UNAVAILABLE");
            return pin;
        };
    }

    private static string ReadWindowsCredential(string target)
    {
        if (!OperatingSystem.IsWindows() || !CredReadW(target, 1, 0, out var pointer))
            throw new McpException("CREDENTIAL_UNAVAILABLE");
        try
        {
            var credential = Marshal.PtrToStructure<Credential>(pointer);
            // Dedicated generic credential containing a UTF-16 PIN; never the app's Hello vault.
            if (credential.BlobSize is 0 or > 32 || credential.BlobSize % 2 != 0)
                throw new McpException("CREDENTIAL_UNAVAILABLE");
            return Marshal.PtrToStringUni(credential.Blob, (int)credential.BlobSize / 2) ??
                throw new McpException("CREDENTIAL_UNAVAILABLE");
        }
        finally { CredFree(pointer); }
    }

    internal static string ReadCommand(string executable, string reference, TimeSpan? timeout = null)
    {
        using var process = new Process { StartInfo = new ProcessStartInfo(executable)
        {
            UseShellExecute = false, CreateNoWindow = true, RedirectStandardInput = true,
            RedirectStandardOutput = true, RedirectStandardError = true
        }};
        process.StartInfo.ArgumentList.Add("read");
        process.StartInfo.ArgumentList.Add("--no-newline");
        process.StartInfo.ArgumentList.Add(reference);
        try
        {
            if (!process.Start()) throw new McpException("CREDENTIAL_UNAVAILABLE");
            process.StandardInput.Close();
            using var deadline = new CancellationTokenSource(timeout ?? TimeSpan.FromSeconds(20));
            var token = deadline.Token;
            var stdout = ReadBounded(process.StandardOutput.BaseStream, token);
            // Discard diagnostics with a fixed buffer rather than retaining provider output.
            var stderr = Discard(process.StandardError.BaseStream, token);
            Task.WhenAll(stdout, stderr, process.WaitForExitAsync(token)).WaitAsync(token).GetAwaiter().GetResult();
            if (process.ExitCode != 0) throw new McpException("CREDENTIAL_UNAVAILABLE");
            return Encoding.UTF8.GetString(stdout.Result);
        }
        catch
        {
            try { if (!process.HasExited) process.Kill(entireProcessTree: true); } catch { }
            throw new McpException("CREDENTIAL_UNAVAILABLE");
        }
    }
    private static async Task<byte[]> ReadBounded(Stream stream, CancellationToken token)
    {
        var bytes = new byte[33];
        var total = 0;
        while (true)
        {
            var count = await stream.ReadAsync(bytes.AsMemory(total), token).ConfigureAwait(false);
            if (count == 0) return bytes[..total];
            total += count;
            if (total > 32) throw new McpException("CREDENTIAL_UNAVAILABLE");
        }
    }
    private static async Task Discard(Stream stream, CancellationToken token)
    {
        var buffer = new byte[4096];
        while (await stream.ReadAsync(buffer, token).ConfigureAwait(false) != 0) { }
    }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct Credential
    {
        public uint Flags, Type;
        public IntPtr TargetName, Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public uint BlobSize;
        public IntPtr Blob;
        public uint Persist, AttributeCount;
        public IntPtr Attributes, TargetAlias, UserName;
    }
    [LibraryImport("advapi32.dll", StringMarshalling = StringMarshalling.Utf16, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static partial bool CredReadW(string target, uint type, uint flags, out IntPtr credential);
    [LibraryImport("advapi32.dll")] private static partial void CredFree(IntPtr credential);
}
