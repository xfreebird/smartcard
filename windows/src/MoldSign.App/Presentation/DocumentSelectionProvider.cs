using Microsoft.UI.Xaml;
using MoldSign.App.Controls;
using MoldSign.App.Services;
using Windows.ApplicationModel.DataTransfer;

namespace MoldSign.App.Presentation;

internal sealed class DocumentSelectionProvider(AppServices services) : IFileSelectionProvider
{
    public bool AcceptsDrops => !services.IsDemo;
    public string DropUnavailableMessage => Loc.Get("demo_fixture_only");

    public Task<IReadOnlyList<string>> PickAsync(XamlRoot? root, string[] extensions)
    {
        if (services.IsDemo) return Task.FromResult<IReadOnlyList<string>>(services.DemoDocuments);
        if (root is null) throw new InvalidOperationException(Loc.Get("Error_PickerWindow"));
        return WindowHelpers.PickFilesAsync(root, extensions);
    }

    public Task<IReadOnlyList<string>> ReadDropAsync(DataPackageView data) => WindowHelpers.DroppedPathsAsync(data);

    public string DescribeFailure(Exception error)
    {
        AppLog.Error(error);
        return Loc.Format("Error_FileSelection", error.Message);
    }
}
