using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;

namespace MoldSign.App.Services;

/// <summary>Windows Shell jump list for MSI/portable apps without package identity.</summary>
internal static class DesktopJumpList
{
    // Must match the MSI Start-menu shortcut property. Test runs have a separate Shell identity.
    private static string AppId => AppSettings.IsolatedTestPreferences ? "md.esemnbun.desktop.Validation" : "md.esemnbun.desktop";
    private static string HistoryPath => Path.Combine(Path.GetDirectoryName(AppSettings.PreferencesPath)!, "taskbar.json");
    private const string OpenPrefix = "--open-document ";

    public static void Initialize()
    {
        try { Marshal.ThrowExceptionForHR(SetCurrentProcessExplicitAppUserModelID(AppId)); }
        catch (COMException error) { AppLog.Error(error); }
    }

    public static void Refresh(IEnumerable<string> signedFiles, string signTitle, string verifyTitle, string recentTitle)
    {
        var destination = Create<ICustomDestinationList>("77F10CF0-3DB5-4966-B520-B7C54FD35ED6");
        var references = new List<object> { destination };
        var begun = false;
        try
        {
            destination.SetAppID(AppId);
            var arrayId = typeof(IObjectArray).GUID;
            destination.BeginList(out var slots, ref arrayId, out var removed);
            references.Add(removed);
            begun = true;
            var removedArguments = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            removed.GetCount(out var count);
            var linkId = typeof(IShellLink).GUID;
            for (uint i = 0; i < count; i++)
            {
                removed.GetAt(i, ref linkId, out var item);
                references.Add(item);
                var arguments = new StringBuilder(32768);
                ((IShellLink)item).GetArguments(arguments, arguments.Capacity);
                removedArguments.Add(arguments.ToString());
            }

            string[] previous = [];
            if (File.Exists(HistoryPath))
            {
                try { previous = JsonSerializer.Deserialize<string[]>(File.ReadAllText(HistoryPath)) ?? []; }
                catch (JsonException) { /* A damaged history must not disable taskbar actions. */ }
            }
            var paths = signedFiles.Concat(previous).Where(File.Exists)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .Where(path => !removedArguments.Contains(Arguments(path))).Take(8).ToArray();
            var tasks = Collection(references);
            tasks.AddObject(Link("--sign", signTitle, references));
            tasks.AddObject(Link("--verify", verifyTitle, references));
            destination.AddUserTasks(tasks);
            if (paths.Length > 0 && slots > 0)
            {
                var recents = Collection(references);
                foreach (var path in paths.Take((int)Math.Min(slots, 8)))
                    recents.AddObject(Link(Arguments(path), Path.GetFileName(path), references));
                // Windows can disable document history. Keep Sign/Verify tasks available in that case.
                try { destination.AppendCategory(recentTitle, recents); }
                catch (COMException error) when (error.HResult == unchecked((int)0x80070005)) { }
            }
            destination.CommitList();
            begun = false;
            Directory.CreateDirectory(Path.GetDirectoryName(HistoryPath)!);
            File.WriteAllText(HistoryPath, JsonSerializer.Serialize(paths));
        }
        finally
        {
            if (begun)
            {
                try { destination.AbortList(); }
                catch (COMException) { }
            }
            for (var i = references.Count - 1; i >= 0; i--)
                if (Marshal.IsComObject(references[i])) Marshal.ReleaseComObject(references[i]);
        }
    }

    private static string Arguments(string path) => $"{OpenPrefix}\"{path}\"";

    private static IObjectCollection Collection(List<object> references)
    {
        var collection = Create<IObjectCollection>("2D3468C1-36A7-43B6-AC24-D3F02FD9607A");
        references.Add(collection);
        return collection;
    }

    private static IShellLink Link(string arguments, string title, List<object> references)
    {
        var link = Create<IShellLink>("00021401-0000-0000-C000-000000000046");
        references.Add(link);
        var executable = Environment.ProcessPath!;
        link.SetPath(executable);
        link.SetWorkingDirectory(AppContext.BaseDirectory);
        link.SetArguments(arguments);
        link.SetIconLocation(executable, 0);
        link.SetDescription(title);
        var store = (IPropertyStore)link;
        var key = new PropertyKey { Format = new Guid("F29F85E0-4FF9-1068-AB91-08002B27B3D9"), Id = 2 }; // System.Title
        var value = new PropVariant { Type = 31, Pointer = Marshal.StringToCoTaskMemUni(title) };
        try { store.SetValue(ref key, ref value); store.Commit(); }
        finally { Marshal.FreeCoTaskMem(value.Pointer); }
        return link;
    }

    private static T Create<T>(string classId) => (T)Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid(classId))!)!;

    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    private static extern int SetCurrentProcessExplicitAppUserModelID(string appId);

    [StructLayout(LayoutKind.Sequential)]
    private struct PropertyKey { public Guid Format; public uint Id; }
    [StructLayout(LayoutKind.Explicit, Size = 24)]
    private struct PropVariant
    {
        [FieldOffset(0)] public ushort Type;
        [FieldOffset(8)] public nint Pointer;
    }

    [ComImport, Guid("6332DEBF-87B5-4670-90C0-5E57B408A49E"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface ICustomDestinationList
    {
        void SetAppID([MarshalAs(UnmanagedType.LPWStr)] string id);
        void BeginList(out uint slots, ref Guid iid, [MarshalAs(UnmanagedType.Interface)] out IObjectArray removed);
        void AppendCategory([MarshalAs(UnmanagedType.LPWStr)] string name, IObjectArray items);
        void AppendKnownCategory(int category);
        void AddUserTasks(IObjectArray tasks);
        void CommitList();
        void GetRemovedDestinations(ref Guid iid, [MarshalAs(UnmanagedType.Interface)] out object removed);
        void DeleteList([MarshalAs(UnmanagedType.LPWStr)] string id);
        void AbortList();
    }

    [ComImport, Guid("92CA9DCD-5622-4BBA-A805-5E9F541BD8C9"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IObjectArray
    {
        void GetCount(out uint count);
        void GetAt(uint index, ref Guid iid, [MarshalAs(UnmanagedType.Interface)] out object item);
    }

    [ComImport, Guid("5632B1A4-E38A-400A-928A-D4CD63230295"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IObjectCollection : IObjectArray
    {
        new void GetCount(out uint count);
        new void GetAt(uint index, ref Guid iid, [MarshalAs(UnmanagedType.Interface)] out object item);
        void AddObject([MarshalAs(UnmanagedType.Interface)] object item);
        void AddFromArray(IObjectArray items);
        void RemoveObjectAt(uint index);
        void Clear();
    }

    [ComImport, Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IPropertyStore
    {
        void GetCount(out uint count);
        void GetAt(uint index, out PropertyKey key);
        void GetValue(ref PropertyKey key, out PropVariant value);
        void SetValue(ref PropertyKey key, ref PropVariant value);
        void Commit();
    }

    [ComImport, Guid("000214F9-0000-0000-C000-000000000046"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IShellLink
    {
        void GetPath(nint file, int size, nint data, uint flags);
        void GetIDList(out nint id);
        void SetIDList(nint id);
        void GetDescription(nint text, int size);
        void SetDescription([MarshalAs(UnmanagedType.LPWStr)] string text);
        void GetWorkingDirectory(nint text, int size);
        void SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string path);
        void GetArguments([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder text, int size);
        void SetArguments([MarshalAs(UnmanagedType.LPWStr)] string text);
        void GetHotkey(out ushort key);
        void SetHotkey(ushort key);
        void GetShowCmd(out int command);
        void SetShowCmd(int command);
        void GetIconLocation(nint path, int size, out int index);
        void SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string path, int index);
        void SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string path, uint reserved);
        void Resolve(nint window, uint flags);
        void SetPath([MarshalAs(UnmanagedType.LPWStr)] string path);
    }
}
