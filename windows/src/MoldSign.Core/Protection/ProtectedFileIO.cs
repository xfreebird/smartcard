using Microsoft.Win32.SafeHandles;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Security.AccessControl;
using System.Security.Principal;
namespace MoldSign.Core.Protection;

public static partial class ProtectedFileIO
{
    public static byte[] Read(string path) {
        using var stream=OpenExisting(path,false);
        if(stream.Length>PasswordFileProtection.MaximumSize+8192) throw new IOException("Choose a file smaller than 64 MB.");
        using var output=new MemoryStream();var buffer=new byte[65536];int count;
        while((count=stream.Read(buffer))>0) {
            if(output.Length+count>PasswordFileProtection.MaximumSize+8192) throw new IOException("File exceeds size limit.");
            output.Write(buffer,0,count);
        }
        return output.ToArray();
    }
    public static void SaveNew(string path,byte[] bytes) {
        // Exclusive creation refuses existing files, including links. Partial output is
        // retained on I/O failure rather than deleting an unverified replacement path.
        if(OperatingSystem.IsWindows()) {
            var owner=WindowsIdentity.GetCurrent().User!;
            var security=new FileSecurity();security.SetOwner(owner);
            security.SetAccessRuleProtection(isProtected:true,preserveInheritance:false);
            security.AddAccessRule(new FileSystemAccessRule(owner,FileSystemRights.FullControl,AccessControlType.Allow));
            using var stream=new System.IO.FileInfo(path).Create(FileMode.CreateNew,FileSystemRights.Write,FileShare.None,4096,FileOptions.WriteThrough,security);
            stream.Write(bytes);stream.Flush(true);
        } else {
            using var stream=new FileStream(path,FileMode.CreateNew,FileAccess.Write,FileShare.None);
            stream.Write(bytes);stream.Flush(true);
        }
    }
    public static void OverwriteAndRemove(string path) {
        if(!OperatingSystem.IsWindows()) throw new PlatformNotSupportedException("Overwrite/removal requires Windows.");
        using var stream=OpenExisting(path,true);
        var buffer=new byte[65536];var remaining=stream.Length;
        try {
            while(remaining>0) {var count=(int)Math.Min(remaining,buffer.Length);RandomNumberGenerator.Fill(buffer);stream.Write(buffer,0,count);remaining-=count;}
            stream.Flush(true);
            // Delete the opened object, never a path that could have been replaced.
            byte disposition=1;
            if(!SetFileInformationByHandle(stream.SafeFileHandle,4,ref disposition,1)) throw new Win32Exception(Marshal.GetLastWin32Error());
        } finally {CryptographicOperations.ZeroMemory(buffer);}
    }
    private static FileStream OpenExisting(string path,bool erase) {
        if(!OperatingSystem.IsWindows()) {
            if((File.GetAttributes(path)&(FileAttributes.ReparsePoint|FileAttributes.Directory))!=0) throw new IOException("Choose a regular local file.");
            return new FileStream(path,FileMode.Open,erase?FileAccess.ReadWrite:FileAccess.Read,FileShare.None);
        }
        var full=Path.GetFullPath(path);
        if(erase && (full.StartsWith(@"\\",StringComparison.Ordinal) || new DriveInfo(Path.GetPathRoot(full)!).DriveType!=DriveType.Fixed)) throw new IOException("Overwrite/removal requires a local fixed drive.");
        var handle=CreateFileW(full,erase?0xC0010000u:0x80000000u,0,0,3,0x00200000,0);
        if(handle.IsInvalid) {handle.Dispose();throw new Win32Exception(Marshal.GetLastWin32Error());}
        try {
            if(!GetFileInformationByHandle(handle,out var info) || GetFileType(handle)!=1 || (info.Attributes & (0x400u|0x10u|0x1000u|0x400000u))!=0 || (erase && info.Links!=1)) throw new IOException("Choose a regular local file with one link.");
            return new FileStream(handle,erase?FileAccess.ReadWrite:FileAccess.Read);
        } catch {handle.Dispose();throw;}
    }
    [StructLayout(LayoutKind.Sequential)]
    private struct FileInfo {
        public uint Attributes,CreationLow,CreationHigh,AccessLow,AccessHigh,WriteLow,WriteHigh,VolumeSerial,SizeHigh,SizeLow,Links,IndexHigh,IndexLow;
    }
    [LibraryImport("kernel32.dll",EntryPoint="CreateFileW",SetLastError=true,StringMarshalling=StringMarshalling.Utf16)]
    private static partial SafeFileHandle CreateFileW(string path,uint access,uint share,nint security,uint disposition,uint flags,nint template);
    [LibraryImport("kernel32.dll",SetLastError=true)]
    [return:MarshalAs(UnmanagedType.Bool)]
    private static partial bool GetFileInformationByHandle(SafeFileHandle file,out FileInfo info);
    [LibraryImport("kernel32.dll")]
    private static partial uint GetFileType(SafeFileHandle file);
    [LibraryImport("kernel32.dll",SetLastError=true)]
    [return:MarshalAs(UnmanagedType.Bool)]
    private static partial bool SetFileInformationByHandle(SafeFileHandle file,int infoClass,ref byte info,uint size);
}
