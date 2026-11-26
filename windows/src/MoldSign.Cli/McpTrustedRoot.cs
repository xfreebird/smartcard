using System.Runtime.InteropServices;
using System.Security.AccessControl;
using System.Security.Principal;
using Microsoft.Win32.SafeHandles;

namespace MoldSign.Cli;

/// <summary>Explicit operator authority. Windows directory handles deny rename/delete for
/// the root lifetime; each child is opened as a reparse point and rejected before reading.</summary>
internal sealed partial class McpTrustedRoot : IDisposable
{
    private readonly string path;
    private readonly object lifetime = new();
    private bool disposed;
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
            if (path.StartsWith('\\') || path.Length < 3 || path[1] != ':')
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
                    // A failed close of a read-only directory descriptor leaves nothing to recover.
                    if (fd >= 0) _ = close(fd);
                    fd = next;
                    if (fd < 0) throw new McpException("PATH_DENIED");
                }
                if (fd < 0) throw new McpException("PATH_DENIED");
                unixRoot = new SafeFileHandle((IntPtr)fd, ownsHandle: true);
            }
            catch
            {
                if (fd >= 0) _ = close(fd);
                throw;
            }
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

    public byte[] Read(string relative, int limit, bool privateFile = false)
    {
        lock (lifetime)
        {
            if (disposed) throw new McpException("PATH_DENIED");
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
                    var parent = unixRoot!;
                    for (var i = 0; i < parts.Length; i++)
                    {
                        var flags = i < parts.Length - 1 ? DirectoryFlags :
                            (Mac ? 0x100 : 0x20000) | (Mac ? 0x1000000 : 0x80000) | (Mac ? 4 : 2048);
                        var fd = openat(parent, parts[i], flags);
                        if (fd < 0) throw new McpException("PATH_DENIED");
                        parent = new SafeFileHandle((IntPtr)fd, ownsHandle: true);
                        handles.Add(parent);
                    }
                    file = handles[^1];
                }
                using var stream = new FileStream(file, FileAccess.Read);
                if (privateFile)
                {
                    if (OperatingSystem.IsWindows())
                    {
                        var security = stream.GetAccessControl();
                        var owner = WindowsIdentity.GetCurrent().User!;
                        if (security.GetOwner(typeof(SecurityIdentifier))?.Equals(owner) != true) throw new McpException("PATH_DENIED");
                        var permitted = new HashSet<string>(StringComparer.Ordinal) { owner.Value, "S-1-5-18", "S-1-5-32-544" };
                        foreach (FileSystemAccessRule rule in security.GetAccessRules(true, true, typeof(SecurityIdentifier)))
                            if (rule.AccessControlType == AccessControlType.Allow && !permitted.Contains(rule.IdentityReference.Value)) throw new McpException("PATH_DENIED");
                    }
                    else if ((File.GetUnixFileMode(file) & (UnixFileMode.GroupRead | UnixFileMode.GroupWrite | UnixFileMode.GroupExecute |
                        UnixFileMode.OtherRead | UnixFileMode.OtherWrite | UnixFileMode.OtherExecute)) != 0) throw new McpException("PATH_DENIED");
                }
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
    }

    public void WriteExclusive(string name, byte[] bytes)
    {
        lock (lifetime)
        {
            if (disposed) throw new McpException("PATH_DENIED");
            ValidatePart(name);
            if (name.Contains('/')) throw new McpException("PATH_DENIED");
            try
            {
                if (OperatingSystem.IsWindows())
                {
                    // Elevated Windows tokens can default new files to Administrators ownership.
                    // Set the current-user owner and private ACL at exclusive creation, before any bytes exist.
                    var owner = WindowsIdentity.GetCurrent().User!;
                    var security = new FileSecurity();
                    security.SetOwner(owner);
                    security.SetAccessRuleProtection(isProtected: true, preserveInheritance: false);
                    security.AddAccessRule(new FileSystemAccessRule(owner, FileSystemRights.FullControl, AccessControlType.Allow));
                    using var stream = new FileInfo(Path.Combine(path, name)).Create(FileMode.CreateNew, FileSystemRights.Write,
                        FileShare.None, 4096, FileOptions.WriteThrough, security);
                    stream.Write(bytes);
                    stream.Flush(flushToDisk: true);
                }
                else
                {
                    var flags = 1 | (Mac ? 0x200 : 0x40) | (Mac ? 0x800 : 0x80) | (Mac ? 0x100 : 0x20000);
                    const uint ownerReadWrite = 0x180; // 0600
                    var fd = Mac && RuntimeInformation.ProcessArchitecture == Architecture.Arm64
                        ? openatCreateDarwinArm64(unixRoot!, name, flags, 0, 0, 0, 0, 0, ownerReadWrite)
                        : openatCreate(unixRoot!, name, flags, ownerReadWrite);
                    if (fd < 0) throw new McpException("PATH_DENIED");
                    using var handle = new SafeFileHandle((IntPtr)fd, ownsHandle: true);
                    using var stream = new FileStream(handle, FileAccess.Write);
                    stream.Write(bytes);
                    stream.Flush(flushToDisk: true);
                    if (fsync(unixRoot!) != 0) throw new McpException("PATH_DENIED");
                }
            }
            catch (McpException) { throw; }
            catch { throw new McpException("PATH_DENIED"); }

        }
    }

    // OS-owned lease is released on process death; no persistent lock prevents broker restart.
    public FileStream AcquireLease(string name)
    {
        lock (lifetime)
        {
            if (disposed) throw new McpException("PATH_DENIED");
            ValidatePart(name);
            if (name.Contains('/') || !OperatingSystem.IsWindows()) throw new McpException("PATH_DENIED");
            var handle = CreateFileW(Path.Combine(path, name), 0xC0000000, 0, IntPtr.Zero, 4, 0x00200000, IntPtr.Zero);
            if (handle.IsInvalid) { handle.Dispose(); throw new McpException("PATH_DENIED"); }
            if (!GetFileInformationByHandle(handle, out var info) || (info.Attributes & (0x400 | 0x10)) != 0)
            { handle.Dispose(); throw new McpException("PATH_DENIED"); }
            return new FileStream(handle, FileAccess.ReadWrite);

        }
    }

    // Publish only fully flushed files. Temporary names are never considered requests.
    public void Publish(string name, byte[] bytes, bool replace = false)
    {
        lock (lifetime)
        {
            if (disposed) throw new McpException("PATH_DENIED");
            ValidatePart(name);
            if (name.Contains('/')) throw new McpException("PATH_DENIED");
            var temporary = Guid.NewGuid().ToString("D") + ".tmp";
            WriteExclusive(temporary, bytes);
            try
            {
                if (OperatingSystem.IsWindows()) File.Move(Path.Combine(path, temporary), Path.Combine(path, name), replace);
                else
                {
                    var directory = unixRoot!;
                    if (replace)
                    {
                        if (renameat(directory, temporary, directory, name) != 0) throw new McpException("PATH_DENIED");
                    }
                    else
                    {
                        if (linkat(directory, temporary, directory, name, 0) != 0) throw new McpException("PATH_DENIED");
                        if (unlinkat(directory, temporary, 0) != 0) throw new McpException("PATH_DENIED");
                    }
                    if (fsync(directory) != 0) throw new McpException("PATH_DENIED");
                }
            }
            catch (McpException) { throw; }
            catch { throw new McpException("PATH_DENIED"); }
            finally { try { Remove(temporary); } catch { } }

        }
    }

    public void Remove(string name)
    {
        lock (lifetime)
        {
            if (disposed) throw new McpException("PATH_DENIED");
            ValidatePart(name);
            if (name.Contains('/')) throw new McpException("PATH_DENIED");
            try
            {
                if (OperatingSystem.IsWindows()) File.Delete(Path.Combine(path, name));
                else if (unlinkat(unixRoot!, name, 0) != 0 ||
                         fsync(unixRoot!) != 0) throw new McpException("PATH_DENIED");
            }
            catch { throw new McpException("PATH_DENIED"); }

        }
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
        // Allow writes through directory handles so atomic publication can rename children.
        // Omit FILE_SHARE_DELETE to keep every directory component pinned against replacement.
        // File readers still deny write/delete while their bytes are being inspected.
        var share = directory ? 3u : 1u; // FILE_SHARE_READ | FILE_SHARE_WRITE for directories only.
        var handle = CreateFileW(name, 0x80000000, share, IntPtr.Zero, 3, 0x00200000 | (directory ? 0x02000000u : 0), IntPtr.Zero);
        if (handle.IsInvalid) { handle.Dispose(); throw new McpException("PATH_DENIED"); }
        if (!GetFileInformationByHandle(handle, out var info) || (info.Attributes & 0x400) != 0 ||
            ((info.Attributes & 0x10) != 0) != directory)
        { handle.Dispose(); throw new McpException("PATH_DENIED"); }
        return handle;
    }

    public void Dispose()
    {
        lock (lifetime)
        {
            if (disposed) return;
            disposed = true;
            unixRoot?.Dispose();
            foreach (var handle in rootHandles) handle.Dispose();
        }
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct FileInformation
    {
        public uint Attributes;
        // Three FILETIMEs (creation, access, write) as low/high DWORD pairs: keeps the struct blittable.
        public uint CreationLow, CreationHigh, AccessLow, AccessHigh, WriteLow, WriteHigh;
        public uint Volume, SizeHigh, SizeLow, Links, IndexHigh, IndexLow;
    }
    [LibraryImport("kernel32.dll", StringMarshalling = StringMarshalling.Utf16, SetLastError = true)]
    private static partial SafeFileHandle CreateFileW(string name, uint access, uint share, IntPtr security, uint creation, uint flags, IntPtr template);
    [LibraryImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static partial bool GetFileInformationByHandle(SafeFileHandle handle, out FileInformation info);
    [LibraryImport("libc", StringMarshalling = StringMarshalling.Utf8, SetLastError = true)] private static partial int open(string path, int flags);
    [LibraryImport("libc", StringMarshalling = StringMarshalling.Utf8, SetLastError = true)] private static partial int openat(int fd, string path, int flags);
    // The runtime holds the descriptor open through each native call; the lifetime lock covers the full operation.
    [LibraryImport("libc", StringMarshalling = StringMarshalling.Utf8, SetLastError = true)] private static partial int openat(SafeFileHandle fd, string path, int flags);
    [LibraryImport("libc", EntryPoint = "openat", StringMarshalling = StringMarshalling.Utf8, SetLastError = true)] private static partial int openatCreate(SafeFileHandle fd, string path, int flags, uint mode);
    // Darwin ARM64 passes the variadic mode on the stack, after eight integer argument registers.
    [LibraryImport("libc", EntryPoint = "openat", StringMarshalling = StringMarshalling.Utf8, SetLastError = true)]
    private static partial int openatCreateDarwinArm64(SafeFileHandle fd, string path, int flags,
        nint unused3, nint unused4, nint unused5, nint unused6, nint unused7, uint mode);
    [LibraryImport("libc", StringMarshalling = StringMarshalling.Utf8, SetLastError = true)] private static partial int unlinkat(SafeFileHandle fd, string path, int flags);
    [LibraryImport("libc", StringMarshalling = StringMarshalling.Utf8, SetLastError = true)] private static partial int linkat(SafeFileHandle from, string source, SafeFileHandle to, string destination, int flags);
    [LibraryImport("libc", StringMarshalling = StringMarshalling.Utf8, SetLastError = true)] private static partial int renameat(SafeFileHandle from, string source, SafeFileHandle to, string destination);
    [LibraryImport("libc", SetLastError = true)] private static partial int fsync(SafeFileHandle fd);
    [LibraryImport("libc")] private static partial int close(int fd);
}

internal sealed class McpException(string code) : Exception { public string Code { get; } = code; }
