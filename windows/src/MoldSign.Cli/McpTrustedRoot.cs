using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
using Microsoft.Win32.SafeHandles;

namespace MoldSign.Cli;

/// <summary>Explicit operator authority. Windows directory handles deny rename/delete for
/// the root lifetime; each child is opened as a reparse point and rejected before reading.</summary>
internal sealed class McpTrustedRoot : IDisposable
{
    private readonly string path;
    private readonly List<SafeFileHandle> rootHandles = [];
    private readonly SafeFileHandle? unixRoot;
    private static bool Mac => OperatingSystem.IsMacOS();
    private static int DirectoryFlags => (Mac ? 0x100000 : 0x10000) | (Mac ? 0x100 : 0x20000) | (Mac ? 0x1000000 : 0x80000);

    public McpTrustedRoot(string path, bool privateDirectory = false)
    {
        if (!Path.IsPathFullyQualified(path) || path.Contains('\0')) throw new McpException("PATH_DENIED");
        this.path = Path.GetFullPath(path);
        if (OperatingSystem.IsWindows())
        {
            // Device and UNC namespaces have different path rules and are deliberately excluded.
            if (path.StartsWith("\\", StringComparison.Ordinal) || path.Length < 3 || path[1] != ':')
                throw new McpException("PATH_DENIED");
            var current = Path.GetPathRoot(this.path)!;
            try
            {
                rootHandles.Add(OpenWindows(current, directory: true));
                foreach (var part in this.path[current.Length..].Split(Path.DirectorySeparatorChar, StringSplitOptions.RemoveEmptyEntries))
                {
                    current = Path.Combine(current, part);
                    rootHandles.Add(OpenWindows(current, directory: true));
                }
            }
            catch { Dispose(); throw; }
        }
        else
        {
            var fd = open("/", DirectoryFlags);
            try
            {
                foreach (var part in path.Split('/', StringSplitOptions.RemoveEmptyEntries))
                {
                    ValidatePart(part);
                    var next = openat(fd, part, DirectoryFlags);
                    if (fd >= 0) close(fd);
                    fd = next;
                    if (fd < 0) throw new McpException("PATH_DENIED");
                }
                if (fd < 0) throw new McpException("PATH_DENIED");
                unixRoot = new SafeFileHandle((IntPtr)fd, ownsHandle: true);
            }
            catch { if (fd >= 0) close(fd); throw; }
        }
        if (privateDirectory)
        {
            try
            {
                if (OperatingSystem.IsWindows())
                {
                    var security = new DirectoryInfo(this.path).GetAccessControl();
                    var owner = WindowsIdentity.GetCurrent().User!;
                    if (security.GetOwner(typeof(SecurityIdentifier))?.Equals(owner) != true) throw new McpException("PATH_DENIED");
                    var permitted = new HashSet<string>(StringComparer.Ordinal) { owner.Value, "S-1-5-18", "S-1-5-32-544" };
                    foreach (FileSystemAccessRule rule in security.GetAccessRules(true, true, typeof(SecurityIdentifier)))
                        if (rule.AccessControlType == AccessControlType.Allow && !permitted.Contains(rule.IdentityReference.Value))
                            throw new McpException("PATH_DENIED");
                }
                else if ((File.GetUnixFileMode(this.path) & (UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute |
                    UnixFileMode.GroupRead | UnixFileMode.GroupWrite | UnixFileMode.GroupExecute |
                    UnixFileMode.OtherRead | UnixFileMode.OtherWrite | UnixFileMode.OtherExecute)) !=
                    (UnixFileMode.UserRead | UnixFileMode.UserWrite | UnixFileMode.UserExecute)) throw new McpException("PATH_DENIED");
            }
            catch { Dispose(); throw; }
        }
    }

    public byte[] Read(string relative, int limit)
    {
        if (relative.Length is 0 or > 1024 || relative.Contains('\\') || relative.Contains(':') || relative.Contains('\0'))
            throw new McpException("PATH_DENIED");
        var parts = relative.Split('/');
        foreach (var part in parts) ValidatePart(part);
        var handles = new List<SafeFileHandle>();
        try
        {
            SafeFileHandle file;
            if (OperatingSystem.IsWindows())
            {
                var current = path;
                for (var i = 0; i < parts.Length; i++)
                {
                    current = Path.Combine(current, parts[i]);
                    handles.Add(OpenWindows(current, directory: i != parts.Length - 1));
                }
                file = handles[^1];
            }
            else
            {
                var parent = unixRoot!.DangerousGetHandle().ToInt32();
                for (var i = 0; i < parts.Length; i++)
                {
                    var flags = i < parts.Length - 1 ? DirectoryFlags :
                        (Mac ? 0x100 : 0x20000) | (Mac ? 0x1000000 : 0x80000) | (Mac ? 4 : 2048);
                    var fd = openat(parent, parts[i], flags);
                    if (fd < 0) throw new McpException("PATH_DENIED");
                    handles.Add(new SafeFileHandle((IntPtr)fd, ownsHandle: true));
                    parent = fd;
                }
                file = handles[^1];
            }
            using var stream = new FileStream(file, FileAccess.Read);
            if (!stream.CanSeek) throw new McpException("PATH_DENIED");
            if (stream.Length > limit) throw new McpException("LIMIT_EXCEEDED");
            using var bytes = new MemoryStream();
            var buffer = new byte[65536];
            int count;
            while ((count = stream.Read(buffer)) != 0)
            {
                if (bytes.Length + count > limit) throw new McpException("LIMIT_EXCEEDED");
                bytes.Write(buffer, 0, count);
            }
            return bytes.ToArray();
        }
        catch (McpException) { throw; }
        catch { throw new McpException("PATH_DENIED"); }
        finally { foreach (var handle in handles) handle.Dispose(); }
    }

    public void WriteExclusive(string name, byte[] bytes)
    {
        ValidatePart(name);
        if (name.Contains('/')) throw new McpException("PATH_DENIED");
        try
        {
            if (OperatingSystem.IsWindows())
            {
                using var stream = new FileStream(Path.Combine(path, name), FileMode.CreateNew, FileAccess.Write,
                    FileShare.None, 4096, FileOptions.WriteThrough);
                stream.Write(bytes);
                stream.Flush(flushToDisk: true);
            }
            else
            {
                var flags = 1 | (Mac ? 0x200 : 0x40) | (Mac ? 0x800 : 0x80) | (Mac ? 0x100 : 0x20000);
                var fd = openatCreate(unixRoot!.DangerousGetHandle().ToInt32(), name, flags, 0x180);
                if (fd < 0) throw new McpException("PATH_DENIED");
                using var handle = new SafeFileHandle((IntPtr)fd, ownsHandle: true);
                using var stream = new FileStream(handle, FileAccess.Write);
                stream.Write(bytes);
                stream.Flush(flushToDisk: true);
                if (fsync(unixRoot.DangerousGetHandle().ToInt32()) != 0) throw new McpException("PATH_DENIED");
            }
        }
        catch (McpException) { throw; }
        catch { throw new McpException("PATH_DENIED"); }
    }

    public void Remove(string name)
    {
        ValidatePart(name);
        if (name.Contains('/')) throw new McpException("PATH_DENIED");
        try
        {
            if (OperatingSystem.IsWindows()) File.Delete(Path.Combine(path, name));
            else if (unlinkat(unixRoot!.DangerousGetHandle().ToInt32(), name, 0) != 0 ||
                     fsync(unixRoot.DangerousGetHandle().ToInt32()) != 0) throw new McpException("PATH_DENIED");
        }
        catch { throw new McpException("PATH_DENIED"); }
    }

    private static void ValidatePart(string part)
    {
        var basename = part.Split('.')[0].ToUpperInvariant();
        if (basename is "CON" or "PRN" or "AUX" or "NUL" ||
            basename.Length == 4 && (basename.StartsWith("COM", StringComparison.Ordinal) || basename.StartsWith("LPT", StringComparison.Ordinal)) && basename[3] is >= '1' and <= '9')
            throw new McpException("PATH_DENIED");
        if (part.Length == 0 || part is "." or ".." || part.EndsWith('.') || part.EndsWith(' ') ||
            part.Any(char.IsControl) || part.IndexOfAny([':', '\\', '*', '?', '<', '>', '|']) >= 0)
            throw new McpException("PATH_DENIED");
    }

    private static SafeFileHandle OpenWindows(string name, bool directory)
    {
        var handle = CreateFileW(name, 0x80000000, 1, IntPtr.Zero, 3, 0x00200000 | (directory ? 0x02000000u : 0), IntPtr.Zero);
        if (handle.IsInvalid) { handle.Dispose(); throw new McpException("PATH_DENIED"); }
        if (!GetFileInformationByHandle(handle, out var info) || (info.Attributes & 0x400) != 0 ||
            ((info.Attributes & 0x10) != 0) != directory)
        { handle.Dispose(); throw new McpException("PATH_DENIED"); }
        return handle;
    }

    public void Dispose()
    {
        unixRoot?.Dispose();
        foreach (var handle in rootHandles) handle.Dispose();
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct FileInformation
    {
        public uint Attributes;
        public System.Runtime.InteropServices.ComTypes.FILETIME Creation, Access, Write;
        public uint Volume, SizeHigh, SizeLow, Links, IndexHigh, IndexLow;
    }
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern SafeFileHandle CreateFileW(string name, uint access, uint share, IntPtr security, uint creation, uint flags, IntPtr template);
    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetFileInformationByHandle(SafeFileHandle handle, out FileInformation info);
    [DllImport("libc", SetLastError = true)] private static extern int open(string path, int flags);
    [DllImport("libc", SetLastError = true)] private static extern int openat(int fd, string path, int flags);
    [DllImport("libc", EntryPoint = "openat", SetLastError = true)] private static extern int openatCreate(int fd, string path, int flags, uint mode);
    [DllImport("libc", SetLastError = true)] private static extern int unlinkat(int fd, string path, int flags);
    [DllImport("libc", SetLastError = true)] private static extern int fsync(int fd);
    [DllImport("libc")] private static extern int close(int fd);
}

internal sealed class McpException(string code) : Exception { public string Code { get; } = code; }
