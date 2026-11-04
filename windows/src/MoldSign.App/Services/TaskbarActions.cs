using Windows.UI.StartScreen;

namespace MoldSign.App.Services;

/// <summary>Taskbar shortcuts for Store and standalone installations.</summary>
internal static class TaskbarActions
{
    private const string OpenPrefix = "--open-document ";
    private static readonly SemaphoreSlim Gate = new(1, 1);

    public static async Task RefreshAsync(IEnumerable<string>? signedFiles = null)
    {
        await Gate.WaitAsync();
        try
        {
            if (!StartupRegistration.IsPackaged)
            {
                DesktopJumpList.Refresh(signedFiles ?? [], Loc.Get("Action_Sign"), Loc.Get("Action_Verify"),
                    Loc.Get("Jump_RecentSigned"));
                return;
            }
            if (!JumpList.IsSupported()) return;
            var list = await JumpList.LoadCurrentAsync();
            var paths = (signedFiles ?? []).Concat(list.Items
                    .Where(item => !item.RemovedByUser && item.Arguments.StartsWith(OpenPrefix, StringComparison.Ordinal))
                    .Select(item => item.Arguments[OpenPrefix.Length..].Trim('"')))
                .Where(File.Exists).Distinct(StringComparer.OrdinalIgnoreCase).Take(8).ToArray();
            list.Items.Clear();
            list.Items.Add(JumpListItem.CreateWithArguments("--sign", Loc.Get("Action_Sign")));
            list.Items.Add(JumpListItem.CreateWithArguments("--verify", Loc.Get("Action_Verify")));
            foreach (var path in paths)
            {
                var item = JumpListItem.CreateWithArguments($"{OpenPrefix}\"{path}\"", Path.GetFileName(path));
                item.GroupName = Loc.Get("Jump_RecentSigned");
                list.Items.Add(item);
            }
            await list.SaveAsync();
        }
        catch (Exception error) { AppLog.Error(error); }
        finally { Gate.Release(); }
    }
}
