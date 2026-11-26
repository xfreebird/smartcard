using MoldSign.Cli;

namespace MoldSign.Core.Tests;

/// <summary>Operator roots: path admission, bounded reads, exclusive leases and atomic publication.</summary>
public sealed class McpTrustedRootTests : IDisposable
{
    private readonly DirectoryInfo _directory = Directory.CreateTempSubdirectory("esemnbun-root-");

    public void Dispose() => _directory.Delete(true);

    private static string Code(Action action) => Assert.Throws<McpException>(action).Code;
    private static string Code(Func<object?> create) => Assert.Throws<McpException>(create).Code;

    [Fact]
    public void Roots_must_be_existing_absolute_local_directories()
    {
        Assert.Equal("PATH_DENIED", Code(() => new McpTrustedRoot("relative/documents")));
        Assert.Equal("PATH_DENIED", Code(() => new McpTrustedRoot(_directory.FullName + "\0hidden")));
        Assert.Equal("PATH_DENIED", Code(() => new McpTrustedRoot(Path.Combine(_directory.FullName, "missing"))));
        File.WriteAllText(Path.Combine(_directory.FullName, "file.txt"), "x");
        Assert.Equal("PATH_DENIED", Code(() => new McpTrustedRoot(Path.Combine(_directory.FullName, "file.txt"))));
        if (OperatingSystem.IsWindows())
        {
            Assert.Equal("PATH_DENIED", Code(() => new McpTrustedRoot(@"\\localhost\c$\Users")));
            Assert.Equal("PATH_DENIED", Code(() => new McpTrustedRoot(@"\\?\" + _directory.FullName)));
        }
    }

    [Fact]
    public void Reads_are_bounded_and_confined_to_regular_files()
    {
        var nested = _directory.CreateSubdirectory("dosar");
        File.WriteAllBytes(Path.Combine(nested.FullName, "contract.pdf"), [1, 2, 3, 4]);
        using var root = new McpTrustedRoot(_directory.FullName);

        Assert.Equal(new byte[] { 1, 2, 3, 4 }, root.Read("dosar/contract.pdf", 4));
        Assert.Equal("LIMIT_EXCEEDED", Code(() => root.Read("dosar/contract.pdf", 3)));
        Assert.Equal("PATH_DENIED", Code(() => root.Read("dosar", 100)));
        Assert.Equal("PATH_DENIED", Code(() => root.Read("dosar/missing.pdf", 100)));
        foreach (var path in new[] { "", "dosar\\contract.pdf", "C:/x", "dosar//contract.pdf", "./dosar/contract.pdf",
                     "dosar/contract.pdf.", "dosar/contract.pdf ", "dosar/AUX.pdf", "dosar/COM1", "dosar/a|b", new string('a', 1025) })
            Assert.Equal("PATH_DENIED", Code(() => root.Read(path, 100)));
    }

    [Fact]
    public void Publication_replaces_only_when_asked_and_removal_is_name_only()
    {
        using var root = new McpTrustedRoot(_directory.FullName);
        root.Publish("result.json", [1]);
        Assert.Equal("PATH_DENIED", Code(() => root.Publish("result.json", [2])));
        root.Publish("result.json", [3], replace: true);
        Assert.Equal(new byte[] { 3 }, root.Read("result.json", 8));
        Assert.Empty(_directory.GetFiles("*.tmp"));

        Assert.Equal("PATH_DENIED", Code(() => root.Publish("nested/result.json", [4])));
        Assert.Equal("PATH_DENIED", Code(() => root.WriteExclusive("a/b", [4])));
        Assert.Equal("PATH_DENIED", Code(() => root.Remove("../result.json")));
        if (OperatingSystem.IsWindows()) root.Remove("absent.json"); // deleting nothing is not an error there
        else Assert.Equal("PATH_DENIED", Code(() => root.Remove("absent.json")));
        root.Remove("result.json");
        Assert.False(File.Exists(Path.Combine(_directory.FullName, "result.json")));
    }

    [Fact]
    public void Leases_are_exclusive_windows_handles()
    {
        using var root = new McpTrustedRoot(_directory.FullName);
        Assert.Equal("PATH_DENIED", Code(() => root.AcquireLease("nested/.lease")));
        if (!OperatingSystem.IsWindows())
        {
            Assert.Equal("PATH_DENIED", Code(() => root.AcquireLease(".lease")));
            return;
        }
        _directory.CreateSubdirectory("folder");
        Assert.Equal("PATH_DENIED", Code(() => root.AcquireLease("folder")));
        using (var lease = root.AcquireLease(".lease"))
        {
            Assert.True(lease.CanWrite);
            Assert.Equal("PATH_DENIED", Code(() => root.AcquireLease(".lease"))); // held by this broker
        }
        using var again = root.AcquireLease(".lease"); // released with its handle (or the process)
        Assert.True(again.CanRead);
    }

    [Fact]
    public void Removal_and_publication_never_touch_a_directory_in_place_of_a_file()
    {
        var folder = _directory.CreateSubdirectory("dosar");
        File.WriteAllBytes(Path.Combine(folder.FullName, "kept.pdf"), [1]);
        using var root = new McpTrustedRoot(_directory.FullName);

        Assert.Equal("PATH_DENIED", Code(() => root.Remove("dosar")));
        Assert.Equal("PATH_DENIED", Code(() => root.Publish("dosar", [2], replace: true)));
        Assert.Equal("PATH_DENIED", Code(() => root.WriteExclusive("dosar", [2])));
        Assert.True(File.Exists(Path.Combine(folder.FullName, "kept.pdf")));
        Assert.Empty(_directory.GetFiles("*.tmp"));
    }

    [Fact]
    public void A_read_that_fails_after_admission_is_reported_as_denied()
    {
        var path = Path.Combine(_directory.FullName, "locked.pdf");
        File.WriteAllBytes(path, [1, 2, 3, 4]);
        using var root = new McpTrustedRoot(_directory.FullName);
        Assert.Equal(new byte[] { 1, 2, 3, 4 }, root.Read("locked.pdf", 16));
        if (!OperatingSystem.IsWindows()) return; // byte-range locks are advisory (or unsupported) elsewhere
        using var holder = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
        holder.Lock(0, 4); // Windows enforces it: the admitted handle cannot read the locked bytes
        try { Assert.Equal("PATH_DENIED", Code(() => root.Read("locked.pdf", 16))); }
        finally { holder.Unlock(0, 4); }
        Assert.Equal(new byte[] { 1, 2, 3, 4 }, root.Read("locked.pdf", 16));
    }

    [Fact]
    public void A_lease_is_never_taken_through_a_symbolic_link()
    {
        var target = Path.Combine(_directory.FullName, "target.lease");
        File.WriteAllBytes(target, [9]);
        var link = Path.Combine(_directory.FullName, ".lease");
        try { File.CreateSymbolicLink(link, target); }
        catch (Exception error) when (error is UnauthorizedAccessException or IOException)
        {
            // Unprivileged Windows accounts without Developer Mode cannot create symbolic links.
            Assert.True(OperatingSystem.IsWindows(), error.Message);
            return;
        }
        using var root = new McpTrustedRoot(_directory.FullName);
        Assert.Equal("PATH_DENIED", Code(() => root.AcquireLease(".lease")));
        Assert.Equal("PATH_DENIED", Code(() => root.Read(".lease", 16)));
        Assert.Equal(new byte[] { 9 }, File.ReadAllBytes(target));
    }

    [Fact]
    public void A_disposed_root_refuses_every_operation()
    {
        File.WriteAllBytes(Path.Combine(_directory.FullName, "kept.pdf"), [1]);
        var root = new McpTrustedRoot(_directory.FullName);
        root.Dispose();
        root.Dispose(); // idempotent

        Assert.Equal("PATH_DENIED", Code(() => root.Read("kept.pdf", 8)));
        Assert.Equal("PATH_DENIED", Code(() => root.WriteExclusive("new.pdf", [1])));
        Assert.Equal("PATH_DENIED", Code(() => root.Publish("new.pdf", [1])));
        Assert.Equal("PATH_DENIED", Code(() => root.Remove("kept.pdf")));
        Assert.Equal("PATH_DENIED", Code(() => root.AcquireLease(".lease")));
        Assert.True(File.Exists(Path.Combine(_directory.FullName, "kept.pdf")));
    }
}
