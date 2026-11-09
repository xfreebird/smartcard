using MoldSign.Core.Protection;
using System.Security.AccessControl;
using System.Security.Principal;
namespace MoldSign.Core.Tests;

public sealed class ProtectedFileIOTests
{
    [Fact]
    public void Exclusive_output_preserves_existing_file()
    {
        var root=Path.Combine(Path.GetTempPath(),"esemnbun-protection-"+Guid.NewGuid().ToString("N"));Directory.CreateDirectory(root);
        try {
            var path=Path.Combine(root,"fixture.bin");ProtectedFileIO.SaveNew(path,[1,2,3]);
            Assert.Throws<IOException>(()=>ProtectedFileIO.SaveNew(path,[9]));
            Assert.Equal(new byte[]{1,2,3},ProtectedFileIO.Read(path));
            if(OperatingSystem.IsWindows()) {
                var security=new FileInfo(path).GetAccessControl();var owner=WindowsIdentity.GetCurrent().User!;
                Assert.True(security.AreAccessRulesProtected);
                Assert.Equal(owner,security.GetOwner(typeof(SecurityIdentifier)));
                foreach(FileSystemAccessRule rule in security.GetAccessRules(true,true,typeof(SecurityIdentifier))) Assert.Equal(owner,rule.IdentityReference);
            }
        } finally {Directory.Delete(root,true);}
    }
    [Fact]
    public void Native_windows_removal_deletes_only_selected_test_file()
    {
        if(!OperatingSystem.IsWindows())return;
        var root=Path.Combine(Path.GetTempPath(),"esemnbun-protection-"+Guid.NewGuid().ToString("N"));Directory.CreateDirectory(root);
        try {
            var target=Path.Combine(root,"disposable.bin");var other=Path.Combine(root,"keep.bin");
            File.WriteAllBytes(target,new byte[70000]);File.WriteAllBytes(other,[1,2,3]);
            ProtectedFileIO.OverwriteAndRemove(target);
            Assert.False(File.Exists(target));Assert.Equal(new byte[]{1,2,3},File.ReadAllBytes(other));
            Assert.ThrowsAny<Exception>(()=>ProtectedFileIO.OverwriteAndRemove(root));
            Assert.True(Directory.Exists(root));
        } finally {Directory.Delete(root,true);}
    }
}
